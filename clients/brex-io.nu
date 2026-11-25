# Auto-generated client for KYC API Documentation v2021.12
# Source: https://api.apis.guru/v2/specs/brex.io/2021.12/openapi.json
# Auth: --token flag or $env.KYC_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "https://api.kompany.com"
  token_env_var: "KYC_API_DOCUMENTATION_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: user_key, in: header, header_name: user_key, prefix: ""}
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

def base-url-completer [] { ["https://api.kompany.com"] }
def auth-scheme-completer [] { ["user_key"] }

# Completers for enum parameters
def lang-completer [] { ["" "EN" "OG"] }
def dataset-completer [] { ["" "full" "master" "mini" "refresh"] }
def lang-completer-1 [] { ["" "EN" "ES" "FR"] }
def type-completer [] { ["" "B" "P"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    company-announcement: "table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string>"
    company-deepsearch-isin: "table<isin: string, listings: list<record>, validIsin: bool>"
    company-deepsearch-lei: "record<company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, current_page: int, isins: list<string>, last_page: int, lei: string, next_page: string, total_num_isins: int, validLei: bool>"
    company-deepsearch-name: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-deepsearch-number: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-monitor-change-types-list: "list<string>"
    company-monitor-list: "table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>"
    company-monitor-id: "table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>"
    company-monitor-register: "record<monitorStatus: string, notificationId: string>"
    company-notification-list: "table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>"
    company-notification-id: "table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>"
    company-notification-register: "record<monitorStatus: string, notificationId: string>"
    company-search-name: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-search-number: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-alternative-search: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-id-announcements: "table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string>"
    company-id-super: "table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    company-id-dataset: "record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>"
    ein-verification-basic: "record<confidence_score: string, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, irs_score: string, irs_score_explanation: string, timestamp: float, validationStatus: bool>"
    ein-verification-comprehensive: "record<ein: string, matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, timestamp: float, validationStatus: bool>"
    ein-verification-lookup: "record<matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, searchterm_name: string, searchterm_state: string, searchterm_zip: string, tight_search: bool, timestamp: float>"
    iban-basic: "record<valid: bool>"
    iban-comprehensive: "record<valid: bool>"
    nif-basic: "record<companyName: string, confidenceScore: float, nifNumber: float, validationStatus: bool>"
    nif-comprehensive: "record<activity: record, address: string, capital: float, companyName: string, confidenceScore: float, currency: string, email: string, fax: string, geo: string, legalType: string, nifNumber: float, phone: string, status: record, validationStatus: bool, website: string>"
    pep-monitor-list: "table<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>"
    pep-monitor-unregister: "record<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>"
    pep-monitor-update: "record<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>"
    pep-order: "record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>"
    pep-retrieve: "record<listsChecked: string, results: record<Excerpts: string, ResultsURL: string, SearchType: string, SourceAgency: string, SourceEntity: string, SourceID: int, SourceName: string, SourceType: string>, search: string, status: string, timestamp: string, type: string>"
    product-availability: "record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>"
    product-catalog: "record<countryCode: string, description: string, form: string, method: string, name: string, price: float, sku: string, url: string>"
    product-notifier: "record<callback: string, identity: string, lastCallTime: string, lastResponseCode: int, notifierType: string, productOrderIdentity: string>"
    product-notifier-create: "record<callback: string, identity: string, lastCallTime: string, lastResponseCode: int, notifierType: string, productOrderIdentity: string>"
    product-order-concierge: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    product-order-ubo: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    product-order-with-option: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    product-order: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    product-search: "table<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>"
    product-status: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    product-update-action: "record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>"
    system-countries: "table<country_code: string, country_name: string>"
    health-check: "table<name: string, status: string>"
    system-pricelist: "table<cost_per_unit: string, max: string, metric_id: string, min: string, sku: string>"
    tin-verification-basic-check: "record<matchStatus: string, name: string, possibleMatch: string, tin: string, validationStatus: string>"
    tin-verification-comprehensive-check: "record<einResult: string, matchedCompanies: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, tinResult: string>"
    tin-verification-name-lookup: "record<matchStatus: string, possibleMatch: string, tin: string>"
    vat-basic: "record<candidate: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, confidenceScore: float, validationStatus: bool>"
    vat-comprehensive: "record<candidate: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, confidenceScore: float, validationStatus: bool>"
    vat-level-two: "record<address: string, confirmation: string, level: string, name: string, validationStatus: bool>"
    vat-lookup: "record<matches: table<company: record, vat: string>, searchterm_address: string, searchterm_country: string, searchterm_name: string, timestamp: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["company-announcement" "company-deepsearch-isin" "company-deepsearch-lei" "company-deepsearch-name" "company-deepsearch-number" "company-monitor-change-types-list" "company-monitor-list" "company-monitor-id" "company-monitor-register" "company-monitor-unregister" "company-notification-list" "company-notification-id" "company-notification-register" "company-notification-unregister" "company-search-name" "company-search-number" "company-alternative-search" "company-id-announcements" "company-id-super" "company-id-dataset" "ein-verification-basic" "ein-verification-comprehensive" "ein-verification-lookup" "iban-basic" "iban-comprehensive" "nif-basic" "nif-comprehensive" "pep-monitor-list" "pep-monitor-unregister" "pep-monitor-update" "pep-order" "pep-retrieve" "product-availability" "product-catalog" "product-notifier" "product-notifier-create" "product-order-concierge" "product-order-ubo" "product-order-with-option" "product-order" "product-search" "product-status" "product-update-action" "product-retrieve" "system-countries" "health-check" "system-pricelist" "tin-verification-basic-check" "tin-verification-comprehensive-check" "tin-verification-name-lookup" "vat-basic" "vat-comprehensive" "vat-level-two" "vat-lookup" "commands"] | sort) } | get name | first)
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

# Retrieves announcement data
#
# GET /api/v1/company/announcement/{id}
# Returns: table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string>
# operationId: CompanyAnnouncement
export def "company-announcement" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/announcement/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of stock exchange listings
#
# POST /api/v1/company/deepsearch/isin
# Returns: table<isin: string, listings: list<record>, validIsin: bool>
# operationId: CompanyDeepsearchISIN
export def "company-deepsearch-isin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --isin: string # A list of ISIN numbers seperated by comma (maximum) is 100
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/company/deepsearch/isin"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: isin, var: isin}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    isin: $isin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies
#
# GET /api/v1/company/deepsearch/lei/{number}
# Returns: record<company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, current_page: int, isins: list<string>, last_page: int, lei: string, next_page: string, total_num_isins: int, validLei: bool>
# operationId: CompanyDeepsearchLEI
export def "company-deepsearch-lei" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Pagination for the ISIN number results (1000 numbers per page) (format: int32, e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/deepsearch/lei/{number}"
    path_params: [{name: number, var: number}]
    query: [{name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    number: $number, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/name/{country}/{name}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanyDeepsearchName
export def "company-deepsearch-name" [
  country: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/deepsearch/name/{country}/{name}"
    path_params: [{name: country, var: country}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/number/{country}/{number}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanyDeepsearchNumber
export def "company-deepsearch-number" [
  country: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/deepsearch/number/{country}/{number}"
    path_params: [{name: country, var: country}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get available ChangeTypes
#
# GET /api/v1/company/monitoring/changeTypes
# Returns: list<string>
# operationId: CompanyMonitorChangeTypesList
export def "company-monitor-change-types-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/monitoring/changeTypes"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of registered monitors
#
# GET /api/v1/company/monitoring/list
# Returns: table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>
# operationId: CompanyMonitorList
export def "company-monitor-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/monitoring/list"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get monitor status for specific company id
#
# GET /api/v1/company/monitoring/list/{id}
# Returns: table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>
# operationId: CompanyMonitorId
export def "company-monitor-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/monitoring/list/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a Company for monitoring
#
# POST /api/v1/company/monitoring/register/{id}
# Returns: record<monitorStatus: string, notificationId: string>
# operationId: CompanyMonitorRegister
export def "company-monitor-register" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  callback_url: string # Callback URL
  change_type: string # ChangeType to monitor
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/company/monitoring/register/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: callbackUrl, var: callback_url}, {name: changeType, var: change_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, callback_url: $callback_url, change_type: $change_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivates an active notification
#
# POST /api/v1/company/monitoring/unregister/{id}
# operationId: CompanyMonitorUnregister
export def "company-monitor-unregister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/company/monitoring/unregister/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list
# Returns: table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>
# operationId: CompanyNotificationList
export def "company-notification-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/notification/list"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list/{id}
# Returns: table<callbackCount: int, callbackUrl: string, created: string, monitorStatus: string, notificationId: string, subjectId: string>
# operationId: CompanyNotificationId
export def "company-notification-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/notification/list/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new notification
#
# POST /api/v1/company/notification/register/{id}
# Returns: record<monitorStatus: string, notificationId: string>
# operationId: CompanyNotificationRegister
export def "company-notification-register" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  callback_url: string # Callback URL
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/company/notification/register/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: callbackUrl, var: callback_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, callback_url: $callback_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unregister a company from Monitoring
#
# POST /api/v1/company/notification/unregister/{id}
# operationId: CompanyNotificationUnregister
export def "company-notification-unregister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/company/notification/unregister/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/name/{country}/{name}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanySearchName
export def "company-search-name" [
  country: string
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
  --limit: int # number of search results (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/search/name/{country}/{name}"
    path_params: [{name: country, var: country}, {name: name, var: name}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, name: $name, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/number/{country}/{number}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanySearchNumber
export def "company-search-number" [
  country: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # number of search results (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/search/number/{country}/{number}"
    path_params: [{name: country, var: country}, {name: number, var: number}]
    query: [{name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, number: $number, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of companies from the KYC API company index
#
# POST /api/v1/company/search/{country}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanyAlternativeSearch
export def "company-alternative-search" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Company address (or address partial)
  --name: string # Company name
  --number: string # Company registration number
  --phone: string # Company contact phone number
  --url: string # Company url
  --vat: string # Company VAT number
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/company/search/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: address, var: address}, {name: name, var: name}, {name: number, var: number}, {name: phone, var: phone}, {name: url, var: url}, {name: vat, var: vat}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, address: $address, name: $name, number: $number, phone: $phone, url: $url, vat: $vat
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves company announcements
#
# GET /api/v1/company/{id}/announcements
# Returns: table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string>
# operationId: CompanyIdAnnouncements
export def "company-id-announcements" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # limit of announcements in response (default 10) (format: int32)
  --offset: int # to paginate through results (default 0) (format: int32)
  --data: oneof<nothing, bool> # If this parameter is set to false, you will only receive ids, and no additional data about announcements and no hits to the metric will be counted. (and potentially minimizing your costs) (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/{id}/announcements"
    path_params: [{name: id, var: id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: data, var: data}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves structured data extracted from a company document
#
# GET /api/v1/company/{id}/super/{country}
# Returns: table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanyIdSuper
export def "company-id-super" [
  id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/{id}/super/{country}"
    path_params: [{name: id, var: id}, {name: country, var: country}]
    query: [{name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, country: $country, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves company details
#
# GET /api/v1/company/{id}/{dataset}
# Returns: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>
# operationId: CompanyIdDataset
export def "company-id-dataset" [
  id: string
  dataset: string@dataset-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-stock-listing: oneof<nothing, bool> # Try to retrieve additional stock information for this company. (Only available on refresh)
  --lang: string@lang-completer-1 # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/company/{id}/{dataset}"
    path_params: [{name: id, var: id}, {name: dataset, var: dataset}]
    query: [{name: check_stock_listing, var: check_stock_listing}, {name: lang, var: lang}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, dataset: $dataset, check_stock_listing: $check_stock_listing, lang: $lang
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies an EIN number
#
# GET /api/v1/ein-verification/basic-check
# Returns: record<confidence_score: string, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, irs_score: string, irs_score_explanation: string, timestamp: float, validationStatus: bool>
# operationId: EinVerificationBasic
export def "ein-verification-basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ein: string # Nine letter EIN number with or without hyphens (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/ein-verification/basic-check"
    query: [{name: ein, var: ein, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    ein: $ein
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies EIN number and retrieves company data
#
# GET /api/v1/ein-verification/comprehensive-check
# Returns: record<ein: string, matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, timestamp: float, validationStatus: bool>
# operationId: EinVerificationComprehensive
export def "ein-verification-comprehensive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ein: string # Nine letter EIN number with or without hyphens (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/ein-verification/comprehensive-check"
    query: [{name: ein, var: ein, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    ein: $ein
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of EIN numbers
#
# GET /api/v1/ein-verification/lookup
# Returns: record<matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, searchterm_name: string, searchterm_state: string, searchterm_zip: string, tight_search: bool, timestamp: float>
# operationId: EinVerificationLookup
export def "ein-verification-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Business name of the company (required, format: string)
  --state: string # Optional state parameter to improve results. (Two letter code for example CA or US-CA for California) (format: string)
  --zip: string # Optional zip code parameter to improve results. (Zip is preferred over state) (format: string)
  --tight: oneof<nothing, bool> # Optional parameter to do tight matching. (Only the best match will be returned rather then the top 5)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/ein-verification/lookup"
    query: [{name: name, var: name, required: true}, {name: state, var: state}, {name: zip, var: zip}, {name: tight, var: tight}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    name: $name, state: $state, zip: $zip, tight: $tight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/check-iban
# Returns: record<valid: bool>
# operationId: IbanBasic
export def "iban-basic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iban_number: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/iban-verification/check-iban"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ibanNumber, var: iban_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    iban_number: $iban_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/comprehensive-check-iban
# Returns: record<valid: bool>
# operationId: IbanComprehensive
export def "iban-comprehensive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iban_number: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/iban-verification/comprehensive-check-iban"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ibanNumber, var: iban_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    iban_number: $iban_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies a NIF number
#
# POST /api/v1/nif-verification/basic-check/{country}
# Returns: record<companyName: string, confidenceScore: float, nifNumber: float, validationStatus: bool>
# operationId: NifBasic
export def "nif-basic" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  nif_number: string # NIF number to validate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/nif-verification/basic-check/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companyAddress, var: company_address}, {name: companyName, var: company_name}, {name: nifNumber, var: nif_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, company_address: $company_address, company_name: $company_name, nif_number: $nif_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies a NIF number and retrieves company data
#
# POST /api/v1/nif-verification/comprehensive-check/{country}
# Returns: record<activity: record, address: string, capital: float, companyName: string, confidenceScore: float, currency: string, email: string, fax: string, geo: string, legalType: string, nifNumber: float, phone: string, status: record, validationStatus: bool, website: string>
# operationId: NifComprehensive
export def "nif-comprehensive" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  nif_number: string # NIF number to validate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/nif-verification/comprehensive-check/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companyAddress, var: company_address}, {name: companyName, var: company_name}, {name: nifNumber, var: nif_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, company_address: $company_address, company_name: $company_name, nif_number: $nif_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of monitor entries
#
# GET /api/v1/pepsanction/monitor/list
# Returns: table<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>
# operationId: PepMonitorList
export def "pep-monitor-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/pepsanction/monitor/list"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactive a pep sanction monitor
#
# POST /api/v1/pepsanction/monitor/unregister/{id}
# Returns: record<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>
# operationId: PepMonitorUnregister
export def "pep-monitor-unregister" [
  id: string
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
    path: "/api/v1/pepsanction/monitor/unregister/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details of active Pep Sanction monitor
#
# POST /api/v1/pepsanction/monitor/update/{id}
# Returns: record<active: bool, caseId: string, created: string, identifier: string, structured: string, updated: string, webhook: string>
# operationId: PepMonitorUpdate
export def "pep-monitor-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/pepsanction/monitor/update/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Webhook, var: webhook}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Orders a new Pep Sanction Check Report
#
# POST /api/v1/pepsanction/order/{type}/{search}
# Returns: record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>
# operationId: PepOrder
export def "pep-order" [
  type: string@type-completer
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: string # Optional parameter for declaring alias names when doing a person search (seperated by commas) (e.g. null)
  --country: string # Optional name of Country to assist in identifying matches based upon location/geography. (e.g. null)
  --dob: string # Optional parameter for date of birth name when doing a person search (e.g. null)
  --family-name: string # Optional parameter for last name when doing a person search (e.g. null)
  --filters: string # Optional parameter for restricting search when doing a person search (seperated by commas) (e.g. null)
  --given-name: string # Optional parameter for first name when doing a person search (e.g. null)
  --lei: string # Optional Legal Entity Identifier for additional business identifier verification. (e.g. null)
  --locale: string # Optional name of City or Locale to assist in identifying matches based upon location/geography. (e.g. null)
  --medialists: string # Optional parameter for selecting only specific media lists. By default all lists are queried (e.g. NMEDIA)
  --middle-name: string # Optional parameter for middle name when doing a person search (e.g. null)
  --monitoring: oneof<nothing, bool> # If this Pep Sanction Check should be continuesly monitored. (e.g. false)
  --peplists: string # Optional parameter for selecting only specific pep lists. By default all lists are queried (e.g. GOV,PEPD,SOE)
  --region: string # Optional name of Region or State to assist in identifying matches based upon location/geography. (e.g. null)
  --smart-match: oneof<nothing, bool> # Optional parameter for enabling SmartMatch to retrieve more results (e.g. false)
  --watchlists: string # Optional parameter for selecting only specific watch lists. By default all lists are queried (e.g. SANCTIONS,FINANCE,TERRORISM,CRIME,SMAGOV,OFAC,MEDICAL)
  --webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/pepsanction/order/{type}/{search}"
    path_params: [{name: type, var: type}, {name: search, var: search}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: Aliases, var: aliases}, {name: Country, var: country}, {name: DOB, var: dob}, {name: FamilyName, var: family_name}, {name: Filters, var: filters}, {name: GivenName, var: given_name}, {name: LEI, var: lei}, {name: Locale, var: locale}, {name: Medialists, var: medialists}, {name: MiddleName, var: middle_name}, {name: Monitoring, var: monitoring}, {name: Peplists, var: peplists}, {name: Region, var: region}, {name: SmartMatch, var: smart_match}, {name: Watchlists, var: watchlists}, {name: Webhook, var: webhook}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    type: $type, search: $search, aliases: $aliases, country: $country, dob: $dob, family_name: $family_name, filters: $filters, given_name: $given_name, lei: $lei, locale: $locale, medialists: $medialists, middle_name: $middle_name, monitoring: $monitoring, peplists: $peplists, region: $region, smart_match: $smart_match, watchlists: $watchlists, webhook: $webhook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a json or pdf report
#
# GET /api/v1/pepsanction/retrieve/{id}
# Returns: record<listsChecked: string, results: record<Excerpts: string, ResultsURL: string, SearchType: string, SourceAgency: string, SourceEntity: string, SourceID: int, SourceName: string, SourceType: string>, search: string, status: string, timestamp: string, type: string>
# operationId: PepRetrieve
export def "pep-retrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string@accept-completer # The type (pdf or json) in which the check should be returned (format: string, default: application/json) (spec name: accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/pepsanction/retrieve/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: accept, var: hdr_accept}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    id: $id, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a document availability result
#
# GET /api/v1/product/availability/{sku}/{subjectId}
# Returns: record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>
# operationId: ProductAvailability
export def "product-availability" [
  sku: string
  subject_id: string
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
    path: "/api/v1/product/availability/{sku}/{subjectId}"
    path_params: [{name: sku, var: sku}, {name: subjectId, var: subject_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    sku: $sku, subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a catalog of products
#
# GET /api/v1/product/catalog/{country}
# Returns: record<countryCode: string, description: string, form: string, method: string, name: string, price: float, sku: string, url: string>
# operationId: ProductCatalog
export def "product-catalog" [
  country: string
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
    path: "/api/v1/product/catalog/{country}"
    path_params: [{name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata for a notifier
#
# GET /api/v1/product/notifier/{notifierId}
# Returns: record<callback: string, identity: string, lastCallTime: string, lastResponseCode: int, notifierType: string, productOrderIdentity: string>
# operationId: ProductNotifier
export def "product-notifier" [
  notifier_id: string
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
    path: "/api/v1/product/notifier/{notifierId}"
    path_params: [{name: notifierId, var: notifier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    notifier_id: $notifier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a notifier for an order
#
# POST /api/v1/product/notifier/{orderId}/{type}/{uri}
# Returns: record<callback: string, identity: string, lastCallTime: string, lastResponseCode: int, notifierType: string, productOrderIdentity: string>
# operationId: ProductNotifierCreate
export def "product-notifier-create" [
  order_id: string
  type: string
  uri: string
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
    path: "/api/v1/product/notifier/{orderId}/{type}/{uri}"
    path_params: [{name: orderId, var: order_id}, {name: type, var: type}, {name: uri, var: uri}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    order_id: $order_id, type: $type, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places a concierge order
#
# POST /api/v1/product/order/concierge
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductOrderConcierge
export def "product-order-concierge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-name: string # Name of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --contact-email: string # Contact E-Mail, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --contact-phone: string # Contact phone, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --cost-confirmation: oneof<nothing, bool> # If the concierge cost should require additional confirmation if a threshold is reached (configured on your plan) (e.g. false)
  --country: string # Two letter ISO code of the country of the company (e.g. null)
  --financial-data: oneof<nothing, bool> # If you want financial data of the company to be retrieved (e.g. false)
  --historic-information: oneof<nothing, bool> # If you want historical data of the company to be retrieved (e.g. false)
  --information-requirements: string # Requirements on what document or information should be provided. Please be very precise (e.g. null)
  --location-investigation: oneof<nothing, bool> # If the companies residency should be investigated (e.g. false)
  --priority: string # Priority of order: standard/express are allowed (e.g. standard)
  --register-data: oneof<nothing, bool> # If you want register data of the company to be retrieved (e.g. false)
  --register-number: string # Registration number of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --subject-id: string # Kompanyid of the company you want to place the order for (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/product/order/concierge"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companyName, var: company_name}, {name: contactEmail, var: contact_email}, {name: contactPhone, var: contact_phone}, {name: costConfirmation, var: cost_confirmation}, {name: country, var: country}, {name: financialData, var: financial_data}, {name: historicInformation, var: historic_information}, {name: informationRequirements, var: information_requirements}, {name: locationInvestigation, var: location_investigation}, {name: priority, var: priority}, {name: registerData, var: register_data}, {name: registerNumber, var: register_number}, {name: subjectId, var: subject_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    company_name: $company_name, contact_email: $contact_email, contact_phone: $contact_phone, cost_confirmation: $cost_confirmation, country: $country, financial_data: $financial_data, historic_information: $historic_information, information_requirements: $information_requirements, location_investigation: $location_investigation, priority: $priority, register_data: $register_data, register_number: $register_number, subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places a UBO order
#
# POST /api/v1/product/order/ubo
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductOrderUbo
export def "product-order-ubo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # An optional callback URL to which updates about the order will be sent (for instance if credits are exceeded) (e.g. null)
  --credits: float # Specify a maximum amount of credits which should be used. To disable use -1 (e.g. -1)
  --include-docs: oneof<nothing, bool> # Include purchase of register document to ubo report (e.g. false)
  --levels: string # Define a threshold for different levels of crawling (e.g. 25,50)
  --strategy: string # Choose a matching strategy. Available options (FULL,LEVELS) (e.g. FULL)
  subject_id: string # KYC API Id (32 byte hexid) of the company you want to place the order for (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/product/order/ubo"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: callbackUrl, var: callback_url}, {name: credits, var: credits}, {name: includeDocs, var: include_docs}, {name: levels, var: levels}, {name: strategy, var: strategy}, {name: subjectId, var: subject_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    callback_url: $callback_url, credits: $credits, include_docs: $include_docs, levels: $levels, strategy: $strategy, subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{option}/{subjectId}
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductOrderWithOption
export def "product-order-with-option" [
  sku: string
  option: string
  subject_id: string
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
    path: "/api/v1/product/order/{sku}/{option}/{subjectId}"
    path_params: [{name: sku, var: sku}, {name: option, var: option}, {name: subjectId, var: subject_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    sku: $sku, option: $option, subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{subjectId}
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductOrder
export def "product-order" [
  sku: string
  subject_id: string
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
    path: "/api/v1/product/order/{sku}/{subjectId}"
    path_params: [{name: sku, var: sku}, {name: subjectId, var: subject_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    sku: $sku, subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of products
#
# GET /api/v1/product/search/{subjectId}
# Returns: table<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string>
# operationId: ProductSearch
export def "product-search" [
  subject_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/product/search/{subjectId}"
    path_params: [{name: subjectId, var: subject_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    subject_id: $subject_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns metadata for a order
#
# GET /api/v1/product/status/{orderId}
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductStatus
export def "product-status" [
  order_id: string
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
    path: "/api/v1/product/status/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates metadata of an order
#
# POST /api/v1/product/update/{action}/{orderId}
# Returns: record<identity: string, option: string, ordered: string, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string>
# operationId: ProductUpdateAction
export def "product-update-action" [
  action: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: float # Specify an amount of credits which should be added to the order (e.g. 100)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/product/update/{action}/{orderId}"
    path_params: [{name: action, var: action}, {name: orderId, var: order_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: credits, var: credits}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    action: $action, order_id: $order_id, credits: $credits
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the result of an order
#
# GET /api/v1/product/{orderId}
# operationId: ProductRetrieve
export def "product-retrieve" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/product/{orderId}"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of countries
#
# GET /api/v1/system/countries
# Returns: table<country_code: string, country_name: string>
# operationId: SystemCountries
export def "system-countries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/system/countries"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the health information for the official business registers based on usage.
#
# GET /api/v1/system/health
# Returns: table<name: string, status: string>
# operationId: HealthCheck
export def "health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/system/health"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of products with prices
#
# GET /api/v1/system/pricelist
# Returns: table<cost_per_unit: string, max: string, metric_id: string, min: string, sku: string>
# operationId: SystemPricelist
export def "system-pricelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/system/pricelist"
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies a TIN number
#
# GET /api/v1/tin-verification/basic-check
# Returns: record<matchStatus: string, name: string, possibleMatch: string, tin: string, validationStatus: string>
# operationId: TinVerificationBasicCheck
export def "tin-verification-basic-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (required, format: string)
  --name: string # Company Name (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tin-verification/basic-check"
    query: [{name: tin, var: tin, required: true}, {name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    tin: $tin, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EIN Name Lookup with TIN number and retrieves company data
#
# GET /api/v1/tin-verification/comprehensive-check
# Returns: record<einResult: string, matchedCompanies: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, tinResult: string>
# operationId: TinVerificationComprehensiveCheck
export def "tin-verification-comprehensive-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (required, format: string)
  --name: string # Company Name (required, format: string)
  --threshold: int # The percentage of minimum similarity threshold for company matching (optional, default: 70%) (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tin-verification/comprehensive-check"
    query: [{name: tin, var: tin, required: true}, {name: name, var: name, required: true}, {name: threshold, var: threshold}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    tin: $tin, name: $name, threshold: $threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EIN Name Lookup with TIN number
#
# GET /api/v1/tin-verification/name-lookup
# Returns: record<matchStatus: string, possibleMatch: string, tin: string>
# operationId: TinVerificationNameLookup
export def "tin-verification-name-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tin: string # Nine letter TIN number with or without hyphens (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/tin-verification/name-lookup"
    query: [{name: tin, var: tin, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    tin: $tin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a verification result
#
# POST /api/v1/vat-verification/basic-check/{country}
# Returns: record<candidate: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, confidenceScore: float, validationStatus: bool>
# operationId: VatBasic
export def "vat-basic" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  --company-number: string # official company number
  vat_number: string # VAT number to validate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/vat-verification/basic-check/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companyAddress, var: company_address}, {name: companyName, var: company_name}, {name: companyNumber, var: company_number}, {name: vatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, company_address: $company_address, company_name: $company_name, company_number: $company_number, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a verification result and company data
#
# POST /api/v1/vat-verification/comprehensive-check/{country}
# Returns: record<candidate: table<address: list, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list, id: string, legalForm: string, managingDirectors: list, name: string, registrationNumber: string, requestTime: int, secretaries: list, sicNaceCodes: list, status: string>, company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, confidenceScore: float, validationStatus: bool>
# operationId: VatComprehensive
export def "vat-comprehensive" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-address: string # company address lines
  --company-name: string # Company name
  --company-number: string # official company number
  vat_number: string # VAT number to validate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/vat-verification/comprehensive-check/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: companyAddress, var: company_address}, {name: companyName, var: company_name}, {name: companyNumber, var: company_number}, {name: vatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, company_address: $company_address, company_name: $company_name, company_number: $company_number, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a level two verification result
#
# POST /api/v1/vat-verification/leveltwo-check/{country}
# Returns: record<address: string, confirmation: string, level: string, name: string, validationStatus: bool>
# operationId: VatLevelTwo
export def "vat-level-two" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmation: oneof<nothing, bool> # If a confirmation document should be ordered
  vat_number: string # VAT number to validate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/vat-verification/leveltwo-check/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: confirmation, var: confirmation}, {name: vatNumber, var: vat_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, confirmation: $confirmation, vat_number: $vat_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of vat numbers with additional data
#
# POST /api/v1/vat-verification/lookup/{country}
# Returns: record<matches: table<company: record, vat: string>, searchterm_address: string, searchterm_country: string, searchterm_name: string, timestamp: int>
# operationId: VatLookup
export def "vat-lookup" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Company address (e.g. null)
  name: string # Company name (e.g. null)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/vat-verification/lookup/{country}"
    path_params: [{name: country, var: country}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: address, var: address}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: user_key
  } {
    country: $country, address: $address, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
