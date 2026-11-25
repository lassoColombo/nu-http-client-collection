# Auto-generated client for Amazon Elastic Kubernetes Service v2017-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/eks/2017-11-01/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_KUBERNETES_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://eks.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ELASTIC_KUBERNETES_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://eks.us-east-1.amazonaws.com" "http://eks.us-east-2.amazonaws.com" "http://eks.us-west-1.amazonaws.com" "http://eks.us-west-2.amazonaws.com" "http://eks.us-gov-west-1.amazonaws.com" "http://eks.us-gov-east-1.amazonaws.com" "http://eks.ca-central-1.amazonaws.com" "http://eks.eu-north-1.amazonaws.com" "http://eks.eu-west-1.amazonaws.com" "http://eks.eu-west-2.amazonaws.com" "http://eks.eu-west-3.amazonaws.com" "http://eks.eu-central-1.amazonaws.com" "http://eks.eu-south-1.amazonaws.com" "http://eks.af-south-1.amazonaws.com" "http://eks.ap-northeast-1.amazonaws.com" "http://eks.ap-northeast-2.amazonaws.com" "http://eks.ap-northeast-3.amazonaws.com" "http://eks.ap-southeast-1.amazonaws.com" "http://eks.ap-southeast-2.amazonaws.com" "http://eks.ap-east-1.amazonaws.com" "http://eks.ap-south-1.amazonaws.com" "http://eks.sa-east-1.amazonaws.com" "http://eks.me-south-1.amazonaws.com" "https://eks.us-east-1.amazonaws.com" "https://eks.us-east-2.amazonaws.com" "https://eks.us-west-1.amazonaws.com" "https://eks.us-west-2.amazonaws.com" "https://eks.us-gov-west-1.amazonaws.com" "https://eks.us-gov-east-1.amazonaws.com" "https://eks.ca-central-1.amazonaws.com" "https://eks.eu-north-1.amazonaws.com" "https://eks.eu-west-1.amazonaws.com" "https://eks.eu-west-2.amazonaws.com" "https://eks.eu-west-3.amazonaws.com" "https://eks.eu-central-1.amazonaws.com" "https://eks.eu-south-1.amazonaws.com" "https://eks.af-south-1.amazonaws.com" "https://eks.ap-northeast-1.amazonaws.com" "https://eks.ap-northeast-2.amazonaws.com" "https://eks.ap-northeast-3.amazonaws.com" "https://eks.ap-southeast-1.amazonaws.com" "https://eks.ap-southeast-2.amazonaws.com" "https://eks.ap-east-1.amazonaws.com" "https://eks.ap-south-1.amazonaws.com" "https://eks.sa-east-1.amazonaws.com" "https://eks.me-south-1.amazonaws.com" "http://eks.cn-north-1.amazonaws.com.cn" "http://eks.cn-northwest-1.amazonaws.com.cn" "https://eks.cn-north-1.amazonaws.com.cn" "https://eks.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resolve-conflicts-completer [] { ["NONE" "OVERWRITE" "PRESERVE"] }
def ami-type-completer [] { ["AL2_ARM_64" "AL2_x86_64" "AL2_x86_64_GPU" "BOTTLEROCKET_ARM_64" "BOTTLEROCKET_ARM_64_NVIDIA" "BOTTLEROCKET_x86_64" "BOTTLEROCKET_x86_64_NVIDIA" "CUSTOM" "WINDOWS_CORE_2019_x86_64" "WINDOWS_CORE_2022_x86_64" "WINDOWS_FULL_2019_x86_64" "WINDOWS_FULL_2022_x86_64"] }
def capacity-type-completer [] { ["ON_DEMAND" "SPOT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-encryption-config: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    associate-identity-provider-config: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>, tags: record>"
    create-addon: "record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>"
    list-addons: "record<addons: list<string>, nextToken: string>"
    create-cluster: "record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>"
    list-clusters: "record<clusters: list<string>, nextToken: string>"
    create-fargate-profile: "record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>"
    list-fargate-profiles: "record<fargateProfileNames: list<string>, nextToken: string>"
    create-nodegroup: "record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>"
    list-nodegroups: "record<nodegroups: list<string>, nextToken: string>"
    delete-addon: "record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>"
    describe-addon: "record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>"
    delete-cluster: "record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>"
    describe-cluster: "record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>"
    delete-fargate-profile: "record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>"
    describe-fargate-profile: "record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>"
    delete-nodegroup: "record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>"
    describe-nodegroup: "record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>"
    deregister-cluster: "record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>"
    describe-addon-configuration: "record<addonName: string, addonVersion: string, configurationSchema: string>"
    describe-addon-versions: "record<addons: table<addonName: string, type: string, addonVersions: list, publisher: string, owner: string, marketplaceInformation: record>, nextToken: string>"
    describe-identity-provider-config: "record<identityProviderConfig: record<oidc: record<identityProviderConfigName: string, identityProviderConfigArn: string, clusterName: string, issuerUrl: string, clientId: string, usernameClaim: string, usernamePrefix: string, groupsClaim: string, groupsPrefix: string, requiredClaims: record, tags: record, status: string>>>"
    describe-update: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    disassociate-identity-provider-config: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    list-identity-provider-configs: "record<identityProviderConfigs: table<type: string, name: string>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    list-updates: "record<updateIds: list<string>, nextToken: string>"
    update-cluster-version: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    register-cluster: "record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>"
    untag-resource: "record"
    update-addon: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    update-cluster-config: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    update-nodegroup-config: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
    update-nodegroup-version: "record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-encryption-config" "associate-identity-provider-config" "create-addon" "list-addons" "create-cluster" "list-clusters" "create-fargate-profile" "list-fargate-profiles" "create-nodegroup" "list-nodegroups" "delete-addon" "describe-addon" "delete-cluster" "describe-cluster" "delete-fargate-profile" "describe-fargate-profile" "delete-nodegroup" "describe-nodegroup" "deregister-cluster" "describe-addon-configuration" "describe-addon-versions" "describe-identity-provider-config" "describe-update" "disassociate-identity-provider-config" "list-identity-provider-configs" "list-tags-for-resource" "tag-resource" "list-updates" "update-cluster-version" "register-cluster" "untag-resource" "update-addon" "update-cluster-config" "update-nodegroup-config" "update-nodegroup-version" "commands"] | sort) } | get name | first)
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

# Associate encryption configuration to an existing cluster. You can use this API to enable encryption on existing clusters which do not have encryption already enabled. This allows you to implement a defense-in-depth security strategy without migrating applications to new Amazon EKS clusters.
#
# POST /clusters/{name}/encryption-config/associate
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: AssociateEncryptionConfig
export def "associate-encryption-config" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  encryption_config: list # The configuration you are using for encryption. — item shape: {resources?: list<string>, provider?: record}
  --client-request-token: string # The client request token you are using with the encryption configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/encryption-config/associate"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptionConfig, var: encryption_config}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, encryption_config: $encryption_config, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate an identity provider configuration to a cluster. If you want to authenticate identities using an identity provider, you can create an identity provider configuration and associate it to your cluster. After configuring authentication to your cluster you can create Kubernetes roles and clusterroles to assign permissions to the roles, and then bind the roles to the identities using Kubernetes rolebindings and clusterrolebindings. For more information see Using RBAC Authorization (https://kubernetes.io/docs/reference/access-authn-authz/rbac/) in the Kubernetes documentation.
#
# POST /clusters/{name}/identity-provider-configs/associate
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>, tags: record>
# operationId: AssociateIdentityProviderConfig
export def "associate-identity-provider-config" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  oidc: record # An object representing an OpenID Connect (OIDC) configuration. Before associating an OIDC identity provider to your cluster, review the considerations in Authenticating users for your cluster from an OpenID Connect identity provider (https://docs.aws.amazon.com/eks/latest/userguide/authenticate-oidc-identity-provider.html) in the Amazon EKS User Guide. — shape: {identityProviderConfigName?: string, issuerUrl?: string, clientId?: string, usernameClaim?: string, usernamePrefix?: string, groupsClaim?: string, groupsPrefix?: string, requiredClaims?: record}
  --tags: record # The metadata to apply to the configuration to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/identity-provider-configs/associate"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: oidc, var: oidc}, {name: tags, var: tags}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, oidc: $oidc, tags: $tags, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon EKS add-on. Amazon EKS add-ons help to automate the provisioning and lifecycle management of common operational software for Amazon EKS clusters. For more information, see Amazon EKS add-ons (https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) in the Amazon EKS User Guide.
#
# POST /clusters/{name}/addons
# Returns: record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>
# operationId: CreateAddon
export def "create-addon" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  addon_name: string # The name of the add-on. The name must match one of the names that DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html) returns.
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html).
  --service-account-role-arn: string # The Amazon Resource Name (ARN) of an existing IAM role to bind to the add-on's service account. The role must be assigned the IAM permissions required by the add-on. If you don't specify an existing IAM role, then the add-on uses the permissions assigned to the node IAM role. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide. To specify an existing IAM role, you must have an IAM OpenID Connect (OIDC) provider created for your cluster. For more information, see Enabling IAM roles for service accounts on your cluster (https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) in the Amazon EKS User Guide.
  --resolve-conflicts: string@resolve-conflicts-completer # How to resolve field value conflicts for an Amazon EKS add-on. Conflicts are handled based on the value you choose: None – If the self-managed version of the add-on is installed on your cluster, Amazon EKS doesn't change the value. Creation of the add-on might fail. Overwrite – If the self-managed version of the add-on is installed on your cluster and the Amazon EKS default value is different than the existing value, Amazon EKS changes the value to the Amazon EKS default value. Preserve – Not supported. You can set this value when updating an add-on though. For more information, see UpdateAddon (https://docs.aws.amazon.com/eks/latest/APIReference/API_UpdateAddon.html). If you don't currently have the self-managed version of the add-on installed on your cluster, the Amazon EKS add-on is installed. Amazon EKS sets all values to default values, regardless of the option that you specify.
  --client-request-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --configuration-values: string # The set of configuration values for the add-on that's created. The values that you provide are validated against the schema in DescribeAddonConfiguration (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonConfiguration.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/addons"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonName, var: addon_name}, {name: addonVersion, var: addon_version}, {name: serviceAccountRoleArn, var: service_account_role_arn}, {name: resolveConflicts, var: resolve_conflicts}, {name: clientRequestToken, var: client_request_token}, {name: tags, var: tags}, {name: configurationValues, var: configuration_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, addon_name: $addon_name, addon_version: $addon_version, service_account_role_arn: $service_account_role_arn, resolve_conflicts: $resolve_conflicts, client_request_token: $client_request_token, tags: $tags, configuration_values: $configuration_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the available add-ons.
#
# GET /clusters/{name}/addons
# Returns: record<addons: list<string>, nextToken: string>
# operationId: ListAddons
export def "list-addons" [
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
  --max-results: int # The maximum number of add-on results returned by ListAddonsRequest in paginated output. When you use this parameter, ListAddonsRequest returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListAddonsRequest request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListAddonsRequest returns up to 100 results and a nextToken value, if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListAddonsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
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
    path: "/clusters/{name}/addons"
    path_params: [{name: name, var: name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon EKS control plane. The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as etcd and the API server. The control plane runs in an account managed by Amazon Web Services, and the Kubernetes API is exposed by the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single tenant and unique. It runs on its own set of Amazon EC2 instances. The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the nodes (for example, to support kubectl exec, logs, and proxy data flows). Amazon EKS nodes run in your Amazon Web Services account and connect to your cluster's control plane over the Kubernetes API server endpoint and a certificate file that is created for your cluster. In most cases, it takes several minutes to create a cluster. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch nodes into your cluster. For more information, see Managing Cluster Authentication (https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html) and Launching Amazon EKS nodes (https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html) in the Amazon EKS User Guide.
#
# POST /clusters
# Returns: record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>
# operationId: CreateCluster
export def "create-cluster" [
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
  name: string # The unique name to give to your cluster.
  --version: string # The desired Kubernetes version for your cluster. If you don't specify a value here, the default version available in Amazon EKS is used. The default version might not be the latest version available.
  role_arn: string # The Amazon Resource Name (ARN) of the IAM role that provides permissions for the Kubernetes control plane to make calls to Amazon Web Services API operations on your behalf. For more information, see Amazon EKS Service IAM Role (https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) in the Amazon EKS User Guide .
  resources_vpc_config: record # An object representing the VPC configuration to use for an Amazon EKS cluster. — shape: {subnetIds?: list<string>, securityGroupIds?: list<string>, endpointPublicAccess?: bool, endpointPrivateAccess?: bool, publicAccessCidrs?: list<string>}
  --kubernetes-network-config: record # The Kubernetes network configuration for the cluster. — shape: {serviceIpv4Cidr?: string, ipFamily?: "ipv4"|"ipv6"}
  --logging: record # An object representing the logging configuration for resources in your cluster. — shape: {clusterLogging?: list}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value. You define both.
  --encryption-config: list # The encryption configuration for the cluster. — item shape: {resources?: list<string>, provider?: record}
  --outpost-config: record # The configuration of your local Amazon EKS cluster on an Amazon Web Services Outpost. Before creating a cluster on an Outpost, review Creating a local cluster on an Outpost (https://docs.aws.amazon.com/eks/latest/userguide/eks-outposts-local-cluster-create.html) in the Amazon EKS User Guide. This API isn't available for Amazon EKS clusters on the Amazon Web Services cloud. — shape: {outpostArns?: list<string>, controlPlaneInstanceType?: string, controlPlanePlacement?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: version, var: version}, {name: roleArn, var: role_arn}, {name: resourcesVpcConfig, var: resources_vpc_config}, {name: kubernetesNetworkConfig, var: kubernetes_network_config}, {name: logging, var: logging}, {name: clientRequestToken, var: client_request_token}, {name: tags, var: tags}, {name: encryptionConfig, var: encryption_config}, {name: outpostConfig, var: outpost_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, version: $version, role_arn: $role_arn, resources_vpc_config: $resources_vpc_config, kubernetes_network_config: $kubernetes_network_config, logging: $logging, client_request_token: $client_request_token, tags: $tags, encryption_config: $encryption_config, outpost_config: $outpost_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon EKS clusters in your Amazon Web Services account in the specified Region.
#
# GET /clusters
# Returns: record<clusters: list<string>, nextToken: string>
# operationId: ListClusters
export def "list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of cluster results returned by ListClusters in paginated output. When you use this parameter, ListClusters returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListClusters request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListClusters returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListClusters request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --include: list<string> # Indicates whether external clusters are included in the returned list. Use 'all' to return connected clusters, or blank to return only Amazon EKS clusters. 'all' must be in lowercase otherwise an error occurs.
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
    path: "/clusters"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: include, var: include, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, include: $include, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate. The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate. When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes Role Based Access Control (https://kubernetes.io/docs/admin/authorization/rbac/) (RBAC) for authorization so that the kubelet that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see Pod Execution Role (https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html) in the Amazon EKS User Guide. Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating. If any Fargate profiles in a cluster are in the DELETING status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster. For more information, see Fargate Profile (https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html) in the Amazon EKS User Guide.
#
# POST /clusters/{name}/fargate-profiles
# Returns: record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>
# operationId: CreateFargateProfile
export def "create-fargate-profile" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  fargate_profile_name: string # The name of the Fargate profile.
  pod_execution_role_arn: string # The Amazon Resource Name (ARN) of the pod execution role to use for pods that match the selectors in the Fargate profile. The pod execution role allows Fargate infrastructure to register with your cluster as a node, and it provides read access to Amazon ECR image repositories. For more information, see Pod Execution Role (https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html) in the Amazon EKS User Guide.
  --subnets: list<string> # The IDs of subnets to launch your pods into. At this time, pods running on Fargate are not assigned public IP addresses, so only private subnets (with no direct route to an Internet Gateway) are accepted for this parameter.
  --selectors: list # The selectors to match for pods to use this Fargate profile. Each selector must have an associated namespace. Optionally, you can also specify labels for a namespace. You may specify up to five selectors in a Fargate profile. — item shape: {namespace?: string, labels?: record}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata to apply to the Fargate profile to assist with categorization and organization. Each tag consists of a key and an optional value. You define both. Fargate profile tags do not propagate to any other resources associated with the Fargate profile, such as the pods that are scheduled with it.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/fargate-profiles"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: fargateProfileName, var: fargate_profile_name}, {name: podExecutionRoleArn, var: pod_execution_role_arn}, {name: subnets, var: subnets}, {name: selectors, var: selectors}, {name: clientRequestToken, var: client_request_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, fargate_profile_name: $fargate_profile_name, pod_execution_role_arn: $pod_execution_role_arn, subnets: $subnets, selectors: $selectors, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Fargate profiles associated with the specified cluster in your Amazon Web Services account in the specified Region.
#
# GET /clusters/{name}/fargate-profiles
# Returns: record<fargateProfileNames: list<string>, nextToken: string>
# operationId: ListFargateProfiles
export def "list-fargate-profiles" [
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
  --max-results: int # The maximum number of Fargate profile results returned by ListFargateProfiles in paginated output. When you use this parameter, ListFargateProfiles returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListFargateProfiles request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListFargateProfiles returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListFargateProfiles request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/clusters/{name}/fargate-profiles"
    path_params: [{name: name, var: name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a managed node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster, unless you deploy a custom AMI using a launch template. For more information about using launch templates, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html). An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by Amazon Web Services for an Amazon EKS cluster. For more information, see Managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) in the Amazon EKS User Guide. Windows AMI types are only supported for commercial Regions that support Windows Amazon EKS.
#
# POST /clusters/{name}/node-groups
# Returns: record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>
# operationId: CreateNodegroup
export def "create-nodegroup" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  nodegroup_name: string # The unique name to give your node group.
  --scaling-config: record # An object representing the scaling configuration details for the Auto Scaling group that is associated with your node group. When creating a node group, you must specify all or none of the properties. When updating a node group, you can specify any or none of the properties. — shape: {minSize?: int, maxSize?: int, desiredSize?: int}
  --disk-size: int # The root device disk size (in GiB) for your node group instances. The default disk size is 20 GiB for Linux and Bottlerocket. The default disk size is 50 GiB for Windows. If you specify launchTemplate, then don't specify diskSize, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  subnets: list<string> # The subnets to use for the Auto Scaling group that is created for your node group. If you specify launchTemplate, then don't specify SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html) in your launch template, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --instance-types: list<string> # Specify the instance types for a node group. If you specify a GPU instance type, make sure to also specify an applicable GPU AMI type with the amiType parameter. If you specify launchTemplate, then you can specify zero or one instance type in your launch template or you can specify 0-20 instance types for instanceTypes. If however, you specify an instance type in your launch template and specify any instanceTypes, the node group deployment will fail. If you don't specify an instance type in a launch template or for instanceTypes, then t3.medium is used, by default. If you specify Spot for capacityType, then we recommend specifying multiple values for instanceTypes. For more information, see Managed node group capacity types (https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-capacity-types) and Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --ami-type: string@ami-type-completer # The AMI type for your node group. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify amiType, or the node group deployment will fail. If your launch template uses a Windows custom AMI, then add eks:kube-proxy-windows to your Windows nodes rolearn in the aws-auth ConfigMap. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --remote-access: record # An object representing the remote access configuration for the managed node group. — shape: {ec2SshKey?: string, sourceSecurityGroups?: list<string>}
  node_role: string # The Amazon Resource Name (ARN) of the IAM role to associate with your node group. The Amazon EKS worker node kubelet daemon makes calls to Amazon Web Services APIs on your behalf. Nodes receive permissions for these API calls through an IAM instance profile and associated policies. Before you can launch nodes and register them into a cluster, you must create an IAM role for those nodes to use when they are launched. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide . If you specify launchTemplate, then don't specify IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html) in your launch template, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --labels: record # The Kubernetes labels to be applied to the nodes in the node group when they are created.
  --taints: list # The Kubernetes taints to be applied to the nodes in the node group. For more information, see Node taints on managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html). — item shape: {key?: string, value?: string, effect?: "NO_SCHEDULE"|"NO_EXECUTE"|"PREFER_NO_SCHEDULE"}
  --tags: record # The metadata to apply to the node group to assist with categorization and organization. Each tag consists of a key and an optional value. You define both. Node group tags do not propagate to any other resources associated with the node group, such as the Amazon EC2 instances or subnets.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --launch-template: record # An object representing a node group launch template specification. The launch template can't include SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html), IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html), RequestSpotInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RequestSpotInstances.html), HibernationOptions (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_HibernationOptionsRequest.html), or TerminateInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TerminateInstances.html), or the node group deployment or update will fail. For more information about launch templates, see CreateLaunchTemplate (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateLaunchTemplate.html) in the Amazon EC2 API Reference. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide. You must specify either the launch template ID or the launch template name in the request, but not both. — shape: {name?: string, version?: string, id?: string}
  --update-config: record # The node group update configuration. — shape: {maxUnavailable?: int, maxUnavailablePercentage?: int}
  --capacity-type: string@capacity-type-completer # The capacity type for your node group.
  --version: string # The Kubernetes version to use for your managed nodes. By default, the Kubernetes version of the cluster is used, and this is the only accepted specified value. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify version, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --release-version: string # The AMI version of the Amazon EKS optimized AMI to use with your node group. By default, the latest available AMI version for the node group's current Kubernetes version is used. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. Amazon EKS managed node groups support the November 2022 and later releases of the Windows AMIs. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify releaseVersion, or the node group deployment will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/node-groups"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: nodegroupName, var: nodegroup_name}, {name: scalingConfig, var: scaling_config}, {name: diskSize, var: disk_size}, {name: subnets, var: subnets}, {name: instanceTypes, var: instance_types}, {name: amiType, var: ami_type}, {name: remoteAccess, var: remote_access}, {name: nodeRole, var: node_role}, {name: labels, var: labels}, {name: taints, var: taints}, {name: tags, var: tags}, {name: clientRequestToken, var: client_request_token}, {name: launchTemplate, var: launch_template}, {name: updateConfig, var: update_config}, {name: capacityType, var: capacity_type}, {name: version, var: version}, {name: releaseVersion, var: release_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, nodegroup_name: $nodegroup_name, scaling_config: $scaling_config, disk_size: $disk_size, subnets: $subnets, instance_types: $instance_types, ami_type: $ami_type, remote_access: $remote_access, node_role: $node_role, labels: $labels, taints: $taints, tags: $tags, client_request_token: $client_request_token, launch_template: $launch_template, update_config: $update_config, capacity_type: $capacity_type, version: $version, release_version: $release_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon EKS managed node groups associated with the specified cluster in your Amazon Web Services account in the specified Region. Self-managed node groups are not listed.
#
# GET /clusters/{name}/node-groups
# Returns: record<nodegroups: list<string>, nextToken: string>
# operationId: ListNodegroups
export def "list-nodegroups" [
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
  --max-results: int # The maximum number of node group results returned by ListNodegroups in paginated output. When you use this parameter, ListNodegroups returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListNodegroups request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListNodegroups returns up to 100 results and a nextToken value if applicable.
  --next-token: string # The nextToken value returned from a previous paginated ListNodegroups request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/clusters/{name}/node-groups"
    path_params: [{name: name, var: name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Amazon EKS add-on. When you remove the add-on, it will also be deleted from the cluster. You can always manually start an add-on on the cluster using the Kubernetes API.
#
# DELETE /clusters/{name}/addons/{addonName}
# Returns: record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>
# operationId: DeleteAddon
export def "delete-addon" [
  name: string
  addon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preserve: oneof<nothing, bool> # Specifying this option preserves the add-on software on your cluster but Amazon EKS stops managing any settings for the add-on. If an IAM account is associated with the add-on, it isn't removed.
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
    path: "/clusters/{name}/addons/{addonName}"
    path_params: [{name: name, var: name}, {name: addonName, var: addon_name}]
    query: [{name: preserve, var: preserve}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, addon_name: $addon_name, preserve: $preserve, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an Amazon EKS add-on.
#
# GET /clusters/{name}/addons/{addonName}
# Returns: record<addon: record<addonName: string, clusterName: string, status: string, addonVersion: string, health: record<issues: list>, addonArn: string, createdAt: string, modifiedAt: string, serviceAccountRoleArn: string, tags: record, publisher: string, owner: string, marketplaceInformation: record<productId: string, productUrl: string>, configurationValues: string>>
# operationId: DescribeAddon
export def "describe-addon" [
  name: string
  addon_name: string
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
    path: "/clusters/{name}/addons/{addonName}"
    path_params: [{name: name, var: name}, {name: addonName, var: addon_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, addon_name: $addon_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon EKS cluster control plane. If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see Deleting a Cluster (https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html) in the Amazon EKS User Guide. If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see DeleteNodegroup and DeleteFargateProfile.
#
# DELETE /clusters/{name}
# Returns: record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>
# operationId: DeleteCluster
export def "delete-cluster" [
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
    path: "/clusters/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns descriptive information about an Amazon EKS cluster. The API server endpoint and certificate authority data returned by this operation are required for kubelet and kubectl to communicate with your Kubernetes API server. For more information, see Create a kubeconfig for Amazon EKS (https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html). The API server endpoint and certificate authority data aren't available until the cluster reaches the ACTIVE state.
#
# GET /clusters/{name}
# Returns: record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>
# operationId: DescribeCluster
export def "describe-cluster" [
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
    path: "/clusters/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Fargate profile. When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state. Only one Fargate profile in a cluster can be in the DELETING status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.
#
# DELETE /clusters/{name}/fargate-profiles/{fargateProfileName}
# Returns: record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>
# operationId: DeleteFargateProfile
export def "delete-fargate-profile" [
  name: string
  fargate_profile_name: string
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
    path: "/clusters/{name}/fargate-profiles/{fargateProfileName}"
    path_params: [{name: name, var: name}, {name: fargateProfileName, var: fargate_profile_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fargate_profile_name: $fargate_profile_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns descriptive information about an Fargate profile.
#
# GET /clusters/{name}/fargate-profiles/{fargateProfileName}
# Returns: record<fargateProfile: record<fargateProfileName: string, fargateProfileArn: string, clusterName: string, createdAt: string, podExecutionRoleArn: string, subnets: list<string>, selectors: list<record>, status: string, tags: record>>
# operationId: DescribeFargateProfile
export def "describe-fargate-profile" [
  name: string
  fargate_profile_name: string
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
    path: "/clusters/{name}/fargate-profiles/{fargateProfileName}"
    path_params: [{name: name, var: name}, {name: fargateProfileName, var: fargate_profile_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, fargate_profile_name: $fargate_profile_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an Amazon EKS node group for a cluster.
#
# DELETE /clusters/{name}/node-groups/{nodegroupName}
# Returns: record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>
# operationId: DeleteNodegroup
export def "delete-nodegroup" [
  name: string
  nodegroup_name: string
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
    path: "/clusters/{name}/node-groups/{nodegroupName}"
    path_params: [{name: name, var: name}, {name: nodegroupName, var: nodegroup_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, nodegroup_name: $nodegroup_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns descriptive information about an Amazon EKS node group.
#
# GET /clusters/{name}/node-groups/{nodegroupName}
# Returns: record<nodegroup: record<nodegroupName: string, nodegroupArn: string, clusterName: string, version: string, releaseVersion: string, createdAt: string, modifiedAt: string, status: string, capacityType: string, scalingConfig: record<minSize: int, maxSize: int, desiredSize: int>, instanceTypes: list<string>, subnets: list<string>, remoteAccess: record<ec2SshKey: string, sourceSecurityGroups: list>, amiType: string, nodeRole: string, labels: record, taints: list<record>, resources: record<autoScalingGroups: list, remoteAccessSecurityGroup: string>, diskSize: int, health: record<issues: list>, updateConfig: record<maxUnavailable: int, maxUnavailablePercentage: int>, launchTemplate: record<name: string, version: string, id: string>, tags: record>>
# operationId: DescribeNodegroup
export def "describe-nodegroup" [
  name: string
  nodegroup_name: string
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
    path: "/clusters/{name}/node-groups/{nodegroupName}"
    path_params: [{name: name, var: name}, {name: nodegroupName, var: nodegroup_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, nodegroup_name: $nodegroup_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters a connected cluster to remove it from the Amazon EKS control plane.
#
# DELETE /cluster-registrations/{name}
# Returns: record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>
# operationId: DeregisterCluster
export def "deregister-cluster" [
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
    path: "/cluster-registrations/{name}"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration options.
#
# GET /addons/configuration-schemas
# Returns: record<addonName: string, addonVersion: string, configurationSchema: string>
# operationId: DescribeAddonConfiguration
export def "describe-addon-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --addon-name: string # The name of the add-on. The name must match one of the names that DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html) returns. (required)
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html). (required)
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
    path: "/addons/configuration-schemas"
    query: [{name: addonName, var: addon_name, required: true}, {name: addonVersion, var: addon_version, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    addon_name: $addon_name, addon_version: $addon_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the versions for an add-on. Information such as the Kubernetes versions that you can use the add-on with, the owner, publisher, and the type of the add-on are returned.
#
# GET /addons/supported-versions
# Returns: record<addons: table<addonName: string, type: string, addonVersions: list, publisher: string, owner: string, marketplaceInformation: record>, nextToken: string>
# operationId: DescribeAddonVersions
export def "describe-addon-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kubernetes-version: string # The Kubernetes versions that you can use the add-on with.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The nextToken value returned from a previous paginated DescribeAddonVersionsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value. This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.
  --addon-name: string # The name of the add-on. The name must match one of the names returned by ListAddons (https://docs.aws.amazon.com/eks/latest/APIReference/API_ListAddons.html).
  --types: list<string> # The type of the add-on. For valid types, don't specify a value for this property.
  --publishers: list<string> # The publisher of the add-on. For valid publishers, don't specify a value for this property.
  --owners: list<string> # The owner of the add-on. For valid owners, don't specify a value for this property.
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
    path: "/addons/supported-versions"
    query: [{name: kubernetesVersion, var: kubernetes_version}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: addonName, var: addon_name}, {name: types, var: types, style: multi}, {name: publishers, var: publishers, style: multi}, {name: owners, var: owners, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    kubernetes_version: $kubernetes_version, max_results: $max_results, next_token: $next_token, addon_name: $addon_name, types: $types, publishers: $publishers, owners: $owners, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns descriptive information about an identity provider configuration.
#
# POST /clusters/{name}/identity-provider-configs/describe
# Returns: record<identityProviderConfig: record<oidc: record<identityProviderConfigName: string, identityProviderConfigArn: string, clusterName: string, issuerUrl: string, clientId: string, usernameClaim: string, usernamePrefix: string, groupsClaim: string, groupsPrefix: string, requiredClaims: record, tags: record, status: string>>>
# operationId: DescribeIdentityProviderConfig
export def "describe-identity-provider-config" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_provider_config: record # An object representing an identity provider configuration. — shape: {type?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/identity-provider-configs/describe"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: identityProviderConfig, var: identity_provider_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, identity_provider_config: $identity_provider_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group or Amazon EKS add-on. When the status of the update is Succeeded, the update is complete. If an update fails, the status is Failed, and an error detail explains the reason for the failure.
#
# GET /clusters/{name}/updates/{updateId}
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: DescribeUpdate
export def "describe-update" [
  name: string
  update_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodegroup-name: string # The name of the Amazon EKS node group associated with the update. This parameter is required if the update is a node group update.
  --addon-name: string # The name of the add-on. The name must match one of the names returned by ListAddons (https://docs.aws.amazon.com/eks/latest/APIReference/API_ListAddons.html). This parameter is required if the update is an add-on update.
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
    path: "/clusters/{name}/updates/{updateId}"
    path_params: [{name: name, var: name}, {name: updateId, var: update_id}]
    query: [{name: nodegroupName, var: nodegroup_name}, {name: addonName, var: addon_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, update_id: $update_id, nodegroup_name: $nodegroup_name, addon_name: $addon_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates an identity provider configuration from a cluster. If you disassociate an identity provider from your cluster, users included in the provider can no longer access the cluster. However, you can still access the cluster with Amazon Web Services IAM users.
#
# POST /clusters/{name}/identity-provider-configs/disassociate
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: DisassociateIdentityProviderConfig
export def "disassociate-identity-provider-config" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_provider_config: record # An object representing an identity provider configuration. — shape: {type?: string, name?: string}
  --client-request-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/identity-provider-configs/disassociate"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: identityProviderConfig, var: identity_provider_config}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, identity_provider_config: $identity_provider_config, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of identity provider configurations.
#
# GET /clusters/{name}/identity-provider-configs
# Returns: record<identityProviderConfigs: table<type: string, name: string>, nextToken: string>
# operationId: ListIdentityProviderConfigs
export def "list-identity-provider-configs" [
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
  --max-results: int # The maximum number of identity provider configurations returned by ListIdentityProviderConfigs in paginated output. When you use this parameter, ListIdentityProviderConfigs returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListIdentityProviderConfigs request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListIdentityProviderConfigs returns up to 100 results and a nextToken value, if applicable.
  --next-token: string # The nextToken value returned from a previous paginated IdentityProviderConfigsRequest where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
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
    path: "/clusters/{name}/identity-provider-configs"
    path_params: [{name: name, var: name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the tags for an Amazon EKS resource.
#
# GET /tags/{resourceArn}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and nodes associated with the cluster.
#
# POST /tags/{resourceArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
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
  tags: record # The tags to add to the resource. A tag is an array of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the updates associated with an Amazon EKS cluster or managed node group in your Amazon Web Services account, in the specified Region.
#
# GET /clusters/{name}/updates
# Returns: record<updateIds: list<string>, nextToken: string>
# operationId: ListUpdates
export def "list-updates" [
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
  --nodegroup-name: string # The name of the Amazon EKS managed node group to list updates for.
  --addon-name: string # The names of the installed add-ons that have available updates.
  --next-token: string # The nextToken value returned from a previous paginated ListUpdates request where maxResults was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the nextToken value.
  --max-results: int # The maximum number of update results returned by ListUpdates in paginated output. When you use this parameter, ListUpdates returns only maxResults results in a single page along with a nextToken response element. You can see the remaining results of the initial request by sending another ListUpdates request with the returned nextToken value. This value can be between 1 and 100. If you don't use this parameter, ListUpdates returns up to 100 results and a nextToken value if applicable.
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
    path: "/clusters/{name}/updates"
    path_params: [{name: name, var: name}]
    query: [{name: nodegroupName, var: nodegroup_name}, {name: addonName, var: addon_name}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, nodegroup_name: $nodegroup_name, addon_name: $addon_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the DescribeUpdate API operation. Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to UPDATING (this status transition is eventually consistent). When the update is complete (either Failed or Successful), the cluster status moves to Active. If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.
#
# POST /clusters/{name}/updates
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: UpdateClusterVersion
export def "update-cluster-version" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  version: string # The desired Kubernetes version following a successful update.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/updates"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, version: $version, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connects a Kubernetes cluster to the Amazon EKS control plane. Any Kubernetes cluster can be connected to the Amazon EKS control plane to view current information about the cluster and its nodes. Cluster connection requires two steps. First, send a RegisterClusterRequest to add it to the Amazon EKS control plane. Second, a Manifest (https://amazon-eks.s3.us-west-2.amazonaws.com/eks-connector/manifests/eks-connector/latest/eks-connector.yaml) containing the activationID and activationCode must be applied to the Kubernetes cluster through it's native provider to provide visibility. After the Manifest is updated and applied, then the connected cluster is visible to the Amazon EKS control plane. If the Manifest is not applied within three days, then the connected cluster will no longer be visible and must be deregistered. See DeregisterCluster.
#
# POST /cluster-registrations
# Returns: record<cluster: record<name: string, arn: string, createdAt: string, version: string, endpoint: string, roleArn: string, resourcesVpcConfig: record<subnetIds: list, securityGroupIds: list, clusterSecurityGroupId: string, vpcId: string, endpointPublicAccess: bool, endpointPrivateAccess: bool, publicAccessCidrs: list>, kubernetesNetworkConfig: record<serviceIpv4Cidr: string, serviceIpv6Cidr: string, ipFamily: string>, logging: record<clusterLogging: list>, identity: record<oidc: record>, status: string, certificateAuthority: record<data: string>, clientRequestToken: string, platformVersion: string, tags: record, encryptionConfig: list<record>, connectorConfig: record<activationId: string, activationCode: string, activationExpiry: string, provider: string, roleArn: string>, id: string, health: record<issues: list>, outpostConfig: record<outpostArns: list, controlPlaneInstanceType: string, controlPlanePlacement: record>>>
# operationId: RegisterCluster
export def "register-cluster" [
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
  name: string # Define a unique name for this cluster for your Region.
  connector_config: record # The configuration sent to a cluster for configuration. — shape: {roleArn?: string, provider?: "EKS_ANYWHERE"|"ANTHOS"|"GKE"|"AKS"|"OPENSHIFT"|"TANZU"|"RANCHER"|"EC2"|"OTHER"}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --tags: record # The metadata that you apply to the cluster to assist with categorization and organization. Each tag consists of a key and an optional value, both of which you define. Cluster tags do not propagate to any other resources associated with the cluster.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cluster-registrations"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: connectorConfig, var: connector_config}, {name: clientRequestToken, var: client_request_token}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, connector_config: $connector_config, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes specified tags from a resource.
#
# DELETE /tags/{resourceArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The keys of the tags to be removed. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EKS add-on.
#
# POST /clusters/{name}/addons/{addonName}/update
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: UpdateAddon
export def "update-addon" [
  name: string
  addon_name: string
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
  --addon-version: string # The version of the add-on. The version must match one of the versions returned by DescribeAddonVersions (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonVersions.html).
  --service-account-role-arn: string # The Amazon Resource Name (ARN) of an existing IAM role to bind to the add-on's service account. The role must be assigned the IAM permissions required by the add-on. If you don't specify an existing IAM role, then the add-on uses the permissions assigned to the node IAM role. For more information, see Amazon EKS node IAM role (https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) in the Amazon EKS User Guide. To specify an existing IAM role, you must have an IAM OpenID Connect (OIDC) provider created for your cluster. For more information, see Enabling IAM roles for service accounts on your cluster (https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) in the Amazon EKS User Guide.
  --resolve-conflicts: string@resolve-conflicts-completer # How to resolve field value conflicts for an Amazon EKS add-on if you've changed a value from the Amazon EKS default value. Conflicts are handled based on the option you choose: None – Amazon EKS doesn't change the value. The update might fail. Overwrite – Amazon EKS overwrites the changed value back to the Amazon EKS default value. Preserve – Amazon EKS preserves the value. If you choose this option, we recommend that you test any field and value changes on a non-production cluster before updating the add-on on your production cluster.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
  --configuration-values: string # The set of configuration values for the add-on that's created. The values that you provide are validated against the schema in DescribeAddonConfiguration (https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeAddonConfiguration.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/addons/{addonName}/update"
    path_params: [{name: name, var: name}, {name: addonName, var: addon_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonVersion, var: addon_version}, {name: serviceAccountRoleArn, var: service_account_role_arn}, {name: resolveConflicts, var: resolve_conflicts}, {name: clientRequestToken, var: client_request_token}, {name: configurationValues, var: configuration_values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, addon_name: $addon_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, addon_version: $addon_version, service_account_role_arn: $service_account_role_arn, resolve_conflicts: $resolve_conflicts, client_request_token: $client_request_token, configuration_values: $configuration_values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the DescribeUpdate API operation. You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see Amazon EKS Cluster Control Plane Logs (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) in the Amazon EKS User Guide . CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see CloudWatch Pricing (http://aws.amazon.com/cloudwatch/pricing/). You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see Amazon EKS cluster endpoint access control (https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) in the Amazon EKS User Guide . You can't update the subnets or security group IDs for an existing cluster. Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to UPDATING (this status transition is eventually consistent). When the update is complete (either Failed or Successful), the cluster status moves to Active.
#
# POST /clusters/{name}/update-config
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: UpdateClusterConfig
export def "update-cluster-config" [
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --resources-vpc-config: record # An object representing the VPC configuration to use for an Amazon EKS cluster. — shape: {subnetIds?: list<string>, securityGroupIds?: list<string>, endpointPublicAccess?: bool, endpointPrivateAccess?: bool, publicAccessCidrs?: list<string>}
  --logging: record # An object representing the logging configuration for resources in your cluster. — shape: {clusterLogging?: list}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/update-config"
    path_params: [{name: name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourcesVpcConfig, var: resources_vpc_config}, {name: logging, var: logging}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, resources_vpc_config: $resources_vpc_config, logging: $logging, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the DescribeUpdate API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
#
# POST /clusters/{name}/node-groups/{nodegroupName}/update-config
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: UpdateNodegroupConfig
export def "update-nodegroup-config" [
  name: string
  nodegroup_name: string
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
  --labels: record # An object representing a Kubernetes label change for a managed node group. — shape: {addOrUpdateLabels?: record, removeLabels?: list<string>}
  --taints: record # An object representing the details of an update to a taints payload. For more information, see Node taints on managed node groups (https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html). — shape: {addOrUpdateTaints?: list, removeTaints?: list}
  --scaling-config: record # An object representing the scaling configuration details for the Auto Scaling group that is associated with your node group. When creating a node group, you must specify all or none of the properties. When updating a node group, you can specify any or none of the properties. — shape: {minSize?: int, maxSize?: int, desiredSize?: int}
  --update-config: record # The node group update configuration. — shape: {maxUnavailable?: int, maxUnavailablePercentage?: int}
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/node-groups/{nodegroupName}/update-config"
    path_params: [{name: name, var: name}, {name: nodegroupName, var: nodegroup_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: taints, var: taints}, {name: scalingConfig, var: scaling_config}, {name: updateConfig, var: update_config}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, nodegroup_name: $nodegroup_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, labels: $labels, taints: $taints, scaling_config: $scaling_config, update_config: $update_config, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Kubernetes version or AMI version of an Amazon EKS managed node group. You can update a node group using a launch template only if the node group was originally deployed with a launch template. If you need to update a custom AMI in a node group that was deployed with a launch template, then update your custom AMI, specify the new ID in a new version of the launch template, and then update the node group to the new version of the launch template. If you update without a launch template, then you can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. You cannot roll back a node group to an earlier Kubernetes version or AMI version. When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can force the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.
#
# POST /clusters/{name}/node-groups/{nodegroupName}/update-version
# Returns: record<update: record<id: string, status: string, type: string, params: list<record>, createdAt: string, errors: list<record>>>
# operationId: UpdateNodegroupVersion
export def "update-nodegroup-version" [
  name: string
  nodegroup_name: string
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
  --version: string # The Kubernetes version to update to. If no version is specified, then the Kubernetes version of the node group does not change. You can specify the Kubernetes version of the cluster to update the node group to the latest AMI version of the cluster's Kubernetes version. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify version, or the node group update will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --release-version: string # The AMI version of the Amazon EKS optimized AMI to use for the update. By default, the latest available AMI version for the node group's Kubernetes version is used. For information about Linux versions, see Amazon EKS optimized Amazon Linux AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) in the Amazon EKS User Guide. Amazon EKS managed node groups support the November 2022 and later releases of the Windows AMIs. For information about Windows versions, see Amazon EKS optimized Windows AMI versions (https://docs.aws.amazon.com/eks/latest/userguide/eks-ami-versions-windows.html) in the Amazon EKS User Guide. If you specify launchTemplate, and your launch template uses a custom AMI, then don't specify releaseVersion, or the node group update will fail. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide.
  --launch-template: record # An object representing a node group launch template specification. The launch template can't include SubnetId (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateNetworkInterface.html), IamInstanceProfile (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IamInstanceProfile.html), RequestSpotInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RequestSpotInstances.html), HibernationOptions (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_HibernationOptionsRequest.html), or TerminateInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TerminateInstances.html), or the node group deployment or update will fail. For more information about launch templates, see CreateLaunchTemplate (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateLaunchTemplate.html) in the Amazon EC2 API Reference. For more information about using launch templates with Amazon EKS, see Launch template support (https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) in the Amazon EKS User Guide. You must specify either the launch template ID or the launch template name in the request, but not both. — shape: {name?: string, version?: string, id?: string}
  --force: oneof<nothing, bool> # Force the update if the existing node group's pods are unable to be drained due to a pod disruption budget issue. If an update fails because pods could not be drained, you can force the update after it fails to terminate the old node whether or not any pods are running on the node.
  --client-request-token: string # Unique, case-sensitive identifier that you provide to ensure the idempotency of the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/clusters/{name}/node-groups/{nodegroupName}/update-version"
    path_params: [{name: name, var: name}, {name: nodegroupName, var: nodegroup_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}, {name: releaseVersion, var: release_version}, {name: launchTemplate, var: launch_template}, {name: force, var: force}, {name: clientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, nodegroup_name: $nodegroup_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, version: $version, release_version: $release_version, launch_template: $launch_template, force: $force, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
