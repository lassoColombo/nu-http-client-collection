# Auto-generated client for Authorized Buyers Marketplace API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/authorizedbuyersmarketplace/v1/openapi.json
# Auth: --token flag or $env.AUTHORIZED_BUYERS_MARKETPLACE_API_TOKEN

const CLIENT = {
  base_url: "https://authorizedbuyersmarketplace.googleapis.com"
  token_env_var: "AUTHORIZED_BUYERS_MARKETPLACE_API_TOKEN"
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

def base-url-completer [] { ["https://authorizedbuyersmarketplace.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def role-completer [] { ["CLIENT_DEAL_APPROVER" "CLIENT_DEAL_NEGOTIATOR" "CLIENT_DEAL_VIEWER" "CLIENT_ROLE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    authorizedbuyersmarketplace-buyers-auction-packages-subscribe-clients: "record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>"
    authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe-clients: "record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>"
    authorizedbuyersmarketplace-buyers-proposals-send-rfp: "record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>"
    authorizedbuyersmarketplace-buyers-finalized-deals-add-creative: "record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>"
    authorizedbuyersmarketplace-buyers-finalized-deals-set-ready-to-serve: "record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>"
    authorizedbuyersmarketplace-buyers-clients-users-delete: "record"
    authorizedbuyersmarketplace-buyers-publisher-profiles-get: "record<audienceDescription: string, directDealsContact: string, displayName: string, domains: list<string>, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: table<appStore: string, externalAppId: string, name: string>, name: string, overview: string, pitchStatement: string, programmaticDealsContact: string, publisherCode: string, samplePageUrl: string, topHeadlines: list<string>>"
    authorizedbuyersmarketplace-buyers-proposals-deals-patch: "record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list<record>, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record<amount: record, type: string>>, privateAuctionTerms: record<floorPrice: record<amount: record, type: string>, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record<amount: record, type: string>, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record<dayParts: list, timeZoneType: string>, geoTargeting: record<excludedCriteriaIds: list, targetedCriteriaIds: list>, inventorySizeTargeting: record<excludedInventorySizes: list, targetedInventorySizes: list>, inventoryTypeTargeting: record<inventoryTypes: list>, placementTargeting: record<mobileApplicationTargeting: record, uriTargeting: record>, technologyTargeting: record<deviceCapabilityTargeting: record, deviceCategoryTargeting: record, operatingSystemTargeting: record>, userListTargeting: record<excludedCriteriaIds: list, targetedCriteriaIds: list>, videoTargeting: record<excludedPositionTypes: list, targetedPositionTypes: list>>, updateTime: string>"
    authorizedbuyersmarketplace-buyers-proposals-accept: "record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>"
    authorizedbuyersmarketplace-buyers-clients-users-activate: "record<email: string, name: string, state: string>"
    authorizedbuyersmarketplace-buyers-clients-users-deactivate: "record<email: string, name: string, state: string>"
    authorizedbuyersmarketplace-buyers-finalized-deals-pause: "record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>"
    authorizedbuyersmarketplace-buyers-finalized-deals-resume: "record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>"
    authorizedbuyersmarketplace-buyers-auction-packages-subscribe: "record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>"
    authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe: "record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>"
    authorizedbuyersmarketplace-buyers-auction-packages-list: "record<auctionPackages: table<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list, updateTime: string>, nextPageToken: string>"
    authorizedbuyersmarketplace-buyers-clients-list: "record<clients: table<displayName: string, name: string, partnerClientId: string, role: string, sellerVisible: bool, state: string>, nextPageToken: string>"
    authorizedbuyersmarketplace-buyers-clients-create: "record<displayName: string, name: string, partnerClientId: string, role: string, sellerVisible: bool, state: string>"
    authorizedbuyersmarketplace-buyers-proposals-deals-list: "record<deals: table<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record, dealType: string, deliveryControl: record, description: string, displayName: string, estimatedGrossSpend: record, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record, privateAuctionTerms: record, programmaticGuaranteedTerms: record, proposalRevision: string, publisherProfile: string, sellerTimeZone: record, targeting: record, updateTime: string>, nextPageToken: string>"
    authorizedbuyersmarketplace-buyers-proposals-deals-batch-update: "record<deals: table<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record, dealType: string, deliveryControl: record, description: string, displayName: string, estimatedGrossSpend: record, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record, privateAuctionTerms: record, programmaticGuaranteedTerms: record, proposalRevision: string, publisherProfile: string, sellerTimeZone: record, targeting: record, updateTime: string>>"
    authorizedbuyersmarketplace-buyers-finalized-deals-list: "record<finalizedDeals: table<deal: record, dealPausingInfo: record, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record>, nextPageToken: string>"
    authorizedbuyersmarketplace-buyers-proposals-list: "record<nextPageToken: string, proposals: table<billedBuyer: string, buyer: string, buyerContacts: list, buyerPrivateData: record, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: list, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: list, state: string, termsAndConditions: string, updateTime: string>>"
    authorizedbuyersmarketplace-buyers-publisher-profiles-list: "record<nextPageToken: string, publisherProfiles: table<audienceDescription: string, directDealsContact: string, displayName: string, domains: list, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: list, name: string, overview: string, pitchStatement: string, programmaticDealsContact: string, publisherCode: string, samplePageUrl: string, topHeadlines: list>>"
    authorizedbuyersmarketplace-buyers-clients-users-list: "record<clientUsers: table<email: string, name: string, state: string>, nextPageToken: string>"
    authorizedbuyersmarketplace-buyers-clients-users-create: "record<email: string, name: string, state: string>"
    authorizedbuyersmarketplace-buyers-proposals-add-note: "record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>"
    authorizedbuyersmarketplace-buyers-proposals-cancel-negotiation: "record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["authorizedbuyersmarketplace-buyers-auction-packages-subscribe-clients" "authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe-clients" "authorizedbuyersmarketplace-buyers-proposals-send-rfp" "authorizedbuyersmarketplace-buyers-finalized-deals-add-creative" "authorizedbuyersmarketplace-buyers-finalized-deals-set-ready-to-serve" "authorizedbuyersmarketplace-buyers-clients-users-delete" "authorizedbuyersmarketplace-buyers-publisher-profiles-get" "authorizedbuyersmarketplace-buyers-proposals-deals-patch" "authorizedbuyersmarketplace-buyers-proposals-accept" "authorizedbuyersmarketplace-buyers-clients-users-activate" "authorizedbuyersmarketplace-buyers-clients-users-deactivate" "authorizedbuyersmarketplace-buyers-finalized-deals-pause" "authorizedbuyersmarketplace-buyers-finalized-deals-resume" "authorizedbuyersmarketplace-buyers-auction-packages-subscribe" "authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe" "authorizedbuyersmarketplace-buyers-auction-packages-list" "authorizedbuyersmarketplace-buyers-clients-list" "authorizedbuyersmarketplace-buyers-clients-create" "authorizedbuyersmarketplace-buyers-proposals-deals-list" "authorizedbuyersmarketplace-buyers-proposals-deals-batch-update" "authorizedbuyersmarketplace-buyers-finalized-deals-list" "authorizedbuyersmarketplace-buyers-proposals-list" "authorizedbuyersmarketplace-buyers-publisher-profiles-list" "authorizedbuyersmarketplace-buyers-clients-users-list" "authorizedbuyersmarketplace-buyers-clients-users-create" "authorizedbuyersmarketplace-buyers-proposals-add-note" "authorizedbuyersmarketplace-buyers-proposals-cancel-negotiation" "commands"] | sort) } | get name | first)
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

# Subscribe the specified clients of the buyer to the auction package. If a client in the list does not belong to the buyer, an error response will be returned, and all of the following clients in the list will not be subscribed. Subscribing an already subscribed client will have no effect.
#
# POST /v1/{auctionPackage}:subscribeClients
# Returns: record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.auctionPackages.subscribeClients
export def "authorizedbuyersmarketplace-buyers-auction-packages-subscribe-clients" [
  auction_package: string
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
  --clients: list<string> # Optional. A list of client buyers to subscribe to the auction package, with client buyer in the format `buyers/{accountId}/clients/{clientAccountId}`. The current buyer will be subscribed to the auction package regardless of the list contents if not already.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{auctionPackage}:subscribeClients"
    path_params: [{name: auctionPackage, var: auction_package}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clients, var: clients}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auction_package: $auction_package, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, clients: $clients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from the auction package for the specified clients of the buyer. Unsubscribing a client that is not subscribed will have no effect.
#
# POST /v1/{auctionPackage}:unsubscribeClients
# Returns: record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.auctionPackages.unsubscribeClients
export def "authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe-clients" [
  auction_package: string
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
  --clients: list<string> # Optional. A list of client buyers to unsubscribe from the auction package, with client buyer in the format `buyers/{accountId}/clients/{clientAccountId}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{auctionPackage}:unsubscribeClients"
    path_params: [{name: auctionPackage, var: auction_package}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clients, var: clients}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auction_package: $auction_package, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, clients: $clients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a request for proposal (RFP) to a publisher to initiate the negotiation regarding certain inventory. In the RFP, buyers can specify the deal type, deal terms, start and end dates, targeting, and a message to the publisher. Once the RFP is sent, a proposal in `SELLER_REVIEW_REQUESTED` state will be created and returned in the response. The publisher may review your request and respond with detailed deals in the proposal.
#
# POST /v1/{buyer}/proposals:sendRfp
# Returns: record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.sendRfp
export def "authorizedbuyersmarketplace-buyers-proposals-send-rfp" [
  buyer: string
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
  --buyer-contacts: list # Contact information for the buyer. — item shape: {displayName?: string, email?: string}
  --client: string # If the current buyer is sending the RFP on behalf of its client, use this field to specify the name of the client in the format: `buyers/{accountId}/clients/{clientAccountid}`.
  --display-name: string # Required. The display name of the proposal being created by this RFP.
  --estimated-gross-spend: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
  --flight-end-time: string # Required. Proposed flight end time of the RFP. A timestamp in RFC3339 UTC "Zulu" format. Note that the specified value will be truncated to a granularity of one second. (format: google-datetime)
  --flight-start-time: string # Required. Proposed flight start time of the RFP. A timestamp in RFC3339 UTC "Zulu" format. Note that the specified value will be truncated to a granularity of one second. (format: google-datetime)
  --geo-targeting: record # Generic targeting used for targeting dimensions that contains a list of included and excluded numeric IDs. This cannot be filtered using list filter syntax. — shape: {excludedCriteriaIds?: list<string>, targetedCriteriaIds?: list<string>}
  --inventory-size-targeting: record # Represents the size of an ad unit that can be targeted on a bid request. — shape: {excludedInventorySizes?: list, targetedInventorySizes?: list}
  --note: string # A message that is sent to the publisher. Maximum length is 1024 characters.
  --preferred-deal-terms: record # Pricing terms for Preferred Deals. — shape: {fixedPrice?: record}
  --programmatic-guaranteed-terms: record # Pricing terms for Programmatic Guaranteed Deals. — shape: {fixedPrice?: record, guaranteedLooks?: string, impressionCap?: string, minimumDailyLooks?: string, percentShareOfVoice?: string, reservationType?: "RESERVATION_TYPE_UNSPECIFIED"|"STANDARD"|"SPONSORSHIP"}
  --publisher-profile: string # Required. The profile of the publisher who will receive this RFP in the format: `buyers/{accountId}/publisherProfiles/{publisherProfileId}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{buyer}/proposals:sendRfp"
    path_params: [{name: buyer, var: buyer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: buyerContacts, var: buyer_contacts}, {name: client, var: client}, {name: displayName, var: display_name}, {name: estimatedGrossSpend, var: estimated_gross_spend}, {name: flightEndTime, var: flight_end_time}, {name: flightStartTime, var: flight_start_time}, {name: geoTargeting, var: geo_targeting}, {name: inventorySizeTargeting, var: inventory_size_targeting}, {name: note, var: note}, {name: preferredDealTerms, var: preferred_deal_terms}, {name: programmaticGuaranteedTerms, var: programmatic_guaranteed_terms}, {name: publisherProfile, var: publisher_profile}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    buyer: $buyer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, buyer_contacts: $buyer_contacts, client: $client, display_name: $display_name, estimated_gross_spend: $estimated_gross_spend, flight_end_time: $flight_end_time, flight_start_time: $flight_start_time, geo_targeting: $geo_targeting, inventory_size_targeting: $inventory_size_targeting, note: $note, preferred_deal_terms: $preferred_deal_terms, programmatic_guaranteed_terms: $programmatic_guaranteed_terms, publisher_profile: $publisher_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add creative to be used in the bidding process for a finalized deal. For programmatic guaranteed deals, it's recommended that you associate at least one approved creative with the deal before calling SetReadyToServe, to help reduce the number of bid responses filtered because they don't contain approved creatives. Creatives successfully added to a deal can be found in the Realtime-bidding Creatives API creative.deal_ids. This method only applies to programmatic guaranteed deals. Maximum number of 1000 creatives can be added to a finalized deal.
#
# POST /v1/{deal}:addCreative
# Returns: record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>
# operationId: authorizedbuyersmarketplace.buyers.finalizedDeals.addCreative
export def "authorizedbuyersmarketplace-buyers-finalized-deals-add-creative" [
  deal: string
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
  --creative: string # Name of the creative to add to the finalized deal, in the format `buyers/{buyerAccountId}/creatives/{creativeId}`. See creative.name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{deal}:addCreative"
    path_params: [{name: deal, var: deal}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: creative, var: creative}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deal: $deal, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, creative: $creative
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the given finalized deal as ready to serve. By default, deals are set as ready to serve as soon as they're finalized. If you want to opt out of the default behavior, and manually indicate that deals are ready to serve, ask your Technical Account Manager to add you to the allowlist. If you choose to use this method, finalized deals belonging to the bidder and its child seats don't start serving until after you call `setReadyToServe`, and after the deals become active. For example, you can use this method to delay receiving bid requests until your creative is ready. This method only applies to programmatic guaranteed deals.
#
# POST /v1/{deal}:setReadyToServe
# Returns: record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>
# operationId: authorizedbuyersmarketplace.buyers.finalizedDeals.setReadyToServe
export def "authorizedbuyersmarketplace-buyers-finalized-deals-set-ready-to-serve" [
  deal: string
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{deal}:setReadyToServe"
    path_params: [{name: deal, var: deal}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deal: $deal, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing client user. The client user will lose access to the Authorized Buyers UI. Note that if a client user is deleted, the user's access to the UI can't be restored unless a new client user is created and activated.
#
# DELETE /v1/{name}
# Returns: record
# operationId: authorizedbuyersmarketplace.buyers.clients.users.delete
export def "authorizedbuyersmarketplace-buyers-clients-users-delete" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the requested publisher profile by name.
#
# GET /v1/{name}
# Returns: record<audienceDescription: string, directDealsContact: string, displayName: string, domains: list<string>, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: table<appStore: string, externalAppId: string, name: string>, name: string, overview: string, pitchStatement: string, programmaticDealsContact: string, publisherCode: string, samplePageUrl: string, topHeadlines: list<string>>
# operationId: authorizedbuyersmarketplace.buyers.publisherProfiles.get
export def "authorizedbuyersmarketplace-buyers-publisher-profiles-get" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the given deal at the buyer known revision number. If the server revision has advanced since the passed-in proposal.proposal_revision an ABORTED error message will be returned. The revision number is incremented by the server whenever the proposal or its constituent deals are updated. Note: The revision number is kept at a proposal level. The buyer of the API is expected to keep track of the revision number after the last update operation and send it in as part of the next update request. This way, if there are further changes on the server (for example, seller making new updates), then the server can detect conflicts and reject the proposed changes.
#
# PATCH /v1/{name}
# Returns: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list<record>, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record<amount: record, type: string>>, privateAuctionTerms: record<floorPrice: record<amount: record, type: string>, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record<amount: record, type: string>, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record<dayParts: list, timeZoneType: string>, geoTargeting: record<excludedCriteriaIds: list, targetedCriteriaIds: list>, inventorySizeTargeting: record<excludedInventorySizes: list, targetedInventorySizes: list>, inventoryTypeTargeting: record<inventoryTypes: list>, placementTargeting: record<mobileApplicationTargeting: record, uriTargeting: record>, technologyTargeting: record<deviceCapabilityTargeting: record, deviceCategoryTargeting: record, operatingSystemTargeting: record>, userListTargeting: record<excludedCriteriaIds: list, targetedCriteriaIds: list>, videoTargeting: record<excludedPositionTypes: list, targetedPositionTypes: list>>, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.deals.patch
export def "authorizedbuyersmarketplace-buyers-proposals-deals-patch" [
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
  --update-mask: string # List of fields to be updated. If empty or unspecified, the service will update all fields populated in the update request excluding the output only fields and primitive fields with default value. Note that explicit field mask is required in order to reset a primitive field back to its default value, for example, false for boolean fields, 0 for integer fields. A special field mask consisting of a single path "*" can be used to indicate full replacement(the equivalent of PUT method), updatable fields unset or unspecified in the input will be cleared or set to default value. Output only fields will be ignored regardless of the value of updateMask.
  --creative-requirements: record # Message captures data about the creatives in the deal.
  --delivery-control: record # Message contains details about how the deal will be paced.
  --estimated-gross-spend: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
  --flight-end-time: string # Proposed flight end time of the deal. This will generally be stored in a granularity of a second. A value is not necessary for Private Auction deals. (format: google-datetime)
  --flight-start-time: string # Proposed flight start time of the deal. This will generally be stored in the granularity of one second since deal serving starts at seconds boundary. Any time specified with more granularity (for example, in milliseconds) will be truncated towards the start of time in seconds. (format: google-datetime)
  --body-name: string # Immutable. The unique identifier of the deal. Auto-generated by the server when a deal is created. Format: buyers/{accountId}/proposals/{proposalId}/deals/{dealId} (spec name: name)
  --preferred-deal-terms: record # Pricing terms for Preferred Deals. — shape: {fixedPrice?: record}
  --private-auction-terms: record # Pricing terms for Private Auctions. — shape: {floorPrice?: record}
  --programmatic-guaranteed-terms: record # Pricing terms for Programmatic Guaranteed Deals. — shape: {fixedPrice?: record, guaranteedLooks?: string, impressionCap?: string, minimumDailyLooks?: string, percentShareOfVoice?: string, reservationType?: "RESERVATION_TYPE_UNSPECIFIED"|"STANDARD"|"SPONSORSHIP"}
  --publisher-profile: string # Immutable. Reference to the seller on the deal. Format: `buyers/{buyerAccountId}/publisherProfiles/{publisherProfileId}`
  --seller-time-zone: record # Represents a time zone from the [IANA Time Zone Database](https://www.iana.org/time-zones). — shape: {id?: string, version?: string}
  --targeting: record # Targeting represents different criteria that can be used to target inventory. For example, they can choose to target inventory only if the user is in the US. Multiple types of targeting are always applied as a logical AND, unless noted otherwise. — shape: {daypartTargeting?: record, geoTargeting?: record, inventorySizeTargeting?: record, inventoryTypeTargeting?: record, placementTargeting?: record, technologyTargeting?: record, userListTargeting?: record, videoTargeting?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: creativeRequirements, var: creative_requirements}, {name: deliveryControl, var: delivery_control}, {name: estimatedGrossSpend, var: estimated_gross_spend}, {name: flightEndTime, var: flight_end_time}, {name: flightStartTime, var: flight_start_time}, {name: name, var: body_name}, {name: preferredDealTerms, var: preferred_deal_terms}, {name: privateAuctionTerms, var: private_auction_terms}, {name: programmaticGuaranteedTerms, var: programmatic_guaranteed_terms}, {name: publisherProfile, var: publisher_profile}, {name: sellerTimeZone, var: seller_time_zone}, {name: targeting, var: targeting}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, creative_requirements: $creative_requirements, delivery_control: $delivery_control, estimated_gross_spend: $estimated_gross_spend, flight_end_time: $flight_end_time, flight_start_time: $flight_start_time, body_name: $body_name, preferred_deal_terms: $preferred_deal_terms, private_auction_terms: $private_auction_terms, programmatic_guaranteed_terms: $programmatic_guaranteed_terms, publisher_profile: $publisher_profile, seller_time_zone: $seller_time_zone, targeting: $targeting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts the proposal at the given revision number. If the revision number in the request is behind the latest from the server, an error message will be returned. This call updates the Proposal.state from `BUYER_ACCEPTANCE_REQUESTED` to `FINALIZED`; it has no side effect if the Proposal.state is already `FINALIZED` and throws exception if the Proposal.state is not either `BUYER_ACCEPTANCE_REQUESTED` or `FINALIZED`. Accepting a proposal means the buyer understands and accepts the Proposal.terms_and_conditions proposed by the seller.
#
# POST /v1/{name}:accept
# Returns: record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.accept
export def "authorizedbuyersmarketplace-buyers-proposals-accept" [
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
  --proposal-revision: string # The last known client revision number of the proposal. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:accept"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: proposalRevision, var: proposal_revision}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, proposal_revision: $proposal_revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates an existing client user. The state of the client user will be updated from "INACTIVE" to "ACTIVE". This method has no effect if the client user is already in "ACTIVE" state. An error will be returned if the client user to activate is still in "INVITED" state.
#
# POST /v1/{name}:activate
# Returns: record<email: string, name: string, state: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.users.activate
export def "authorizedbuyersmarketplace-buyers-clients-users-activate" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:activate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates an existing client user. The state of the client user will be updated from "ACTIVE" to "INACTIVE". This method has no effect if the client user is already in "INACTIVE" state. An error will be returned if the client user to deactivate is still in "INVITED" state.
#
# POST /v1/{name}:deactivate
# Returns: record<email: string, name: string, state: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.users.deactivate
export def "authorizedbuyersmarketplace-buyers-clients-users-deactivate" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:deactivate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pauses serving of the given finalized deal. This call only pauses the serving status, and does not affect other fields of the finalized deal. Calling this method for an already paused deal has no effect. This method only applies to programmatic guaranteed deals.
#
# POST /v1/{name}:pause
# Returns: record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>
# operationId: authorizedbuyersmarketplace.buyers.finalizedDeals.pause
export def "authorizedbuyersmarketplace-buyers-finalized-deals-pause" [
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
  --reason: string # The reason to pause the finalized deal, will be displayed to the seller. Maximum length is 1000 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:pause"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes serving of the given finalized deal. Calling this method for an running deal has no effect. If a deal is initially paused by the seller, calling this method will not resume serving of the deal until the seller also resumes the deal. This method only applies to programmatic guaranteed deals.
#
# POST /v1/{name}:resume
# Returns: record<deal: record<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record<creativeFormat: string, creativePreApprovalPolicy: string, creativeSafeFrameCompatibility: string, maxAdDurationMs: string, programmaticCreativeSource: string, skippableAdType: string>, dealType: string, deliveryControl: record<companionDeliveryType: string, creativeRotationType: string, deliveryRateType: string, frequencyCap: list, roadblockingType: string>, description: string, displayName: string, estimatedGrossSpend: record<currencyCode: string, nanos: int, units: string>, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record<fixedPrice: record>, privateAuctionTerms: record<floorPrice: record, openAuctionAllowed: bool>, programmaticGuaranteedTerms: record<fixedPrice: record, guaranteedLooks: string, impressionCap: string, minimumDailyLooks: string, percentShareOfVoice: string, reservationType: string>, proposalRevision: string, publisherProfile: string, sellerTimeZone: record<id: string, version: string>, targeting: record<daypartTargeting: record, geoTargeting: record, inventorySizeTargeting: record, inventoryTypeTargeting: record, placementTargeting: record, technologyTargeting: record, userListTargeting: record, videoTargeting: record>, updateTime: string>, dealPausingInfo: record<pauseReason: string, pauseRole: string, pausingConsented: bool>, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record<adImpressions7Days: string, bidRate7Days: float, bidRequests7Days: string, bids7Days: string, filteredBidRate7Days: float, mustBidRateCurrentMonth: float>>
# operationId: authorizedbuyersmarketplace.buyers.finalizedDeals.resume
export def "authorizedbuyersmarketplace-buyers-finalized-deals-resume" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:resume"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to the auction package for the specified buyer. Once subscribed, the bidder will receive a call out for inventory matching the auction package targeting criteria with the auction package deal ID and the specified buyer.
#
# POST /v1/{name}:subscribe
# Returns: record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.auctionPackages.subscribe
export def "authorizedbuyersmarketplace-buyers-auction-packages-subscribe" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:subscribe"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from the auction package for the specified buyer. Once unsubscribed, the bidder will no longer receive a call out for the auction package deal ID and the specified buyer.
#
# POST /v1/{name}:unsubscribe
# Returns: record<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list<string>, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.auctionPackages.unsubscribe
export def "authorizedbuyersmarketplace-buyers-auction-packages-unsubscribe" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:unsubscribe"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the auction packages subscribed by a buyer and its clients.
#
# GET /v1/{parent}/auctionPackages
# Returns: record<auctionPackages: table<createTime: string, creator: string, description: string, displayName: string, name: string, subscribedClients: list, updateTime: string>, nextPageToken: string>
# operationId: authorizedbuyersmarketplace.buyers.auctionPackages.list
export def "authorizedbuyersmarketplace-buyers-auction-packages-list" [
  parent: string
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
  --page-size: int # Requested page size. The server may return fewer results than requested. Max allowed page size is 500.
  --page-token: string # The page token as returned. ListAuctionPackagesResponse.nextPageToken
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/auctionPackages"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the clients for the current buyer.
#
# GET /v1/{parent}/clients
# Returns: record<clients: table<displayName: string, name: string, partnerClientId: string, role: string, sellerVisible: bool, state: string>, nextPageToken: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.list
export def "authorizedbuyersmarketplace-buyers-clients-list" [
  parent: string
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
  --filter: string # Query string using the [Filtering Syntax](https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters) Supported fields for filtering are: * partnerClientId Use this field to filter the clients by the partnerClientId. For example, if the partnerClientId of the client is "1234", the value of this field should be `partnerClientId = "1234"`, in order to get only the client whose partnerClientId is "1234" in the response.
  --page-size: int # Requested page size. If left blank, a default page size of 500 will be applied.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientsResponse.nextPageToken returned from the previous call to the list method.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/clients"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new client.
#
# POST /v1/{parent}/clients
# Returns: record<displayName: string, name: string, partnerClientId: string, role: string, sellerVisible: bool, state: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.create
export def "authorizedbuyersmarketplace-buyers-clients-create" [
  parent: string
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
  --display-name: string # Required. Display name shown to publishers. Must be unique for clients without partnerClientId specified. Maximum length of 255 characters is allowed.
  --partner-client-id: string # Arbitrary unique identifier provided by the buyer. This field can be used to associate a client with an identifier in the namespace of the buyer, lookup clients by that identifier and verify whether an Authorized Buyers account of the client already exists. If present, must be unique across all the clients.
  --role: string@role-completer # Required. The role assigned to the client. Each role implies a set of permissions granted to the client.
  --seller-visible: oneof<nothing, bool> # Whether the client will be visible to sellers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/clients"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: partnerClientId, var: partner_client_id}, {name: role, var: role}, {name: sellerVisible, var: seller_visible}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, display_name: $display_name, partner_client_id: $partner_client_id, role: $role, seller_visible: $seller_visible
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all deals in a proposal. To retrieve only the finalized revision deals regardless if a deal is being renegotiated, see the FinalizedDeals resource.
#
# GET /v1/{parent}/deals
# Returns: record<deals: table<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record, dealType: string, deliveryControl: record, description: string, displayName: string, estimatedGrossSpend: record, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record, privateAuctionTerms: record, programmaticGuaranteedTerms: record, proposalRevision: string, publisherProfile: string, sellerTimeZone: record, targeting: record, updateTime: string>, nextPageToken: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.deals.list
export def "authorizedbuyersmarketplace-buyers-proposals-deals-list" [
  parent: string
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
  --page-size: int # Requested page size. The server may return fewer results than requested. If requested more than 500, the server will return 500 results per page. If unspecified, the server will pick a default page size of 100.
  --page-token: string # The page token as returned from ListDealsResponse.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/deals"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch updates multiple deals in the same proposal.
#
# POST /v1/{parent}/deals:batchUpdate
# Returns: record<deals: table<billedBuyer: string, buyer: string, client: string, createTime: string, creativeRequirements: record, dealType: string, deliveryControl: record, description: string, displayName: string, estimatedGrossSpend: record, flightEndTime: string, flightStartTime: string, name: string, preferredDealTerms: record, privateAuctionTerms: record, programmaticGuaranteedTerms: record, proposalRevision: string, publisherProfile: string, sellerTimeZone: record, targeting: record, updateTime: string>>
# operationId: authorizedbuyersmarketplace.buyers.proposals.deals.batchUpdate
export def "authorizedbuyersmarketplace-buyers-proposals-deals-batch-update" [
  parent: string
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
  --requests: list # Required. List of request messages to update deals. — item shape: {deal?: record, updateMask?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/deals:batchUpdate"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: requests, var: requests}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, requests: $requests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists finalized deals. Use the URL path "/v1/buyers/{accountId}/finalizedDeals" to list finalized deals for the current buyer and its clients. Bidders can use the URL path "/v1/bidders/{accountId}/finalizedDeals" to list finalized deals for the bidder, its buyers and all their clients.
#
# GET /v1/{parent}/finalizedDeals
# Returns: record<finalizedDeals: table<deal: record, dealPausingInfo: record, dealServingStatus: string, name: string, readyToServe: bool, rtbMetrics: record>, nextPageToken: string>
# operationId: authorizedbuyersmarketplace.buyers.finalizedDeals.list
export def "authorizedbuyersmarketplace-buyers-finalized-deals-list" [
  parent: string
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
  --filter: string # Optional query string using the [Cloud API list filtering syntax](https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters) Supported columns for filtering are: * deal.displayName * deal.dealType * deal.createTime * deal.updateTime * deal.flightStartTime * deal.flightEndTime * dealServingStatus
  --order-by: string # An optional query string to sort finalized deals using the [Cloud API sorting syntax](https://cloud.google.com/apis/design/design_patterns#sorting_order). If no sort order is specified, results will be returned in an arbitrary order. Supported columns for sorting are: * deal.displayName * deal.createTime * deal.updateTime * deal.flightStartTime * deal.flightEndTime * rtbMetrics.bidRequests7Days * rtbMetrics.bids7Days * rtbMetrics.adImpressions7Days * rtbMetrics.bidRate7Days * rtbMetrics.filteredBidRate7Days * rtbMetrics.mustBidRateCurrentMonth Example: 'deal.displayName, deal.updateTime desc'
  --page-size: int # Requested page size. The server may return fewer results than requested. If requested more than 500, the server will return 500 results per page. If unspecified, the server will pick a default page size of 100.
  --page-token: string # The page token as returned from ListFinalizedDealsResponse.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/finalizedDeals"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists proposals. A filter expression (list filter syntax) may be specified to filter the results. This will not list finalized versions of proposals that are being renegotiated; to retrieve these use the finalizedProposals resource.
#
# GET /v1/{parent}/proposals
# Returns: record<nextPageToken: string, proposals: table<billedBuyer: string, buyer: string, buyerContacts: list, buyerPrivateData: record, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: list, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: list, state: string, termsAndConditions: string, updateTime: string>>
# operationId: authorizedbuyersmarketplace.buyers.proposals.list
export def "authorizedbuyersmarketplace-buyers-proposals-list" [
  parent: string
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
  --filter: string # Optional query string using the [Cloud API list filtering syntax](https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters) Supported columns for filtering are: * displayName * dealType * updateTime * state
  --page-size: int # Requested page size. The server may return fewer results than requested. If unspecified, the server will put a size of 500.
  --page-token: string # The page token as returned from ListProposalsResponse.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/proposals"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists publisher profiles. The returned publisher profiles aren't in any defined order. The order of the results might change. A new publisher profile can appear in any place in the list of returned results.
#
# GET /v1/{parent}/publisherProfiles
# Returns: record<nextPageToken: string, publisherProfiles: table<audienceDescription: string, directDealsContact: string, displayName: string, domains: list, isParent: bool, logoUrl: string, mediaKitUrl: string, mobileApps: list, name: string, overview: string, pitchStatement: string, programmaticDealsContact: string, publisherCode: string, samplePageUrl: string, topHeadlines: list>>
# operationId: authorizedbuyersmarketplace.buyers.publisherProfiles.list
export def "authorizedbuyersmarketplace-buyers-publisher-profiles-list" [
  parent: string
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
  --filter: string # Optional query string using the [Cloud API list filtering] (https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters) syntax.
  --page-size: int # Requested page size. The server may return fewer results than requested. If requested more than 500, the server will return 500 results per page. If unspecified, the server will pick a default page size of 100.
  --page-token: string # The page token as returned from a previous ListPublisherProfilesResponse.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/publisherProfiles"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all client users for a specified client.
#
# GET /v1/{parent}/users
# Returns: record<clientUsers: table<email: string, name: string, state: string>, nextPageToken: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.users.list
export def "authorizedbuyersmarketplace-buyers-clients-users-list" [
  parent: string
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
  --page-size: int # Requested page size. If left blank, a default page size of 500 will be applied.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of ListClientUsersResponse.nextPageToken returned from the previous call to the list method.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/users"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new client user in "INVITED" state. An email invitation will be sent to the new user, once accepted the user will become active.
#
# POST /v1/{parent}/users
# Returns: record<email: string, name: string, state: string>
# operationId: authorizedbuyersmarketplace.buyers.clients.users.create
export def "authorizedbuyersmarketplace-buyers-clients-users-create" [
  parent: string
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
  --email: string # Required. The client user's email address that has to be unique across all users for the same client.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/users"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a note for this proposal and sends to the seller.
#
# POST /v1/{proposal}:addNote
# Returns: record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.addNote
export def "authorizedbuyersmarketplace-buyers-proposals-add-note" [
  proposal: string
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
  --note: record # A text note attached to the proposal to facilitate the communication between buyers and sellers. — shape: {note?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{proposal}:addNote"
    path_params: [{name: proposal, var: proposal}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal: $proposal, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an ongoing negotiation on a proposal. This does not cancel or end serving for the deals if the proposal has been finalized. If the proposal has not been finalized before, calling this method will set the Proposal.state to `TERMINATED` and increment the Proposal.proposal_revision. If the proposal has been finalized before and is under renegotiation now, calling this method will reset the Proposal.state to `FINALIZED` and increment the Proposal.proposal_revision. This method does not support private auction proposals whose Proposal.deal_type is 'PRIVATE_AUCTION'.
#
# POST /v1/{proposal}:cancelNegotiation
# Returns: record<billedBuyer: string, buyer: string, buyerContacts: table<displayName: string, email: string>, buyerPrivateData: record<referenceId: string>, client: string, dealType: string, displayName: string, isRenegotiating: bool, lastUpdaterOrCommentorRole: string, name: string, notes: table<createTime: string, creatorRole: string, note: string>, originatorRole: string, pausingConsented: bool, proposalRevision: string, publisherProfile: string, sellerContacts: table<displayName: string, email: string>, state: string, termsAndConditions: string, updateTime: string>
# operationId: authorizedbuyersmarketplace.buyers.proposals.cancelNegotiation
export def "authorizedbuyersmarketplace-buyers-proposals-cancel-negotiation" [
  proposal: string
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{proposal}:cancelNegotiation"
    path_params: [{name: proposal, var: proposal}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    proposal: $proposal, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
