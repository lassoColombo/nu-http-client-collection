# Auto-generated client for Account API v6
# Source: https://api.apis.guru/v2/specs/adyen.com/AccountService/6/openapi.json
# Auth: --token flag or $env.ACCOUNT_API_TOKEN

const CLIENT = {
  base_url: "https://cal-test.adyen.com/cal/services/Account/v6"
  token_env_var: "ACCOUNT_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://cal-test.adyen.com/cal/services/Account/v6"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def account-state-type-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }
def payout-schedule-completer [] { ["BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT" "DAILY" "DAILY_AU" "DAILY_EU" "DAILY_SG" "DAILY_US" "HOLD" "MONTHLY" "WEEKLY" "WEEKLY_MON_TO_FRI_AU" "WEEKLY_MON_TO_FRI_EU" "WEEKLY_MON_TO_FRI_US" "WEEKLY_ON_TUE_FRI_MIDNIGHT" "WEEKLY_SUN_TO_THU_AU" "WEEKLY_SUN_TO_THU_US"] }
def payout-speed-completer [] { ["INSTANT" "SAME_DAY" "STANDARD"] }
def legal-entity-completer [] { ["Business" "Individual" "NonProfit" "Partnership" "PublicCompany"] }
def state-type-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-check-account-holder: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-close-account: "record<accountCode: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string, status: string>"
    post-close-account-holder: "record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-close-stores: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-create-account: "record<accountCode: string, accountHolderCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string, status: string>"
    post-create-account-holder: "record<accountCode: string, accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>"
    post-delete-bank-accounts: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-delete-legal-arrangements: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-delete-payout-methods: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-delete-shareholders: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-delete-signatories: "record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-get-account-holder: "record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, accounts: table<accountCode: string, bankAccountUUID: string, beneficiaryAccount: string, beneficiaryMerchantReference: string, description: string, metadata: record, payoutMethodCode: string, payoutSchedule: record, payoutSpeed: string, status: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, migrationData: record<accountHolderId: string, balancePlatform: string, migrated: bool, migratedAccounts: list<record>, migratedStores: list<record>, migrationDate: string>, primaryCurrency: string, pspReference: string, resultCode: string, systemUpToDateTime: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>"
    post-get-tax-form: "record<content: string, contentType: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-get-uploaded-documents: "record<documentDetails: table<accountHolderCode: string, bankAccountUUID: string, description: string, documentType: string, filename: string, legalArrangementCode: string, legalArrangementEntityCode: string, shareholderCode: string, signatoryCode: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-suspend-account-holder: "record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-un-suspend-account-holder: "record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-update-account: "record<accountCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string>"
    post-update-account-holder: "record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>"
    post-update-account-holder-state: "record<accountHolderCode: string, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>"
    post-upload-document: "record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-check-account-holder" "post-close-account" "post-close-account-holder" "post-close-stores" "post-create-account" "post-create-account-holder" "post-delete-bank-accounts" "post-delete-legal-arrangements" "post-delete-payout-methods" "post-delete-shareholders" "post-delete-signatories" "post-get-account-holder" "post-get-tax-form" "post-get-uploaded-documents" "post-suspend-account-holder" "post-un-suspend-account-holder" "post-update-account" "post-update-account-holder" "post-update-account-holder-state" "post-upload-document" "commands"] | sort) } | get name | first)
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

# Trigger verification
#
# POST /checkAccountHolder
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-checkAccountHolder
export def "post-check-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to verify.
  account_state_type: string@account-state-type-completer # The state required for the account holder. > Permitted values: `Processing`, `Payout`.
  tier: int # The tier required for the account holder. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/checkAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: accountStateType, var: account_state_type}, {name: tier, var: tier}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, account_state_type: $account_state_type, tier: $tier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close an account
#
# POST /closeAccount
# Returns: record<accountCode: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string, status: string>
# operationId: post-closeAccount
export def "post-close-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of account to be closed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/closeAccount"
    body: {content_type: "application/json", kind: json, fields: [{name: accountCode, var: account_code}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_code: $account_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close an account holder
#
# POST /closeAccountHolder
# Returns: record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-closeAccountHolder
export def "post-close-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder to be closed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/closeAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close stores
#
# POST /closeStores
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-closeStores
export def "post-close-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder.
  stores: list<string> # List of stores to be closed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/closeStores"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: stores, var: stores}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_code: $account_holder_code, stores: $stores
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an account
#
# POST /createAccount
# Returns: record<accountCode: string, accountHolderCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string, status: string>
# operationId: post-createAccount
export def "post-create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of Account Holder under which to create the account.
  --bank-account-uuid: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payout-method-code: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payout-schedule: string@payout-schedule-completer # The payout schedule of the prospective account. >Permitted values: `DEFAULT`, `HOLD`, `DAILY`, `WEEKLY`, `MONTHLY`.
  --payout-schedule-reason: string # The reason for the payout schedule choice. >Required if the payoutSchedule is `HOLD`.
  --payout-speed: string@payout-speed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`. (default: STANDARD)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createAccount"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: bankAccountUUID, var: bank_account_uuid}, {name: description, var: description}, {name: metadata, var: metadata}, {name: payoutMethodCode, var: payout_method_code}, {name: payoutSchedule, var: payout_schedule}, {name: payoutScheduleReason, var: payout_schedule_reason}, {name: payoutSpeed, var: payout_speed}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, bank_account_uuid: $bank_account_uuid, description: $description, metadata: $metadata, payout_method_code: $payout_method_code, payout_schedule: $payout_schedule, payout_schedule_reason: $payout_schedule_reason, payout_speed: $payout_speed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an account holder
#
# POST /createAccountHolder
# Returns: record<accountCode: string, accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>
# operationId: post-createAccountHolder
@deprecated --flag primary-currency
export def "post-create-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # Your unique identifier for the prospective account holder. The length must be between three (3) and fifty (50) characters long. Only letters, digits, and hyphens (-) are allowed.
  account_holder_details: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --create-default-account: oneof<nothing, bool> # If set to **true**, an account with the default options is automatically created for the account holder. By default, this field is set to **true**.
  --description: string # A description of the prospective account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  legal_entity: string@legal-entity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request. Possible values: **Business**, **Individual**, or **NonProfit**. * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list. * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primary-currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), with which the prospective account holder primarily deals. (DEPRECATED)
  --processing-tier: int # The starting [processing tier](https://docs.adyen.com/marketplaces-and-platforms/classic/onboarding-and-verification/precheck-kyc-information) for the prospective account holder. (format: int32)
  --verification-profile: string # The identifier of the profile that applies to this entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/createAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: accountHolderDetails, var: account_holder_details}, {name: createDefaultAccount, var: create_default_account}, {name: description, var: description}, {name: legalEntity, var: legal_entity}, {name: primaryCurrency, var: primary_currency}, {name: processingTier, var: processing_tier}, {name: verificationProfile, var: verification_profile}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_code: $account_holder_code, account_holder_details: $account_holder_details, create_default_account: $create_default_account, description: $description, legal_entity: $legal_entity, primary_currency: $primary_currency, processing_tier: $processing_tier, verification_profile: $verification_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete bank accounts
#
# POST /deleteBankAccounts
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-deleteBankAccounts
export def "post-delete-bank-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder from which to delete the Bank Account(s).
  bank_account_uui_ds: list<string> # The code(s) of the Bank Accounts to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteBankAccounts"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: bankAccountUUIDs, var: bank_account_uui_ds}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, bank_account_uui_ds: $bank_account_uui_ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete legal arrangements
#
# POST /deleteLegalArrangements
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-deleteLegalArrangements
export def "post-delete-legal-arrangements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder.
  legal_arrangements: list # List of legal arrangements. — item shape: {legalArrangementCode: string, legalArrangementEntityCodes?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteLegalArrangements"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: legalArrangements, var: legal_arrangements}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, legal_arrangements: $legal_arrangements
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete payout methods
#
# POST /deletePayoutMethods
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-deletePayoutMethods
export def "post-delete-payout-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder, from which to delete the payout methods.
  payout_method_codes: list<string> # The codes of the payout methods to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deletePayoutMethods"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: payoutMethodCodes, var: payout_method_codes}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, payout_method_codes: $payout_method_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete shareholders
#
# POST /deleteShareholders
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-deleteShareholders
export def "post-delete-shareholders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder from which to delete the Shareholders.
  shareholder_codes: list<string> # The code(s) of the Shareholders to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteShareholders"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: shareholderCodes, var: shareholder_codes}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, shareholder_codes: $shareholder_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete signatories
#
# POST /deleteSignatories
# Returns: record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-deleteSignatories
export def "post-delete-signatories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder from which to delete the signatories.
  signatory_codes: list<string> # Array of codes of the signatories to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/deleteSignatories"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: signatoryCodes, var: signatory_codes}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, signatory_codes: $signatory_codes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an account holder
#
# POST /getAccountHolder
# Returns: record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, accounts: table<accountCode: string, bankAccountUUID: string, beneficiaryAccount: string, beneficiaryMerchantReference: string, description: string, metadata: record, payoutMethodCode: string, payoutSchedule: record, payoutSpeed: string, status: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, migrationData: record<accountHolderId: string, balancePlatform: string, migrated: bool, migratedAccounts: list<record>, migratedStores: list<record>, migrationDate: string>, primaryCurrency: string, pspReference: string, resultCode: string, systemUpToDateTime: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>
# operationId: post-getAccountHolder
export def "post-get-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-code: string # The code of the account of which to retrieve the details. > Required if no `accountHolderCode` is provided.
  --account-holder-code: string # The code of the account holder of which to retrieve the details. > Required if no `accountCode` is provided.
  --show-details: oneof<nothing, bool> # True if the request should return the account holder details
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountCode, var: account_code}, {name: accountHolderCode, var: account_holder_code}, {name: showDetails, var: show_details}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_code: $account_code, account_holder_code: $account_holder_code, show_details: $show_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tax form
#
# POST /getTaxForm
# Returns: record<content: string, contentType: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-getTaxForm
export def "post-get-tax-form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The account holder code you provided when you created the account holder.
  form_type: string # Type of the requested tax form. For example, 1099-K.
  year: int # Applicable tax year in the YYYY format. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getTaxForm"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: formType, var: form_type}, {name: year, var: year}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_code: $account_holder_code, form_type: $form_type, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get documents
#
# POST /getUploadedDocuments
# Returns: record<documentDetails: table<accountHolderCode: string, bankAccountUUID: string, description: string, documentType: string, filename: string, legalArrangementCode: string, legalArrangementEntityCode: string, shareholderCode: string, signatoryCode: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-getUploadedDocuments
export def "post-get-uploaded-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder for which to retrieve the documents.
  --bank-account-uuid: string # The code of the Bank Account for which to retrieve the documents.
  --shareholder-code: string # The code of the Shareholder for which to retrieve the documents.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/getUploadedDocuments"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: bankAccountUUID, var: bank_account_uuid}, {name: shareholderCode, var: shareholder_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    account_holder_code: $account_holder_code, bank_account_uuid: $bank_account_uuid, shareholder_code: $shareholder_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspend an account holder
#
# POST /suspendAccountHolder
# Returns: record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-suspendAccountHolder
export def "post-suspend-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to be suspended.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/suspendAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsuspend an account holder
#
# POST /unSuspendAccountHolder
# Returns: record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-unSuspendAccountHolder
export def "post-un-suspend-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to be reinstated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/unSuspendAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an account
#
# POST /updateAccount
# Returns: record<accountCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string>
# operationId: post-updateAccount
export def "post-update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of the account to update.
  --bank-account-uuid: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters.You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payout-method-code: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payout-schedule: record # shape: {action?: "CLOSE"|"NOTHING"|"UPDATE", reason?: string, schedule: "BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT"|"DAILY"|"DAILY_AU"|"DAILY_EU"|"DAILY_SG"|"DAILY_US"|"HOLD"|"MONTHLY"|"WEEKLY"|"WEEKLY_MON_TO_FRI_AU"|"WEEKLY_MON_TO_FRI_EU"|"WEEKLY_MON_TO_FRI_US"|"WEEKLY_ON_TUE_FRI_MIDNIGHT"|"WEEKLY_SUN_TO_THU_AU"|"WEEKLY_SUN_TO_THU_US"}
  --payout-speed: string@payout-speed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/updateAccount"
    body: {content_type: "application/json", kind: json, fields: [{name: accountCode, var: account_code}, {name: bankAccountUUID, var: bank_account_uuid}, {name: description, var: description}, {name: metadata, var: metadata}, {name: payoutMethodCode, var: payout_method_code}, {name: payoutSchedule, var: payout_schedule}, {name: payoutSpeed, var: payout_speed}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_code: $account_code, bank_account_uuid: $bank_account_uuid, description: $description, metadata: $metadata, payout_method_code: $payout_method_code, payout_schedule: $payout_schedule, payout_speed: $payout_speed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an account holder
#
# POST /updateAccountHolder
# Returns: record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>
# operationId: post-updateAccountHolder
@deprecated --flag primary-currency
export def "post-update-account-holder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder to be updated.
  --account-holder-details: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --description: string # A description of the account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --legal-entity: string@legal-entity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request. Possible values: **Business**, **Individual**, or **NonProfit**. * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list. * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primary-currency: string # The primary three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), to which the account holder should be updated. (DEPRECATED)
  --processing-tier: int # The processing tier to which the Account Holder should be updated. >The processing tier can not be lowered through this request. >Required if accountHolderDetails are not provided. (format: int32)
  --verification-profile: string # The identifier of the profile that applies to this entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/updateAccountHolder"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: accountHolderDetails, var: account_holder_details}, {name: description, var: description}, {name: legalEntity, var: legal_entity}, {name: primaryCurrency, var: primary_currency}, {name: processingTier, var: processing_tier}, {name: verificationProfile, var: verification_profile}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, account_holder_details: $account_holder_details, description: $description, legal_entity: $legal_entity, primary_currency: $primary_currency, processing_tier: $processing_tier, verification_profile: $verification_profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update payout or processing state
#
# POST /updateAccountHolderState
# Returns: record<accountHolderCode: string, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string>
# operationId: post-updateAccountHolderState
export def "post-update-account-holder-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder on which to update the state.
  --disable: oneof<nothing, bool> # If true, disable the requested state. If false, enable the requested state.
  --reason: string # The reason that the state is being updated. >Required if the state is being disabled.
  state_type: string@state-type-completer # The state to be updated. >Permitted values are: `Processing`, `Payout`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/updateAccountHolderState"
    body: {content_type: "application/json", kind: json, fields: [{name: accountHolderCode, var: account_holder_code}, {name: disable, var: disable, required: true}, {name: reason, var: reason}, {name: stateType, var: state_type}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    account_holder_code: $account_holder_code, disable: $disable, reason: $reason, state_type: $state_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a document
#
# POST /uploadDocument
# Returns: record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string>
# operationId: post-uploadDocument
export def "post-upload-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document_content: string # The content of the document, in Base64-encoded string format. To learn about document requirements, refer to [Verification checks](https://docs.adyen.com/marketplaces-and-platforms/classic/verification-checks).
  document_detail: record # shape: {accountHolderCode?: string, bankAccountUUID?: string, description?: string, documentType: "BANK_STATEMENT"|"BSN"|"COMPANY_REGISTRATION_SCREENING"|"CONSTITUTIONAL_DOCUMENT"|"DRIVING_LICENCE"|"DRIVING_LICENCE_BACK"|"DRIVING_LICENCE_FRONT"|"ID_CARD"|"ID_CARD_BACK"|"ID_CARD_FRONT"|"PASSPORT"|"PROOF_OF_RESIDENCY"|"SSN"|"SUPPORTING_DOCUMENTS", filename?: string, legalArrangementCode?: string, legalArrangementEntityCode?: string, shareholderCode?: string, signatoryCode?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploadDocument"
    body: {content_type: "application/json", kind: json, fields: [{name: documentContent, var: document_content}, {name: documentDetail, var: document_detail}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: basic
  } {
    document_content: $document_content, document_detail: $document_detail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
