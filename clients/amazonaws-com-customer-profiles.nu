# Auto-generated client for Amazon Connect Customer Profiles v2020-08-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/customer-profiles/2020-08-15/openapi.json
# Auth: --token flag or $env.AMAZON_CONNECT_CUSTOMER_PROFILES_TOKEN

const CLIENT = {
  base_url: "http://profile.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_CONNECT_CUSTOMER_PROFILES_TOKEN"
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

def base-url-completer [] { ["http://profile.us-east-1.amazonaws.com" "http://profile.us-east-2.amazonaws.com" "http://profile.us-west-1.amazonaws.com" "http://profile.us-west-2.amazonaws.com" "http://profile.us-gov-west-1.amazonaws.com" "http://profile.us-gov-east-1.amazonaws.com" "http://profile.ca-central-1.amazonaws.com" "http://profile.eu-north-1.amazonaws.com" "http://profile.eu-west-1.amazonaws.com" "http://profile.eu-west-2.amazonaws.com" "http://profile.eu-west-3.amazonaws.com" "http://profile.eu-central-1.amazonaws.com" "http://profile.eu-south-1.amazonaws.com" "http://profile.af-south-1.amazonaws.com" "http://profile.ap-northeast-1.amazonaws.com" "http://profile.ap-northeast-2.amazonaws.com" "http://profile.ap-northeast-3.amazonaws.com" "http://profile.ap-southeast-1.amazonaws.com" "http://profile.ap-southeast-2.amazonaws.com" "http://profile.ap-east-1.amazonaws.com" "http://profile.ap-south-1.amazonaws.com" "http://profile.sa-east-1.amazonaws.com" "http://profile.me-south-1.amazonaws.com" "https://profile.us-east-1.amazonaws.com" "https://profile.us-east-2.amazonaws.com" "https://profile.us-west-1.amazonaws.com" "https://profile.us-west-2.amazonaws.com" "https://profile.us-gov-west-1.amazonaws.com" "https://profile.us-gov-east-1.amazonaws.com" "https://profile.ca-central-1.amazonaws.com" "https://profile.eu-north-1.amazonaws.com" "https://profile.eu-west-1.amazonaws.com" "https://profile.eu-west-2.amazonaws.com" "https://profile.eu-west-3.amazonaws.com" "https://profile.eu-central-1.amazonaws.com" "https://profile.eu-south-1.amazonaws.com" "https://profile.af-south-1.amazonaws.com" "https://profile.ap-northeast-1.amazonaws.com" "https://profile.ap-northeast-2.amazonaws.com" "https://profile.ap-northeast-3.amazonaws.com" "https://profile.ap-southeast-1.amazonaws.com" "https://profile.ap-southeast-2.amazonaws.com" "https://profile.ap-east-1.amazonaws.com" "https://profile.ap-south-1.amazonaws.com" "https://profile.sa-east-1.amazonaws.com" "https://profile.me-south-1.amazonaws.com" "http://profile.cn-north-1.amazonaws.com.cn" "http://profile.cn-northwest-1.amazonaws.com.cn" "https://profile.cn-north-1.amazonaws.com.cn" "https://profile.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def workflow-type-completer [] { ["APPFLOW_INTEGRATION"] }
def party-type-completer [] { ["BUSINESS" "INDIVIDUAL" "OTHER"] }
def gender-completer [] { ["FEMALE" "MALE" "UNSPECIFIED"] }
def status-completer [] { ["CANCELLED" "COMPLETE" "FAILED" "IN_PROGRESS" "NOT_STARTED" "RETRY" "SPLIT"] }
def logical-operator-completer [] { ["AND" "OR"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-profile-key: "record<KeyName: string, Values: list<string>>"
    create-domain: "record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>"
    delete-domain: "record<Message: string>"
    get-domain: "record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Stats: record<ProfileCount: int, MeteringProfileCount: int, ObjectCount: int, TotalSize: int>, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>"
    update-domain: "record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>"
    create-integration-workflow: "record<WorkflowId: string, Message: string>"
    create-profile: "record<ProfileId: string>"
    update-profile: "record<ProfileId: string>"
    delete-integration: "record<Message: string>"
    delete-profile: "record<Message: string>"
    delete-profile-key: "record<Message: string>"
    delete-profile-object: "record<Message: string>"
    delete-profile-object-type: "record<Message: string>"
    get-profile-object-type: "record<ObjectTypeName: string, Description: string, TemplateId: string, ExpirationDays: int, EncryptionKey: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record, CreatedAt: string, LastUpdatedAt: string, Tags: record>"
    put-profile-object-type: "record<ObjectTypeName: string, Description: string, TemplateId: string, ExpirationDays: int, EncryptionKey: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record, CreatedAt: string, LastUpdatedAt: string, Tags: record>"
    delete-workflow: "record"
    get-workflow: "record<WorkflowId: string, WorkflowType: string, Status: string, ErrorDescription: string, StartDate: string, LastUpdatedAt: string, Attributes: record<AppflowIntegration: record<SourceConnectorType: string, ConnectorProfileName: string, RoleArn: string>>, Metrics: record<AppflowIntegration: record<RecordsProcessed: int, StepsCompleted: int, TotalSteps: int>>>"
    get-auto-merging-preview: "record<DomainName: string, NumberOfMatchesInSample: int, NumberOfProfilesInSample: int, NumberOfProfilesWillBeMerged: int>"
    get-identity-resolution-job: "record<DomainName: string, JobId: string, Status: string, Message: string, JobStartTime: string, JobEndTime: string, LastUpdatedAt: string, JobExpirationTime: string, AutoMerging: record<Enabled: bool, Consolidation: record<MatchingAttributesList: list>, ConflictResolution: record<ConflictResolvingModel: string, SourceName: string>, MinAllowedConfidenceScoreForMerging: float>, ExportingLocation: record<S3Exporting: record<S3BucketName: string, S3KeyName: string>>, JobStats: record<NumberOfProfilesReviewed: int, NumberOfMatchesFound: int, NumberOfMergesDone: int>>"
    get-integration: "record<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>"
    list-integrations: "record<Items: table<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>, NextToken: string>"
    put-integration: "record<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>"
    get-matches: "record<NextToken: string, MatchGenerationDate: string, PotentialMatches: int, Matches: table<MatchId: string, ProfileIds: list, ConfidenceScore: float>>"
    get-profile-object-type-template: "record<TemplateId: string, SourceName: string, SourceObject: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record>"
    get-workflow-steps: "record<WorkflowId: string, WorkflowType: string, Items: table<AppflowIntegration: record>, NextToken: string>"
    list-account-integrations: "record<Items: table<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>, NextToken: string>"
    list-domains: "record<Items: table<DomainName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record>, NextToken: string>"
    list-identity-resolution-jobs: "record<IdentityResolutionJobsList: table<DomainName: string, JobId: string, Status: string, JobStartTime: string, JobEndTime: string, JobStats: record, ExportingLocation: record, Message: string>, NextToken: string>"
    list-profile-object-type-templates: "record<Items: table<TemplateId: string, SourceName: string, SourceObject: string>, NextToken: string>"
    list-profile-object-types: "record<Items: table<ObjectTypeName: string, Description: string, CreatedAt: string, LastUpdatedAt: string, Tags: record>, NextToken: string>"
    list-profile-objects: "record<Items: table<ObjectTypeName: string, ProfileObjectUniqueKey: string, Object: string>, NextToken: string>"
    put-profile-object: "record<ProfileObjectUniqueKey: string>"
    list-tags-for-resource: "record<tags: record>"
    tag-resource: "record"
    list-workflows: "record<Items: table<WorkflowType: string, WorkflowId: string, Status: string, StatusDescription: string, CreatedAt: string, LastUpdatedAt: string>, NextToken: string>"
    merge-profiles: "record<Message: string>"
    search-profiles: "record<Items: table<ProfileId: string, AccountNumber: string, AdditionalInformation: string, PartyType: string, BusinessName: string, FirstName: string, MiddleName: string, LastName: string, BirthDate: string, Gender: string, PhoneNumber: string, MobilePhoneNumber: string, HomePhoneNumber: string, BusinessPhoneNumber: string, EmailAddress: string, PersonalEmailAddress: string, BusinessEmailAddress: string, Address: record, ShippingAddress: record, MailingAddress: record, BillingAddress: record, Attributes: record, FoundByItems: list, PartyTypeString: string, GenderString: string>, NextToken: string>"
    untag-resource: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-profile-key" "create-domain" "delete-domain" "get-domain" "update-domain" "create-integration-workflow" "create-profile" "update-profile" "delete-integration" "delete-profile" "delete-profile-key" "delete-profile-object" "delete-profile-object-type" "get-profile-object-type" "put-profile-object-type" "delete-workflow" "get-workflow" "get-auto-merging-preview" "get-identity-resolution-job" "get-integration" "list-integrations" "put-integration" "get-matches" "get-profile-object-type-template" "get-workflow-steps" "list-account-integrations" "list-domains" "list-identity-resolution-jobs" "list-profile-object-type-templates" "list-profile-object-types" "list-profile-objects" "put-profile-object" "list-tags-for-resource" "tag-resource" "list-workflows" "merge-profiles" "search-profiles" "untag-resource" "commands"] | sort) } | get name | first)
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

# Associates a new key value with a specific profile, such as a Contact Record ContactId. A profile object can have a single unique key and any number of additional keys that can be used to identify the profile that it belongs to.
#
# POST /domains/{DomainName}/profiles/keys
# Returns: record<KeyName: string, Values: list<string>>
# operationId: AddProfileKey
export def "add-profile-key" [
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
  profile_id: string # The unique identifier of a customer profile.
  key_name: string # A searchable identifier of a customer profile. The predefined keys you can use include: _account, _profileId, _assetId, _caseId, _orderId, _fullName, _phone, _email, _ctrContactId, _marketoLeadId, _salesforceAccountId, _salesforceContactId, _salesforceAssetId, _zendeskUserId, _zendeskExternalId, _zendeskTicketId, _serviceNowSystemId, _serviceNowIncidentId, _segmentUserId, _shopifyCustomerId, _shopifyOrderId.
  values: list<string> # A list of key values.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/keys"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProfileId, var: profile_id}, {name: KeyName, var: key_name}, {name: Values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, profile_id: $profile_id, key_name: $key_name, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a domain, which is a container for all customer data, such as customer profile attributes, object types, profile keys, and encryption keys. You can create multiple domains, and each domain can have multiple third-party integrations. Each Amazon Connect instance can be associated with only one domain. Multiple Amazon Connect instances can be associated with one domain. Use this API or UpdateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UpdateDomain.html) to enable identity resolution (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html): set Matching to true. To prevent cross-service impersonation when you call this API, see Cross-service confused deputy prevention (https://docs.aws.amazon.com/connect/latest/adminguide/cross-service-confused-deputy-prevention.html) for sample policies that you should apply.
#
# POST /domains/{DomainName}
# Returns: record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>
# operationId: CreateDomain
export def "create-domain" [
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
  default_expiration_days: int # The default number of days until the data within the domain expires.
  --default-encryption-key: string # The default encryption key, which is an AWS managed key, is used when no specific type of encryption key is specified. It is used to encrypt all data before it is placed in permanent or semi-permanent storage.
  --dead-letter-queue-url: string # The URL of the SQS dead letter queue, which is used for reporting errors associated with ingesting data from third party applications. You must set up a policy on the DeadLetterQueue for the SendMessage operation to enable Amazon Connect Customer Profiles to send messages to the DeadLetterQueue.
  --matching: record # The flag that enables the matching process of duplicate profiles. — shape: {Enabled?: bool, JobSchedule?: record, AutoMerging?: record, ExportingConfig?: record}
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DefaultExpirationDays, var: default_expiration_days}, {name: DefaultEncryptionKey, var: default_encryption_key}, {name: DeadLetterQueueUrl, var: dead_letter_queue_url}, {name: Matching, var: matching}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, default_expiration_days: $default_expiration_days, default_encryption_key: $default_encryption_key, dead_letter_queue_url: $dead_letter_queue_url, matching: $matching, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a specific domain and all of its customer data, such as customer profile attributes and their related objects.
#
# DELETE /domains/{DomainName}
# Returns: record<Message: string>
# operationId: DeleteDomain
export def "delete-domain" [
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
    path: "/domains/{DomainName}"
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

# Returns information about a specific domain.
#
# GET /domains/{DomainName}
# Returns: record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Stats: record<ProfileCount: int, MeteringProfileCount: int, ObjectCount: int, TotalSize: int>, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>
# operationId: GetDomain
export def "get-domain" [
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
    path: "/domains/{DomainName}"
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

# Updates the properties of a domain, including creating or selecting a dead letter queue or an encryption key. After a domain is created, the name can’t be changed. Use this API or CreateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_CreateDomain.html) to enable identity resolution (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html): set Matching to true. To prevent cross-service impersonation when you call this API, see Cross-service confused deputy prevention (https://docs.aws.amazon.com/connect/latest/adminguide/cross-service-confused-deputy-prevention.html) for sample policies that you should apply. To add or remove tags on an existing Domain, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}
# Returns: record<DomainName: string, DefaultExpirationDays: int, DefaultEncryptionKey: string, DeadLetterQueueUrl: string, Matching: record<Enabled: bool, JobSchedule: record<DayOfTheWeek: string, Time: string>, AutoMerging: record<Enabled: bool, Consolidation: record, ConflictResolution: record, MinAllowedConfidenceScoreForMerging: float>, ExportingConfig: record<S3Exporting: record>>, CreatedAt: string, LastUpdatedAt: string, Tags: record>
# operationId: UpdateDomain
export def "update-domain" [
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
  --default-expiration-days: int # The default number of days until the data within the domain expires.
  --default-encryption-key: string # The default encryption key, which is an AWS managed key, is used when no specific type of encryption key is specified. It is used to encrypt all data before it is placed in permanent or semi-permanent storage. If specified as an empty string, it will clear any existing value.
  --dead-letter-queue-url: string # The URL of the SQS dead letter queue, which is used for reporting errors associated with ingesting data from third party applications. If specified as an empty string, it will clear any existing value. You must set up a policy on the DeadLetterQueue for the SendMessage operation to enable Amazon Connect Customer Profiles to send messages to the DeadLetterQueue.
  --matching: record # The flag that enables the matching process of duplicate profiles. — shape: {Enabled?: bool, JobSchedule?: record, AutoMerging?: record, ExportingConfig?: record}
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{DomainName}"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DefaultExpirationDays, var: default_expiration_days}, {name: DefaultEncryptionKey, var: default_encryption_key}, {name: DeadLetterQueueUrl, var: dead_letter_queue_url}, {name: Matching, var: matching}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, default_expiration_days: $default_expiration_days, default_encryption_key: $default_encryption_key, dead_letter_queue_url: $dead_letter_queue_url, matching: $matching, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an integration workflow. An integration workflow is an async process which ingests historic data and sets up an integration for ongoing updates. The supported Amazon AppFlow sources are Salesforce, ServiceNow, and Marketo.
#
# POST /domains/{DomainName}/workflows/integrations
# Returns: record<WorkflowId: string, Message: string>
# operationId: CreateIntegrationWorkflow
export def "create-integration-workflow" [
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
  workflow_type: string@workflow-type-completer # The type of workflow. The only supported value is APPFLOW_INTEGRATION.
  integration_config: record # Configuration data for integration workflow. — shape: {AppflowIntegration?: record}
  object_type_name: string # The name of the profile object type.
  role_arn: string # The Amazon Resource Name (ARN) of the IAM role. Customer Profiles assumes this role to create resources on your behalf as part of workflow execution.
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/workflows/integrations"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkflowType, var: workflow_type}, {name: IntegrationConfig, var: integration_config}, {name: ObjectTypeName, var: object_type_name}, {name: RoleArn, var: role_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workflow_type: $workflow_type, integration_config: $integration_config, object_type_name: $object_type_name, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a standard profile. A standard profile represents the following attributes for a customer profile in a domain.
#
# POST /domains/{DomainName}/profiles
# Returns: record<ProfileId: string>
# operationId: CreateProfile
@deprecated --flag party-type
@deprecated --flag gender
export def "create-profile" [
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
  --account-number: string # A unique account number that you have given to the customer.
  --additional-information: string # Any additional information relevant to the customer’s profile.
  --party-type: string@party-type-completer # The type of profile used to describe the customer. (DEPRECATED)
  --business-name: string # The name of the customer’s business.
  --first-name: string # The customer’s first name.
  --middle-name: string # The customer’s middle name.
  --last-name: string # The customer’s last name.
  --birth-date: string # The customer’s birth date.
  --gender: string@gender-completer # The gender with which the customer identifies. (DEPRECATED)
  --phone-number: string # The customer’s phone number, which has not been specified as a mobile, home, or business number.
  --mobile-phone-number: string # The customer’s mobile phone number.
  --home-phone-number: string # The customer’s home phone number.
  --business-phone-number: string # The customer’s business phone number.
  --email-address: string # The customer’s email address, which has not been specified as a personal or business address.
  --personal-email-address: string # The customer’s personal email address.
  --business-email-address: string # The customer’s business email address.
  --address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --shipping-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --mailing-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --billing-address: record # A generic address associated with the customer that is not mailing, shipping, or billing. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --attributes: record # A key value pair of attributes of a customer profile.
  --party-type-string: string # An alternative to PartyType which accepts any string as input.
  --gender-string: string # An alternative to Gender which accepts any string as input.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountNumber, var: account_number}, {name: AdditionalInformation, var: additional_information}, {name: PartyType, var: party_type}, {name: BusinessName, var: business_name}, {name: FirstName, var: first_name}, {name: MiddleName, var: middle_name}, {name: LastName, var: last_name}, {name: BirthDate, var: birth_date}, {name: Gender, var: gender}, {name: PhoneNumber, var: phone_number}, {name: MobilePhoneNumber, var: mobile_phone_number}, {name: HomePhoneNumber, var: home_phone_number}, {name: BusinessPhoneNumber, var: business_phone_number}, {name: EmailAddress, var: email_address}, {name: PersonalEmailAddress, var: personal_email_address}, {name: BusinessEmailAddress, var: business_email_address}, {name: Address, var: address}, {name: ShippingAddress, var: shipping_address}, {name: MailingAddress, var: mailing_address}, {name: BillingAddress, var: billing_address}, {name: Attributes, var: attributes}, {name: PartyTypeString, var: party_type_string}, {name: GenderString, var: gender_string}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account_number: $account_number, additional_information: $additional_information, party_type: $party_type, business_name: $business_name, first_name: $first_name, middle_name: $middle_name, last_name: $last_name, birth_date: $birth_date, gender: $gender, phone_number: $phone_number, mobile_phone_number: $mobile_phone_number, home_phone_number: $home_phone_number, business_phone_number: $business_phone_number, email_address: $email_address, personal_email_address: $personal_email_address, business_email_address: $business_email_address, address: $address, shipping_address: $shipping_address, mailing_address: $mailing_address, billing_address: $billing_address, attributes: $attributes, party_type_string: $party_type_string, gender_string: $gender_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the properties of a profile. The ProfileId is required for updating a customer profile. When calling the UpdateProfile API, specifying an empty string value means that any existing value will be removed. Not specifying a string value means that any value already there will be kept.
#
# PUT /domains/{DomainName}/profiles
# Returns: record<ProfileId: string>
# operationId: UpdateProfile
@deprecated --flag party-type
@deprecated --flag gender
export def "update-profile" [
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
  profile_id: string # The unique identifier of a customer profile.
  --additional-information: string # Any additional information relevant to the customer’s profile.
  --account-number: string # A unique account number that you have given to the customer.
  --party-type: string@party-type-completer # The type of profile used to describe the customer. (DEPRECATED)
  --business-name: string # The name of the customer’s business.
  --first-name: string # The customer’s first name.
  --middle-name: string # The customer’s middle name.
  --last-name: string # The customer’s last name.
  --birth-date: string # The customer’s birth date.
  --gender: string@gender-completer # The gender with which the customer identifies. (DEPRECATED)
  --phone-number: string # The customer’s phone number, which has not been specified as a mobile, home, or business number.
  --mobile-phone-number: string # The customer’s mobile phone number.
  --home-phone-number: string # The customer’s home phone number.
  --business-phone-number: string # The customer’s business phone number.
  --email-address: string # The customer’s email address, which has not been specified as a personal or business address.
  --personal-email-address: string # The customer’s personal email address.
  --business-email-address: string # The customer’s business email address.
  --address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --shipping-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --mailing-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --billing-address: record # Updates associated with the address properties of a customer profile. — shape: {Address1?: string, Address2?: string, Address3?: string, Address4?: string, City?: string, County?: string, State?: string, Province?: string, Country?: string, PostalCode?: string}
  --attributes: record # A key value pair of attributes of a customer profile.
  --party-type-string: string # An alternative to PartyType which accepts any string as input.
  --gender-string: string # An alternative to Gender which accepts any string as input.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{DomainName}/profiles"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProfileId, var: profile_id}, {name: AdditionalInformation, var: additional_information}, {name: AccountNumber, var: account_number}, {name: PartyType, var: party_type}, {name: BusinessName, var: business_name}, {name: FirstName, var: first_name}, {name: MiddleName, var: middle_name}, {name: LastName, var: last_name}, {name: BirthDate, var: birth_date}, {name: Gender, var: gender}, {name: PhoneNumber, var: phone_number}, {name: MobilePhoneNumber, var: mobile_phone_number}, {name: HomePhoneNumber, var: home_phone_number}, {name: BusinessPhoneNumber, var: business_phone_number}, {name: EmailAddress, var: email_address}, {name: PersonalEmailAddress, var: personal_email_address}, {name: BusinessEmailAddress, var: business_email_address}, {name: Address, var: address}, {name: ShippingAddress, var: shipping_address}, {name: MailingAddress, var: mailing_address}, {name: BillingAddress, var: billing_address}, {name: Attributes, var: attributes}, {name: PartyTypeString, var: party_type_string}, {name: GenderString, var: gender_string}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, profile_id: $profile_id, additional_information: $additional_information, account_number: $account_number, party_type: $party_type, business_name: $business_name, first_name: $first_name, middle_name: $middle_name, last_name: $last_name, birth_date: $birth_date, gender: $gender, phone_number: $phone_number, mobile_phone_number: $mobile_phone_number, home_phone_number: $home_phone_number, business_phone_number: $business_phone_number, email_address: $email_address, personal_email_address: $personal_email_address, business_email_address: $business_email_address, address: $address, shipping_address: $shipping_address, mailing_address: $mailing_address, billing_address: $billing_address, attributes: $attributes, party_type_string: $party_type_string, gender_string: $gender_string
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an integration from a specific domain.
#
# POST /domains/{DomainName}/integrations/delete
# Returns: record<Message: string>
# operationId: DeleteIntegration
export def "delete-integration" [
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
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/integrations/delete"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the standard customer profile and all data pertaining to the profile.
#
# POST /domains/{DomainName}/profiles/delete
# Returns: record<Message: string>
# operationId: DeleteProfile
export def "delete-profile" [
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
  profile_id: string # The unique identifier of a customer profile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/delete"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProfileId, var: profile_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, profile_id: $profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a searchable key from a customer profile.
#
# POST /domains/{DomainName}/profiles/keys/delete
# Returns: record<Message: string>
# operationId: DeleteProfileKey
export def "delete-profile-key" [
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
  profile_id: string # The unique identifier of a customer profile.
  key_name: string # A searchable identifier of a customer profile.
  values: list<string> # A list of key values.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/keys/delete"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProfileId, var: profile_id}, {name: KeyName, var: key_name}, {name: Values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, profile_id: $profile_id, key_name: $key_name, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an object associated with a profile of a given ProfileObjectType.
#
# POST /domains/{DomainName}/profiles/objects/delete
# Returns: record<Message: string>
# operationId: DeleteProfileObject
export def "delete-profile-object" [
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
  profile_id: string # The unique identifier of a customer profile.
  profile_object_unique_key: string # The unique identifier of the profile object generated by the service.
  object_type_name: string # The name of the profile object type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/objects/delete"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProfileId, var: profile_id}, {name: ProfileObjectUniqueKey, var: profile_object_unique_key}, {name: ObjectTypeName, var: object_type_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, profile_id: $profile_id, profile_object_unique_key: $profile_object_unique_key, object_type_name: $object_type_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a ProfileObjectType from a specific domain as well as removes all the ProfileObjects of that type. It also disables integrations from this specific ProfileObjectType. In addition, it scrubs all of the fields of the standard profile that were populated from this ProfileObjectType.
#
# DELETE /domains/{DomainName}/object-types/{ObjectTypeName}
# Returns: record<Message: string>
# operationId: DeleteProfileObjectType
export def "delete-profile-object-type" [
  domain_name: string
  object_type_name: string
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
    path: "/domains/{DomainName}/object-types/{ObjectTypeName}"
    path_params: [{name: DomainName, var: domain_name}, {name: ObjectTypeName, var: object_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, object_type_name: $object_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the object types for a specific domain.
#
# GET /domains/{DomainName}/object-types/{ObjectTypeName}
# Returns: record<ObjectTypeName: string, Description: string, TemplateId: string, ExpirationDays: int, EncryptionKey: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record, CreatedAt: string, LastUpdatedAt: string, Tags: record>
# operationId: GetProfileObjectType
export def "get-profile-object-type" [
  domain_name: string
  object_type_name: string
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
    path: "/domains/{DomainName}/object-types/{ObjectTypeName}"
    path_params: [{name: DomainName, var: domain_name}, {name: ObjectTypeName, var: object_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, object_type_name: $object_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defines a ProfileObjectType. To add or remove tags on an existing ObjectType, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}/object-types/{ObjectTypeName}
# Returns: record<ObjectTypeName: string, Description: string, TemplateId: string, ExpirationDays: int, EncryptionKey: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record, CreatedAt: string, LastUpdatedAt: string, Tags: record>
# operationId: PutProfileObjectType
export def "put-profile-object-type" [
  domain_name: string
  object_type_name: string
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
  description: string # Description of the profile object type.
  --template-id: string # A unique identifier for the object template. For some attributes in the request, the service will use the default value from the object template when TemplateId is present. If these attributes are present in the request, the service may return a BadRequestException. These attributes include: AllowProfileCreation, SourceLastUpdatedTimestampFormat, Fields, and Keys. For example, if AllowProfileCreation is set to true when TemplateId is set, the service may return a BadRequestException.
  --expiration-days: int # The number of days until the data in the object expires.
  --encryption-key: string # The customer-provided key to encrypt the profile object that will be created in this profile object type.
  --allow-profile-creation: oneof<nothing, bool> # Indicates whether a profile should be created when data is received if one doesn’t exist for an object of this type. The default is FALSE. If the AllowProfileCreation flag is set to FALSE, then the service tries to fetch a standard profile and associate this object with the profile. If it is set to TRUE, and if no match is found, then the service creates a new standard profile.
  --source-last-updated-timestamp-format: string # The format of your sourceLastUpdatedTimestamp that was previously set up.
  --fields: record # A map of the name and ObjectType field.
  --keys: record # A list of unique keys that can be used to map data to the profile.
  --tags: record # The tags used to organize, track, or control access for this resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{DomainName}/object-types/{ObjectTypeName}"
    path_params: [{name: DomainName, var: domain_name}, {name: ObjectTypeName, var: object_type_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: TemplateId, var: template_id}, {name: ExpirationDays, var: expiration_days}, {name: EncryptionKey, var: encryption_key}, {name: AllowProfileCreation, var: allow_profile_creation}, {name: SourceLastUpdatedTimestampFormat, var: source_last_updated_timestamp_format}, {name: Fields, var: fields}, {name: Keys, var: keys}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, object_type_name: $object_type_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, template_id: $template_id, expiration_days: $expiration_days, encryption_key: $encryption_key, allow_profile_creation: $allow_profile_creation, source_last_updated_timestamp_format: $source_last_updated_timestamp_format, fields: $fields, keys: $keys, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified workflow and all its corresponding resources. This is an async process.
#
# DELETE /domains/{DomainName}/workflows/{WorkflowId}
# Returns: record
# operationId: DeleteWorkflow
export def "delete-workflow" [
  domain_name: string
  workflow_id: string
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
    path: "/domains/{DomainName}/workflows/{WorkflowId}"
    path_params: [{name: DomainName, var: domain_name}, {name: WorkflowId, var: workflow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, workflow_id: $workflow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of specified workflow.
#
# GET /domains/{DomainName}/workflows/{WorkflowId}
# Returns: record<WorkflowId: string, WorkflowType: string, Status: string, ErrorDescription: string, StartDate: string, LastUpdatedAt: string, Attributes: record<AppflowIntegration: record<SourceConnectorType: string, ConnectorProfileName: string, RoleArn: string>>, Metrics: record<AppflowIntegration: record<RecordsProcessed: int, StepsCompleted: int, TotalSteps: int>>>
# operationId: GetWorkflow
export def "get-workflow" [
  domain_name: string
  workflow_id: string
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
    path: "/domains/{DomainName}/workflows/{WorkflowId}"
    path_params: [{name: DomainName, var: domain_name}, {name: WorkflowId, var: workflow_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, workflow_id: $workflow_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests the auto-merging settings of your Identity Resolution Job without merging your data. It randomly selects a sample of matching groups from the existing matching results, and applies the automerging settings that you provided. You can then view the number of profiles in the sample, the number of matches, and the number of profiles identified to be merged. This enables you to evaluate the accuracy of the attributes in your matching list. You can't view which profiles are matched and would be merged. We strongly recommend you use this API to do a dry run of the automerging process before running the Identity Resolution Job. Include at least two matching attributes. If your matching list includes too few attributes (such as only FirstName or only LastName), there may be a large number of matches. This increases the chances of erroneous merges.
#
# POST /domains/{DomainName}/identity-resolution-jobs/auto-merging-preview
# Returns: record<DomainName: string, NumberOfMatchesInSample: int, NumberOfProfilesInSample: int, NumberOfProfilesWillBeMerged: int>
# operationId: GetAutoMergingPreview
export def "get-auto-merging-preview" [
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
  consolidation: record # The matching criteria to be used during the auto-merging process. — shape: {MatchingAttributesList?: list}
  conflict_resolution: record # How the auto-merging process should resolve conflicts between different profiles. — shape: {ConflictResolvingModel?: "RECENCY"|"SOURCE", SourceName?: string}
  --min-allowed-confidence-score-for-merging: float # Minimum confidence score required for profiles within a matching group to be merged during the auto-merge process. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/identity-resolution-jobs/auto-merging-preview"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Consolidation, var: consolidation}, {name: ConflictResolution, var: conflict_resolution}, {name: MinAllowedConfidenceScoreForMerging, var: min_allowed_confidence_score_for_merging}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, consolidation: $consolidation, conflict_resolution: $conflict_resolution, min_allowed_confidence_score_for_merging: $min_allowed_confidence_score_for_merging
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about an Identity Resolution Job in a specific domain. Identity Resolution Jobs are set up using the Amazon Connect admin console. For more information, see Use Identity Resolution to consolidate similar profiles (https://docs.aws.amazon.com/connect/latest/adminguide/use-identity-resolution.html).
#
# GET /domains/{DomainName}/identity-resolution-jobs/{JobId}
# Returns: record<DomainName: string, JobId: string, Status: string, Message: string, JobStartTime: string, JobEndTime: string, LastUpdatedAt: string, JobExpirationTime: string, AutoMerging: record<Enabled: bool, Consolidation: record<MatchingAttributesList: list>, ConflictResolution: record<ConflictResolvingModel: string, SourceName: string>, MinAllowedConfidenceScoreForMerging: float>, ExportingLocation: record<S3Exporting: record<S3BucketName: string, S3KeyName: string>>, JobStats: record<NumberOfProfilesReviewed: int, NumberOfMatchesFound: int, NumberOfMergesDone: int>>
# operationId: GetIdentityResolutionJob
export def "get-identity-resolution-job" [
  domain_name: string
  job_id: string
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
    path: "/domains/{DomainName}/identity-resolution-jobs/{JobId}"
    path_params: [{name: DomainName, var: domain_name}, {name: JobId, var: job_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, job_id: $job_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an integration for a domain.
#
# POST /domains/{DomainName}/integrations
# Returns: record<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>
# operationId: GetIntegration
export def "get-integration" [
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
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/integrations"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the integrations in your domain.
#
# GET /domains/{DomainName}/integrations
# Returns: record<Items: table<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>, NextToken: string>
# operationId: ListIntegrations
export def "list-integrations" [
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
  --next-token: string # The pagination token from the previous ListIntegrations API call.
  --max-results: int # The maximum number of objects returned per page.
  --include-hidden: oneof<nothing, bool> # Boolean to indicate if hidden integration should be returned. Defaults to False.
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
    path: "/domains/{DomainName}/integrations"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: include-hidden, var: include_hidden}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, include_hidden: $include_hidden, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an integration between the service and a third-party service, which includes Amazon AppFlow and Amazon Connect. An integration can belong to only one domain. To add or remove tags on an existing Integration, see TagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_TagResource.html)/ UntagResource (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UntagResource.html).
#
# PUT /domains/{DomainName}/integrations
# Returns: record<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>
# operationId: PutIntegration
export def "put-integration" [
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
  --uri: string # The URI of the S3 bucket or any other type of data source.
  --object-type-name: string # The name of the profile object type.
  --tags: record # The tags used to organize, track, or control access for this resource.
  --flow-definition: record # The configurations that control how Customer Profiles retrieves data from the source, Amazon AppFlow. Customer Profiles uses this information to create an AppFlow flow on behalf of customers. — shape: {Description?: string, FlowName?: string, KmsArn?: string, SourceFlowConfig?: record, Tasks?: list, TriggerConfig?: record}
  --object-type-names: record # A map in which each key is an event type from an external application such as Segment or Shopify, and each value is an ObjectTypeName (template) used to ingest the event. It supports the following event types: SegmentIdentify, ShopifyCreateCustomers, ShopifyUpdateCustomers, ShopifyCreateDraftOrders, ShopifyUpdateDraftOrders, ShopifyCreateOrders, and ShopifyUpdatedOrders.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{DomainName}/integrations"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Uri, var: uri}, {name: ObjectTypeName, var: object_type_name}, {name: Tags, var: tags}, {name: FlowDefinition, var: flow_definition}, {name: ObjectTypeNames, var: object_type_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, uri: $uri, object_type_name: $object_type_name, tags: $tags, flow_definition: $flow_definition, object_type_names: $object_type_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Before calling this API, use CreateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_CreateDomain.html) or UpdateDomain (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_UpdateDomain.html) to enable identity resolution: set Matching to true. GetMatches returns potentially matching profiles, based on the results of the latest run of a machine learning process. The process of matching duplicate profiles. If Matching = true, Amazon Connect Customer Profiles starts a weekly batch process called Identity Resolution Job. If you do not specify a date and time for Identity Resolution Job to run, by default it runs every Saturday at 12AM UTC to detect duplicate profiles in your domains. After the Identity Resolution Job completes, use the GetMatches (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html) API to return and review the results. Or, if you have configured ExportingConfig in the MatchingRequest, you can download the results from S3. Amazon Connect uses the following profile attributes to identify matches: PhoneNumber HomePhoneNumber BusinessPhoneNumber MobilePhoneNumber EmailAddress PersonalEmailAddress BusinessEmailAddress FullName For example, two or more profiles—with spelling mistakes such as John Doe and Jhn Doe, or different casing email addresses such as JOHN_DOE@ANYCOMPANY.COM and johndoe@anycompany.com, or different phone number formats such as 555-010-0000 and +1-555-010-0000—can be detected as belonging to the same customer John Doe and merged into a unified profile.
#
# GET /domains/{DomainName}/matches
# Returns: record<NextToken: string, MatchGenerationDate: string, PotentialMatches: int, Matches: table<MatchId: string, ProfileIds: list, ConfidenceScore: float>>
# operationId: GetMatches
export def "get-matches" [
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
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
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
    path: "/domains/{DomainName}/matches"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the template information for a specific object type. A template is a predefined ProfileObjectType, such as “Salesforce-Account” or “Salesforce-Contact.” When a user sends a ProfileObject, using the PutProfileObject API, with an ObjectTypeName that matches one of the TemplateIds, it uses the mappings from the template.
#
# GET /templates/{TemplateId}
# Returns: record<TemplateId: string, SourceName: string, SourceObject: string, AllowProfileCreation: bool, SourceLastUpdatedTimestampFormat: string, Fields: record, Keys: record>
# operationId: GetProfileObjectTypeTemplate
export def "get-profile-object-type-template" [
  template_id: string
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
    path: "/templates/{TemplateId}"
    path_params: [{name: TemplateId, var: template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get granular list of steps in workflow.
#
# GET /domains/{DomainName}/workflows/{WorkflowId}/steps
# Returns: record<WorkflowId: string, WorkflowType: string, Items: table<AppflowIntegration: record>, NextToken: string>
# operationId: GetWorkflowSteps
export def "get-workflow-steps" [
  domain_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
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
    path: "/domains/{DomainName}/workflows/{WorkflowId}/steps"
    path_params: [{name: DomainName, var: domain_name}, {name: WorkflowId, var: workflow_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, workflow_id: $workflow_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the integrations associated to a specific URI in the AWS account.
#
# POST /integrations
# Returns: record<Items: table<DomainName: string, Uri: string, ObjectTypeName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record, ObjectTypeNames: record, WorkflowId: string, IsUnstructured: bool>, NextToken: string>
# operationId: ListAccountIntegrations
export def "list-account-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListAccountIntegrations API call.
  --max-results: int # The maximum number of objects returned per page.
  --include-hidden: oneof<nothing, bool> # Boolean to indicate if hidden integration should be returned. Defaults to False.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  uri: string # The URI of the S3 bucket or any other type of data source.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/integrations"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: include-hidden, var: include_hidden}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, include_hidden: $include_hidden, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all the domains for an AWS account that have been created.
#
# GET /domains
# Returns: record<Items: table<DomainName: string, CreatedAt: string, LastUpdatedAt: string, Tags: record>, NextToken: string>
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
  --next-token: string # The pagination token from the previous ListDomain API call.
  --max-results: int # The maximum number of objects returned per page.
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
    path: "/domains"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the Identity Resolution Jobs in your domain. The response sorts the list by JobStartTime.
#
# GET /domains/{DomainName}/identity-resolution-jobs
# Returns: record<IdentityResolutionJobsList: table<DomainName: string, JobId: string, Status: string, JobStartTime: string, JobEndTime: string, JobStats: record, ExportingLocation: record, Message: string>, NextToken: string>
# operationId: ListIdentityResolutionJobs
export def "list-identity-resolution-jobs" [
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
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
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
    path: "/domains/{DomainName}/identity-resolution-jobs"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the template information for object types.
#
# GET /templates
# Returns: record<Items: table<TemplateId: string, SourceName: string, SourceObject: string>, NextToken: string>
# operationId: ListProfileObjectTypeTemplates
export def "list-profile-object-type-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The pagination token from the previous ListObjectTypeTemplates API call.
  --max-results: int # The maximum number of objects returned per page.
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
    path: "/templates"
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the templates available within the service.
#
# GET /domains/{DomainName}/object-types
# Returns: record<Items: table<ObjectTypeName: string, Description: string, CreatedAt: string, LastUpdatedAt: string, Tags: record>, NextToken: string>
# operationId: ListProfileObjectTypes
export def "list-profile-object-types" [
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
  --next-token: string # Identifies the next page of results to return.
  --max-results: int # The maximum number of objects returned per page.
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
    path: "/domains/{DomainName}/object-types"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of objects associated with a profile of a given ProfileObjectType.
#
# POST /domains/{DomainName}/profiles/objects
# Returns: record<Items: table<ObjectTypeName: string, ProfileObjectUniqueKey: string, Object: string>, NextToken: string>
# operationId: ListProfileObjects
export def "list-profile-objects" [
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
  --next-token: string # The pagination token from the previous call to ListProfileObjects.
  --max-results: int # The maximum number of objects returned per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  object_type_name: string # The name of the profile object type.
  profile_id: string # The unique identifier of a customer profile.
  --object-filter: record # The filter applied to ListProfileObjects response to include profile objects with the specified index values. This filter is only supported for ObjectTypeName _asset, _case and _order. — shape: {KeyName?: string, Values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/objects"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectTypeName, var: object_type_name}, {name: ProfileId, var: profile_id}, {name: ObjectFilter, var: object_filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, object_type_name: $object_type_name, profile_id: $profile_id, object_filter: $object_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds additional objects to customer profiles of a given ObjectType. When adding a specific profile object, like a Contact Record, an inferred profile can get created if it is not mapped to an existing profile. The resulting profile will only have a phone number populated in the standard ProfileObject. Any additional Contact Records with the same phone number will be mapped to the same inferred profile. When a ProfileObject is created and if a ProfileObjectType already exists for the ProfileObject, it will provide data to a standard profile depending on the ProfileObjectType definition. PutProfileObject needs an ObjectType, which can be created using PutProfileObjectType.
#
# PUT /domains/{DomainName}/profiles/objects
# Returns: record<ProfileObjectUniqueKey: string>
# operationId: PutProfileObject
export def "put-profile-object" [
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
  object_type_name: string # The name of the profile object type.
  object: string # A string that is serialized from a JSON object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/domains/{DomainName}/profiles/objects"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ObjectTypeName, var: object_type_name}, {name: Object, var: object}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, object_type_name: $object_type_name, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Displays the tags associated with an Amazon Connect Customer Profiles resource. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged.
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

# Assigns one or more tags (key-value pairs) to the specified Amazon Connect Customer Profiles resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged. Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters. You can use the TagResource action with a resource that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate as many as 50 tags with a resource.
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
  tags: record # The tags used to organize, track, or control access for this resource.
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

# Query to list all workflows.
#
# POST /domains/{DomainName}/workflows
# Returns: record<Items: table<WorkflowType: string, WorkflowId: string, Status: string, StatusDescription: string, CreatedAt: string, LastUpdatedAt: string>, NextToken: string>
# operationId: ListWorkflows
export def "list-workflows" [
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
  --next-token: string # The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  --max-results: int # The maximum number of results to return per page.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --workflow-type: string@workflow-type-completer # The type of workflow. The only supported value is APPFLOW_INTEGRATION.
  --status: string@status-completer # Status of workflow execution.
  --query-start-date: string # Retrieve workflows started after timestamp. (format: date-time)
  --query-end-date: string # Retrieve workflows ended after timestamp. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/workflows"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkflowType, var: workflow_type}, {name: Status, var: status}, {name: QueryStartDate, var: query_start_date}, {name: QueryEndDate, var: query_end_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workflow_type: $workflow_type, status: $status, query_start_date: $query_start_date, query_end_date: $query_end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs an AWS Lambda job that does the following: All the profileKeys in the ProfileToBeMerged will be moved to the main profile. All the objects in the ProfileToBeMerged will be moved to the main profile. All the ProfileToBeMerged will be deleted at the end. All the profileKeys in the ProfileIdsToBeMerged will be moved to the main profile. Standard fields are merged as follows: Fields are always "union"-ed if there are no conflicts in standard fields or attributeKeys. When there are conflicting fields: If no SourceProfileIds entry is specified, the main Profile value is always taken. If a SourceProfileIds entry is specified, the specified profileId is always taken, even if it is a NULL value. You can use MergeProfiles together with GetMatches (https://docs.aws.amazon.com/customerprofiles/latest/APIReference/API_GetMatches.html), which returns potentially matching profiles, or use it with the results of another matching system. After profiles have been merged, they cannot be separated (unmerged).
#
# POST /domains/{DomainName}/profiles/objects/merge
# Returns: record<Message: string>
# operationId: MergeProfiles
export def "merge-profiles" [
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
  main_profile_id: string # The identifier of the profile to be taken.
  profile_ids_to_be_merged: list<string> # The identifier of the profile to be merged into MainProfileId.
  --field-source-profile-ids: record # A duplicate customer profile that is to be merged into a main profile. — shape: {AccountNumber?: string, AdditionalInformation?: string, PartyType?: string, BusinessName?: string, FirstName?: string, MiddleName?: string, LastName?: string, BirthDate?: string, Gender?: string, PhoneNumber?: string, MobilePhoneNumber?: string, HomePhoneNumber?: string, BusinessPhoneNumber?: string, EmailAddress?: string, PersonalEmailAddress?: string, BusinessEmailAddress?: string, Address?: string, ShippingAddress?: string, MailingAddress?: string, BillingAddress?: string, Attributes?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/objects/merge"
    path_params: [{name: DomainName, var: domain_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MainProfileId, var: main_profile_id}, {name: ProfileIdsToBeMerged, var: profile_ids_to_be_merged}, {name: FieldSourceProfileIds, var: field_source_profile_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, main_profile_id: $main_profile_id, profile_ids_to_be_merged: $profile_ids_to_be_merged, field_source_profile_ids: $field_source_profile_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for profiles within a specific domain using one or more predefined search keys (e.g., _fullName, _phone, _email, _account, etc.) and/or custom-defined search keys. A search key is a data type pair that consists of a KeyName and Values list. This operation supports searching for profiles with a minimum of 1 key-value(s) pair and up to 5 key-value(s) pairs using either AND or OR logic.
#
# POST /domains/{DomainName}/profiles/search
# Returns: record<Items: table<ProfileId: string, AccountNumber: string, AdditionalInformation: string, PartyType: string, BusinessName: string, FirstName: string, MiddleName: string, LastName: string, BirthDate: string, Gender: string, PhoneNumber: string, MobilePhoneNumber: string, HomePhoneNumber: string, BusinessPhoneNumber: string, EmailAddress: string, PersonalEmailAddress: string, BusinessEmailAddress: string, Address: record, ShippingAddress: record, MailingAddress: record, BillingAddress: record, Attributes: record, FoundByItems: list, PartyTypeString: string, GenderString: string>, NextToken: string>
# operationId: SearchProfiles
export def "search-profiles" [
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
  --next-token: string # The pagination token from the previous SearchProfiles API call.
  --max-results: int # The maximum number of objects returned per page. The default is 20 if this parameter is not included in the request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  key_name: string # A searchable identifier of a customer profile. The predefined keys you can use to search include: _account, _profileId, _assetId, _caseId, _orderId, _fullName, _phone, _email, _ctrContactId, _marketoLeadId, _salesforceAccountId, _salesforceContactId, _salesforceAssetId, _zendeskUserId, _zendeskExternalId, _zendeskTicketId, _serviceNowSystemId, _serviceNowIncidentId, _segmentUserId, _shopifyCustomerId, _shopifyOrderId.
  values: list<string> # A list of key values.
  --additional-search-keys: list # A list of AdditionalSearchKey objects that are each searchable identifiers of a profile. Each AdditionalSearchKey object contains a KeyName and a list of Values associated with that specific key (i.e., a key-value(s) pair). These additional search keys will be used in conjunction with the LogicalOperator and the required KeyName and Values parameters to search for profiles that satisfy the search criteria. — item shape: {KeyName: string, Values: list<string>}
  --logical-operator: string@logical-operator-completer # Relationship between all specified search keys that will be used to search for profiles. This includes the required KeyName and Values parameters as well as any key-value(s) pairs specified in the AdditionalSearchKeys list. This parameter influences which profiles will be returned in the response in the following manner: AND - The response only includes profiles that match all of the search keys. OR - The response includes profiles that match at least one of the search keys. The OR relationship is the default behavior if this parameter is not included in the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/domains/{DomainName}/profiles/search"
    path_params: [{name: DomainName, var: domain_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: KeyName, var: key_name}, {name: Values, var: values}, {name: AdditionalSearchKeys, var: additional_search_keys}, {name: LogicalOperator, var: logical_operator}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, key_name: $key_name, values: $values, additional_search_keys: $additional_search_keys, logical_operator: $logical_operator
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more tags from the specified Amazon Connect Customer Profiles resource. In Connect Customer Profiles, domains, profile object types, and integrations can be tagged.
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
  --tag-keys: list<string> # The list of tag keys to remove from the resource. (required)
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
