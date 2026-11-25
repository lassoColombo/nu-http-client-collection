# Auto-generated client for Amazon Route 53 Resolver v2018-04-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/route53resolver/2018-04-01/openapi.json
# Auth: --token flag or $env.AMAZON_ROUTE_53_RESOLVER_TOKEN

const CLIENT = {
  base_url: "http://route53resolver.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ROUTE_53_RESOLVER_TOKEN"
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

def base-url-completer [] { ["http://route53resolver.us-east-1.amazonaws.com" "http://route53resolver.us-east-2.amazonaws.com" "http://route53resolver.us-west-1.amazonaws.com" "http://route53resolver.us-west-2.amazonaws.com" "http://route53resolver.us-gov-west-1.amazonaws.com" "http://route53resolver.us-gov-east-1.amazonaws.com" "http://route53resolver.ca-central-1.amazonaws.com" "http://route53resolver.eu-north-1.amazonaws.com" "http://route53resolver.eu-west-1.amazonaws.com" "http://route53resolver.eu-west-2.amazonaws.com" "http://route53resolver.eu-west-3.amazonaws.com" "http://route53resolver.eu-central-1.amazonaws.com" "http://route53resolver.eu-south-1.amazonaws.com" "http://route53resolver.af-south-1.amazonaws.com" "http://route53resolver.ap-northeast-1.amazonaws.com" "http://route53resolver.ap-northeast-2.amazonaws.com" "http://route53resolver.ap-northeast-3.amazonaws.com" "http://route53resolver.ap-southeast-1.amazonaws.com" "http://route53resolver.ap-southeast-2.amazonaws.com" "http://route53resolver.ap-east-1.amazonaws.com" "http://route53resolver.ap-south-1.amazonaws.com" "http://route53resolver.sa-east-1.amazonaws.com" "http://route53resolver.me-south-1.amazonaws.com" "https://route53resolver.us-east-1.amazonaws.com" "https://route53resolver.us-east-2.amazonaws.com" "https://route53resolver.us-west-1.amazonaws.com" "https://route53resolver.us-west-2.amazonaws.com" "https://route53resolver.us-gov-west-1.amazonaws.com" "https://route53resolver.us-gov-east-1.amazonaws.com" "https://route53resolver.ca-central-1.amazonaws.com" "https://route53resolver.eu-north-1.amazonaws.com" "https://route53resolver.eu-west-1.amazonaws.com" "https://route53resolver.eu-west-2.amazonaws.com" "https://route53resolver.eu-west-3.amazonaws.com" "https://route53resolver.eu-central-1.amazonaws.com" "https://route53resolver.eu-south-1.amazonaws.com" "https://route53resolver.af-south-1.amazonaws.com" "https://route53resolver.ap-northeast-1.amazonaws.com" "https://route53resolver.ap-northeast-2.amazonaws.com" "https://route53resolver.ap-northeast-3.amazonaws.com" "https://route53resolver.ap-southeast-1.amazonaws.com" "https://route53resolver.ap-southeast-2.amazonaws.com" "https://route53resolver.ap-east-1.amazonaws.com" "https://route53resolver.ap-south-1.amazonaws.com" "https://route53resolver.sa-east-1.amazonaws.com" "https://route53resolver.me-south-1.amazonaws.com" "http://route53resolver.cn-north-1.amazonaws.com.cn" "http://route53resolver.cn-northwest-1.amazonaws.com.cn" "https://route53resolver.cn-north-1.amazonaws.com.cn" "https://route53resolver.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mutation-protection-completer [] { ["DISABLED" "ENABLED"] }
def x-amz-target-completer [] { ["Route53Resolver.AssociateFirewallRuleGroup"] }
def x-amz-target-completer-1 [] { ["Route53Resolver.AssociateResolverEndpointIpAddress"] }
def x-amz-target-completer-2 [] { ["Route53Resolver.AssociateResolverQueryLogConfig"] }
def x-amz-target-completer-3 [] { ["Route53Resolver.AssociateResolverRule"] }
def x-amz-target-completer-4 [] { ["Route53Resolver.CreateFirewallDomainList"] }
def action-completer [] { ["ALERT" "ALLOW" "BLOCK"] }
def block-response-completer [] { ["NODATA" "NXDOMAIN" "OVERRIDE"] }
def block-override-dns-type-completer [] { ["CNAME"] }
def x-amz-target-completer-5 [] { ["Route53Resolver.CreateFirewallRule"] }
def x-amz-target-completer-6 [] { ["Route53Resolver.CreateFirewallRuleGroup"] }
def direction-completer [] { ["INBOUND" "OUTBOUND"] }
def resolver-endpoint-type-completer [] { ["DUALSTACK" "IPV4" "IPV6"] }
def x-amz-target-completer-7 [] { ["Route53Resolver.CreateResolverEndpoint"] }
def x-amz-target-completer-8 [] { ["Route53Resolver.CreateResolverQueryLogConfig"] }
def rule-type-completer [] { ["FORWARD" "RECURSIVE" "SYSTEM"] }
def x-amz-target-completer-9 [] { ["Route53Resolver.CreateResolverRule"] }
def x-amz-target-completer-10 [] { ["Route53Resolver.DeleteFirewallDomainList"] }
def x-amz-target-completer-11 [] { ["Route53Resolver.DeleteFirewallRule"] }
def x-amz-target-completer-12 [] { ["Route53Resolver.DeleteFirewallRuleGroup"] }
def x-amz-target-completer-13 [] { ["Route53Resolver.DeleteResolverEndpoint"] }
def x-amz-target-completer-14 [] { ["Route53Resolver.DeleteResolverQueryLogConfig"] }
def x-amz-target-completer-15 [] { ["Route53Resolver.DeleteResolverRule"] }
def x-amz-target-completer-16 [] { ["Route53Resolver.DisassociateFirewallRuleGroup"] }
def x-amz-target-completer-17 [] { ["Route53Resolver.DisassociateResolverEndpointIpAddress"] }
def x-amz-target-completer-18 [] { ["Route53Resolver.DisassociateResolverQueryLogConfig"] }
def x-amz-target-completer-19 [] { ["Route53Resolver.DisassociateResolverRule"] }
def x-amz-target-completer-20 [] { ["Route53Resolver.GetFirewallConfig"] }
def x-amz-target-completer-21 [] { ["Route53Resolver.GetFirewallDomainList"] }
def x-amz-target-completer-22 [] { ["Route53Resolver.GetFirewallRuleGroup"] }
def x-amz-target-completer-23 [] { ["Route53Resolver.GetFirewallRuleGroupAssociation"] }
def x-amz-target-completer-24 [] { ["Route53Resolver.GetFirewallRuleGroupPolicy"] }
def x-amz-target-completer-25 [] { ["Route53Resolver.GetResolverConfig"] }
def x-amz-target-completer-26 [] { ["Route53Resolver.GetResolverDnssecConfig"] }
def x-amz-target-completer-27 [] { ["Route53Resolver.GetResolverEndpoint"] }
def x-amz-target-completer-28 [] { ["Route53Resolver.GetResolverQueryLogConfig"] }
def x-amz-target-completer-29 [] { ["Route53Resolver.GetResolverQueryLogConfigAssociation"] }
def x-amz-target-completer-30 [] { ["Route53Resolver.GetResolverQueryLogConfigPolicy"] }
def x-amz-target-completer-31 [] { ["Route53Resolver.GetResolverRule"] }
def x-amz-target-completer-32 [] { ["Route53Resolver.GetResolverRuleAssociation"] }
def x-amz-target-completer-33 [] { ["Route53Resolver.GetResolverRulePolicy"] }
def operation-completer [] { ["REPLACE"] }
def x-amz-target-completer-34 [] { ["Route53Resolver.ImportFirewallDomains"] }
def x-amz-target-completer-35 [] { ["Route53Resolver.ListFirewallConfigs"] }
def x-amz-target-completer-36 [] { ["Route53Resolver.ListFirewallDomainLists"] }
def x-amz-target-completer-37 [] { ["Route53Resolver.ListFirewallDomains"] }
def status-completer [] { ["COMPLETE" "DELETING" "UPDATING"] }
def x-amz-target-completer-38 [] { ["Route53Resolver.ListFirewallRuleGroupAssociations"] }
def x-amz-target-completer-39 [] { ["Route53Resolver.ListFirewallRuleGroups"] }
def x-amz-target-completer-40 [] { ["Route53Resolver.ListFirewallRules"] }
def x-amz-target-completer-41 [] { ["Route53Resolver.ListResolverConfigs"] }
def x-amz-target-completer-42 [] { ["Route53Resolver.ListResolverDnssecConfigs"] }
def x-amz-target-completer-43 [] { ["Route53Resolver.ListResolverEndpointIpAddresses"] }
def x-amz-target-completer-44 [] { ["Route53Resolver.ListResolverEndpoints"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-45 [] { ["Route53Resolver.ListResolverQueryLogConfigAssociations"] }
def x-amz-target-completer-46 [] { ["Route53Resolver.ListResolverQueryLogConfigs"] }
def x-amz-target-completer-47 [] { ["Route53Resolver.ListResolverRuleAssociations"] }
def x-amz-target-completer-48 [] { ["Route53Resolver.ListResolverRules"] }
def x-amz-target-completer-49 [] { ["Route53Resolver.ListTagsForResource"] }
def x-amz-target-completer-50 [] { ["Route53Resolver.PutFirewallRuleGroupPolicy"] }
def x-amz-target-completer-51 [] { ["Route53Resolver.PutResolverQueryLogConfigPolicy"] }
def x-amz-target-completer-52 [] { ["Route53Resolver.PutResolverRulePolicy"] }
def x-amz-target-completer-53 [] { ["Route53Resolver.TagResource"] }
def x-amz-target-completer-54 [] { ["Route53Resolver.UntagResource"] }
def firewall-fail-open-completer [] { ["DISABLED" "ENABLED" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-55 [] { ["Route53Resolver.UpdateFirewallConfig"] }
def operation-completer-1 [] { ["ADD" "REMOVE" "REPLACE"] }
def x-amz-target-completer-56 [] { ["Route53Resolver.UpdateFirewallDomains"] }
def x-amz-target-completer-57 [] { ["Route53Resolver.UpdateFirewallRule"] }
def x-amz-target-completer-58 [] { ["Route53Resolver.UpdateFirewallRuleGroupAssociation"] }
def autodefined-reverse-flag-completer [] { ["DISABLE" "ENABLE" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-59 [] { ["Route53Resolver.UpdateResolverConfig"] }
def validation-completer [] { ["DISABLE" "ENABLE" "USE_LOCAL_RESOURCE_SETTING"] }
def x-amz-target-completer-60 [] { ["Route53Resolver.UpdateResolverDnssecConfig"] }
def x-amz-target-completer-61 [] { ["Route53Resolver.UpdateResolverEndpoint"] }
def x-amz-target-completer-62 [] { ["Route53Resolver.UpdateResolverRule"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    associate-firewall-rule-group: "record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    associate-resolver-endpoint-ip-address: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    associate-resolver-query-log-config: "record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>"
    associate-resolver-rule: "record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>"
    create-firewall-domain-list: "record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    create-firewall-rule: "record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    create-firewall-rule-group: "record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    create-resolver-endpoint: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    create-resolver-query-log-config: "record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>"
    create-resolver-rule: "record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    delete-firewall-domain-list: "record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    delete-firewall-rule: "record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    delete-firewall-rule-group: "record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    delete-resolver-endpoint: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    delete-resolver-query-log-config: "record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>"
    delete-resolver-rule: "record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    disassociate-firewall-rule-group: "record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    disassociate-resolver-endpoint-ip-address: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    disassociate-resolver-query-log-config: "record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>"
    disassociate-resolver-rule: "record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>"
    get-firewall-config: "record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>"
    get-firewall-domain-list: "record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    get-firewall-rule-group: "record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    get-firewall-rule-group-association: "record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    get-firewall-rule-group-policy: "record<FirewallRuleGroupPolicy: string>"
    get-resolver-config: "record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>"
    get-resolver-dnssec-config: "record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>"
    get-resolver-endpoint: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    get-resolver-query-log-config: "record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>"
    get-resolver-query-log-config-association: "record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>"
    get-resolver-query-log-config-policy: "record<ResolverQueryLogConfigPolicy: string>"
    get-resolver-rule: "record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    get-resolver-rule-association: "record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>"
    get-resolver-rule-policy: "record<ResolverRulePolicy: string>"
    import-firewall-domains: "record<Id: string, Name: string, Status: string, StatusMessage: string>"
    list-firewall-configs: "record<NextToken: string, FirewallConfigs: table<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>"
    list-firewall-domain-lists: "record<NextToken: string, FirewallDomainLists: table<Id: string, Arn: string, Name: string, CreatorRequestId: string, ManagedOwnerName: string>>"
    list-firewall-domains: "record<NextToken: string, Domains: list<string>>"
    list-firewall-rule-group-associations: "record<NextToken: string, FirewallRuleGroupAssociations: table<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    list-firewall-rule-groups: "record<NextToken: string, FirewallRuleGroups: table<Id: string, Arn: string, Name: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string>>"
    list-firewall-rules: "record<NextToken: string, FirewallRules: table<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    list-resolver-configs: "record<NextToken: string, ResolverConfigs: table<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>"
    list-resolver-dnssec-configs: "record<NextToken: string, ResolverDnssecConfigs: table<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>"
    list-resolver-endpoint-ip-addresses: "record<NextToken: string, MaxResults: int, IpAddresses: table<IpId: string, SubnetId: string, Ip: string, Ipv6: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string>>"
    list-resolver-endpoints: "record<NextToken: string, MaxResults: int, ResolverEndpoints: table<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    list-resolver-query-log-config-associations: "record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigAssociations: table<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>"
    list-resolver-query-log-configs: "record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigs: table<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>"
    list-resolver-rule-associations: "record<NextToken: string, MaxResults: int, ResolverRuleAssociations: table<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>"
    list-resolver-rules: "record<NextToken: string, MaxResults: int, ResolverRules: table<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    put-firewall-rule-group-policy: "record<ReturnValue: bool>"
    put-resolver-query-log-config-policy: "record<ReturnValue: bool>"
    put-resolver-rule-policy: "record<ReturnValue: bool>"
    tag-resource: "record"
    untag-resource: "record"
    update-firewall-config: "record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>"
    update-firewall-domains: "record<Id: string, Name: string, Status: string, StatusMessage: string>"
    update-firewall-rule: "record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    update-firewall-rule-group-association: "record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>"
    update-resolver-config: "record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>"
    update-resolver-dnssec-config: "record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>"
    update-resolver-endpoint: "record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>"
    update-resolver-rule: "record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-firewall-rule-group" "associate-resolver-endpoint-ip-address" "associate-resolver-query-log-config" "associate-resolver-rule" "create-firewall-domain-list" "create-firewall-rule" "create-firewall-rule-group" "create-resolver-endpoint" "create-resolver-query-log-config" "create-resolver-rule" "delete-firewall-domain-list" "delete-firewall-rule" "delete-firewall-rule-group" "delete-resolver-endpoint" "delete-resolver-query-log-config" "delete-resolver-rule" "disassociate-firewall-rule-group" "disassociate-resolver-endpoint-ip-address" "disassociate-resolver-query-log-config" "disassociate-resolver-rule" "get-firewall-config" "get-firewall-domain-list" "get-firewall-rule-group" "get-firewall-rule-group-association" "get-firewall-rule-group-policy" "get-resolver-config" "get-resolver-dnssec-config" "get-resolver-endpoint" "get-resolver-query-log-config" "get-resolver-query-log-config-association" "get-resolver-query-log-config-policy" "get-resolver-rule" "get-resolver-rule-association" "get-resolver-rule-policy" "import-firewall-domains" "list-firewall-configs" "list-firewall-domain-lists" "list-firewall-domains" "list-firewall-rule-group-associations" "list-firewall-rule-groups" "list-firewall-rules" "list-resolver-configs" "list-resolver-dnssec-configs" "list-resolver-endpoint-ip-addresses" "list-resolver-endpoints" "list-resolver-query-log-config-associations" "list-resolver-query-log-configs" "list-resolver-rule-associations" "list-resolver-rules" "list-tags-for-resource" "put-firewall-rule-group-policy" "put-resolver-query-log-config-policy" "put-resolver-rule-policy" "tag-resource" "untag-resource" "update-firewall-config" "update-firewall-domains" "update-firewall-rule" "update-firewall-rule-group-association" "update-resolver-config" "update-resolver-dnssec-config" "update-resolver-endpoint" "update-resolver-rule" "commands"] | sort) } | get name | first)
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

# Associates a FirewallRuleGroup with a VPC, to provide DNS filtering for the VPC.
#
# POST /
# Returns: record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: AssociateFirewallRuleGroup
export def "associate-firewall-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer # required
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  firewall_rule_group_id: string # The unique identifier of the firewall rule group.
  vpc_id: string # The unique identifier of the VPC that you want to associate with the rule group.
  priority: int # The setting that determines the processing order of the rule group among the rule groups that you associate with the specified VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting. You must specify a unique priority for each rule group that you associate with a single VPC. To make it easier to insert rule groups later, leave space between the numbers, for example, use 101, 200, and so on. You can change the priority setting for a rule group association after you create it. The allowed values for Priority are between 100 and 9900.
  name: string # A name that lets you identify the association, to manage and use it.
  --mutation-protection: string@mutation-protection-completer # If enabled, this setting disallows modification or removal of the association, to help prevent against accidentally altering DNS firewall protections. When you create the association, the default setting is DISABLED.
  --tags: list # A list of the tag keys and values that you want to associate with the rule group association. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.AssociateFirewallRuleGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: VpcId, var: vpc_id}, {name: Priority, var: priority}, {name: Name, var: name}, {name: MutationProtection, var: mutation_protection}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, firewall_rule_group_id: $firewall_rule_group_id, vpc_id: $vpc_id, priority: $priority, name: $name, mutation_protection: $mutation_protection, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds IP addresses to an inbound or an outbound Resolver endpoint. If you want to add more than one IP address, submit one AssociateResolverEndpointIpAddress request for each IP address. To remove an IP address from an endpoint, see DisassociateResolverEndpointIpAddress (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverEndpointIpAddress.html).
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: AssociateResolverEndpointIpAddress
export def "associate-resolver-endpoint-ip-address" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to associate IP addresses with.
  ip_address: record # In an UpdateResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverEndpoint.html) request, information about an IP address to update. — shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.AssociateResolverEndpointIpAddress"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}, {name: IpAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates an Amazon VPC with a specified query logging configuration. Route 53 Resolver logs DNS queries that originate in all of the Amazon VPCs that are associated with a specified query logging configuration. To associate more than one VPC with a configuration, submit one AssociateResolverQueryLogConfig request for each VPC. The VPCs that you associate with a query logging configuration must be in the same Region as the configuration. To remove a VPC from a query logging configuration, see DisassociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverQueryLogConfig.html).
#
# POST /
# Returns: record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>
# operationId: AssociateResolverQueryLogConfig
export def "associate-resolver-query-log-config" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to associate a VPC with.
  resource_id: string # The ID of an Amazon VPC that you want this query logging configuration to log queries for. The VPCs and the query logging configuration must be in the same Region.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.AssociateResolverQueryLogConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverQueryLogConfigId, var: resolver_query_log_config_id}, {name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_query_log_config_id: $resolver_query_log_config_id, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a Resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see CreateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_CreateResolverRule.html).
#
# POST /
# Returns: record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>
# operationId: AssociateResolverRule
export def "associate-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  resolver_rule_id: string # The ID of the Resolver rule that you want to associate with the VPC. To list the existing Resolver rules, use ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html).
  --name: string # A name for the association that you're creating between a Resolver rule and a VPC.
  vpc_id: string # The ID of the VPC that you want to associate the Resolver rule with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.AssociateResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverRuleId, var: resolver_rule_id}, {name: Name, var: name}, {name: VPCId, var: vpc_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_rule_id: $resolver_rule_id, name: $name, vpc_id: $vpc_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty firewall domain list for use in DNS Firewall rules. You can populate the domains for the new list with a file, using ImportFirewallDomains, or with domain strings, using UpdateFirewallDomains.
#
# POST /
# Returns: record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: CreateFirewallDomainList
export def "create-firewall-domain-list" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  creator_request_id: string # A unique string that identifies the request and that allows you to retry failed requests without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  name: string # A name that lets you identify the domain list to manage and use it.
  --tags: list # A list of the tag keys and values that you want to associate with the domain list. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateFirewallDomainList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: Name, var: name}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a single DNS Firewall rule in the specified rule group, using the specified domain list.
#
# POST /
# Returns: record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: CreateFirewallRule
export def "create-firewall-rule" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  creator_request_id: string # A unique string that identifies the request and that allows you to retry failed requests without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  firewall_rule_group_id: string # The unique identifier of the firewall rule group where you want to create the rule.
  firewall_domain_list_id: string # The ID of the domain list that you want to use in the rule.
  priority: int # The setting that determines the processing order of the rule in the rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting. You must specify a unique priority for each rule in a rule group. To make it easier to insert rules later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for the rules in a rule group at any time.
  action: string@action-completer # The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request and send metrics and logs to Cloud Watch. BLOCK - Disallow the request. This option requires additional details in the rule's BlockResponse.
  --block-response: string@block-response-completer # The way that you want DNS Firewall to block the request, used with the rule action setting BLOCK. NODATA - Respond indicating that the query was successful, but no response is available for it. NXDOMAIN - Respond indicating that the domain name that's in the query doesn't exist. OVERRIDE - Provide a custom override in the response. This option requires custom handling details in the rule's BlockOverride* settings. This setting is required if the rule action setting is BLOCK.
  --block-override-domain: string # The custom DNS record to send back in response to the query. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  --block-override-dns-type: string@block-override-dns-type-completer # The DNS record's type. This determines the format of the record value that you provided in BlockOverrideDomain. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  --block-override-ttl: int # The recommended amount of time, in seconds, for the DNS resolver or web browser to cache the provided override record. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE. This setting is required if the BlockResponse setting is OVERRIDE.
  name: string # A name that lets you identify the rule in the rule group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateFirewallRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: FirewallDomainListId, var: firewall_domain_list_id}, {name: Priority, var: priority}, {name: Action, var: action}, {name: BlockResponse, var: block_response}, {name: BlockOverrideDomain, var: block_override_domain}, {name: BlockOverrideDnsType, var: block_override_dns_type}, {name: BlockOverrideTtl, var: block_override_ttl}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, firewall_rule_group_id: $firewall_rule_group_id, firewall_domain_list_id: $firewall_domain_list_id, priority: $priority, action: $action, block_response: $block_response, block_override_domain: $block_override_domain, block_override_dns_type: $block_override_dns_type, block_override_ttl: $block_override_ttl, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty DNS Firewall rule group for filtering DNS network traffic in a VPC. You can add rules to the new rule group by calling CreateFirewallRule.
#
# POST /
# Returns: record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: CreateFirewallRuleGroup
export def "create-firewall-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  creator_request_id: string # A unique string defined by you to identify the request. This allows you to retry failed requests without the risk of running the operation twice. This can be any unique string, for example, a timestamp.
  name: string # A name that lets you identify the rule group, to manage and use it.
  --tags: list # A list of the tag keys and values that you want to associate with the rule group. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateFirewallRuleGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: Name, var: name}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Resolver endpoint. There are two types of Resolver endpoints, inbound and outbound: An inbound Resolver endpoint forwards DNS queries to the DNS service for a VPC from your network. An outbound Resolver endpoint forwards DNS queries from the DNS service for a VPC to your network.
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: CreateResolverEndpoint
export def "create-resolver-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --name: string # A friendly name that lets you easily find a configuration in the Resolver dashboard in the Route 53 console.
  security_group_ids: list<string> # The ID of one or more security groups that you want to use to control access to this VPC. The security group that you specify must include one or more inbound rules (for inbound Resolver endpoints) or outbound rules (for outbound Resolver endpoints). Inbound and outbound rules must allow TCP and UDP access. For inbound access, open port 53. For outbound access, open the port that you're using for DNS queries on your network.
  direction: string@direction-completer # Specify the applicable value: INBOUND: Resolver forwards DNS queries to the DNS service for a VPC from your network OUTBOUND: Resolver forwards DNS queries from the DNS service for a VPC to your network
  ip_addresses: list # The subnets and IP addresses in your VPC that DNS queries originate from (for outbound endpoints) or that you forward DNS queries to (for inbound endpoints). The subnet ID uniquely identifies a VPC. — item shape: {SubnetId: string, Ip?: string, Ipv6?: string}
  --tags: list # A list of the tag keys and values that you want to associate with the endpoint. — item shape: {Key: string, Value: string}
  --resolver-endpoint-type: string@resolver-endpoint-type-completer # For the endpoint type you can choose either IPv4, IPv6. or dual-stack. A dual-stack endpoint means that it will resolve via both IPv4 and IPv6. This endpoint type is applied to all IP addresses.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateResolverEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: Name, var: name}, {name: SecurityGroupIds, var: security_group_ids}, {name: Direction, var: direction}, {name: IpAddresses, var: ip_addresses}, {name: Tags, var: tags}, {name: ResolverEndpointType, var: resolver_endpoint_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, name: $name, security_group_ids: $security_group_ids, direction: $direction, ip_addresses: $ip_addresses, tags: $tags, resolver_endpoint_type: $resolver_endpoint_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Resolver query logging configuration, which defines where you want Resolver to save DNS query logs that originate in your VPCs. Resolver can log queries only for VPCs that are in the same Region as the query logging configuration. To specify which VPCs you want to log queries for, you use AssociateResolverQueryLogConfig. For more information, see AssociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverQueryLogConfig.html). You can optionally use Resource Access Manager (RAM) to share a query logging configuration with other Amazon Web Services accounts. The other accounts can then associate VPCs with the configuration. The query logs that Resolver creates for a configuration include all DNS queries that originate in all VPCs that are associated with the configuration.
#
# POST /
# Returns: record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>
# operationId: CreateResolverQueryLogConfig
export def "create-resolver-query-log-config" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  name: string # The name that you want to give the query logging configuration.
  destination_arn: string # The ARN of the resource that you want Resolver to send query logs. You can send query logs to an S3 bucket, a CloudWatch Logs log group, or a Kinesis Data Firehose delivery stream. Examples of valid values include the following: S3 bucket: arn:aws:s3:::examplebucket You can optionally append a file prefix to the end of the ARN. arn:aws:s3:::examplebucket/development/ CloudWatch Logs log group: arn:aws:logs:us-west-1:123456789012:log-group:/mystack-testgroup-12ABC1AB12A1:* Kinesis Data Firehose delivery stream: arn:aws:kinesis:us-east-2:0123456789:stream/my_stream_name
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --tags: list # A list of the tag keys and values that you want to associate with the query logging configuration. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateResolverQueryLogConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DestinationArn, var: destination_arn}, {name: CreatorRequestId, var: creator_request_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, destination_arn: $destination_arn, creator_request_id: $creator_request_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For DNS queries that originate in your VPCs, specifies which Resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
#
# POST /
# Returns: record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: CreateResolverRule
export def "create-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  creator_request_id: string # A unique string that identifies the request and that allows failed requests to be retried without the risk of running the operation twice. CreatorRequestId can be any unique string, for example, a date/time stamp.
  --name: string # A friendly name that lets you easily find a rule in the Resolver dashboard in the Route 53 console.
  rule_type: string@rule-type-completer # When you want to forward DNS queries for specified domain name to resolvers on your network, specify FORWARD. When you have a forwarding rule to forward DNS queries for a domain to your network and you want Resolver to process queries for a subdomain of that domain, specify SYSTEM. For example, to forward DNS queries for example.com to resolvers on your network, you create a rule and specify FORWARD for RuleType. To then have Resolver process queries for apex.example.com, you create a rule and specify SYSTEM for RuleType. Currently, only Resolver can create rules that have a value of RECURSIVE for RuleType.
  domain_name: string # DNS queries for this domain name are forwarded to the IP addresses that you specify in TargetIps. If a query matches multiple Resolver rules (example.com and www.example.com), outbound DNS queries are routed using the Resolver rule that contains the most specific domain name (www.example.com).
  --target-ips: list # The IPs that you want Resolver to forward DNS queries to. You can specify only IPv4 addresses. Separate IP addresses with a space. TargetIps is available only when the value of Rule type is FORWARD. — item shape: {Ip?: string, Port?: int, Ipv6?: string}
  --resolver-endpoint-id: string # The ID of the outbound Resolver endpoint that you want to use to route DNS queries to the IP addresses that you specify in TargetIps.
  --tags: list # A list of the tag keys and values that you want to associate with the endpoint. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.CreateResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreatorRequestId, var: creator_request_id}, {name: Name, var: name}, {name: RuleType, var: rule_type}, {name: DomainName, var: domain_name}, {name: TargetIps, var: target_ips}, {name: ResolverEndpointId, var: resolver_endpoint_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, creator_request_id: $creator_request_id, name: $name, rule_type: $rule_type, domain_name: $domain_name, target_ips: $target_ips, resolver_endpoint_id: $resolver_endpoint_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified domain list.
#
# POST /
# Returns: record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: DeleteFirewallDomainList
export def "delete-firewall-domain-list" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  firewall_domain_list_id: string # The ID of the domain list that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteFirewallDomainList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallDomainListId, var: firewall_domain_list_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_domain_list_id: $firewall_domain_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified firewall rule.
#
# POST /
# Returns: record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: DeleteFirewallRule
export def "delete-firewall-rule" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to delete the rule from.
  firewall_domain_list_id: string # The ID of the domain list that's used in the rule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteFirewallRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: FirewallDomainListId, var: firewall_domain_list_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id, firewall_domain_list_id: $firewall_domain_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified firewall rule group.
#
# POST /
# Returns: record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: DeleteFirewallRuleGroup
export def "delete-firewall-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteFirewallRuleGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Resolver endpoint. The effect of deleting a Resolver endpoint depends on whether it's an inbound or an outbound Resolver endpoint: Inbound: DNS queries from your network are no longer routed to the DNS service for the specified VPC. Outbound: DNS queries from a VPC are no longer routed to your network.
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: DeleteResolverEndpoint
export def "delete-resolver-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteResolverEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a query logging configuration. When you delete a configuration, Resolver stops logging DNS queries for all of the Amazon VPCs that are associated with the configuration. This also applies if the query logging configuration is shared with other Amazon Web Services accounts, and the other accounts have associated VPCs with the shared configuration. Before you can delete a query logging configuration, you must first disassociate all VPCs from the configuration. See DisassociateResolverQueryLogConfig (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverQueryLogConfig.html). If you used Resource Access Manager (RAM) to share a query logging configuration with other accounts, you must stop sharing the configuration before you can delete a configuration. The accounts that you shared the configuration with can first disassociate VPCs that they associated with the configuration, but that's not necessary. If you stop sharing the configuration, those VPCs are automatically disassociated from the configuration.
#
# POST /
# Returns: record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>
# operationId: DeleteResolverQueryLogConfig
export def "delete-resolver-query-log-config" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteResolverQueryLogConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverQueryLogConfigId, var: resolver_query_log_config_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_query_log_config_id: $resolver_query_log_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Resolver rule. Before you can delete a Resolver rule, you must disassociate it from all the VPCs that you associated the Resolver rule with. For more information, see DisassociateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_DisassociateResolverRule.html).
#
# POST /
# Returns: record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: DeleteResolverRule
export def "delete-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  resolver_rule_id: string # The ID of the Resolver rule that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DeleteResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverRuleId, var: resolver_rule_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_rule_id: $resolver_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a FirewallRuleGroup from a VPC, to remove DNS filtering from the VPC.
#
# POST /
# Returns: record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: DisassociateFirewallRuleGroup
export def "disassociate-firewall-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DisassociateFirewallRuleGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupAssociationId, var: firewall_rule_group_association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_association_id: $firewall_rule_group_association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes IP addresses from an inbound or an outbound Resolver endpoint. If you want to remove more than one IP address, submit one DisassociateResolverEndpointIpAddress request for each IP address. To add an IP address to an endpoint, see AssociateResolverEndpointIpAddress (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverEndpointIpAddress.html).
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: DisassociateResolverEndpointIpAddress
export def "disassociate-resolver-endpoint-ip-address" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to disassociate an IP address from.
  ip_address: record # In an UpdateResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverEndpoint.html) request, information about an IP address to update. — shape: {IpId?: string, SubnetId?: string, Ip?: string, Ipv6?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DisassociateResolverEndpointIpAddress"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}, {name: IpAddress, var: ip_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id, ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a VPC from a query logging configuration. Before you can delete a query logging configuration, you must first disassociate all VPCs from the configuration. If you used Resource Access Manager (RAM) to share a query logging configuration with other accounts, VPCs can be disassociated from the configuration in the following ways: The accounts that you shared the configuration with can disassociate VPCs from the configuration. You can stop sharing the configuration.
#
# POST /
# Returns: record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>
# operationId: DisassociateResolverQueryLogConfig
export def "disassociate-resolver-query-log-config" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  resolver_query_log_config_id: string # The ID of the query logging configuration that you want to disassociate a specified VPC from.
  resource_id: string # The ID of the Amazon VPC that you want to disassociate from a specified query logging configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DisassociateResolverQueryLogConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverQueryLogConfigId, var: resolver_query_log_config_id}, {name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_query_log_config_id: $resolver_query_log_config_id, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the association between a specified Resolver rule and a specified VPC. If you disassociate a Resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the Resolver rule.
#
# POST /
# Returns: record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>
# operationId: DisassociateResolverRule
export def "disassociate-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  vpc_id: string # The ID of the VPC that you want to disassociate the Resolver rule from.
  resolver_rule_id: string # The ID of the Resolver rule that you want to disassociate from the specified VPC.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.DisassociateResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: VPCId, var: vpc_id}, {name: ResolverRuleId, var: resolver_rule_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, vpc_id: $vpc_id, resolver_rule_id: $resolver_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the configuration of the firewall behavior provided by DNS Firewall for a single VPC from Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# Returns: record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>
# operationId: GetFirewallConfig
export def "get-firewall-config" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  resource_id: string # The ID of the VPC from Amazon VPC that the configuration is for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetFirewallConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the specified firewall domain list.
#
# POST /
# Returns: record<FirewallDomainList: record<Id: string, Arn: string, Name: string, DomainCount: int, Status: string, StatusMessage: string, ManagedOwnerName: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: GetFirewallDomainList
export def "get-firewall-domain-list" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  firewall_domain_list_id: string # The ID of the domain list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetFirewallDomainList"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallDomainListId, var: firewall_domain_list_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_domain_list_id: $firewall_domain_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the specified firewall rule group.
#
# POST /
# Returns: record<FirewallRuleGroup: record<Id: string, Arn: string, Name: string, RuleCount: int, Status: string, StatusMessage: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: GetFirewallRuleGroup
export def "get-firewall-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetFirewallRuleGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a firewall rule group association, which enables DNS filtering for a VPC with one rule group. A VPC can have more than one firewall rule group association, and a rule group can be associated with more than one VPC.
#
# POST /
# Returns: record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: GetFirewallRuleGroupAssociation
export def "get-firewall-rule-group-association" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetFirewallRuleGroupAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupAssociationId, var: firewall_rule_group_association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_association_id: $firewall_rule_group_association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Identity and Access Management (Amazon Web Services IAM) policy for sharing the specified rule group. You can use the policy to share the rule group using Resource Access Manager (RAM).
#
# POST /
# Returns: record<FirewallRuleGroupPolicy: string>
# operationId: GetFirewallRuleGroupPolicy
export def "get-firewall-rule-group-policy" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  arn: string # The ARN (Amazon Resource Name) for the rule group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetFirewallRuleGroupPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the behavior configuration of Route 53 Resolver behavior for a single VPC from Amazon Virtual Private Cloud.
#
# POST /
# Returns: record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>
# operationId: GetResolverConfig
export def "get-resolver-config" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  resource_id: string # Resource ID of the Amazon VPC that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets DNSSEC validation information for a specified resource.
#
# POST /
# Returns: record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>
# operationId: GetResolverDnssecConfig
export def "get-resolver-dnssec-config" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  resource_id: string # The ID of the virtual private cloud (VPC) for the DNSSEC validation status.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverDnssecConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified Resolver endpoint, such as whether it's an inbound or an outbound Resolver endpoint, and the current status of the endpoint.
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: GetResolverEndpoint
export def "get-resolver-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified Resolver query logging configuration, such as the number of VPCs that the configuration is logging queries for and the location that logs are sent to.
#
# POST /
# Returns: record<ResolverQueryLogConfig: record<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>
# operationId: GetResolverQueryLogConfig
export def "get-resolver-query-log-config" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  resolver_query_log_config_id: string # The ID of the Resolver query logging configuration that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverQueryLogConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverQueryLogConfigId, var: resolver_query_log_config_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_query_log_config_id: $resolver_query_log_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified association between a Resolver query logging configuration and an Amazon VPC. When you associate a VPC with a query logging configuration, Resolver logs DNS queries that originate in that VPC.
#
# POST /
# Returns: record<ResolverQueryLogConfigAssociation: record<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>
# operationId: GetResolverQueryLogConfigAssociation
export def "get-resolver-query-log-config-association" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  resolver_query_log_config_association_id: string # The ID of the Resolver query logging configuration association that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverQueryLogConfigAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverQueryLogConfigAssociationId, var: resolver_query_log_config_association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_query_log_config_association_id: $resolver_query_log_config_association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a query logging policy. A query logging policy specifies the Resolver query logging operations and resources that you want to allow another Amazon Web Services account to be able to use.
#
# POST /
# Returns: record<ResolverQueryLogConfigPolicy: string>
# operationId: GetResolverQueryLogConfigPolicy
export def "get-resolver-query-log-config-policy" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  arn: string # The ARN of the query logging configuration that you want to get the query logging policy for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverQueryLogConfigPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified Resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound Resolver endpoint that the rule is associated with.
#
# POST /
# Returns: record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: GetResolverRule
export def "get-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  resolver_rule_id: string # The ID of the Resolver rule that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverRuleId, var: resolver_rule_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_rule_id: $resolver_rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an association between a specified Resolver rule and a VPC. You associate a Resolver rule and a VPC using AssociateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_AssociateResolverRule.html).
#
# POST /
# Returns: record<ResolverRuleAssociation: record<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>
# operationId: GetResolverRuleAssociation
export def "get-resolver-rule-association" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  resolver_rule_association_id: string # The ID of the Resolver rule association that you want to get information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverRuleAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverRuleAssociationId, var: resolver_rule_association_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_rule_association_id: $resolver_rule_association_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Resolver rule policy for a specified rule. A Resolver rule policy includes the rule that you want to share with another account, the account that you want to share the rule with, and the Resolver operations that you want to allow the account to use.
#
# POST /
# Returns: record<ResolverRulePolicy: string>
# operationId: GetResolverRulePolicy
export def "get-resolver-rule-policy" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  arn: string # The ID of the Resolver rule that you want to get the Resolver rule policy for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.GetResolverRulePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports domain names from a file into a domain list, for use in a DNS firewall rule group. Each domain specification in your domain list must satisfy the following requirements: It can optionally start with * (asterisk). With the exception of the optional starting asterisk, it must only contain the following characters: A-Z, a-z, 0-9, - (hyphen). It must be from 1-255 characters in length.
#
# POST /
# Returns: record<Id: string, Name: string, Status: string, StatusMessage: string>
# operationId: ImportFirewallDomains
export def "import-firewall-domains" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  firewall_domain_list_id: string # The ID of the domain list that you want to modify with the import operation.
  operation: string@operation-completer # What you want DNS Firewall to do with the domains that are listed in the file. This must be set to REPLACE, which updates the domain list to exactly match the list in the file.
  domain_file_url: string # The fully qualified URL or URI of the file stored in Amazon Simple Storage Service (Amazon S3) that contains the list of domains to import. The file must be in an S3 bucket that's in the same Region as your DNS Firewall. The file must be a text file and must contain a single domain per line.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ImportFirewallDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallDomainListId, var: firewall_domain_list_id}, {name: Operation, var: operation}, {name: DomainFileUrl, var: domain_file_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_domain_list_id: $firewall_domain_list_id, operation: $operation, domain_file_url: $domain_file_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the firewall configurations that you have defined. DNS Firewall uses the configurations to manage firewall behavior for your VPCs. A single call might return only a partial list of the configurations. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, FirewallConfigs: table<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>
# operationId: ListFirewallConfigs
export def "list-firewall-configs" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the firewall domain lists that you have defined. For each firewall domain list, you can retrieve the domains that are defined for a list by calling ListFirewallDomains. A single call to this list operation might return only a partial list of the domain lists. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, FirewallDomainLists: table<Id: string, Arn: string, Name: string, CreatorRequestId: string, ManagedOwnerName: string>>
# operationId: ListFirewallDomainLists
export def "list-firewall-domain-lists" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallDomainLists"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the domains that you have defined for the specified firewall domain list. A single call might return only a partial list of the domains. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, Domains: list<string>>
# operationId: ListFirewallDomains
export def "list-firewall-domains" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  firewall_domain_list_id: string # The ID of the domain list whose domains you want to retrieve.
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallDomainListId, var: firewall_domain_list_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_domain_list_id: $firewall_domain_list_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the firewall rule group associations that you have defined. Each association enables DNS filtering for a VPC with one rule group. A single call might return only a partial list of the associations. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, FirewallRuleGroupAssociations: table<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: ListFirewallRuleGroupAssociations
export def "list-firewall-rule-group-associations" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  --firewall-rule-group-id: string # The unique identifier of the firewall rule group that you want to retrieve the associations for. Leave this blank to retrieve associations for any rule group.
  --vpc-id: string # The unique identifier of the VPC that you want to retrieve the associations for. Leave this blank to retrieve associations for any VPC.
  --priority: int # The setting that determines the processing order of the rule group among the rule groups that are associated with a single VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting.
  --status: string@status-completer # The association Status setting that you want DNS Firewall to filter on for the list. If you don't specify this, then DNS Firewall returns all associations, regardless of status.
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallRuleGroupAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: VpcId, var: vpc_id}, {name: Priority, var: priority}, {name: Status, var: status}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id, vpc_id: $vpc_id, priority: $priority, status: $status, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the minimal high-level information for the rule groups that you have defined. A single call might return only a partial list of the rule groups. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, FirewallRuleGroups: table<Id: string, Arn: string, Name: string, OwnerId: string, CreatorRequestId: string, ShareStatus: string>>
# operationId: ListFirewallRuleGroups
export def "list-firewall-rule-groups" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallRuleGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the firewall rules that you have defined for the specified firewall rule group. DNS Firewall uses the rules in a rule group to filter DNS network traffic for a VPC. A single call might return only a partial list of the rules. For information, see MaxResults.
#
# POST /
# Returns: record<NextToken: string, FirewallRules: table<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: ListFirewallRules
export def "list-firewall-rules" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group that you want to retrieve the rules for.
  --priority: int # Optional additional filter for the rules to retrieve. The setting that determines the processing order of the rules in a rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting.
  --action: string@action-completer # Optional additional filter for the rules to retrieve. The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request to go through but send an alert to the logs. BLOCK - Disallow the request. If this is specified, additional handling details are provided in the rule's BlockResponse setting.
  --body-max-results: int # The maximum number of objects that you want Resolver to return for this request. If more objects are available, in the response, Resolver provides a NextToken value that you can use in a subsequent call to get the next batch of objects. If you don't specify a value for MaxResults, Resolver returns up to 100 objects. (spec name: MaxResults)
  --body-next-token: string # For the first call to this list request, omit this value. When you request a list of objects, Resolver returns at most the number of objects specified in MaxResults. If more objects are available for retrieval, Resolver returns a NextToken value in the response. To retrieve the next batch of objects, use the token that was returned for the prior request in your next request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListFirewallRules"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: Priority, var: priority}, {name: Action, var: action}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id, priority: $priority, action: $action, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Resolver configurations that you have defined. Route 53 Resolver uses the configurations to manage DNS resolution behavior for your VPCs.
#
# POST /
# Returns: record<NextToken: string, ResolverConfigs: table<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>
# operationId: ListResolverConfigs
export def "list-resolver-configs" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  --body-max-results: int # The maximum number of Resolver configurations that you want to return in the response to a ListResolverConfigs request. If you don't specify a value for MaxResults, up to 100 Resolver configurations are returned. (spec name: MaxResults)
  --body-next-token: string # (Optional) If the current Amazon Web Services account has more than MaxResults Resolver configurations, use NextToken to get the second and subsequent pages of results. For the first ListResolverConfigs request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the configurations for DNSSEC validation that are associated with the current Amazon Web Services account.
#
# POST /
# Returns: record<NextToken: string, ResolverDnssecConfigs: table<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>
# operationId: ListResolverDnssecConfigs
export def "list-resolver-dnssec-configs" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  --body-max-results: int # Optional: An integer that specifies the maximum number of DNSSEC configuration results that you want Amazon Route 53 to return. If you don't specify a value for MaxResults, Route 53 returns up to 100 configuration per page. (spec name: MaxResults)
  --body-next-token: string # (Optional) If the current Amazon Web Services account has more than MaxResults DNSSEC configurations, use NextToken to get the second and subsequent pages of results. For the first ListResolverDnssecConfigs request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of objects. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverDnssecConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the IP addresses for a specified Resolver endpoint.
#
# POST /
# Returns: record<NextToken: string, MaxResults: int, IpAddresses: table<IpId: string, SubnetId: string, Ip: string, Ipv6: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string>>
# operationId: ListResolverEndpointIpAddresses
export def "list-resolver-endpoint-ip-addresses" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to get IP addresses for.
  --body-max-results: int # The maximum number of IP addresses that you want to return in the response to a ListResolverEndpointIpAddresses request. If you don't specify a value for MaxResults, Resolver returns up to 100 IP addresses. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverEndpointIpAddresses request, omit this value. If the specified Resolver endpoint has more than MaxResults IP addresses, you can submit another ListResolverEndpointIpAddresses request to get the next group of IP addresses. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverEndpointIpAddresses"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the Resolver endpoints that were created using the current Amazon Web Services account.
#
# POST /
# Returns: record<NextToken: string, MaxResults: int, ResolverEndpoints: table<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: ListResolverEndpoints
export def "list-resolver-endpoints" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  --body-max-results: int # The maximum number of Resolver endpoints that you want to return in the response to a ListResolverEndpoints request. If you don't specify a value for MaxResults, Resolver returns up to 100 Resolver endpoints. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverEndpoints request, omit this value. If you have more than MaxResults Resolver endpoints, you can submit another ListResolverEndpoints request to get the next group of Resolver endpoints. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of Resolver endpoints, such as all inbound Resolver endpoints. If you submit a second or subsequent ListResolverEndpoints request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about associations between Amazon VPCs and query logging configurations.
#
# POST /
# Returns: record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigAssociations: table<Id: string, ResolverQueryLogConfigId: string, ResourceId: string, Status: string, Error: string, ErrorMessage: string, CreationTime: string>>
# operationId: ListResolverQueryLogConfigAssociations
export def "list-resolver-query-log-config-associations" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  --body-max-results: int # The maximum number of query logging associations that you want to return in the response to a ListResolverQueryLogConfigAssociations request. If you don't specify a value for MaxResults, Resolver returns up to 100 query logging associations. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverQueryLogConfigAssociations request, omit this value. If there are more than MaxResults query logging associations that match the values that you specify for Filters, you can submit another ListResolverQueryLogConfigAssociations request to get the next group of associations. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of query logging associations. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
  --sort-by: string # The element that you want Resolver to sort query logging associations by. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same value for SortBy, if any, as in the previous request. Valid values include the following elements: CreationTime: The ID of the query logging association. Error: If the value of Status is FAILED, the value of Error indicates the cause: DESTINATION_NOT_FOUND: The specified destination (for example, an Amazon S3 bucket) was deleted. ACCESS_DENIED: Permissions don't allow sending logs to the destination. If Status is a value other than FAILED, ERROR is null. Id: The ID of the query logging association ResolverQueryLogConfigId: The ID of the query logging configuration ResourceId: The ID of the VPC that is associated with the query logging configuration Status: The current status of the configuration. Valid values include the following: CREATING: Resolver is creating an association between an Amazon VPC and a query logging configuration. CREATED: The association between an Amazon VPC and a query logging configuration was successfully created. Resolver is logging queries that originate in the specified VPC. DELETING: Resolver is deleting this query logging association. FAILED: Resolver either couldn't create or couldn't delete the query logging association. Here are two common causes: The specified destination (for example, an Amazon S3 bucket) was deleted. Permissions don't allow sending logs to the destination.
  --sort-order: string@sort-order-completer # If you specified a value for SortBy, the order that you want query logging associations to be listed in, ASCENDING or DESCENDING. If you submit a second or subsequent ListResolverQueryLogConfigAssociations request and specify the NextToken parameter, you must use the same value for SortOrder, if any, as in the previous request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverQueryLogConfigAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters, sort_by: $sort_by, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the specified query logging configurations. Each configuration defines where you want Resolver to save DNS query logs and specifies the VPCs that you want to log queries for.
#
# POST /
# Returns: record<NextToken: string, TotalCount: int, TotalFilteredCount: int, ResolverQueryLogConfigs: table<Id: string, OwnerId: string, Status: string, ShareStatus: string, AssociationCount: int, Arn: string, Name: string, DestinationArn: string, CreatorRequestId: string, CreationTime: string>>
# operationId: ListResolverQueryLogConfigs
export def "list-resolver-query-log-configs" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  --body-max-results: int # The maximum number of query logging configurations that you want to return in the response to a ListResolverQueryLogConfigs request. If you don't specify a value for MaxResults, Resolver returns up to 100 query logging configurations. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverQueryLogConfigs request, omit this value. If there are more than MaxResults query logging configurations that match the values that you specify for Filters, you can submit another ListResolverQueryLogConfigs request to get the next group of configurations. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of query logging configurations. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
  --sort-by: string # The element that you want Resolver to sort query logging configurations by. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same value for SortBy, if any, as in the previous request. Valid values include the following elements: Arn: The ARN of the query logging configuration AssociationCount: The number of VPCs that are associated with the specified configuration CreationTime: The date and time that Resolver returned when the configuration was created CreatorRequestId: The value that was specified for CreatorRequestId when the configuration was created DestinationArn: The location that logs are sent to Id: The ID of the configuration Name: The name of the configuration OwnerId: The Amazon Web Services account number of the account that created the configuration ShareStatus: Whether the configuration is shared with other Amazon Web Services accounts or shared with the current account by another Amazon Web Services account. Sharing is configured through Resource Access Manager (RAM). Status: The current status of the configuration. Valid values include the following: CREATING: Resolver is creating the query logging configuration. CREATED: The query logging configuration was successfully created. Resolver is logging queries that originate in the specified VPC. DELETING: Resolver is deleting this query logging configuration. FAILED: Resolver either couldn't create or couldn't delete the query logging configuration. Here are two common causes: The specified destination (for example, an Amazon S3 bucket) was deleted. Permissions don't allow sending logs to the destination.
  --sort-order: string@sort-order-completer # If you specified a value for SortBy, the order that you want query logging configurations to be listed in, ASCENDING or DESCENDING. If you submit a second or subsequent ListResolverQueryLogConfigs request and specify the NextToken parameter, you must use the same value for SortOrder, if any, as in the previous request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverQueryLogConfigs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters, sort_by: $sort_by, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the associations that were created between Resolver rules and VPCs using the current Amazon Web Services account.
#
# POST /
# Returns: record<NextToken: string, MaxResults: int, ResolverRuleAssociations: table<Id: string, ResolverRuleId: string, Name: string, VPCId: string, Status: string, StatusMessage: string>>
# operationId: ListResolverRuleAssociations
export def "list-resolver-rule-associations" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  --body-max-results: int # The maximum number of rule associations that you want to return in the response to a ListResolverRuleAssociations request. If you don't specify a value for MaxResults, Resolver returns up to 100 rule associations. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverRuleAssociation request, omit this value. If you have more than MaxResults rule associations, you can submit another ListResolverRuleAssociation request to get the next group of rule associations. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of Resolver rules, such as Resolver rules that are associated with the same VPC ID. If you submit a second or subsequent ListResolverRuleAssociations request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverRuleAssociations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Resolver rules that were created using the current Amazon Web Services account.
#
# POST /
# Returns: record<NextToken: string, MaxResults: int, ResolverRules: table<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: ListResolverRules
export def "list-resolver-rules" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --body-max-results: int # The maximum number of Resolver rules that you want to return in the response to a ListResolverRules request. If you don't specify a value for MaxResults, Resolver returns up to 100 Resolver rules. (spec name: MaxResults)
  --body-next-token: string # For the first ListResolverRules request, omit this value. If you have more than MaxResults Resolver rules, you can submit another ListResolverRules request to get the next group of Resolver rules. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
  --filters: list # An optional specification to return a subset of Resolver rules, such as all Resolver rules that are associated with the same Resolver endpoint. If you submit a second or subsequent ListResolverRules request and specify the NextToken parameter, you must use the same values for Filters, if any, as in the previous request. — item shape: {Name?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListResolverRules"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags that you associated with the specified resource.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to list tags for.
  --body-max-results: int # The maximum number of tags that you want to return in the response to a ListTagsForResource request. If you don't specify a value for MaxResults, Resolver returns up to 100 tags. (spec name: MaxResults)
  --body-next-token: string # For the first ListTagsForResource request, omit this value. If you have more than MaxResults tags, you can submit another ListTagsForResource request to get the next group of tags for the resource. In the next request, specify the value of NextToken from the previous response. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches an Identity and Access Management (Amazon Web Services IAM) policy for sharing the rule group. You can use the policy to share the rule group using Resource Access Manager (RAM).
#
# POST /
# Returns: record<ReturnValue: bool>
# operationId: PutFirewallRuleGroupPolicy
export def "put-firewall-rule-group-policy" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  arn: string # The ARN (Amazon Resource Name) for the rule group that you want to share.
  firewall_rule_group_policy: string # The Identity and Access Management (Amazon Web Services IAM) policy to attach to the rule group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.PutFirewallRuleGroupPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}, {name: FirewallRuleGroupPolicy, var: firewall_rule_group_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, firewall_rule_group_policy: $firewall_rule_group_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specifies an Amazon Web Services account that you want to share a query logging configuration with, the query logging configuration that you want to share, and the operations that you want the account to be able to perform on the configuration.
#
# POST /
# Returns: record<ReturnValue: bool>
# operationId: PutResolverQueryLogConfigPolicy
export def "put-resolver-query-log-config-policy" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  arn: string # The Amazon Resource Name (ARN) of the account that you want to share rules with.
  resolver_query_log_config_policy: string # An Identity and Access Management policy statement that lists the query logging configurations that you want to share with another Amazon Web Services account and the operations that you want the account to be able to perform. You can specify the following operations in the Actions section of the statement: route53resolver:AssociateResolverQueryLogConfig route53resolver:DisassociateResolverQueryLogConfig route53resolver:ListResolverQueryLogConfigAssociations route53resolver:ListResolverQueryLogConfigs In the Resource section of the statement, you specify the ARNs for the query logging configurations that you want to share with the account that you specified in Arn.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.PutResolverQueryLogConfigPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}, {name: ResolverQueryLogConfigPolicy, var: resolver_query_log_config_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, resolver_query_log_config_policy: $resolver_query_log_config_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specifies an Amazon Web Services rule that you want to share with another account, the account that you want to share the rule with, and the operations that you want the account to be able to perform on the rule.
#
# POST /
# Returns: record<ReturnValue: bool>
# operationId: PutResolverRulePolicy
export def "put-resolver-rule-policy" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  arn: string # The Amazon Resource Name (ARN) of the rule that you want to share with another account.
  resolver_rule_policy: string # An Identity and Access Management policy statement that lists the rules that you want to share with another Amazon Web Services account and the operations that you want the account to be able to perform. You can specify the following operations in the Action section of the statement: route53resolver:GetResolverRule route53resolver:AssociateResolverRule route53resolver:DisassociateResolverRule route53resolver:ListResolverRules route53resolver:ListResolverRuleAssociations In the Resource section of the statement, specify the ARN for the rule that you want to share with another account. Specify the same ARN that you specified in Arn.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.PutResolverRulePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Arn, var: arn}, {name: ResolverRulePolicy, var: resolver_rule_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, arn: $arn, resolver_rule_policy: $resolver_rule_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to a specified resource.
#
# POST /
# Returns: record
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to add tags to. To get the ARN for a resource, use the applicable Get or List command: GetResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverEndpoint.html) GetResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRule.html) GetResolverRuleAssociation (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRuleAssociation.html) ListResolverEndpoints (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverEndpoints.html) ListResolverRuleAssociations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRuleAssociations.html) ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html)
  tags: list # The tags that you want to add to the specified resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from a specified resource.
#
# POST /
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  resource_arn: string # The Amazon Resource Name (ARN) for the resource that you want to remove tags from. To get the ARN for a resource, use the applicable Get or List command: GetResolverEndpoint (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverEndpoint.html) GetResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRule.html) GetResolverRuleAssociation (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_GetResolverRuleAssociation.html) ListResolverEndpoints (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverEndpoints.html) ListResolverRuleAssociations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRuleAssociations.html) ListResolverRules (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_ListResolverRules.html)
  tag_keys: list<string> # The tags that you want to remove to the specified resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the configuration of the firewall behavior provided by DNS Firewall for a single VPC from Amazon Virtual Private Cloud (Amazon VPC).
#
# POST /
# Returns: record<FirewallConfig: record<Id: string, ResourceId: string, OwnerId: string, FirewallFailOpen: string>>
# operationId: UpdateFirewallConfig
export def "update-firewall-config" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  resource_id: string # The ID of the VPC that the configuration is for.
  firewall_fail_open: string@firewall-fail-open-completer # Determines how Route 53 Resolver handles queries during failures, for example when all traffic that is sent to DNS Firewall fails to receive a reply. By default, fail open is disabled, which means the failure mode is closed. This approach favors security over availability. DNS Firewall blocks queries that it is unable to evaluate properly. If you enable this option, the failure mode is open. This approach favors availability over security. DNS Firewall allows queries to proceed if it is unable to properly evaluate them. This behavior is only enforced for VPCs that have at least one DNS Firewall rule group association.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateFirewallConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: FirewallFailOpen, var: firewall_fail_open}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, firewall_fail_open: $firewall_fail_open
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the firewall domain list from an array of domain specifications.
#
# POST /
# Returns: record<Id: string, Name: string, Status: string, StatusMessage: string>
# operationId: UpdateFirewallDomains
export def "update-firewall-domains" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  firewall_domain_list_id: string # The ID of the domain list whose domains you want to update.
  operation: string@operation-completer-1 # What you want DNS Firewall to do with the domains that you are providing: ADD - Add the domains to the ones that are already in the domain list. REMOVE - Search the domain list for the domains and remove them from the list. REPLACE - Update the domain list to exactly match the list that you are providing.
  domains: list<string> # A list of domains to use in the update operation. There is a limit of 1000 domains per request. Each domain specification in your domain list must satisfy the following requirements: It can optionally start with * (asterisk). With the exception of the optional starting asterisk, it must only contain the following characters: A-Z, a-z, 0-9, - (hyphen). It must be from 1-255 characters in length.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateFirewallDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallDomainListId, var: firewall_domain_list_id}, {name: Operation, var: operation}, {name: Domains, var: domains}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_domain_list_id: $firewall_domain_list_id, operation: $operation, domains: $domains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified firewall rule.
#
# POST /
# Returns: record<FirewallRule: record<FirewallRuleGroupId: string, FirewallDomainListId: string, Name: string, Priority: int, Action: string, BlockResponse: string, BlockOverrideDomain: string, BlockOverrideDnsType: string, BlockOverrideTtl: int, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: UpdateFirewallRule
export def "update-firewall-rule" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  firewall_rule_group_id: string # The unique identifier of the firewall rule group for the rule.
  firewall_domain_list_id: string # The ID of the domain list to use in the rule.
  --priority: int # The setting that determines the processing order of the rule in the rule group. DNS Firewall processes the rules in a rule group by order of priority, starting from the lowest setting. You must specify a unique priority for each rule in a rule group. To make it easier to insert rules later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for the rules in a rule group at any time.
  --action: string@action-completer # The action that DNS Firewall should take on a DNS query when it matches one of the domains in the rule's domain list: ALLOW - Permit the request to go through. ALERT - Permit the request to go through but send an alert to the logs. BLOCK - Disallow the request. This option requires additional details in the rule's BlockResponse.
  --block-response: string@block-response-completer # The way that you want DNS Firewall to block the request. Used for the rule action setting BLOCK. NODATA - Respond indicating that the query was successful, but no response is available for it. NXDOMAIN - Respond indicating that the domain name that's in the query doesn't exist. OVERRIDE - Provide a custom override in the response. This option requires custom handling details in the rule's BlockOverride* settings.
  --block-override-domain: string # The custom DNS record to send back in response to the query. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --block-override-dns-type: string@block-override-dns-type-completer # The DNS record's type. This determines the format of the record value that you provided in BlockOverrideDomain. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --block-override-ttl: int # The recommended amount of time, in seconds, for the DNS resolver or web browser to cache the provided override record. Used for the rule action BLOCK with a BlockResponse setting of OVERRIDE.
  --name: string # The name of the rule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateFirewallRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupId, var: firewall_rule_group_id}, {name: FirewallDomainListId, var: firewall_domain_list_id}, {name: Priority, var: priority}, {name: Action, var: action}, {name: BlockResponse, var: block_response}, {name: BlockOverrideDomain, var: block_override_domain}, {name: BlockOverrideDnsType, var: block_override_dns_type}, {name: BlockOverrideTtl, var: block_override_ttl}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_id: $firewall_rule_group_id, firewall_domain_list_id: $firewall_domain_list_id, priority: $priority, action: $action, block_response: $block_response, block_override_domain: $block_override_domain, block_override_dns_type: $block_override_dns_type, block_override_ttl: $block_override_ttl, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes the association of a FirewallRuleGroup with a VPC. The association enables DNS filtering for the VPC.
#
# POST /
# Returns: record<FirewallRuleGroupAssociation: record<Id: string, Arn: string, FirewallRuleGroupId: string, VpcId: string, Name: string, Priority: int, MutationProtection: string, ManagedOwnerName: string, Status: string, StatusMessage: string, CreatorRequestId: string, CreationTime: string, ModificationTime: string>>
# operationId: UpdateFirewallRuleGroupAssociation
export def "update-firewall-rule-group-association" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  firewall_rule_group_association_id: string # The identifier of the FirewallRuleGroupAssociation.
  --priority: int # The setting that determines the processing order of the rule group among the rule groups that you associate with the specified VPC. DNS Firewall filters VPC traffic starting from the rule group with the lowest numeric priority setting. You must specify a unique priority for each rule group that you associate with a single VPC. To make it easier to insert rule groups later, leave space between the numbers, for example, use 100, 200, and so on. You can change the priority setting for a rule group association after you create it.
  --mutation-protection: string@mutation-protection-completer # If enabled, this setting disallows modification or removal of the association, to help prevent against accidentally altering DNS firewall protections.
  --name: string # The name of the rule group association.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateFirewallRuleGroupAssociation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FirewallRuleGroupAssociationId, var: firewall_rule_group_association_id}, {name: Priority, var: priority}, {name: MutationProtection, var: mutation_protection}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, firewall_rule_group_association_id: $firewall_rule_group_association_id, priority: $priority, mutation_protection: $mutation_protection, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the behavior configuration of Route 53 Resolver behavior for a single VPC from Amazon Virtual Private Cloud.
#
# POST /
# Returns: record<ResolverConfig: record<Id: string, ResourceId: string, OwnerId: string, AutodefinedReverse: string>>
# operationId: UpdateResolverConfig
export def "update-resolver-config" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  resource_id: string # Resource ID of the Amazon VPC that you want to update the Resolver configuration for.
  autodefined_reverse_flag: string@autodefined-reverse-flag-completer # Indicates whether or not the Resolver will create autodefined rules for reverse DNS lookups. This is enabled by default. Disabling this option will also affect EC2-Classic instances using ClassicLink. For more information, see ClassicLink (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-classiclink.html) in the Amazon EC2 guide. We are retiring EC2-Classic on August 15, 2022. We recommend that you migrate from EC2-Classic to a VPC. For more information, see Migrate from EC2-Classic to a VPC (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-migrate.html) in the Amazon EC2 guide and the blog EC2-Classic Networking is Retiring – Here’s How to Prepare (http://aws.amazon.com/blogs/aws/ec2-classic-is-retiring-heres-how-to-prepare/). It can take some time for the status change to be completed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateResolverConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: AutodefinedReverseFlag, var: autodefined_reverse_flag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, autodefined_reverse_flag: $autodefined_reverse_flag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing DNSSEC validation configuration. If there is no existing DNSSEC validation configuration, one is created.
#
# POST /
# Returns: record<ResolverDNSSECConfig: record<Id: string, OwnerId: string, ResourceId: string, ValidationStatus: string>>
# operationId: UpdateResolverDnssecConfig
export def "update-resolver-dnssec-config" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_id: string # The ID of the virtual private cloud (VPC) that you're updating the DNSSEC validation status for.
  validation: string@validation-completer # The new value that you are specifying for DNSSEC validation for the VPC. The value can be ENABLE or DISABLE. Be aware that it can take time for a validation status change to be completed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateResolverDnssecConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: Validation, var: validation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, validation: $validation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name, or enpoint type for an inbound or an outbound Resolver endpoint. You can only update between IPV4 and DUALSTACK, IPV6 endpoint type can't be updated to other type.
#
# POST /
# Returns: record<ResolverEndpoint: record<Id: string, CreatorRequestId: string, Arn: string, Name: string, SecurityGroupIds: list<string>, Direction: string, IpAddressCount: int, HostVPCId: string, Status: string, StatusMessage: string, CreationTime: string, ModificationTime: string, ResolverEndpointType: string>>
# operationId: UpdateResolverEndpoint
export def "update-resolver-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  resolver_endpoint_id: string # The ID of the Resolver endpoint that you want to update.
  --name: string # The name of the Resolver endpoint that you want to update.
  --resolver-endpoint-type: string@resolver-endpoint-type-completer # Specifies the endpoint type for what type of IP address the endpoint uses to forward DNS queries.
  --update-ip-addresses: list # Updates the Resolver endpoint type to IpV4, Ipv6, or dual-stack. — item shape: {IpId: string, Ipv6: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateResolverEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverEndpointId, var: resolver_endpoint_id}, {name: Name, var: name}, {name: ResolverEndpointType, var: resolver_endpoint_type}, {name: UpdateIpAddresses, var: update_ip_addresses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_endpoint_id: $resolver_endpoint_id, name: $name, resolver_endpoint_type: $resolver_endpoint_type, update_ip_addresses: $update_ip_addresses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates settings for a specified Resolver rule. ResolverRuleId is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
#
# POST /
# Returns: record<ResolverRule: record<Id: string, CreatorRequestId: string, Arn: string, DomainName: string, Status: string, StatusMessage: string, RuleType: string, Name: string, TargetIps: list<record>, ResolverEndpointId: string, OwnerId: string, ShareStatus: string, CreationTime: string, ModificationTime: string>>
# operationId: UpdateResolverRule
export def "update-resolver-rule" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  resolver_rule_id: string # The ID of the Resolver rule that you want to update.
  config: record # In an UpdateResolverRule (https://docs.aws.amazon.com/Route53/latest/APIReference/API_route53resolver_UpdateResolverRule.html) request, information about the changes that you want to make. — shape: {Name?: string, TargetIps?: list, ResolverEndpointId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Resolver.UpdateResolverRule"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResolverRuleId, var: resolver_rule_id}, {name: Config, var: config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resolver_rule_id: $resolver_rule_id, config: $config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
