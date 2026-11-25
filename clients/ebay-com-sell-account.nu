# Auto-generated client for Account API v1.9.0
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-account/v1.9.0/openapi.json
# Auth: --token flag or $env.ACCOUNT_API_TOKEN

const CLIENT = {
  base_url: "https://api.ebay.com/sell/account/v1"
  token_env_var: "ACCOUNT_API_TOKEN"
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

def base-url-completer [] { ["https://api.ebay.com/sell/account/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-advertising-eligibility: "record<advertisingEligibility: table<programType: string, reason: string, status: string>>"
    get-custom-policies: "record<customPolicies: table<customPolicyId: string, label: string, name: string, policyType: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int>"
    create-custom-policy: "record"
    get-custom-policy: "record<customPolicyId: string, description: string, label: string, name: string, policyType: string>"
    get-fulfillment-policies: "record<fulfillmentPolicies: table<categoryTypes: list, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record, shippingOptions: list>, href: string, limit: int, next: string, offset: int, prev: string, total: int>"
    create-fulfillment-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-fulfillment-policy-by-name: "record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>>"
    get-fulfillment-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>>"
    update-fulfillment-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-kyc: "record<kycChecks: table<alert: string, dataRequired: string, detailMessage: string, dueDate: string, remedyUrl: string>>"
    get-payment-policies: "record<href: string, limit: int, next: string, offset: int, paymentPolicies: table<categoryTypes: list, deposit: record, description: string, fullPaymentDueIn: record, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: list, paymentPolicyId: string>, prev: string, total: int>"
    create-payment-policy: "record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-payment-policy-by-name: "record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string>"
    get-payment-policy: "record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string>"
    update-payment-policy: "record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-payments-program: "record<marketplaceId: string, paymentsProgramType: string, status: string, wasPreviouslyOptedIn: bool>"
    get-payments-program-onboarding: "record<onboardingStatus: string, steps: table<name: string, status: string, webUrl: string>>"
    get-privileges: "record<sellerRegistrationCompleted: bool, sellingLimit: record<amount: record<currency: string, value: string>, quantity: int>>"
    get-opted-in-programs: "record<programs: table<programType: string>>"
    opt-in-to-program: "record"
    opt-out-of-program: "record"
    get-rate-tables: "record<rateTables: table<countryCode: string, locality: string, name: string, rateTableId: string>>"
    get-return-policies: "record<href: string, limit: int, next: string, offset: int, prev: string, returnPolicies: table<categoryTypes: list, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>, total: int>"
    create-return-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-return-policy-by-name: "record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>"
    get-return-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>"
    update-return-policy: "record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-sales-taxes: "record<salesTaxes: table<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool>>"
    get-sales-tax: "record<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool>"
    get-subscription: "record<href: string, limit: int, next: string, subscriptions: table<marketplaceId: string, subscriptionId: string, subscriptionLevel: string, subscriptionType: string, term: record>, total: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-advertising-eligibility" "get-custom-policies" "create-custom-policy" "get-custom-policy" "update-custom-policy" "get-fulfillment-policies" "create-fulfillment-policy" "get-fulfillment-policy-by-name" "delete-fulfillment-policy" "get-fulfillment-policy" "update-fulfillment-policy" "get-kyc" "get-payment-policies" "create-payment-policy" "get-payment-policy-by-name" "delete-payment-policy" "get-payment-policy" "update-payment-policy" "get-payments-program" "get-payments-program-onboarding" "get-privileges" "get-opted-in-programs" "opt-in-to-program" "opt-out-of-program" "get-rate-tables" "get-return-policies" "create-return-policy" "get-return-policy-by-name" "delete-return-policy" "get-return-policy" "update-return-policy" "get-sales-taxes" "delete-sales-tax" "get-sales-tax" "create-or-replace-sales-tax" "get-subscription" "commands"] | sort) } | get name | first)
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

# This method allows developers to check the seller eligibility status for eBay advertising programs.
#
# GET /advertising_eligibility
# Returns: record<advertisingEligibility: table<programType: string, reason: string, status: string>>
# operationId: getAdvertisingEligibility
export def "get-advertising-eligibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-types: string # A comma-separated list of eBay advertising programs.Tip: See the AdvertisingProgramEnum (/api-docs/sell/account/types/plser:AdvertisingProgramEnum) type for possible values.If no programs are specified, the results will be returned for all programs.
  --x-ebay-c-marketplace-id: string # The unique identifier of the eBay marketplace for which the seller eligibility status shall be checked.Note: This value is case-sensitive. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/advertising_eligibility"
    query: [{name: program_types, var: program_types}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    program_types: $program_types, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the list of custom policies specified by the policy_types query parameter for the selected eBay marketplace. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR)For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /custom_policy/
# Returns: record<customPolicies: table<customPolicyId: string, label: string, name: string, policyType: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int>
# operationId: getCustomPolicies
export def "get-custom-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-types: string # This query parameter specifies the type of custom policies to be returned.Multiple policy types may be requested in a single call by providing a comma-delimited set of all policy types to be returned.Note: Omitting this query parameter from a request will also return policies of all policy types.Two Custom Policy types are supported: Product Compliance (PRODUCT_COMPLIANCE) Takeback (TAKE_BACK)
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the MarketplaceIdEnum (/api-docs/sell/account/types/ba:MarketplaceIdEnum) type definition. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_policy/"
    query: [{name: policy_types, var: policy_types}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_types: $policy_types, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates a new custom policy in which a seller specifies their terms for complying with local governmental regulations. Two Custom Policy types are supported: Product Compliance (PRODUCT_COMPLIANCE) Takeback (TAKE_BACK)Each Custom Policy targets a policyType and eBay marketplace combination. Multiple policies may be created as follows: Product Compliance: a maximum of 10 policies per eBay marketplace may be created Takeback: a maximum of 3 policies per eBay marketplace may be createdA successful create policy call returns an HTTP status code of 201 Created with the system-generated policy ID included in the Location response header.Product Compliance PolicyProduct Compliance policies disclose product information as required for regulatory compliance.Note: A maximum of 10 Product Compliance policies per eBay marketplace may be created. Takeback PolicyTakeback policies describe the seller's legal obligation to take back a previously purchased item when the buyer purchases a new one.Note: A maximum of 3 Takeback policies per eBay marketplace may be created.
#
# POST /custom_policy/
# Returns: record
# operationId: createCustomPolicy
export def "create-custom-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the MarketplaceIdEnum (/api-docs/sell/account/types/ba:MarketplaceIdEnum) type definition. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR) (required)
  --description: string # Details of the seller's specific policy and terms for this policy.Max length: 15,000
  --label: string # Customer-facing label shown on View Item pages for items to which the policy applies. This seller-defined string is displayed as a system-generated hyperlink pointing to detailed policy information.Max length: 65
  --name: string # The seller-defined name for the custom policy. Names must be unique for policies assigned to the same seller, policy type, and eBay marketplace.Note: This field is visible only to the seller. Max length: 65
  --policy-type: string # Specifies the type of custom policy being created. Two Custom Policy types are supported: Product Compliance (PRODUCT_COMPLIANCE) Takeback (TAKE_BACK) For implementation help, refer to eBay API documentation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_policy/"
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: label, var: label}, {name: name, var: name}, {name: policyType, var: policy_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, description: $description, label: $label, name: $name, policy_type: $policy_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the custom policy specified by the custom_policy_id path parameter for the selected eBay marketplace. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR)For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /custom_policy/{custom_policy_id}
# Returns: record<customPolicyId: string, description: string, label: string, name: string, policyType: string>
# operationId: getCustomPolicy
export def "get-custom-policy" [
  custom_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the MarketplaceIdEnum (/api-docs/sell/account/types/ba:MarketplaceIdEnum) type definition. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_policy/{custom_policy_id}"
    path_params: [{name: custom_policy_id, var: custom_policy_id}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_policy_id: $custom_policy_id, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method updates an existing custom policy specified by the custom_policy_id path parameter for the selected marketplace. This method overwrites the policy's Name, Label, and Description fields. Therefore, the complete, current text of all three policy fields must be included in the request payload even when one or two of these fields will not actually be updated. For example, the value for the Label field is to be updated, but the Name and Description values will remain unchanged. The existing Name and Description values, as they are defined in the current policy, must also be passed in. A successful policy update call returns an HTTP status code of 204 No Content.Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR)For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# PUT /custom_policy/{custom_policy_id}
# operationId: updateCustomPolicy
export def "update-custom-policy" [
  custom_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This header parameter specifies the eBay marketplace for the custom policy that is being created. Supported values for this header can be found in the MarketplaceIdEnum (/api-docs/sell/account/types/ba:MarketplaceIdEnum) type definition. Note: The following eBay marketplaces support Custom Policies: Germany (EBAY_DE) Canada (EBAY_CA) Australia (EBAY_AU) United States (EBAY_US) France (EBAY_FR) (required)
  --description: string # Details of the seller's specific policy and terms for this policy.Max length: 15,000
  --label: string # Customer-facing label shown on View Item pages for items to which the policy applies. This seller-defined string is displayed as a system-generated hyperlink pointing to detailed policy information.Max length: 65
  --name: string # The seller-defined name for the custom policy. Names must be unique for policies assigned to the same seller, policy type, and eBay marketplace.Note: This field is visible only to the seller. Max length: 65
]: any -> any {
  $in | http-request {
    method: put
    path: "/custom_policy/{custom_policy_id}"
    path_params: [{name: custom_policy_id, var: custom_policy_id}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: label, var: label}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    custom_policy_id: $custom_policy_id, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, description: $description, label: $label, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves all the fulfillment policies configured for the marketplace you specify using the marketplace_id query parameter. Marketplaces and locales Get the correct policies for a marketplace that supports multiple locales using the Content-Language request header. For example, get the policies for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /fulfillment_policy
# Returns: record<fulfillmentPolicies: table<categoryTypes: list, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record, shippingOptions: list>, href: string, limit: int, next: string, offset: int, prev: string, total: int>
# operationId: getFulfillmentPolicies
export def "get-fulfillment-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policies you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fulfillment_policy"
    query: [{name: marketplace_id, var: marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates a new fulfillment policy where the policy encapsulates seller's terms for fulfilling item purchases. Fulfillment policies include the shipment options that the seller offers to buyers. Each policy targets a specific eBay marketplace and a category group type, and you can create multiple policies for each combination. A successful request returns the getFulfillmentPolicy URI to the new policy in the Location response header and the ID for the new policy is returned in the response payload. Tip: For details on creating and using the business policies supported by the Account API, see eBay business policies (/api-docs/sell/static/seller-accounts/business-policies.html). Using the eBay standard envelope service (eSE) The eBay standard envelope service (eSE) is a domestic envelope service with tracking through eBay. This service applies to specific Trading Cards categories (not all categories are supported), and to Coins & Paper Money, Postcards, and Stamps. See Using the eBay standard envelope (eSE) service (/api-docs/sell/static/seller-accounts/using-the-ebay-standard-envelope-service.html).
#
# POST /fulfillment_policy/
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: createFulfillmentPolicy
export def "create-fulfillment-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the fulfillment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the fulfillment policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --freight-shipping: oneof<nothing, bool> # This field is included and set to true if freight shipping is available for the item. Freight shipping can be used for large items over 150 lbs.Default: false
  --global-shipping: oneof<nothing, bool> # This field is included and set to true if the seller wants to use the Global Shipping Program for international shipments. See the Global Shipping Program (https://pages.ebay.com/help/sell/shipping-globally.html ) help topic for more details and requirements on the Global Shipping Program.It is possible for a seller to use a combination of the Global Shipping Program and other international shipping services. If this value is set to false or if the field is omitted, the seller is responsible for manually specifying individual international shipping services (if the seller ships internationally)., as described in Setting up worldwide shipping (https://developer.ebay.com/api-docs/sell/static/seller-accounts/ht_shipping-worldwide.html ). Sellers can opt in or out of the Global Shipping Program through the Shipping preferences in My eBay.Note: On the US marketplace, the Global Shipping Program is scheduled to be replaced by a new intermediated international shipping program called eBay International Shipping. US sellers who are opted in to the Global Shipping Program will be automatically opted in to eBay International Shipping when it becomes available to them. All US sellers will be migrated by March 31, 2023. eBay International Shipping is an account level setting, and no field needs to be set in a Fulfillment business policy to enable it. As long as the US seller's account is opted in to eBay International Shipping, this shipping option will be enabled automatically for all listings where international shipping is available. A US seller who is opted in to eBay International Shipping can also specify individual international shipping service options for a Fulfillment business policy.Default: false
  --handling-time: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --local-pickup: oneof<nothing, bool> # This field should be included and set to true if local pickup is one of the fulfillment options available to the buyer. It is possible for the seller to make local pickup and some shipping service options available to the buyer.With local pickup, the buyer and seller make arrangements for pickup time and location.Default: false
  --marketplace-id: string # The ID of the eBay marketplace to which this fulfillment policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this fulfillment policy. Names must be unique for policies assigned to the same marketplace. Max length: 64
  --pickup-drop-off: oneof<nothing, bool> # This field should be included and set to true if the seller offers the "Click and Collect" feature for an item. To enable "Click and Collect" on a listing, a seller must be eligible for Click and Collect. Currently, Click and Collect is available to only large retail merchants selling in the eBay AU and UK marketplaces. In addition to setting this field to true, the merchant must also do the following to enable the "Click and Collect" option on a listing: Have inventory for the product at one or more physical stores tied to the merchant's account. Sellers can use the createInventoryLocaion method in the Inventory API to associate physical stores to their account and they can then can add inventory to specific store locations.Set an immediate payment requirement on the item. The immediate payment feature requires the seller to: Set the immediatePay flag in the payment policy to 'true'.Have a valid store location with a complete street address.When a merchant successfully lists an item with Click and Collect, prospective buyers within a reasonable distance from one of the merchant's stores (that has stock available) will see the "Available for Click and Collect" option on the listing, along with information on the closest store that has the item.Default: false
  --ship-to-locations: record # This type consists of the regionIncluded and regionExcluded arrays, which indicate the areas to where the seller does and doesn't ship. — shape: {regionExcluded?: list, regionIncluded?: list}
  --shipping-options: list # This array is used to provide detailed information on the domestic and international shipping options available for the policy. A separate ShippingOption object is required for domestic shipping service options and for international shipping service options (if the seller ships to international locations). The optionType field is used to indicate whether the ShippingOption object applies to domestic or international shipping, and the costType field is used to indicate whether flat-rate shipping or calculated shipping will be used. The rateTableId field can be used to associate a defined shipping rate table to the policy, and the packageHandlingCost container can be used to set a handling charge for the policy. A separate ShippingServices object will be used to specify cost and other details for every available domestic and international shipping service option. — item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/fulfillment_policy/"
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: description, var: description}, {name: freightShipping, var: freight_shipping}, {name: globalShipping, var: global_shipping}, {name: handlingTime, var: handling_time}, {name: localPickup, var: local_pickup}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: pickupDropOff, var: pickup_drop_off}, {name: shipToLocations, var: ship_to_locations}, {name: shippingOptions, var: shipping_options}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    category_types: $category_types, description: $description, freight_shipping: $freight_shipping, global_shipping: $global_shipping, handling_time: $handling_time, local_pickup: $local_pickup, marketplace_id: $marketplace_id, name: $name, pickup_drop_off: $pickup_drop_off, ship_to_locations: $ship_to_locations, shipping_options: $shipping_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details for a specific fulfillment policy. In the request, supply both the policy name and its associated marketplace_id as query parameters. Marketplaces and locales Get the correct policy for a marketplace that supports multiple locales using the Content-Language request header. For example, get a policy for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /fulfillment_policy/get_by_policy_name
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>>
# operationId: getFulfillmentPolicyByName
export def "get-fulfillment-policy-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
  --name: string # This query parameter specifies the seller-defined name of the fulfillment policy you want to retrieve. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fulfillment_policy/get_by_policy_name"
    query: [{name: marketplace_id, var: marketplace_id, required: true}, {name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method deletes a fulfillment policy. Supply the ID of the policy you want to delete in the fulfillmentPolicyId path parameter.
#
# DELETE /fulfillment_policy/{fulfillmentPolicyId}
# operationId: deleteFulfillmentPolicy
export def "delete-fulfillment-policy" [
  fulfillment_policy_id: string
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
    method: delete
    path: "/fulfillment_policy/{fulfillmentPolicyId}"
    path_params: [{name: fulfillmentPolicyId, var: fulfillment_policy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    fulfillment_policy_id: $fulfillment_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the complete details of a fulfillment policy. Supply the ID of the policy you want to retrieve using the fulfillmentPolicyId path parameter.
#
# GET /fulfillment_policy/{fulfillmentPolicyId}
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>>
# operationId: getFulfillmentPolicy
export def "get-fulfillment-policy" [
  fulfillment_policy_id: string
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
    path: "/fulfillment_policy/{fulfillmentPolicyId}"
    path_params: [{name: fulfillmentPolicyId, var: fulfillment_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fulfillment_policy_id: $fulfillment_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method updates an existing fulfillment policy. Specify the policy you want to update using the fulfillment_policy_id path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /fulfillment_policy/{fulfillmentPolicyId}
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, freightShipping: bool, fulfillmentPolicyId: string, globalShipping: bool, handlingTime: record<unit: string, value: int>, localPickup: bool, marketplaceId: string, name: string, pickupDropOff: bool, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<costType: string, insuranceFee: record, insuranceOffered: bool, optionType: string, packageHandlingCost: record, rateTableId: string, shippingDiscountProfileId: string, shippingPromotionOffered: bool, shippingServices: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: updateFulfillmentPolicy
export def "update-fulfillment-policy" [
  fulfillment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the fulfillment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the fulfillment policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --freight-shipping: oneof<nothing, bool> # This field is included and set to true if freight shipping is available for the item. Freight shipping can be used for large items over 150 lbs.Default: false
  --global-shipping: oneof<nothing, bool> # This field is included and set to true if the seller wants to use the Global Shipping Program for international shipments. See the Global Shipping Program (https://pages.ebay.com/help/sell/shipping-globally.html ) help topic for more details and requirements on the Global Shipping Program.It is possible for a seller to use a combination of the Global Shipping Program and other international shipping services. If this value is set to false or if the field is omitted, the seller is responsible for manually specifying individual international shipping services (if the seller ships internationally)., as described in Setting up worldwide shipping (https://developer.ebay.com/api-docs/sell/static/seller-accounts/ht_shipping-worldwide.html ). Sellers can opt in or out of the Global Shipping Program through the Shipping preferences in My eBay.Note: On the US marketplace, the Global Shipping Program is scheduled to be replaced by a new intermediated international shipping program called eBay International Shipping. US sellers who are opted in to the Global Shipping Program will be automatically opted in to eBay International Shipping when it becomes available to them. All US sellers will be migrated by March 31, 2023. eBay International Shipping is an account level setting, and no field needs to be set in a Fulfillment business policy to enable it. As long as the US seller's account is opted in to eBay International Shipping, this shipping option will be enabled automatically for all listings where international shipping is available. A US seller who is opted in to eBay International Shipping can also specify individual international shipping service options for a Fulfillment business policy.Default: false
  --handling-time: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --local-pickup: oneof<nothing, bool> # This field should be included and set to true if local pickup is one of the fulfillment options available to the buyer. It is possible for the seller to make local pickup and some shipping service options available to the buyer.With local pickup, the buyer and seller make arrangements for pickup time and location.Default: false
  --marketplace-id: string # The ID of the eBay marketplace to which this fulfillment policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this fulfillment policy. Names must be unique for policies assigned to the same marketplace. Max length: 64
  --pickup-drop-off: oneof<nothing, bool> # This field should be included and set to true if the seller offers the "Click and Collect" feature for an item. To enable "Click and Collect" on a listing, a seller must be eligible for Click and Collect. Currently, Click and Collect is available to only large retail merchants selling in the eBay AU and UK marketplaces. In addition to setting this field to true, the merchant must also do the following to enable the "Click and Collect" option on a listing: Have inventory for the product at one or more physical stores tied to the merchant's account. Sellers can use the createInventoryLocaion method in the Inventory API to associate physical stores to their account and they can then can add inventory to specific store locations.Set an immediate payment requirement on the item. The immediate payment feature requires the seller to: Set the immediatePay flag in the payment policy to 'true'.Have a valid store location with a complete street address.When a merchant successfully lists an item with Click and Collect, prospective buyers within a reasonable distance from one of the merchant's stores (that has stock available) will see the "Available for Click and Collect" option on the listing, along with information on the closest store that has the item.Default: false
  --ship-to-locations: record # This type consists of the regionIncluded and regionExcluded arrays, which indicate the areas to where the seller does and doesn't ship. — shape: {regionExcluded?: list, regionIncluded?: list}
  --shipping-options: list # This array is used to provide detailed information on the domestic and international shipping options available for the policy. A separate ShippingOption object is required for domestic shipping service options and for international shipping service options (if the seller ships to international locations). The optionType field is used to indicate whether the ShippingOption object applies to domestic or international shipping, and the costType field is used to indicate whether flat-rate shipping or calculated shipping will be used. The rateTableId field can be used to associate a defined shipping rate table to the policy, and the packageHandlingCost container can be used to set a handling charge for the policy. A separate ShippingServices object will be used to specify cost and other details for every available domestic and international shipping service option. — item shape: {costType?: string, insuranceFee?: record, insuranceOffered?: bool, optionType?: string, packageHandlingCost?: record, rateTableId?: string, shippingDiscountProfileId?: string, shippingPromotionOffered?: bool, shippingServices?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/fulfillment_policy/{fulfillmentPolicyId}"
    path_params: [{name: fulfillmentPolicyId, var: fulfillment_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: description, var: description}, {name: freightShipping, var: freight_shipping}, {name: globalShipping, var: global_shipping}, {name: handlingTime, var: handling_time}, {name: localPickup, var: local_pickup}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: pickupDropOff, var: pickup_drop_off}, {name: shipToLocations, var: ship_to_locations}, {name: shippingOptions, var: shipping_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fulfillment_policy_id: $fulfillment_policy_id, category_types: $category_types, description: $description, freight_shipping: $freight_shipping, global_shipping: $global_shipping, handling_time: $handling_time, local_pickup: $local_pickup, marketplace_id: $marketplace_id, name: $name, pickup_drop_off: $pickup_drop_off, ship_to_locations: $ship_to_locations, shipping_options: $shipping_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Note:This method was originally created to see which onboarding requirements were still pending for sellers being onboarded for eBay managed payments, but now that all seller accounts are onboarded globally, this method should now just returne an empty payload with a 204 No Content HTTP status code.
#
# GET /kyc
# Returns: record<kycChecks: table<alert: string, dataRequired: string, detailMessage: string, dueDate: string, remedyUrl: string>>
# operationId: getKYC
export def "get-kyc" [
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
    path: "/kyc"
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves all the payment policies configured for the marketplace you specify using the marketplace_id query parameter. Marketplaces and locales Get the correct policies for a marketplace that supports multiple locales using the Content-Language request header. For example, get the policies for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /payment_policy
# Returns: record<href: string, limit: int, next: string, offset: int, paymentPolicies: table<categoryTypes: list, deposit: record, description: string, fullPaymentDueIn: record, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: list, paymentPolicyId: string>, prev: string, total: int>
# operationId: getPaymentPolicies
export def "get-payment-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policies you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payment_policy"
    query: [{name: marketplace_id, var: marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates a new payment policy where the policy encapsulates seller's terms for order payments. Each policy targets a specific eBay marketplace and category group, and you can create multiple policies for each combination. A successful request returns the getPaymentPolicy URI to the new policy in the Location response header and the ID for the new policy is returned in the response payload. Tip: For details on creating and using the business policies supported by the Account API, see eBay business policies (/api-docs/sell/static/seller-accounts/business-policies.html).
#
# POST /payment_policy
# Returns: record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: createPaymentPolicy
export def "create-payment-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the payment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --deposit: record # This type is used to specify/indicate that an initial deposit is required for a motor vehicle listing. — shape: {amount?: record, dueIn?: record, paymentMethods?: list}
  --description: string # A seller-defined description of the payment business policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --full-payment-due-in: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --immediate-pay: oneof<nothing, bool> # This field should be included and set to true if the seller wants to require immediate payment from the buyer for: A fixed-price itemAn auction item where the buyer is using the 'Buy it Now' optionA deposit for a motor vehicle listingDefault: False
  --marketplace-id: string # The ID of the eBay marketplace to which this payment business policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this payment business policy. Names must be unique for policies assigned to the same marketplace.Max length: 64
  --payment-instructions: string # Note: DO NOT USE THIS FIELD. Payment instructions are no longer supported by payment business policies.A free-form string field that allows sellers to add detailed payment instructions to their listings.
  --payment-methods: list # Note: This field applies only when the seller needs to specify one or more offline payment methods. eBay now manages the electronic payment options available to buyers to pay for the item.This array is used to specify one or more offline payment methods that will be accepted for payment that occurs off of eBay's platform. — item shape: {brands?: list<string>, paymentMethodType?: string, recipientAccountReference?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payment_policy"
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: deposit, var: deposit}, {name: description, var: description}, {name: fullPaymentDueIn, var: full_payment_due_in}, {name: immediatePay, var: immediate_pay}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: paymentInstructions, var: payment_instructions}, {name: paymentMethods, var: payment_methods}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    category_types: $category_types, deposit: $deposit, description: $description, full_payment_due_in: $full_payment_due_in, immediate_pay: $immediate_pay, marketplace_id: $marketplace_id, name: $name, payment_instructions: $payment_instructions, payment_methods: $payment_methods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details of a specific payment policy. Supply both the policy name and its associated marketplace_id in the request query parameters. Marketplaces and locales Get the correct policy for a marketplace that supports multiple locales using the Content-Language request header. For example, get a policy for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /payment_policy/get_by_policy_name
# Returns: record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string>
# operationId: getPaymentPolicyByName
export def "get-payment-policy-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
  --name: string # This query parameter specifies the seller-defined name of the payment policy you want to retrieve. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payment_policy/get_by_policy_name"
    query: [{name: marketplace_id, var: marketplace_id, required: true}, {name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method deletes a payment policy. Supply the ID of the policy you want to delete in the paymentPolicyId path parameter.
#
# DELETE /payment_policy/{payment_policy_id}
# operationId: deletePaymentPolicy
export def "delete-payment-policy" [
  payment_policy_id: string
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
    method: delete
    path: "/payment_policy/{payment_policy_id}"
    path_params: [{name: payment_policy_id, var: payment_policy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    payment_policy_id: $payment_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the complete details of a payment policy. Supply the ID of the policy you want to retrieve using the paymentPolicyId path parameter.
#
# GET /payment_policy/{payment_policy_id}
# Returns: record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string>
# operationId: getPaymentPolicy
export def "get-payment-policy" [
  payment_policy_id: string
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
    path: "/payment_policy/{payment_policy_id}"
    path_params: [{name: payment_policy_id, var: payment_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_policy_id: $payment_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method updates an existing payment policy. Specify the policy you want to update using the payment_policy_id path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /payment_policy/{payment_policy_id}
# Returns: record<categoryTypes: table<default: bool, name: string>, deposit: record<amount: record<currency: string, value: string>, dueIn: record<unit: string, value: int>, paymentMethods: list<record>>, description: string, fullPaymentDueIn: record<unit: string, value: int>, immediatePay: bool, marketplaceId: string, name: string, paymentInstructions: string, paymentMethods: table<brands: list, paymentMethodType: string, recipientAccountReference: record>, paymentPolicyId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: updatePaymentPolicy
export def "update-payment-policy" [
  payment_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container is used to specify whether the payment business policy applies to motor vehicle listings, or if it applies to non-motor vehicle listings. — item shape: {default?: bool, name?: string}
  --deposit: record # This type is used to specify/indicate that an initial deposit is required for a motor vehicle listing. — shape: {amount?: record, dueIn?: record, paymentMethods?: list}
  --description: string # A seller-defined description of the payment business policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --full-payment-due-in: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --immediate-pay: oneof<nothing, bool> # This field should be included and set to true if the seller wants to require immediate payment from the buyer for: A fixed-price itemAn auction item where the buyer is using the 'Buy it Now' optionA deposit for a motor vehicle listingDefault: False
  --marketplace-id: string # The ID of the eBay marketplace to which this payment business policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this payment business policy. Names must be unique for policies assigned to the same marketplace.Max length: 64
  --payment-instructions: string # Note: DO NOT USE THIS FIELD. Payment instructions are no longer supported by payment business policies.A free-form string field that allows sellers to add detailed payment instructions to their listings.
  --payment-methods: list # Note: This field applies only when the seller needs to specify one or more offline payment methods. eBay now manages the electronic payment options available to buyers to pay for the item.This array is used to specify one or more offline payment methods that will be accepted for payment that occurs off of eBay's platform. — item shape: {brands?: list<string>, paymentMethodType?: string, recipientAccountReference?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/payment_policy/{payment_policy_id}"
    path_params: [{name: payment_policy_id, var: payment_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: deposit, var: deposit}, {name: description, var: description}, {name: fullPaymentDueIn, var: full_payment_due_in}, {name: immediatePay, var: immediate_pay}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: paymentInstructions, var: payment_instructions}, {name: paymentMethods, var: payment_methods}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_policy_id: $payment_policy_id, category_types: $category_types, deposit: $deposit, description: $description, full_payment_due_in: $full_payment_due_in, immediate_pay: $immediate_pay, marketplace_id: $marketplace_id, name: $name, payment_instructions: $payment_instructions, payment_methods: $payment_methods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Note: This method is no longer applicable, as all seller accounts globally have been enabled for the new eBay payment and checkout flow.This method returns whether or not the user is opted-in to the specified payments program. Sellers opt-in to payments programs by marketplace and you use the marketplace_id path parameter to specify the marketplace of the status flag you want returned.
#
# GET /payments_program/{marketplace_id}/{payments_program_type}
# Returns: record<marketplaceId: string, paymentsProgramType: string, status: string, wasPreviouslyOptedIn: bool>
# operationId: getPaymentsProgram
export def "get-payments-program" [
  marketplace_id: string
  payments_program_type: string
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
    path: "/payments_program/{marketplace_id}/{payments_program_type}"
    path_params: [{name: marketplace_id, var: marketplace_id}, {name: payments_program_type, var: payments_program_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id, payments_program_type: $payments_program_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Note: This method is no longer applicable, as all seller accounts globally have been enabled for the new eBay payment and checkout flow.This method retrieves a seller's onboarding status for a payments program for a specified marketplace. The overall onboarding status of the seller and the status of each onboarding step is returned.
#
# GET /payments_program/{marketplace_id}/{payments_program_type}/onboarding
# Returns: record<onboardingStatus: string, steps: table<name: string, status: string, webUrl: string>>
# operationId: getPaymentsProgramOnboarding
export def "get-payments-program-onboarding" [
  marketplace_id: string
  payments_program_type: string
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
    path: "/payments_program/{marketplace_id}/{payments_program_type}/onboarding"
    path_params: [{name: marketplace_id, var: marketplace_id}, {name: payments_program_type, var: payments_program_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id, payments_program_type: $payments_program_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the seller's current set of privileges, including whether or not the seller's eBay registration has been completed, as well as the details of their site-wide sellingLimt (the amount and quantity they can sell on a given day).
#
# GET /privilege
# Returns: record<sellerRegistrationCompleted: bool, sellingLimit: record<amount: record<currency: string, value: string>, quantity: int>>
# operationId: getPrivileges
export def "get-privileges" [
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
    path: "/privilege"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method gets a list of the seller programs that the seller has opted-in to.
#
# GET /program/get_opted_in_programs
# Returns: record<programs: table<programType: string>>
# operationId: getOptedInPrograms
export def "get-opted-in-programs" [
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
    path: "/program/get_opted_in_programs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method opts the seller in to an eBay seller program. Refer to the Account API overview (/api-docs/sell/account/overview.html#opt-in) for information about available eBay seller programs.Note: It can take up to 24-hours for eBay to process your request to opt-in to a Seller Program. Use the getOptedInPrograms (/api-docs/sell/account/resources/program/methods/getOptedInPrograms) call to check the status of your request after the processing period has passed.
#
# POST /program/opt_in
# Returns: record
# operationId: optInToProgram
export def "opt-in-to-program" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-type: string # A seller program in to which a seller can opt-in. For implementation help, refer to eBay API documentation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/program/opt_in"
    body: {content_type: "application/json", kind: json, fields: [{name: programType, var: program_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    program_type: $program_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method opts the seller out of a seller program to which you have previously opted-in to. Get a list of the seller programs you have opted-in to using the getOptedInPrograms call.
#
# POST /program/opt_out
# Returns: record
# operationId: optOutOfProgram
export def "opt-out-of-program" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --program-type: string # A seller program in to which a seller can opt-in. For implementation help, refer to eBay API documentation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/program/opt_out"
    body: {content_type: "application/json", kind: json, fields: [{name: programType, var: program_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    program_type: $program_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves a seller's shipping rate tables for the country specified in the country_code query parameter. If you call this method without specifying a country code, the call returns all of the seller's shipping rate tables. The method's response includes a rateTableId for each table defined by the seller. This rateTableId value is used in add/revise item call or in create/update fulfillment business policy call to specify the shipping rate table to use for that policy's domestic or international shipping options. This call currently supports getting rate tables related to the following marketplaces:EBAY_AU EBAY_CA EBAY_DE EBAY_ES EBAY_FR EBAY_GB EBAY_IT EBAY_US Note: Rate tables created with the Trading API might not have been assigned a rateTableId at the time of their creation. This method can assign and return rateTableId values for rate tables with missing IDs if you make a request using the country_code where the seller has defined rate tables. Sellers can define up to 40 shipping rate tables for their account, which lets them set up different rate tables for each of the marketplaces they sell into. Go to Shipping rate tables (https://www.ebay.com/ship/rt ) in My eBay to create and update rate tables.
#
# GET /rate_table
# Returns: record<rateTables: table<countryCode: string, locality: string, name: string, rateTableId: string>>
# operationId: getRateTables
export def "get-rate-tables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # This query parameter specifies the two-letter ISO 3166 (https://www.iso.org/iso-3166-country-codes.html ) code of country for which you want shipping rate table information. If you do not specify a country code, the request returns all of the seller's defined shipping rate tables for all eBay marketplaces. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:CountryCodeEnum
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/rate_table"
    query: [{name: country_code, var: country_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_code: $country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves all the return policies configured for the marketplace you specify using the marketplace_id query parameter. Marketplaces and locales Get the correct policies for a marketplace that supports multiple locales using the Content-Language request header. For example, get the policies for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /return_policy
# Returns: record<href: string, limit: int, next: string, offset: int, prev: string, returnPolicies: table<categoryTypes: list, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>, total: int>
# operationId: getReturnPolicies
export def "get-return-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the ID of the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/return_policy"
    query: [{name: marketplace_id, var: marketplace_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates a new return policy where the policy encapsulates seller's terms for returning items. Each policy targets a specific marketplace, and you can create multiple policies for each marketplace. Return policies are not applicable to motor-vehicle listings.A successful request returns the getReturnPolicy URI to the new policy in the Location response header and the ID for the new policy is returned in the response payload. Tip: For details on creating and using the business policies supported by the Account API, see eBay business policies (/api-docs/sell/static/seller-accounts/business-policies.html).
#
# POST /return_policy
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: createReturnPolicy
export def "create-return-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container indicates which category group that the return policy applies to.Note: Return business policies are not applicable to motor vehicle listings, so the categoryTypes.name value must be set to ALL_EXCLUDING_MOTORS_VEHICLES for return business policies. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the return business policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --extended-holiday-returns-offered: oneof<nothing, bool> # Important! This field is deprecated, since eBay no longer supports extended holiday returns. Any value supplied in this field is neither read nor returned.
  --international-override: record # This type defines the fields for a seller's international return policy. Sellers have the ability to set separate domestic and international return policies, but if an international return policy is not set, the same return policy settings specified for the domestic return policy are also used for returns for international buyers. — shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
  --marketplace-id: string # The ID of the eBay marketplace to which this return business policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this return business policy. Names must be unique for policies assigned to the same marketplace. Max length: 64
  --refund-method: string # This value indicates the refund method that will be used by the seller for buyer returns.Important! If this field is not included in a return business policy, it will default to MONEY_BACK. For implementation help, refer to eBay API documentation
  --restocking-fee-percentage: string # Important! This field is deprecated, since eBay no longer allows sellers to charge a restocking fee for buyer remorse returns. If this field is included, it is ignored.
  --return-instructions: string # This text-based field provides more details on seller-specified return instructions. Important! This field is no longer supported on many eBay marketplaces. To see if a marketplace and eBay category does support this field, call getReturnPolicies (/api-docs/sell/metadata/resources/marketplace/methods/getReturnPolicies) method of the Metadata API. Then you will look for the policyDescriptionEnabled field with a value of true for the eBay category.Max length: 5000 (8000 for DE)
  --return-method: string # This field can be used if the seller is willing and able to offer a replacement item as an alternative to 'Money Back'. For implementation help, refer to eBay API documentation
  --return-period: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --return-shipping-cost-payer: string # This field indicates who is responsible for paying for the shipping charges for returned items. The field can be set to either BUYER or SELLER. Depending on the return policy and specifics of the return, either the buyer or the seller can be responsible for the return shipping costs. Note that the seller is always responsible for return shipping costs for SNAD-related issues. This field is conditionally required if returnsAccepted is set to true. For implementation help, refer to eBay API documentation
  --returns-accepted: oneof<nothing, bool> # If set to true, the seller accepts returns. Note:Top-Rated sellers must accept item returns and the handlingTime should be set to zero days or one day for a listing to receive a Top-Rated Plus badge on the View Item or search result pages. For more information on eBay's Top-Rated seller program, see Becoming a Top Rated Seller and qualifying for Top Rated Plus benefits (http://pages.ebay.com/help/sell/top-rated.html ).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/return_policy"
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: description, var: description}, {name: extendedHolidayReturnsOffered, var: extended_holiday_returns_offered}, {name: internationalOverride, var: international_override}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: refundMethod, var: refund_method}, {name: restockingFeePercentage, var: restocking_fee_percentage}, {name: returnInstructions, var: return_instructions}, {name: returnMethod, var: return_method}, {name: returnPeriod, var: return_period}, {name: returnShippingCostPayer, var: return_shipping_cost_payer}, {name: returnsAccepted, var: returns_accepted}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    category_types: $category_types, description: $description, extended_holiday_returns_offered: $extended_holiday_returns_offered, international_override: $international_override, marketplace_id: $marketplace_id, name: $name, refund_method: $refund_method, restocking_fee_percentage: $restocking_fee_percentage, return_instructions: $return_instructions, return_method: $return_method, return_period: $return_period, return_shipping_cost_payer: $return_shipping_cost_payer, returns_accepted: $returns_accepted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details of a specific return policy. Supply both the policy name and its associated marketplace_id in the request query parameters. Marketplaces and locales Get the correct policy for a marketplace that supports multiple locales using the Content-Language request header. For example, get a policy for the French locale of the Canadian marketplace by specifying fr-CA for the Content-Language header. Likewise, target the Dutch locale of the Belgium marketplace by setting Content-Language: nl-BE. For details on header values, see HTTP request headers (/api-docs/static/rest-request-components.html#HTTP).
#
# GET /return_policy/get_by_policy_name
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>
# operationId: getReturnPolicyByName
export def "get-return-policy-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # This query parameter specifies the ID of the eBay marketplace of the policy you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:MarketplaceIdEnum (required)
  --name: string # This query parameter specifies the seller-defined name of the return policy you want to retrieve. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/return_policy/get_by_policy_name"
    query: [{name: marketplace_id, var: marketplace_id, required: true}, {name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    marketplace_id: $marketplace_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method deletes a return policy. Supply the ID of the policy you want to delete in the returnPolicyId path parameter.
#
# DELETE /return_policy/{return_policy_id}
# operationId: deleteReturnPolicy
export def "delete-return-policy" [
  return_policy_id: string
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
    method: delete
    path: "/return_policy/{return_policy_id}"
    path_params: [{name: return_policy_id, var: return_policy_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    return_policy_id: $return_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the complete details of the return policy specified by the returnPolicyId path parameter.
#
# GET /return_policy/{return_policy_id}
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool>
# operationId: getReturnPolicy
export def "get-return-policy" [
  return_policy_id: string
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
    path: "/return_policy/{return_policy_id}"
    path_params: [{name: return_policy_id, var: return_policy_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    return_policy_id: $return_policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method updates an existing return policy. Specify the policy you want to update using the return_policy_id path parameter. Supply a complete policy payload with the updates you want to make; this call overwrites the existing policy with the new details specified in the payload.
#
# PUT /return_policy/{return_policy_id}
# Returns: record<categoryTypes: table<default: bool, name: string>, description: string, extendedHolidayReturnsOffered: bool, internationalOverride: record<returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, marketplaceId: string, name: string, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnPolicyId: string, returnShippingCostPayer: string, returnsAccepted: bool, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: updateReturnPolicy
export def "update-return-policy" [
  return_policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-types: list # This container indicates which category group that the return policy applies to.Note: Return business policies are not applicable to motor vehicle listings, so the categoryTypes.name value must be set to ALL_EXCLUDING_MOTORS_VEHICLES for return business policies. — item shape: {default?: bool, name?: string}
  --description: string # A seller-defined description of the return business policy. This description is only for the seller's use, and is not exposed on any eBay pages. Max length: 250
  --extended-holiday-returns-offered: oneof<nothing, bool> # Important! This field is deprecated, since eBay no longer supports extended holiday returns. Any value supplied in this field is neither read nor returned.
  --international-override: record # This type defines the fields for a seller's international return policy. Sellers have the ability to set separate domestic and international return policies, but if an international return policy is not set, the same return policy settings specified for the domestic return policy are also used for returns for international buyers. — shape: {returnMethod?: string, returnPeriod?: record, returnShippingCostPayer?: string, returnsAccepted?: bool}
  --marketplace-id: string # The ID of the eBay marketplace to which this return business policy applies. For implementation help, refer to eBay API documentation
  --name: string # A seller-defined name for this return business policy. Names must be unique for policies assigned to the same marketplace. Max length: 64
  --refund-method: string # This value indicates the refund method that will be used by the seller for buyer returns.Important! If this field is not included in a return business policy, it will default to MONEY_BACK. For implementation help, refer to eBay API documentation
  --restocking-fee-percentage: string # Important! This field is deprecated, since eBay no longer allows sellers to charge a restocking fee for buyer remorse returns. If this field is included, it is ignored.
  --return-instructions: string # This text-based field provides more details on seller-specified return instructions. Important! This field is no longer supported on many eBay marketplaces. To see if a marketplace and eBay category does support this field, call getReturnPolicies (/api-docs/sell/metadata/resources/marketplace/methods/getReturnPolicies) method of the Metadata API. Then you will look for the policyDescriptionEnabled field with a value of true for the eBay category.Max length: 5000 (8000 for DE)
  --return-method: string # This field can be used if the seller is willing and able to offer a replacement item as an alternative to 'Money Back'. For implementation help, refer to eBay API documentation
  --return-period: record # A type used to specify a period of time using a specified time-measurement unit. Payment, return, and fulfillment business policies all use this type to specify time windows.Whenever a container that uses this type is used in a request, both of these fields are required. Similarly, whenever a container that uses this type is returned in a response, both of these fields are always returned. — shape: {unit?: string, value?: int}
  --return-shipping-cost-payer: string # This field indicates who is responsible for paying for the shipping charges for returned items. The field can be set to either BUYER or SELLER. Depending on the return policy and specifics of the return, either the buyer or the seller can be responsible for the return shipping costs. Note that the seller is always responsible for return shipping costs for SNAD-related issues. This field is conditionally required if returnsAccepted is set to true. For implementation help, refer to eBay API documentation
  --returns-accepted: oneof<nothing, bool> # If set to true, the seller accepts returns. Note:Top-Rated sellers must accept item returns and the handlingTime should be set to zero days or one day for a listing to receive a Top-Rated Plus badge on the View Item or search result pages. For more information on eBay's Top-Rated seller program, see Becoming a Top Rated Seller and qualifying for Top Rated Plus benefits (http://pages.ebay.com/help/sell/top-rated.html ).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/return_policy/{return_policy_id}"
    path_params: [{name: return_policy_id, var: return_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categoryTypes, var: category_types}, {name: description, var: description}, {name: extendedHolidayReturnsOffered, var: extended_holiday_returns_offered}, {name: internationalOverride, var: international_override}, {name: marketplaceId, var: marketplace_id}, {name: name, var: name}, {name: refundMethod, var: refund_method}, {name: restockingFeePercentage, var: restocking_fee_percentage}, {name: returnInstructions, var: return_instructions}, {name: returnMethod, var: return_method}, {name: returnPeriod, var: return_period}, {name: returnShippingCostPayer, var: return_shipping_cost_payer}, {name: returnsAccepted, var: returns_accepted}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    return_policy_id: $return_policy_id, category_types: $category_types, description: $description, extended_holiday_returns_offered: $extended_holiday_returns_offered, international_override: $international_override, marketplace_id: $marketplace_id, name: $name, refund_method: $refund_method, restocking_fee_percentage: $restocking_fee_percentage, return_instructions: $return_instructions, return_method: $return_method, return_period: $return_period, return_shipping_cost_payer: $return_shipping_cost_payer, returns_accepted: $returns_accepted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this call to retrieve all sales tax table entries that the seller has defined for a specific country. All four response fields will be returned for each tax jurisdiction that matches the search criteria. Important! In most US states and territories, eBay now 'collects and remits' sales tax, so sellers can no longer configure sales tax rates for these states/territories.
#
# GET /sales_tax
# Returns: record<salesTaxes: table<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool>>
# operationId: getSalesTaxes
export def "get-sales-taxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # This path parameter specifies the two-letter ISO 3166 (https://www.iso.org/iso-3166-country-codes.html ) code for the country whose tax table you want to retrieve. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/account/types/ba:CountryCodeEnum (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sales_tax"
    query: [{name: country_code, var: country_code, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_code: $country_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This call deletes a sales tax table entry for a jurisdiction. Specify the jurisdiction to delete using the countryCode and jurisdictionId path parameters.
#
# DELETE /sales_tax/{countryCode}/{jurisdictionId}
# operationId: deleteSalesTax
export def "delete-sales-tax" [
  country_code: string
  jurisdiction_id: string
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
    method: delete
    path: "/sales_tax/{countryCode}/{jurisdictionId}"
    path_params: [{name: countryCode, var: country_code}, {name: jurisdictionId, var: jurisdiction_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    country_code: $country_code, jurisdiction_id: $jurisdiction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This call gets the current sales tax table entry for a specific tax jurisdiction. Specify the jurisdiction to retrieve using the countryCode and jurisdictionId path parameters. All four response fields will be returned if a sales tax entry exists for the tax jurisdiction. Otherwise, the response will be returned as empty.Important! In most US states and territories, eBay now 'collects and remits' sales tax, so sellers can no longer configure sales tax rates for these states/territories.
#
# GET /sales_tax/{countryCode}/{jurisdictionId}
# Returns: record<countryCode: string, salesTaxJurisdictionId: string, salesTaxPercentage: string, shippingAndHandlingTaxed: bool>
# operationId: getSalesTax
export def "get-sales-tax" [
  country_code: string
  jurisdiction_id: string
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
    path: "/sales_tax/{countryCode}/{jurisdictionId}"
    path_params: [{name: countryCode, var: country_code}, {name: jurisdictionId, var: jurisdiction_id}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    country_code: $country_code, jurisdiction_id: $jurisdiction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method creates or updates a sales tax table entry for a jurisdiction. Specify the tax table entry you want to configure using the two path parameters: countryCode and jurisdictionId. A tax table entry for a jurisdiction is comprised of two fields: one for the jurisdiction's sales-tax rate and another that's a boolean value indicating whether or not shipping and handling are taxed in the jurisdiction. You can set up tax tables for countries that support different tax jurisdictions. Currently, only Canada, India, and the US support separate tax jurisdictions. If you sell into any of these countries, you can set up tax tables for any of the country's jurisdictions. Retrieve valid jurisdiction IDs using getSalesTaxJurisdictions in the Metadata API. For details on using this call, see Establishing sales-tax tables (/api-docs/sell/static/seller-accounts/tax-tables.html). Important! In the US, eBay now 'collects and remits' sales tax for every US state except for Missouri (and a few US territories), so sellers can no longer configure sales tax rates for any states except Missouri. With eBay 'collect and remit', eBay calculates the sales tax, collects the sales tax from the buyer, and remits the sales tax to the tax authorities at the buyer's location.
#
# PUT /sales_tax/{countryCode}/{jurisdictionId}
# operationId: createOrReplaceSalesTax
export def "create-or-replace-sales-tax" [
  country_code: string
  jurisdiction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sales-tax-percentage: string # This field is used to set the sales tax rate for the tax jurisdiction set in the call URI. When applicable to an order, this sales tax rate will be applied to sales price. The shippingAndHandlingTaxed value will indicate whether or not sales tax is also applied to shipping and handling chargesAlthough it is a string, a percentage value is set here, such as 7.75.
  --shipping-and-handling-taxed: oneof<nothing, bool> # This field is set to true if the seller wishes to apply sales tax to shipping and handling charges, and not just the total sales price of the order. Otherwise, this field's value should be set to false.
]: any -> any {
  $in | http-request {
    method: put
    path: "/sales_tax/{countryCode}/{jurisdictionId}"
    path_params: [{name: countryCode, var: country_code}, {name: jurisdictionId, var: jurisdiction_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: salesTaxPercentage, var: sales_tax_percentage}, {name: shippingAndHandlingTaxed, var: shipping_and_handling_taxed}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    country_code: $country_code, jurisdiction_id: $jurisdiction_id, sales_tax_percentage: $sales_tax_percentage, shipping_and_handling_taxed: $shipping_and_handling_taxed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves a list of subscriptions associated with the seller account.
#
# GET /subscription
# Returns: record<href: string, limit: int, next: string, subscriptions: table<marketplaceId: string, subscriptionId: string, subscriptionLevel: string, subscriptionType: string, term: record>, total: int>
# operationId: getSubscription
export def "get-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # This field is for future use.
  --continuation-token: string # This field is for future use.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscription"
    query: [{name: limit, var: limit}, {name: continuation_token, var: continuation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, continuation_token: $continuation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
