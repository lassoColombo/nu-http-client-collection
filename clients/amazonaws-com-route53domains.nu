# Auto-generated client for Amazon Route 53 Domains v2014-05-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/route53domains/2014-05-15/openapi.json
# Auth: --token flag or $env.AMAZON_ROUTE_53_DOMAINS_TOKEN

const CLIENT = {
  base_url: "http://route53domains.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_ROUTE_53_DOMAINS_TOKEN"
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

def base-url-completer [] { ["http://route53domains.us-east-1.amazonaws.com" "http://route53domains.us-east-2.amazonaws.com" "http://route53domains.us-west-1.amazonaws.com" "http://route53domains.us-west-2.amazonaws.com" "http://route53domains.us-gov-west-1.amazonaws.com" "http://route53domains.us-gov-east-1.amazonaws.com" "http://route53domains.ca-central-1.amazonaws.com" "http://route53domains.eu-north-1.amazonaws.com" "http://route53domains.eu-west-1.amazonaws.com" "http://route53domains.eu-west-2.amazonaws.com" "http://route53domains.eu-west-3.amazonaws.com" "http://route53domains.eu-central-1.amazonaws.com" "http://route53domains.eu-south-1.amazonaws.com" "http://route53domains.af-south-1.amazonaws.com" "http://route53domains.ap-northeast-1.amazonaws.com" "http://route53domains.ap-northeast-2.amazonaws.com" "http://route53domains.ap-northeast-3.amazonaws.com" "http://route53domains.ap-southeast-1.amazonaws.com" "http://route53domains.ap-southeast-2.amazonaws.com" "http://route53domains.ap-east-1.amazonaws.com" "http://route53domains.ap-south-1.amazonaws.com" "http://route53domains.sa-east-1.amazonaws.com" "http://route53domains.me-south-1.amazonaws.com" "https://route53domains.us-east-1.amazonaws.com" "https://route53domains.us-east-2.amazonaws.com" "https://route53domains.us-west-1.amazonaws.com" "https://route53domains.us-west-2.amazonaws.com" "https://route53domains.us-gov-west-1.amazonaws.com" "https://route53domains.us-gov-east-1.amazonaws.com" "https://route53domains.ca-central-1.amazonaws.com" "https://route53domains.eu-north-1.amazonaws.com" "https://route53domains.eu-west-1.amazonaws.com" "https://route53domains.eu-west-2.amazonaws.com" "https://route53domains.eu-west-3.amazonaws.com" "https://route53domains.eu-central-1.amazonaws.com" "https://route53domains.eu-south-1.amazonaws.com" "https://route53domains.af-south-1.amazonaws.com" "https://route53domains.ap-northeast-1.amazonaws.com" "https://route53domains.ap-northeast-2.amazonaws.com" "https://route53domains.ap-northeast-3.amazonaws.com" "https://route53domains.ap-southeast-1.amazonaws.com" "https://route53domains.ap-southeast-2.amazonaws.com" "https://route53domains.ap-east-1.amazonaws.com" "https://route53domains.ap-south-1.amazonaws.com" "https://route53domains.sa-east-1.amazonaws.com" "https://route53domains.me-south-1.amazonaws.com" "http://route53domains.cn-north-1.amazonaws.com.cn" "http://route53domains.cn-northwest-1.amazonaws.com.cn" "https://route53domains.cn-north-1.amazonaws.com.cn" "https://route53domains.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["Route53Domains_v20140515.AcceptDomainTransferFromAnotherAwsAccount"] }
def x-amz-target-completer-1 [] { ["Route53Domains_v20140515.AssociateDelegationSignerToDomain"] }
def x-amz-target-completer-2 [] { ["Route53Domains_v20140515.CancelDomainTransferToAnotherAwsAccount"] }
def x-amz-target-completer-3 [] { ["Route53Domains_v20140515.CheckDomainAvailability"] }
def x-amz-target-completer-4 [] { ["Route53Domains_v20140515.CheckDomainTransferability"] }
def x-amz-target-completer-5 [] { ["Route53Domains_v20140515.DeleteDomain"] }
def x-amz-target-completer-6 [] { ["Route53Domains_v20140515.DeleteTagsForDomain"] }
def x-amz-target-completer-7 [] { ["Route53Domains_v20140515.DisableDomainAutoRenew"] }
def x-amz-target-completer-8 [] { ["Route53Domains_v20140515.DisableDomainTransferLock"] }
def x-amz-target-completer-9 [] { ["Route53Domains_v20140515.DisassociateDelegationSignerFromDomain"] }
def x-amz-target-completer-10 [] { ["Route53Domains_v20140515.EnableDomainAutoRenew"] }
def x-amz-target-completer-11 [] { ["Route53Domains_v20140515.EnableDomainTransferLock"] }
def x-amz-target-completer-12 [] { ["Route53Domains_v20140515.GetContactReachabilityStatus"] }
def x-amz-target-completer-13 [] { ["Route53Domains_v20140515.GetDomainDetail"] }
def x-amz-target-completer-14 [] { ["Route53Domains_v20140515.GetDomainSuggestions"] }
def x-amz-target-completer-15 [] { ["Route53Domains_v20140515.GetOperationDetail"] }
def x-amz-target-completer-16 [] { ["Route53Domains_v20140515.ListDomains"] }
def sort-by-completer [] { ["SubmittedDate"] }
def sort-order-completer [] { ["ASC" "DESC"] }
def x-amz-target-completer-17 [] { ["Route53Domains_v20140515.ListOperations"] }
def x-amz-target-completer-18 [] { ["Route53Domains_v20140515.ListPrices"] }
def x-amz-target-completer-19 [] { ["Route53Domains_v20140515.ListTagsForDomain"] }
def x-amz-target-completer-20 [] { ["Route53Domains_v20140515.PushDomain"] }
def x-amz-target-completer-21 [] { ["Route53Domains_v20140515.RegisterDomain"] }
def x-amz-target-completer-22 [] { ["Route53Domains_v20140515.RejectDomainTransferFromAnotherAwsAccount"] }
def x-amz-target-completer-23 [] { ["Route53Domains_v20140515.RenewDomain"] }
def x-amz-target-completer-24 [] { ["Route53Domains_v20140515.ResendContactReachabilityEmail"] }
def x-amz-target-completer-25 [] { ["Route53Domains_v20140515.ResendOperationAuthorization"] }
def x-amz-target-completer-26 [] { ["Route53Domains_v20140515.RetrieveDomainAuthCode"] }
def x-amz-target-completer-27 [] { ["Route53Domains_v20140515.TransferDomain"] }
def x-amz-target-completer-28 [] { ["Route53Domains_v20140515.TransferDomainToAnotherAwsAccount"] }
def x-amz-target-completer-29 [] { ["Route53Domains_v20140515.UpdateDomainContact"] }
def x-amz-target-completer-30 [] { ["Route53Domains_v20140515.UpdateDomainContactPrivacy"] }
def x-amz-target-completer-31 [] { ["Route53Domains_v20140515.UpdateDomainNameservers"] }
def x-amz-target-completer-32 [] { ["Route53Domains_v20140515.UpdateTagsForDomain"] }
def x-amz-target-completer-33 [] { ["Route53Domains_v20140515.ViewBilling"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-domain-transfer-from-another-aws-account: "record<OperationId: string>"
    associate-delegation-signer-to-domain: "record<OperationId: string>"
    cancel-domain-transfer-to-another-aws-account: "record<OperationId: string>"
    check-domain-availability: "record<Availability: string>"
    check-domain-transferability: "record<Transferability: record<Transferable: string>>"
    delete-domain: "record<OperationId: string>"
    delete-tags-for-domain: "record"
    disable-domain-auto-renew: "record"
    disable-domain-transfer-lock: "record<OperationId: string>"
    disassociate-delegation-signer-from-domain: "record<OperationId: string>"
    enable-domain-auto-renew: "record"
    enable-domain-transfer-lock: "record<OperationId: string>"
    get-contact-reachability-status: "record<domainName: string, status: string>"
    get-domain-detail: "record<DomainName: string, Nameservers: table<Name: string, GlueIps: list>, AutoRenew: bool, AdminContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, RegistrantContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, TechContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, AdminPrivacy: bool, RegistrantPrivacy: bool, TechPrivacy: bool, RegistrarName: string, WhoIsServer: string, RegistrarUrl: string, AbuseContactEmail: string, AbuseContactPhone: string, RegistryDomainId: string, CreationDate: string, UpdatedDate: string, ExpirationDate: string, Reseller: string, DnsSec: string, StatusList: list<string>, DnssecKeys: table<Algorithm: int, Flags: int, PublicKey: string, DigestType: int, Digest: string, KeyTag: int, Id: string>>"
    get-domain-suggestions: "record<SuggestionsList: table<DomainName: string, Availability: string>>"
    get-operation-detail: "record<OperationId: string, Status: string, Message: string, DomainName: string, Type: string, SubmittedDate: string, LastUpdatedDate: string, StatusFlag: string>"
    list-domains: "record<Domains: table<DomainName: string, AutoRenew: bool, TransferLock: bool, Expiry: string>, NextPageMarker: string>"
    list-operations: "record<Operations: table<OperationId: string, Status: string, Type: string, SubmittedDate: string, DomainName: string, Message: string, StatusFlag: string, LastUpdatedDate: string>, NextPageMarker: string>"
    list-prices: "record<Prices: table<Name: string, RegistrationPrice: record, TransferPrice: record, RenewalPrice: record, ChangeOwnershipPrice: record, RestorationPrice: record>, NextPageMarker: string>"
    list-tags-for-domain: "record<TagList: table<Key: string, Value: string>>"
    register-domain: "record<OperationId: string>"
    reject-domain-transfer-from-another-aws-account: "record<OperationId: string>"
    renew-domain: "record<OperationId: string>"
    resend-contact-reachability-email: "record<domainName: string, emailAddress: string, isAlreadyVerified: bool>"
    retrieve-domain-auth-code: "record<AuthCode: string>"
    transfer-domain: "record<OperationId: string>"
    transfer-domain-to-another-aws-account: "record<OperationId: string, Password: string>"
    update-domain-contact: "record<OperationId: string>"
    update-domain-contact-privacy: "record<OperationId: string>"
    update-domain-nameservers: "record<OperationId: string>"
    update-tags-for-domain: "record"
    view-billing: "record<NextPageMarker: string, BillingRecords: table<DomainName: string, Operation: string, InvoiceId: string, BillDate: string, Price: float>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-domain-transfer-from-another-aws-account" "associate-delegation-signer-to-domain" "cancel-domain-transfer-to-another-aws-account" "check-domain-availability" "check-domain-transferability" "delete-domain" "delete-tags-for-domain" "disable-domain-auto-renew" "disable-domain-transfer-lock" "disassociate-delegation-signer-from-domain" "enable-domain-auto-renew" "enable-domain-transfer-lock" "get-contact-reachability-status" "get-domain-detail" "get-domain-suggestions" "get-operation-detail" "list-domains" "list-operations" "list-prices" "list-tags-for-domain" "push-domain" "register-domain" "reject-domain-transfer-from-another-aws-account" "renew-domain" "resend-contact-reachability-email" "resend-operation-authorization" "retrieve-domain-auth-code" "transfer-domain" "transfer-domain-to-another-aws-account" "update-domain-contact" "update-domain-contact-privacy" "update-domain-nameservers" "update-tags-for-domain" "view-billing" "commands"] | sort) } | get name | first)
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

# Accepts the transfer of a domain from another Amazon Web Services account to the currentAmazon Web Services account. You initiate a transfer between Amazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). If you use the CLI command at accept-domain-transfer-from-another-aws-account (https://docs.aws.amazon.com/cli/latest/reference/route53domains/accept-domain-transfer-from-another-aws-account.html), use JSON format as input instead of text because otherwise CLI will throw an error from domain transfer input that includes single quotes. Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# Returns: record<OperationId: string>
# operationId: AcceptDomainTransferFromAnotherAwsAccount
export def "accept-domain-transfer-from-another-aws-account" [
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
  domain_name: string # The name of the domain that was specified when another Amazon Web Services account submitted a TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
  password: string # The password that was returned by the TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.AcceptDomainTransferFromAnotherAwsAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: Password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a delegation signer (DS) record in the registry zone for this domain name. Note that creating DS record at the registry impacts DNSSEC validation of your DNS records. This action may render your domain name unavailable on the internet if the steps are completed in the wrong order, or with incorrect timing. For more information about DNSSEC signing, see Configuring DNSSEC signing (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html) in the Route 53 developer guide.
#
# POST /
# Returns: record<OperationId: string>
# operationId: AssociateDelegationSignerToDomain
export def "associate-delegation-signer-to-domain" [
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
  domain_name: string # The name of the domain.
  signing_attributes: record # Information about a delegation signer (DS) record that was created in the registry by AssociateDelegationSignerToDomain (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AssociateDelegationSignerToDomain.html). — shape: {Algorithm?: int, Flags?: int, PublicKey?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.AssociateDelegationSignerToDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: SigningAttributes, var: signing_attributes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, signing_attributes: $signing_attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the transfer of a domain from the current Amazon Web Services account to another Amazon Web Services account. You initiate a transfer betweenAmazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). You must cancel the transfer before the other Amazon Web Services account accepts the transfer using AcceptDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AcceptDomainTransferFromAnotherAwsAccount.html). Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# Returns: record<OperationId: string>
# operationId: CancelDomainTransferToAnotherAwsAccount
export def "cancel-domain-transfer-to-another-aws-account" [
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
  domain_name: string # The name of the domain for which you want to cancel the transfer to another Amazon Web Services account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.CancelDomainTransferToAnotherAwsAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
#
# POST /
# Returns: record<Availability: string>
# operationId: CheckDomainAvailability
export def "check-domain-availability" [
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
  domain_name: string # The name of the domain that you want to get availability for. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html). For more information, see Formatting Internationalized Domain Names (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html#domain-name-format-idns).
  --idn-lang-code: string # Reserved for future use.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.CheckDomainAvailability"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: IdnLangCode, var: idn_lang_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, idn_lang_code: $idn_lang_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether a domain name can be transferred to Amazon Route 53.
#
# POST /
# Returns: record<Transferability: record<Transferable: string>>
# operationId: CheckDomainTransferability
export def "check-domain-transferability" [
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
  domain_name: string # The name of the domain that you want to transfer to Route 53. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com.
  --auth-code: string # If the registrar for the top-level domain (TLD) requires an authorization code to transfer the domain, the code that you got from the current registrar for the domain. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.CheckDomainTransferability"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: AuthCode, var: auth_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, auth_code: $auth_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation deletes the specified domain. This action is permanent. For more information, see Deleting a domain name registration (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-delete.html). To transfer the domain registration to another registrar, use the transfer process that’s provided by the registrar to which you want to transfer the registration. Otherwise, the following apply: You can’t get a refund for the cost of a deleted domain registration. The registry for the top-level domain might hold the domain name for a brief time before releasing it for other users to register (varies by registry). When the registration has been deleted, we'll send you a confirmation to the registrant contact. The email will come from noreply@domainnameverification.net or noreply@registrar.amazon.com.
#
# POST /
# Returns: record<OperationId: string>
# operationId: DeleteDomain
export def "delete-domain" [
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
  domain_name: string # Name of the domain to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.DeleteDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation deletes the specified tags for a domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# Returns: record
# operationId: DeleteTagsForDomain
export def "delete-tags-for-domain" [
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
  domain_name: string # The domain for which you want to delete one or more tags.
  tags_to_delete: list<string> # A list of tag keys to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.DeleteTagsForDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: TagsToDelete, var: tags_to_delete}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, tags_to_delete: $tags_to_delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation disables automatic renewal of domain registration for the specified domain.
#
# POST /
# Returns: record
# operationId: DisableDomainAutoRenew
export def "disable-domain-auto-renew" [
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
  domain_name: string # The name of the domain that you want to disable automatic renewal for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.DisableDomainAutoRenew"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation removes the transfer lock on the domain (specifically the clientTransferProhibited status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# Returns: record<OperationId: string>
# operationId: DisableDomainTransferLock
export def "disable-domain-transfer-lock" [
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
  domain_name: string # The name of the domain that you want to remove the transfer lock for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.DisableDomainTransferLock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a delegation signer (DS) record in the registry zone for this domain name.
#
# POST /
# Returns: record<OperationId: string>
# operationId: DisassociateDelegationSignerFromDomain
export def "disassociate-delegation-signer-from-domain" [
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
  domain_name: string # Name of the domain.
  id: string # An internal identification number assigned to each DS record after it’s created. You can retrieve it as part of DNSSEC information returned by GetDomainDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetDomainDetail.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.DisassociateDelegationSignerFromDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: Id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your Amazon Web Services account. The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see Domains That You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Route 53 requires that you renew before the end of the renewal period so we can complete processing before the deadline.
#
# POST /
# Returns: record
# operationId: EnableDomainAutoRenew
export def "enable-domain-auto-renew" [
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
  domain_name: string # The name of the domain that you want to enable automatic renewal for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.EnableDomainAutoRenew"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation sets the transfer lock on the domain (specifically the clientTransferProhibited status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# Returns: record<OperationId: string>
# operationId: EnableDomainTransferLock
export def "enable-domain-transfer-lock" [
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
  domain_name: string # The name of the domain that you want to set the transfer lock for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.EnableDomainTransferLock"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded. If you want us to resend the email, use the ResendContactReachabilityEmail operation.
#
# POST /
# Returns: record<domainName: string, status: string>
# operationId: GetContactReachabilityStatus
export def "get-contact-reachability-status" [
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
  --domain-name: string # The name of the domain for which you want to know whether the registrant contact has confirmed that the email address is valid.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.GetContactReachabilityStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns detailed information about a specified domain that is associated with the current Amazon Web Services account. Contact information for the domain is also returned as part of the output.
#
# POST /
# Returns: record<DomainName: string, Nameservers: table<Name: string, GlueIps: list>, AutoRenew: bool, AdminContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, RegistrantContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, TechContact: record<FirstName: string, LastName: string, ContactType: string, OrganizationName: string, AddressLine1: string, AddressLine2: string, City: string, State: string, CountryCode: string, ZipCode: string, PhoneNumber: string, Email: string, Fax: string, ExtraParams: list<record>>, AdminPrivacy: bool, RegistrantPrivacy: bool, TechPrivacy: bool, RegistrarName: string, WhoIsServer: string, RegistrarUrl: string, AbuseContactEmail: string, AbuseContactPhone: string, RegistryDomainId: string, CreationDate: string, UpdatedDate: string, ExpirationDate: string, Reseller: string, DnsSec: string, StatusList: list<string>, DnssecKeys: table<Algorithm: int, Flags: int, PublicKey: string, DigestType: int, Digest: string, KeyTag: int, Id: string>>
# operationId: GetDomainDetail
export def "get-domain-detail" [
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
  domain_name: string # The name of the domain that you want to get detailed information about.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.GetDomainDetail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The GetDomainSuggestions operation returns a list of suggested domain names.
#
# POST /
# Returns: record<SuggestionsList: table<DomainName: string, Availability: string>>
# operationId: GetDomainSuggestions
export def "get-domain-suggestions" [
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
  domain_name: string # A domain name that you want to use as the basis for a list of possible domain names. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html).
  suggestion_count: int # The number of suggested domain names that you want Route 53 to return. Specify a value between 1 and 50.
  --only-available: oneof<nothing, bool> # If OnlyAvailable is true, Route 53 returns only domain names that are available. If OnlyAvailable is false, Route 53 returns domain names without checking whether they're available to be registered. To determine whether the domain is available, you can call checkDomainAvailability for each suggestion.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.GetDomainSuggestions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: SuggestionCount, var: suggestion_count}, {name: OnlyAvailable, var: only_available, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, suggestion_count: $suggestion_count, only_available: $only_available
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns the current status of an operation that is not completed.
#
# POST /
# Returns: record<OperationId: string, Status: string, Message: string, DomainName: string, Type: string, SubmittedDate: string, LastUpdatedDate: string, StatusFlag: string>
# operationId: GetOperationDetail
export def "get-operation-detail" [
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
  operation_id: string # The identifier for the operation for which you want to get the status. Route 53 returned the identifier in the response to the original request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.GetOperationDetail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns all the domain names registered with Amazon Route 53 for the current Amazon Web Services account if no filtering conditions are used.
#
# POST /
# Returns: record<Domains: table<DomainName: string, AutoRenew: bool, TransferLock: bool, Expiry: string>, NextPageMarker: string>
# operationId: ListDomains
export def "list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --filter-conditions: list # A complex type that contains information about the filters applied during the ListDomains request. The filter conditions can include domain name and domain expiration. — item shape: {Name: "DomainName"|"Expiry", Operator: "LE"|"GE"|"BEGINS_WITH", Values: list<string>}
  --sort-condition: record # Information for sorting a list of domains. — shape: {Name: "DomainName"|"Expiry", SortOrder: "ASC"|"DESC"}
  --body-marker: string # For an initial request for a list of domains, omit this element. If the number of domains that are associated with the current Amazon Web Services account is greater than the value that you specified for MaxItems, you can use Marker to return additional domains. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Constraints: The marker must match the value specified in the previous request. (spec name: Marker)
  --body-max-items: int # Number of domains to be returned. Default: 20 (spec name: MaxItems)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxItems, var: max_items}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ListDomains"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FilterConditions, var: filter_conditions}, {name: SortCondition, var: sort_condition}, {name: Marker, var: body_marker}, {name: MaxItems, var: body_max_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_items: $max_items, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_conditions: $filter_conditions, sort_condition: $sort_condition, body_marker: $body_marker, body_max_items: $body_max_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about all of the operations that return an operation ID and that have ever been performed on domains that were registered by the current account. This command runs only in the us-east-1 Region.
#
# POST /
# Returns: record<Operations: table<OperationId: string, Status: string, Type: string, SubmittedDate: string, DomainName: string, Message: string, StatusFlag: string, LastUpdatedDate: string>, NextPageMarker: string>
# operationId: ListOperations
export def "list-operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --submitted-since: string # An optional parameter that lets you get information about all the operations that you submitted after a specified date and time. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --body-marker: string # For an initial request for a list of operations, omit this element. If the number of operations that are not yet complete is greater than the value that you specified for MaxItems, you can use Marker to return additional operations. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. (spec name: Marker)
  --body-max-items: int # Number of domains to be returned. Default: 20 (spec name: MaxItems)
  --status: list<string> # The status of the operations.
  --type: list<string> # An arrays of the domains operation types.
  --sort-by: string@sort-by-completer # The sort type for returned values.
  --sort-order: string@sort-order-completer # The sort order ofr returned values, either ascending or descending.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxItems, var: max_items}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ListOperations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubmittedSince, var: submitted_since}, {name: Marker, var: body_marker}, {name: MaxItems, var: body_max_items}, {name: Status, var: status}, {name: Type, var: type}, {name: SortBy, var: sort_by}, {name: SortOrder, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_items: $max_items, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, submitted_since: $submitted_since, body_marker: $body_marker, body_max_items: $body_max_items, status: $status, type: $type, sort_by: $sort_by, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the following prices for either all the TLDs supported by Route 53, or the specified TLD: Registration Transfer Owner change Domain renewal Domain restoration
#
# POST /
# Returns: record<Prices: table<Name: string, RegistrationPrice: record, TransferPrice: record, RenewalPrice: record, ChangeOwnershipPrice: record, RestorationPrice: record>, NextPageMarker: string>
# operationId: ListPrices
export def "list-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  --tld: string # The TLD for which you want to receive the pricing information. For example. .net. If a Tld value is not provided, a list of prices for all TLDs supported by Route 53 is returned.
  --body-marker: string # For an initial request for a list of prices, omit this element. If the number of prices that are not yet complete is greater than the value that you specified for MaxItems, you can use Marker to return additional prices. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Used only for all TLDs. If you specify a TLD, don't specify a Marker. (spec name: Marker)
  --body-max-items: int # Number of Prices to be returned. Used only for all TLDs. If you specify a TLD, don't specify a MaxItems. (spec name: MaxItems)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxItems, var: max_items}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ListPrices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tld, var: tld}, {name: Marker, var: body_marker}, {name: MaxItems, var: body_max_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_items: $max_items, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tld: $tld, body_marker: $body_marker, body_max_items: $body_max_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns all of the tags that are associated with the specified domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# Returns: record<TagList: table<Key: string, Value: string>>
# operationId: ListTagsForDomain
export def "list-tags-for-domain" [
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
  domain_name: string # The domain for which you want to get a list of tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ListTagsForDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a domain from Amazon Web Services to another registrar. Supported actions: Changes the IPS tags of a .uk domain, and pushes it to transit. Transit means that the domain is ready to be transferred to another registrar.
#
# POST /
# operationId: PushDomain
export def "push-domain" [
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
  domain_name: string # Name of the domain.
  target: string # New IPS tag for the domain.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.PushDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: Target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters. When you register a domain, Amazon Route 53 does the following: Creates a Route 53 hosted zone that has the same name as the domain. Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers. Enables auto renew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration. Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the administrative, registrant, and technical contacts. You must specify the same privacy setting for the administrative, registrant, and technical contacts. If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email. Charges your Amazon Web Services account an amount based on the top-level domain. For more information, see Amazon Route 53 Pricing (http://aws.amazon.com/route53/pricing/).
#
# POST /
# Returns: record<OperationId: string>
# operationId: RegisterDomain
export def "register-domain" [
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
  domain_name: string # The domain name that you want to register. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com. Internationalized domain names are not supported for some top-level domains. To determine whether the TLD that you want to use supports internationalized domain names, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html). For more information, see Formatting Internationalized Domain Names (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html#domain-name-format-idns).
  --idn-lang-code: string # Reserved for future use.
  duration_in_years: int # The number of years that you want to register the domain for. Domains are registered for a minimum of one year. The maximum period depends on the top-level domain. For the range of valid values for your domain, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Default: 1
  --auto-renew: oneof<nothing, bool> # Indicates whether the domain will be automatically renewed (true) or not (false). Auto renewal only takes effect after the account is charged. Default: true
  admin_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  registrant_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  tech_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --privacy-protect-admin-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-registrant-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (the domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-tech-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.RegisterDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: IdnLangCode, var: idn_lang_code}, {name: DurationInYears, var: duration_in_years}, {name: AutoRenew, var: auto_renew}, {name: AdminContact, var: admin_contact}, {name: RegistrantContact, var: registrant_contact}, {name: TechContact, var: tech_contact}, {name: PrivacyProtectAdminContact, var: privacy_protect_admin_contact}, {name: PrivacyProtectRegistrantContact, var: privacy_protect_registrant_contact}, {name: PrivacyProtectTechContact, var: privacy_protect_tech_contact}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, idn_lang_code: $idn_lang_code, duration_in_years: $duration_in_years, auto_renew: $auto_renew, admin_contact: $admin_contact, registrant_contact: $registrant_contact, tech_contact: $tech_contact, privacy_protect_admin_contact: $privacy_protect_admin_contact, privacy_protect_registrant_contact: $privacy_protect_registrant_contact, privacy_protect_tech_contact: $privacy_protect_tech_contact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects the transfer of a domain from another Amazon Web Services account to the current Amazon Web Services account. You initiate a transfer betweenAmazon Web Services accounts using TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# Returns: record<OperationId: string>
# operationId: RejectDomainTransferFromAnotherAwsAccount
export def "reject-domain-transfer-from-another-aws-account" [
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
  domain_name: string # The name of the domain that was specified when another Amazon Web Services account submitted a TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html) request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.RejectDomainTransferFromAnotherAwsAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your Amazon Web Services account. We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see Renewing Registration for a Domain (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html) in the Amazon Route 53 Developer Guide.
#
# POST /
# Returns: record<OperationId: string>
# operationId: RenewDomain
export def "renew-domain" [
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
  domain_name: string # The name of the domain that you want to renew.
  --duration-in-years: int # The number of years that you want to renew the domain for. The maximum number of years depends on the top-level domain. For the range of valid values for your domain, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. Default: 1
  current_expiry_year: int # The year when the registration for the domain is set to expire. This value must match the current expiration date for the domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.RenewDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: DurationInYears, var: duration_in_years}, {name: CurrentExpiryYear, var: current_expiry_year}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, duration_in_years: $duration_in_years, current_expiry_year: $current_expiry_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
#
# POST /
# Returns: record<domainName: string, emailAddress: string, isAlreadyVerified: bool>
# operationId: ResendContactReachabilityEmail
export def "resend-contact-reachability-email" [
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
  --domain-name: string # The name of the domain for which you want Route 53 to resend a confirmation email to the registrant contact.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ResendContactReachabilityEmail"}]
    body: {content_type: "application/json", kind: json, fields: [{name: domainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend the form of authorization email for this operation.
#
# POST /
# operationId: ResendOperationAuthorization
export def "resend-operation-authorization" [
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
  operation_id: string # Operation ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ResendOperationAuthorization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OperationId, var: operation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation returns the authorization code for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
#
# POST /
# Returns: record<AuthCode: string>
# operationId: RetrieveDomainAuthCode
export def "retrieve-domain-auth-code" [
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
  domain_name: string # The name of the domain that you want to get an authorization code for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.RetrieveDomainAuthCode"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs). For more information about transferring domains, see the following topics: For transfer requirements, a detailed procedure, and information about viewing the status of a domain that you're transferring to Route 53, see Transferring Registration for a Domain to Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html) in the Amazon Route 53 Developer Guide. For information about how to transfer a domain from one Amazon Web Services account to another, see TransferDomainToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_TransferDomainToAnotherAwsAccount.html). For information about how to transfer a domain to another domain registrar, see Transferring a Domain from Amazon Route 53 to Another Registrar (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-from-route-53.html) in the Amazon Route 53 Developer Guide. If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you transfer your DNS service to Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time. If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable. If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.
#
# POST /
# Returns: record<OperationId: string>
# operationId: TransferDomain
export def "transfer-domain" [
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
  domain_name: string # The name of the domain that you want to transfer to Route 53. The top-level domain (TLD), such as .com, must be a TLD that Route 53 supports. For a list of supported TLDs, see Domains that You Can Register with Amazon Route 53 (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar-tld-list.html) in the Amazon Route 53 Developer Guide. The domain name can contain only the following characters: Letters a through z. Domain names are not case sensitive. Numbers 0 through 9. Hyphen (-). You can't specify a hyphen at the beginning or end of a label. Period (.) to separate the labels in the name, such as the . in example.com.
  --idn-lang-code: string # Reserved for future use.
  duration_in_years: int # The number of years that you want to register the domain for. Domains are registered for a minimum of one year. The maximum period depends on the top-level domain. Default: 1
  --nameservers: list # Contains details for the host and glue IP addresses. — item shape: {Name: string, GlueIps?: list<string>}
  --auth-code: string # The authorization code for the domain. You get this value from the current registrar. (format: password)
  --auto-renew: oneof<nothing, bool> # Indicates whether the domain will be automatically renewed (true) or not (false). Auto renewal only takes effect after the account is charged. Default: true
  admin_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  registrant_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  tech_contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --privacy-protect-admin-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-registrant-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
  --privacy-protect-tech-contact: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts. Default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.TransferDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: IdnLangCode, var: idn_lang_code}, {name: DurationInYears, var: duration_in_years}, {name: Nameservers, var: nameservers}, {name: AuthCode, var: auth_code}, {name: AutoRenew, var: auto_renew}, {name: AdminContact, var: admin_contact}, {name: RegistrantContact, var: registrant_contact}, {name: TechContact, var: tech_contact}, {name: PrivacyProtectAdminContact, var: privacy_protect_admin_contact}, {name: PrivacyProtectRegistrantContact, var: privacy_protect_registrant_contact}, {name: PrivacyProtectTechContact, var: privacy_protect_tech_contact}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, idn_lang_code: $idn_lang_code, duration_in_years: $duration_in_years, nameservers: $nameservers, auth_code: $auth_code, auto_renew: $auto_renew, admin_contact: $admin_contact, registrant_contact: $registrant_contact, tech_contact: $tech_contact, privacy_protect_admin_contact: $privacy_protect_admin_contact, privacy_protect_registrant_contact: $privacy_protect_registrant_contact, privacy_protect_tech_contact: $privacy_protect_tech_contact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfers a domain from the current Amazon Web Services account to another Amazon Web Services account. Note the following: The Amazon Web Services account that you're transferring the domain to must accept the transfer. If the other account doesn't accept the transfer within 3 days, we cancel the transfer. See AcceptDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_AcceptDomainTransferFromAnotherAwsAccount.html). You can cancel the transfer before the other account accepts it. See CancelDomainTransferToAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_CancelDomainTransferToAnotherAwsAccount.html). The other account can reject the transfer. See RejectDomainTransferFromAnotherAwsAccount (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_RejectDomainTransferFromAnotherAwsAccount.html). When you transfer a domain from one Amazon Web Services account to another, Route 53 doesn't transfer the hosted zone that is associated with the domain. DNS resolution isn't affected if the domain and the hosted zone are owned by separate accounts, so transferring the hosted zone is optional. For information about transferring the hosted zone to another Amazon Web Services account, see Migrating a Hosted Zone to a Different Amazon Web Services Account (https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html) in the Amazon Route 53 Developer Guide. Use either ListOperations (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_ListOperations.html) or GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to determine whether the operation succeeded. GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) provides additional information, for example, Domain Transfer from Aws Account 111122223333 has been cancelled.
#
# POST /
# Returns: record<OperationId: string, Password: string>
# operationId: TransferDomainToAnotherAwsAccount
export def "transfer-domain-to-another-aws-account" [
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
  domain_name: string # The name of the domain that you want to transfer from the current Amazon Web Services account to another account.
  account_id: string # The account ID of the Amazon Web Services account that you want to transfer the domain to, for example, 111122223333.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.TransferDomainToAnotherAwsAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: AccountId, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical. If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the operation. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdateDomainContact
export def "update-domain-contact" [
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
  domain_name: string # The name of the domain that you want to update contact information for.
  --admin-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --registrant-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --tech-contact: record # ContactDetail includes the following elements. — shape: {FirstName?: string, LastName?: string, ContactType?: "PERSON"|"COMPANY"|"ASSOCIATION"|"PUBLIC_BODY"|"RESELLER", OrganizationName?: string, AddressLine1?: string, AddressLine2?: string, City?: string, State?: string, ... (6 more fields)}
  --consent: record # Customer's consent for the owner change request. — shape: {MaxPrice: float, Currency: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.UpdateDomainContact"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: AdminContact, var: admin_contact}, {name: RegistrantContact, var: registrant_contact}, {name: TechContact, var: tech_contact}, {name: Consent, var: consent}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, admin_contact: $admin_contact, registrant_contact: $registrant_contact, tech_contact: $tech_contact, consent: $consent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi. You must specify the same privacy setting for the administrative, registrant, and technical contacts. This operation affects only the contact information for the specified contact type (administrative, registrant, or technical). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with GetOperationDetail (https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_GetOperationDetail.html) to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email. By disabling the privacy service via API, you consent to the publication of the contact information provided for this domain via the public WHOIS database. You certify that you are the registrant of this domain name and have the authority to make this decision. You may withdraw your consent at any time by enabling privacy protection using either UpdateDomainContactPrivacy or the Route 53 console. Enabling privacy protection removes the contact information provided for this domain from the WHOIS database. For more information on our privacy practices, see https://aws.amazon.com/privacy/ (https://aws.amazon.com/privacy/).
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdateDomainContactPrivacy
export def "update-domain-contact-privacy" [
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
  domain_name: string # The name of the domain that you want to update the privacy setting for.
  --admin-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the admin contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts.
  --registrant-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the registrant contact (domain owner). You must specify the same privacy setting for the administrative, registrant, and technical contacts.
  --tech-privacy: oneof<nothing, bool> # Whether you want to conceal contact information from WHOIS queries. If you specify true, WHOIS ("who is") queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you specify false, WHOIS queries return the information that you entered for the technical contact. You must specify the same privacy setting for the administrative, registrant, and technical contacts.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.UpdateDomainContactPrivacy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: AdminPrivacy, var: admin_privacy}, {name: RegistrantPrivacy, var: registrant_privacy}, {name: TechPrivacy, var: tech_privacy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, admin_privacy: $admin_privacy, registrant_privacy: $registrant_privacy, tech_privacy: $tech_privacy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain. If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
#
# POST /
# Returns: record<OperationId: string>
# operationId: UpdateDomainNameservers
export def "update-domain-nameservers" [
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
  domain_name: string # The name of the domain that you want to change name servers for.
  --fi-auth-key: string # The authorization key for .fi domains (format: password)
  nameservers: list # A list of new name servers for the domain. — item shape: {Name: string, GlueIps?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.UpdateDomainNameservers"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: FIAuthKey, var: fi_auth_key}, {name: Nameservers, var: nameservers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, fi_auth_key: $fi_auth_key, nameservers: $nameservers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This operation adds or updates tags for a specified domain. All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.
#
# POST /
# Returns: record
# operationId: UpdateTagsForDomain
export def "update-tags-for-domain" [
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
  domain_name: string # The domain for which you want to add or update tags.
  --tags-to-update: list # A list of the tag keys and values that you want to add or update. If you specify a key that already exists, the corresponding value will be replaced. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.UpdateTagsForDomain"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DomainName, var: domain_name}, {name: TagsToUpdate, var: tags_to_update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, domain_name: $domain_name, tags_to_update: $tags_to_update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all the domain-related billing records for the current Amazon Web Services account for a specified period
#
# POST /
# Returns: record<NextPageMarker: string, BillingRecords: table<DomainName: string, Operation: string, InvoiceId: string, BillDate: string, Price: float>>
# operationId: ViewBilling
export def "view-billing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-items: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --start: string # The beginning date and time for the time period for which you want a list of billing records. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --end: string # The end date and time for the time period for which you want a list of billing records. Specify the date and time in Unix time format and Coordinated Universal time (UTC). (format: date-time)
  --body-marker: string # For an initial request for a list of billing records, omit this element. If the number of billing records that are associated with the current Amazon Web Services account during the specified period is greater than the value that you specified for MaxItems, you can use Marker to return additional billing records. Get the value of NextPageMarker from the previous response, and submit another request that includes the value of NextPageMarker in the Marker element. Constraints: The marker must match the value of NextPageMarker that was returned in the previous response. (spec name: Marker)
  --body-max-items: int # The number of billing records to be returned. Default: 20 (spec name: MaxItems)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxItems, var: max_items}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "Route53Domains_v20140515.ViewBilling"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Start, var: start}, {name: End, var: end}, {name: Marker, var: body_marker}, {name: MaxItems, var: body_max_items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_items: $max_items, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, start: $start, end: $end, body_marker: $body_marker, body_max_items: $body_max_items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
