# Auto-generated client for Marketcheck APIs v2.01
# Source: https://api.apis.guru/v2/specs/apigee.net/marketcheck-cars/2.01/openapi.json
# Auth: --token flag or $env.MARKETCHECK_APIS_TOKEN

const CLIENT = {
  base_url: "https://marketcheck-prod.apigee.net/v2"
  token_env_var: "MARKETCHECK_APIS_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
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

def base-url-completer [] { ["https://marketcheck-prod.apigee.net/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def car-type-completer [] { ["certified" "new" "used"] }
def carfax-1-owner-completer [] { ["false" "true"] }
def carfax-clean-title-completer [] { ["false" "true"] }
def sort-order-completer [] { ["ASC" "DESC" "asc" "desc"] }
def facet-sort-completer [] { ["count" "index"] }
def country-completer [] { ["ALL" "CA" "US" "all" "ca" "us"] }
def dealer-type-completer [] { ["franchise" "independent"] }
def in-transit-completer [] { ["false" "true"] }
def country-completer-1 [] { ["CA" "UK" "US"] }
def country-completer-2 [] { ["CA" "US" "ca" "england" "northan ireland" "scotland" "uk" "us" "wales"] }
def country-completer-3 [] { ["CA" "US" "ca" "us"] }
def car-type-completer-1 [] { ["new" "used"] }
def transmission-completer [] { ["Automatic" "Manual"] }
def drivetrain-completer [] { ["4WD" "AWD" "FWD" "RWD"] }
def engine-block-completer [] { ["H" "I" "V"] }
def country-completer-4 [] { ["ca" "us"] }
def price-change-completer [] { ["negative" "positive"] }
def inventory-type-completer [] { ["new" "used"] }
def title-type-completer [] { ["clean" "salvage"] }
def field-completer [] { ["body_subtype" "body_type" "city" "drivetrain" "engine" "engine_block" "engine_size" "exterior_color" "fuel_type" "interior_color" "make" "mm" "model" "state" "transmission" "trim" "vehicle_type" "ymm"] }
def include-non-vin-listings-completer [] { ["false" "true"] }
def sort-by-completer [] { ["count" "index"] }
def offer-type-completer [] { ["cash" "finance" "lease"] }
def expired-completer [] { ["false" "true"] }
def country-completer-5 [] { ["england" "northan ireland" "scotland" "uk" "wales"] }
def client-filters-completer [] { ["false" "true"] }
def boost-completer [] { ["false" "true"] }
def field-completer-1 [] { ["body_type" "category" "city" "drivetrain" "engine" "exterior_color" "fuel_type" "interior_color" "make" "model" "state" "sub_category" "transmission" "trim"] }
def field-completer-2 [] { ["body_type" "city" "color" "drivetrain" "engine" "fuel_type" "make" "model" "state" "transmission" "trim" "vehicle_type"] }
def field-completer-3 [] { ["city" "class" "engine" "exterior_color" "fuel_type" "interior_color" "make" "model" "state" "transmission" "trim"] }
def field-completer-4 [] { ["body_subtype" "body_type" "drivetrain" "engine" "engine_block" "engine_size" "fuel_type" "make" "model" "transmission" "trim" "vehicle_type"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-car-dealer-inventory-active: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    get-recall-history: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    crm-check: "record<for_sale: string>"
    get-dealer-car-uk-id: "record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>"
    get-dealer: "record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>"
    get-dealer-heavy-equipment-id: "record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>"
    get-dealer-motorcycle-id: "record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>"
    get-dealer-rv-id: "record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>"
    dealer-search: "record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>"
    get-dealers-car-uk: "record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>"
    get-dealers-heavy-equipment: "record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>"
    get-dealers-motorcycle: "record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>"
    get-dealers-rv: "record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>"
    decode-via-epi: "record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>"
    decode-via-neo-vin: "record<available_options_details: record, body_subtype: string, body_type: string, city_mpg: float, combined_msrp: float, created_at: int, created_at_date: string, decode_version: int, delivery_charges: float, doors: int, drivetrain: string, engine: string, exterior_color: record, features: record, fuel_type: string, height: float, highway_mpg: float, installed_equipment: record, installed_options_details: record, installed_options_msrp: float, interior_color: record, length: float, listing_confidence: string, make: string, manufacturer_code: string, model: string, msrp: float, options_packages: string, package_code: string, package_description: string, seating_capacity: float, squish_vin: string, transmission: string, transmission_confidence: string, transmission_description: string, trim: string, trim_confidence: string, updated_at: int, updated_at_date: string, version: string, version_confidence: string, vin: string, weight: float, width: float, year: int>"
    get-decode-car-vin-specs: "record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>"
    get-history-car-uk-vrm: "table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string>"
    get-car-history: "table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string>"
    get-cached-image: "binary"
    get-listing-car-auction-id: "record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>"
    get-listing-car-auction-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-car-auction-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-car-fsbo-id: "record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>"
    get-listing-car-fsbo-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-car-fsbo-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-car-uk-id: "record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>"
    get-listing-car-uk-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-car-uk-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing: "record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>"
    get-listing-car-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-car-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-heavy-equipment-id: "record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>"
    get-listing-heavy-equipment-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-heavy-equipment-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-motorcycle-id: "record<build: record<body_type: string, cylinders: int, drivetrain: string, dry_weight: string, engine: string, fuel_type: string, made_in: string, make: string, model: string, transmission: string, trim: string, vehicle_type: string, year: int>, color: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>"
    get-listing-motorcycle-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-motorcycle-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-rv-uk-id: "record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>"
    get-listing-rv-uk-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-rv-uk-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-listing-rv-id: "record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>"
    get-listing-rv-id-extra: "record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>"
    get-listing-rv-id-media: "record<id: string, photo_links: list<string>, photo_url: string>"
    get-mds: "record<make: string, mds: int, model: string, sold_vins: list<string>, total_active_cars_for_ymmt: int, total_cars_sold_in_last_45_days: int, trim: string, year: int>"
    get-popular-cars: "record<new_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>, used_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>>"
    predict-car-price: "record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>>"
    fare-value: "record<avg_days_to_sold_local: int, avg_days_to_sold_national: int, fmv_local: int, fmv_national: int>"
    predict-uk-car-price: "record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>>"
    get-sales-count: "record<city: string, counts: int, cpo: int, dom_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, inventory_type: string, make: string, miles_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, model: string, non-cpo: int, price_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, state: string, taxonomy_vin: string, trim: string, year: string>"
    get-search-car-active: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    search-and-rank-car: "record<num_ranked: int, ranked_listings: table<ranked_listing: record>>"
    rank-car: "record<num_ranked: int, ranked_listings: table<ranked_listing: record>>"
    get-search-car-auction-active: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    auto-complete: "record<terms: table<count: int, item: string>>"
    get-search-car-fsbo-active: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    oem-search: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    get-search-car-recents: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    search: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    get-search-car-uk-recents: "record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>"
    get-search-heavy-equipment-active: "record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>"
    get-search-heavy-equipment-auto-complete: "record<terms: table<count: int, item: string>>"
    get-search-motorcycle-active: "record<facets: record, listings: table<build: record, color: string, dealer: record, dist: float, dp_url: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>"
    get-search-motorcycle-auto-complete: "record<terms: table<count: int, item: string>>"
    get-search-rv-active: "record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>"
    get-search-rv-auto-complete: "record<terms: table<count: int, item: string>>"
    get-search-rv-uk-active: "record<facets: record, listings: table<availability_status: string, build: record, currency_indicator: string, dealer: record, dist: float, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, miles_indicator: string, mot_expires: string, motorhome_build: string, msrp: int, origin: string, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vin: string>, num_found: int, range_facets: record, stats: record>"
    get-specs-car-auto-complete: "record<terms: list<string>>"
    get-taxonomy-terms: "record<terms: list<string>>"
    get-daily-stats: "record<dom: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, miles_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, price_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, units_for_sale: float>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-car-dealer-inventory-active" "get-recall-history" "get-client-configure-get" "set" "crm-check" "get-dealer-car-uk-id" "get-dealer" "get-dealer-heavy-equipment-id" "get-dealer-motorcycle-id" "get-dealer-rv-id" "dealer-search" "get-dealers-car-uk" "get-dealers-heavy-equipment" "get-dealers-motorcycle" "get-dealers-rv" "decode-via-epi" "decode-via-neo-vin" "get-decode-car-vin-specs" "get-history-car-uk-vrm" "get-car-history" "get-cached-image" "get-listing-car-auction-id" "get-listing-car-auction-id-extra" "get-listing-car-auction-id-media" "get-listing-car-fsbo-id" "get-listing-car-fsbo-id-extra" "get-listing-car-fsbo-id-media" "get-listing-car-uk-id" "get-listing-car-uk-id-extra" "get-listing-car-uk-id-media" "get-listing" "get-listing-car-id-extra" "get-listing-car-id-media" "get-listing-heavy-equipment-id" "get-listing-heavy-equipment-id-extra" "get-listing-heavy-equipment-id-media" "get-listing-motorcycle-id" "get-listing-motorcycle-id-extra" "get-listing-motorcycle-id-media" "get-listing-rv-uk-id" "get-listing-rv-uk-id-extra" "get-listing-rv-uk-id-media" "get-listing-rv-id" "get-listing-rv-id-extra" "get-listing-rv-id-media" "get-mds" "get-popular-cars" "predict-car-price" "fare-value" "predict-uk-car-price" "get-sales-count" "get-search-car-active" "search-and-rank-car" "rank-car" "get-search-car-auction-active" "auto-complete" "get-search-car-fsbo-active" "oem-search" "get-search-car-recents" "search" "get-search-car-uk-recents" "get-search-heavy-equipment-active" "get-search-heavy-equipment-auto-complete" "get-search-motorcycle-active" "get-search-motorcycle-auto-complete" "get-search-rv-active" "get-search-rv-auto-complete" "get-search-rv-uk-active" "get-specs-car-auto-complete" "get-taxonomy-terms" "get-daily-stats" "commands"] | sort) } | get name | first)
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

# Get dealers active inventory
#
# GET /car/dealer/inventory/active
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-car-dealer-inventory-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/car/dealer/inventory/active"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: dealer_id, var: dealer_id}, {name: vin, var: vin}, {name: source, var: source}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: mm, var: mm}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: dealer_name, var: dealer_name}, {name: dealership_group_name, var: dealership_group_name}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: include_relevant_links, var: include_relevant_links}, {name: inventory_count_range, var: inventory_count_range}, {name: in_transit, var: in_transit}, {name: seating_capacity, var: seating_capacity}, {name: engine_size_range, var: engine_size_range}, {name: powertrain_type, var: powertrain_type}, {name: min_photo_links, var: min_photo_links}, {name: min_photo_links_cached, var: min_photo_links_cached}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, dealer_id: $dealer_id, vin: $vin, source: $source, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, mm: $mm, ymm: $ymm, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, dealer_name: $dealer_name, dealership_group_name: $dealership_group_name, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, include_relevant_links: $include_relevant_links, inventory_count_range: $inventory_count_range, in_transit: $in_transit, seating_capacity: $seating_capacity, engine_size_range: $engine_size_range, powertrain_type: $powertrain_type, min_photo_links: $min_photo_links, min_photo_links_cached: $min_photo_links_cached
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recall info by vin
#
# GET /car/recall/{vin}
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
# operationId: getRecallHistory
export def "get-recall-history" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/car/recall/{vin}"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# get client filters
#
# GET /client/configure/get
# operationId: get
export def "get-client-configure-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-1 # To filter listing on Country in which they are listed (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/client/configure/get"
    query: [{name: api_key, var: api_key}, {name: country, var: country, required: true}]
    accept: ["text/csv"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# set client filters
#
# POST /client/configure/set
# operationId: set
export def "set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-1 # To filter listing on Country in which they are listed (required)
  csvfile: string # csv file with filters (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/client/configure/set"
    query: [{name: api_key, var: api_key}, {name: country, var: country, required: true}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: csvfile, var: csvfile}], files: [csvfile]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, country: $country, csvfile: $csvfile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CRM check of a particular vin
#
# GET /crm_check/car/{vin}
# Returns: record<for_sale: string>
# operationId: crmCheck
export def "crm-check" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --sale-date: string # sale date to check whether after this listing has appeared or not. Must be 8 character long, with YYYYMMDD format (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm_check/car/{vin}"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}, {name: sale_date, var: sale_date, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key, sale_date: $sale_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dealer by id
#
# GET /dealer/car/uk/{id}
# Returns: record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>
export def "get-dealer-car-uk-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealer/car/uk/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dealer by id
#
# GET /dealer/car/{id}
# Returns: record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>
# operationId: getDealer
export def "get-dealer" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealer/car/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dealer by id
#
# GET /dealer/heavy-equipment/{id}
# Returns: record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>
export def "get-dealer-heavy-equipment-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealer/heavy-equipment/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dealer by id
#
# GET /dealer/motorcycle/{id}
# Returns: record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>
export def "get-dealer-motorcycle-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealer/motorcycle/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dealer by id
#
# GET /dealer/rv/{id}
# Returns: record<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>
export def "get-dealer-rv-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealer/rv/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find car dealers around
#
# GET /dealers/car
# Returns: record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>
# operationId: dealerSearch
export def "dealer-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealers/car"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: rows, var: rows}, {name: start, var: start}, {name: country, var: country}, {name: dealer_type, var: dealer_type}, {name: city, var: city}, {name: state, var: state}, {name: listing_count_range, var: listing_count_range}, {name: inventory_url, var: inventory_url}, {name: zip, var: zip}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: provider, var: provider}, {name: facets, var: facets}, {name: range_facets, var: range_facets}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, rows: $rows, start: $start, country: $country, dealer_type: $dealer_type, city: $city, state: $state, listing_count_range: $listing_count_range, inventory_url: $inventory_url, zip: $zip, sort_by: $sort_by, sort_order: $sort_order, provider: $provider, facets: $facets, range_facets: $range_facets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find car dealers around
#
# GET /dealers/car/uk
# Returns: record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>
export def "get-dealers-car-uk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --county: string # To filter listing on county in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --postal-code: string # To filter listing on postal code around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealers/car/uk"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: rows, var: rows}, {name: start, var: start}, {name: country, var: country}, {name: dealer_type, var: dealer_type}, {name: city, var: city}, {name: county, var: county}, {name: listing_count_range, var: listing_count_range}, {name: inventory_url, var: inventory_url}, {name: postal_code, var: postal_code}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: provider, var: provider}, {name: facets, var: facets}, {name: range_facets, var: range_facets}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, rows: $rows, start: $start, country: $country, dealer_type: $dealer_type, city: $city, county: $county, listing_count_range: $listing_count_range, inventory_url: $inventory_url, postal_code: $postal_code, sort_by: $sort_by, sort_order: $sort_order, provider: $provider, facets: $facets, range_facets: $range_facets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find car dealers around
#
# GET /dealers/heavy-equipment
# Returns: record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>
export def "get-dealers-heavy-equipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealers/heavy-equipment"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: rows, var: rows}, {name: start, var: start}, {name: country, var: country}, {name: dealer_type, var: dealer_type}, {name: city, var: city}, {name: state, var: state}, {name: listing_count_range, var: listing_count_range}, {name: inventory_url, var: inventory_url}, {name: zip, var: zip}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: provider, var: provider}, {name: facets, var: facets}, {name: range_facets, var: range_facets}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, rows: $rows, start: $start, country: $country, dealer_type: $dealer_type, city: $city, state: $state, listing_count_range: $listing_count_range, inventory_url: $inventory_url, zip: $zip, sort_by: $sort_by, sort_order: $sort_order, provider: $provider, facets: $facets, range_facets: $range_facets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find car dealers around
#
# GET /dealers/motorcycle
# Returns: record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>
export def "get-dealers-motorcycle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealers/motorcycle"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: rows, var: rows}, {name: start, var: start}, {name: country, var: country}, {name: dealer_type, var: dealer_type}, {name: city, var: city}, {name: state, var: state}, {name: listing_count_range, var: listing_count_range}, {name: inventory_url, var: inventory_url}, {name: zip, var: zip}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: provider, var: provider}, {name: facets, var: facets}, {name: range_facets, var: range_facets}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, rows: $rows, start: $start, country: $country, dealer_type: $dealer_type, city: $city, state: $state, listing_count_range: $listing_count_range, inventory_url: $inventory_url, zip: $zip, sort_by: $sort_by, sort_order: $sort_order, provider: $provider, facets: $facets, range_facets: $range_facets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find car dealers around
#
# GET /dealers/rv
# Returns: record<dealers: table<city: string, country: string, data_source: string, dealer_type: string, dealership_group_name: string, distance: float, id: string, inventory_url: string, latitude: string, listing_count: int, location_ll: string, longitude: string, seller_email: string, seller_name: string, seller_phone: string, state: string, status: string, street: string, zip: string>, num_found: int>
export def "get-dealers-rv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --country: string@country-completer-2 # To filter listing on Country in which they are listed
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --listing-count-range: string # To filter dealers based on their inventory size. Range can be given in the format - min-max e.g. 50-100 (format: string)
  --inventory-url: string # inventory_url of dealer to be searched (format: string)
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --provider: oneof<nothing, bool> # boolean param to include site providers name in response (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dealers/rv"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: rows, var: rows}, {name: start, var: start}, {name: country, var: country}, {name: dealer_type, var: dealer_type}, {name: city, var: city}, {name: state, var: state}, {name: listing_count_range, var: listing_count_range}, {name: inventory_url, var: inventory_url}, {name: zip, var: zip}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: provider, var: provider}, {name: facets, var: facets}, {name: range_facets, var: range_facets}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, rows: $rows, start: $start, country: $country, dealer_type: $dealer_type, city: $city, state: $state, listing_count_range: $listing_count_range, inventory_url: $inventory_url, zip: $zip, sort_by: $sort_by, sort_order: $sort_order, provider: $provider, facets: $facets, range_facets: $range_facets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# EPI VIN Decoder
#
# GET /decode/car/epi/{vin}/specs
# Returns: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>
# operationId: decodeViaEPI
export def "decode-via-epi" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/decode/car/epi/{vin}/specs"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# NeoVIN Decoder
#
# GET /decode/car/neovin/{vin}/specs
# Returns: record<available_options_details: record, body_subtype: string, body_type: string, city_mpg: float, combined_msrp: float, created_at: int, created_at_date: string, decode_version: int, delivery_charges: float, doors: int, drivetrain: string, engine: string, exterior_color: record, features: record, fuel_type: string, height: float, highway_mpg: float, installed_equipment: record, installed_options_details: record, installed_options_msrp: float, interior_color: record, length: float, listing_confidence: string, make: string, manufacturer_code: string, model: string, msrp: float, options_packages: string, package_code: string, package_description: string, seating_capacity: float, squish_vin: string, transmission: string, transmission_confidence: string, transmission_description: string, trim: string, trim_confidence: string, updated_at: int, updated_at_date: string, version: string, version_confidence: string, vin: string, weight: float, width: float, year: int>
# operationId: decodeViaNeoVIN
export def "decode-via-neo-vin" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --include-generic: oneof<nothing, bool> # Boolean variable to indicate wheather to include generic data as well in response (default: false)
  --force-decode: oneof<nothing, bool> # Decode VIN on the fly instead of cached response (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/decode/car/neovin/{vin}/specs"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}, {name: include_generic, var: include_generic}, {name: force_decode, var: force_decode}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key, include_generic: $include_generic, force_decode: $force_decode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# VIN Decoder
#
# GET /decode/car/{vin}/specs
# Returns: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>
# operationId: decode
export def "get-decode-car-vin-specs" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/decode/car/{vin}/specs"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a cars online listing history
#
# GET /history/car/uk/{vrm}
# Returns: table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string>
export def "get-history-car-uk-vrm" [
  vrm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --include-duplicates: oneof<nothing, bool> # Flag to indicate whether to include duplicate historical records as well in the response
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/car/uk/{vrm}"
    path_params: [{name: vrm, var: vrm}]
    query: [{name: api_key, var: api_key}, {name: page, var: page}, {name: include_duplicates, var: include_duplicates}, {name: sort_order, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vrm: $vrm, api_key: $api_key, page: $page, include_duplicates: $include_duplicates, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a cars online listing history
#
# GET /history/car/{vin}
# Returns: table<carfax_1_owner: bool, carfax_clean_title: bool, city: string, data_source: string, dealer_id: int, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list<record>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, is_searchable: string, last_seen_at: int, last_seen_at_date: string, latitude: string, leasing_options: list<record>, longitude: string, miles: int, msrp: int, price: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: int, scraped_at_date: string, seller_name: string, seller_name_o: string, seller_type: string, source: string, state: string, status_date: int, stock_no: string, street: string, trim_r: string, vdp_url: string, vin: string, zip: string>
# operationId: getCarHistory
export def "get-car-history" [
  vin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --fields: string # List of fields to fetch, in case the default fields list in the response is to be trimmed down (format: string)
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --include-duplicates: oneof<nothing, bool> # Flag to indicate whether to include duplicate historical records as well in the response
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/history/car/{vin}"
    path_params: [{name: vin, var: vin}]
    query: [{name: api_key, var: api_key}, {name: fields, var: fields}, {name: page, var: page}, {name: include_duplicates, var: include_duplicates}, {name: sort_order, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    vin: $vin, api_key: $api_key, fields: $fields, page: $page, include_duplicates: $include_duplicates, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch cached image
#
# GET /image/cache/car/{listingID}/{imageID}
# Returns: binary
# operationId: getCachedImage
export def "get-cached-image" [
  listing_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> any {
  http-request {
    method: get
    path: "/image/cache/car/{listingID}/{imageID}"
    path_params: [{name: listingID, var: listing_id}, {name: imageID, var: image_id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    listing_id: $listing_id, image_id: $image_id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing by id
#
# GET /listing/car/auction/{id}
# Returns: record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>
export def "get-listing-car-auction-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/auction/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: include_relevant_links, var: include_relevant_links}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key, include_relevant_links: $include_relevant_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/auction/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-car-auction-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/auction/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/car/auction/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-car-auction-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/auction/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing by id
#
# GET /listing/car/fsbo/{id}
# Returns: record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>
export def "get-listing-car-fsbo-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/fsbo/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: include_relevant_links, var: include_relevant_links}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key, include_relevant_links: $include_relevant_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/fsbo/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-car-fsbo-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/fsbo/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/car/fsbo/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-car-fsbo-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/fsbo/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing by id
#
# GET /listing/car/uk/{id}
# Returns: record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>
export def "get-listing-car-uk-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/uk/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/uk/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-car-uk-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/uk/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/car/uk/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-car-uk-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/uk/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing by id
#
# GET /listing/car/{id}
# Returns: record<base_ext_color: string, base_int_color: string, build: record<antibrake_sys: string, body_subtype: string, body_type: string, city_miles: string, city_mpg: int, cylinders: int, doors: int, drivetrain: string, engine: string, engine_aspiration: string, engine_block: string, engine_measure: string, engine_size: float, fuel_type: string, highway_miles: string, highway_mpg: int, made_in: string, make: string, model: string, opt_seating: string, overall_height: string, overall_length: string, overall_width: string, powertrain_type: string, short_trim: string, std_seating: string, steering_type: string, tank_size: string, transmission: string, trim: string, trim_r: string, vehicle_type: string, year: int>, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dom: int, dom_180: int, dom_active: int, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, financing_options: table<down_payment: float, down_payment_percentage: float, estimated_monthly_payment: float, loan_apr: float, loan_term: int>, first_seen_at: int, first_seen_at_date: string, first_seen_at_mc: int, first_seen_at_mc_date: string, first_seen_at_source: int, first_seen_at_source_date: string, heading: string, id: string, interior_color: string, inventory_type: string, is_certified: int, last_seen_at: int, last_seen_at_date: string, leasing_options: table<down_payment: float, estimated_monthly_payment: float, lease_term: int>, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, price_change_percent: float, rank: int, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, score: float, scraped_at: int, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vehicle_registration_mark: string, vin: string>
# operationId: getListing
export def "get-listing" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: include_relevant_links, var: include_relevant_links}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key, include_relevant_links: $include_relevant_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Listings attributes for Listing with the given id
#
# GET /listing/car/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-car-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/car/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-car-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/car/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key, append_api_key: $append_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Heavy equipment listing by id
#
# GET /listing/heavy-equipment/{id}
# Returns: record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>
export def "get-listing-heavy-equipment-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/heavy-equipment/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Heavy equipment Listings attributes for Listing with the given id
#
# GET /listing/heavy-equipment/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-heavy-equipment-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/heavy-equipment/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/heavy-equipment/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-heavy-equipment-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/heavy-equipment/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Motorcycle listing by id
#
# GET /listing/motorcycle/{id}
# Returns: record<build: record<body_type: string, cylinders: int, drivetrain: string, dry_weight: string, engine: string, fuel_type: string, made_in: string, make: string, model: string, transmission: string, trim: string, vehicle_type: string, year: int>, color: string, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>
export def "get-listing-motorcycle-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/motorcycle/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text Motorcycle Listings attributes for Listing with the given id
#
# GET /listing/motorcycle/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-motorcycle-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/motorcycle/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Motorcycle listing media by id
#
# GET /listing/motorcycle/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-motorcycle-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/motorcycle/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RV listing by id
#
# GET /listing/rv/uk/{id}
# Returns: record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>
export def "get-listing-rv-uk-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/uk/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text RV Listings attributes for Listing with the given id
#
# GET /listing/rv/uk/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-rv-uk-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/uk/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/rv/uk/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-rv-uk-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/uk/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RV listing by id
#
# GET /listing/rv/{id}
# Returns: record<build: record<area: string, class: string, engine: string, fuel_type: string, gvwr: string, length: string, made_in: string, make: string, model: string, sleeps: string, slideouts: string, transmission: string, year: int>, dealer: record<city: string, country: string, county: string, dealer_type: string, dealership_group_name: string, id: int, latitude: string, longitude: string, msa_code: string, name: string, phone: string, seller_email: string, state: string, street: string, website: string, zip: string>, dp_url: string, exterior_color: string, extra: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_comments: string, standard_f: list<string>, technical_f: list<string>>, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record<photo_links: list<string>, photo_links_cached: list<string>>, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>
export def "get-listing-rv-id" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Long text RV Listings attributes for Listing with the given id
#
# GET /listing/rv/{id}/extra
# Returns: record<dealer_added_f: list<string>, electronics_f: list<string>, exterior_f: list<string>, features: list<string>, id: string, interior_f: list<string>, options: list<string>, safety_f: list<string>, seller_cmts: string, standard_f: list<string>, technical_f: list<string>>
export def "get-listing-rv-id-extra" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/{id}/extra"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing media by id
#
# GET /listing/rv/{id}/media
# Returns: record<id: string, photo_links: list<string>, photo_url: string>
export def "get-listing-rv-id-media" [
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
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listing/rv/{id}/media"
    path_params: [{name: id, var: id}]
    query: [{name: api_key, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Market Days Supply
#
# GET /mds/car
# Returns: record<make: string, mds: int, model: string, sold_vins: list<string>, total_active_cars_for_ymmt: int, total_cars_sold_in_last_45_days: int, trim: string, year: int>
# operationId: getMDS
export def "get-mds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vin: string # VIN to decode (format: string)
  --exact: oneof<nothing, bool> # Exact parameter (default: false)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --debug: oneof<nothing, bool> # Debug parameter (default: false)
  --include-sold: oneof<nothing, bool> # To fetch sold vins (default: false)
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mds/car"
    query: [{name: api_key, var: api_key}, {name: vin, var: vin}, {name: exact, var: exact}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: msa_code, var: msa_code}, {name: debug, var: debug}, {name: include_sold, var: include_sold}, {name: country, var: country}, {name: state, var: state}, {name: city, var: city}, {name: ymmt, var: ymmt}, {name: car_type, var: car_type}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: dealer_id, var: dealer_id}, {name: source, var: source}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: dealership_group_name, var: dealership_group_name}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: engine_size_range, var: engine_size_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, vin: $vin, exact: $exact, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, msa_code: $msa_code, debug: $debug, include_sold: $include_sold, country: $country, state: $state, city: $city, ymmt: $ymmt, car_type: $car_type, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year: $year, make: $make, model: $model, trim: $trim, dealer_id: $dealer_id, source: $source, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, dealership_group_name: $dealership_group_name, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, fuel_type: $fuel_type, dealer_type: $dealer_type, engine_size_range: $engine_size_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get make model wise top 50 popular cars on national, state, city level
#
# GET /popular/cars
# Returns: record<new_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>, used_top50: table<city: string, counts: string, dom_stats: record, inventoryType: string, make: string, miles_stats: record, model: string, price_stats: record, state: string>>
# operationId: getPopularCars
export def "get-popular-cars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --state: string # State level sales count (format: string)
  --city-state: string # City level sales count, pipe seperated like city_state=jacksonville|FL (format: string)
  --car-type: string@car-type-completer-1 # Inventory type for which popular count is to be searched (required, format: string)
  --country: string@country-completer-3 # Country for which the popular cars are to be searched (default: us)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/popular/cars"
    query: [{name: api_key, var: api_key}, {name: state, var: state}, {name: city_state, var: city_state}, {name: car_type, var: car_type, required: true}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, state: $state, city_state: $city_state, car_type: $car_type, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Predict car price based on it's specifications
#
# GET /predict/car/price
# Returns: record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>>
# operationId: predictCarPrice
export def "predict-car-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vin: string # Predict price for a VIN
  --car-type: string@car-type-completer-1 # Car condition (required)
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --trim: string # Car's trim
  --is-certified: oneof<nothing, bool> # Boolean to indicate car is certified or not
  --carfax-1-owner: oneof<nothing, bool> # Boolean to indicate car is carfax one owner or not
  --carfax-clean-title: oneof<nothing, bool> # Boolean to indicate car has clean title or not
  --base-exterior-color: string # Base exterior color of the car
  --base-interior-color: string # Base interior color of the car
  --transmission: string@transmission-completer # Transmission on the car
  --drivetrain: string@drivetrain-completer # Drivetrain on the car
  --engine-size: float # Engine Size of the car
  --engine-block: string@engine-block-completer # Engine Block of the car
  --cylinders: int # Number of cylinders in the vehicle
  --doors: int # Number of doors in the vehicle
  --highway-mpg: int # Highway mileage
  --city-mpg: int # City mileage of the car
  --latitude: float # Latitude component of the location
  --longitude: float # Longitude component of the location
  --miles: int # miles vehicle has driven in total
  --zip: string # Location zip
  --country: string@country-completer-4 # Country for which car price will be predicted (default: us)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/predict/car/price"
    query: [{name: api_key, var: api_key}, {name: vin, var: vin}, {name: car_type, var: car_type, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: is_certified, var: is_certified}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: engine_size, var: engine_size}, {name: engine_block, var: engine_block}, {name: cylinders, var: cylinders}, {name: doors, var: doors}, {name: highway_mpg, var: highway_mpg}, {name: city_mpg, var: city_mpg}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: miles, var: miles}, {name: zip, var: zip}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, vin: $vin, car_type: $car_type, year: $year, make: $make, model: $model, trim: $trim, is_certified: $is_certified, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, transmission: $transmission, drivetrain: $drivetrain, engine_size: $engine_size, engine_block: $engine_block, cylinders: $cylinders, doors: $doors, highway_mpg: $highway_mpg, city_mpg: $city_mpg, latitude: $latitude, longitude: $longitude, miles: $miles, zip: $zip, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Predict fare value of car for UK based on YMMT & miles
#
# GET /predict/car/uk/fmv
# Returns: record<avg_days_to_sold_local: int, avg_days_to_sold_national: int, fmv_local: int, fmv_national: int>
# operationId: fareValue
export def "fare-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vrm: string # Predict price for a VRM
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --variant: string # Car's variant
  --miles: int # miles vehicle has driven in total
  --postal-code: string # Postal code of the car
  --radius: int # Radius around postal code
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/predict/car/uk/fmv"
    query: [{name: api_key, var: api_key}, {name: vrm, var: vrm}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: variant, var: variant}, {name: miles, var: miles}, {name: postal_code, var: postal_code}, {name: radius, var: radius}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, vrm: $vrm, year: $year, make: $make, model: $model, variant: $variant, miles: $miles, postal_code: $postal_code, radius: $radius
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Predict car price for UK based on it's specifications
#
# GET /predict/car/uk/price
# Returns: record<predicted_price: int, price_range: record<lower_bound: int, upper_bound: int>, specs: record<base_exterior_color: string, base_interior_color: string, carfax_1_owner: bool, carfax_clean_title: bool, city_mpg: float, cylinders: int, doors: int, drivetrain: string, engine_block: string, engine_size: float, highway_mpg: float, is_certified: bool, latitude: float, longitude: float, make: string, miles: int, model: string, transmission: string, trim: string, year: int>>
# operationId: predictUkCarPrice
export def "predict-uk-car-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --vrm: string # Predict price for a VRM
  --year: int # Car manufacturing year
  --make: string # Car's make
  --model: string # Car's model
  --trim: string # Car's trim
  --base-exterior-color: string # Base exterior color of the car
  --transmission: string@transmission-completer # Transmission on the car
  --drivetrain: string # Drivetrain on the car
  --engine-size: float # Engine Size of the car (format: double)
  --cylinders: int # Number of cylinders in the vehicle
  --doors: int # Number of doors in the vehicle
  --fuel-type: string # Fuel type of the car
  --highway-mpg: float # Highway mileage (format: double)
  --city-mpg: float # City mileage of the car (format: double)
  --combined-mpg: float # Combiined mileage of the car (format: double)
  --latitude: float # Latitude component of the location
  --longitude: float # Longitude component of the location
  --miles: int # miles vehicle has driven in total
  --zip: string # Location zip
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/predict/car/uk/price"
    query: [{name: api_key, var: api_key}, {name: vrm, var: vrm}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: base_exterior_color, var: base_exterior_color}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: engine_size, var: engine_size}, {name: cylinders, var: cylinders}, {name: doors, var: doors}, {name: fuel_type, var: fuel_type}, {name: highway_mpg, var: highway_mpg}, {name: city_mpg, var: city_mpg}, {name: combined_mpg, var: combined_mpg}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: miles, var: miles}, {name: zip, var: zip}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, vrm: $vrm, year: $year, make: $make, model: $model, trim: $trim, base_exterior_color: $base_exterior_color, transmission: $transmission, drivetrain: $drivetrain, engine_size: $engine_size, cylinders: $cylinders, doors: $doors, fuel_type: $fuel_type, highway_mpg: $highway_mpg, city_mpg: $city_mpg, combined_mpg: $combined_mpg, latitude: $latitude, longitude: $longitude, miles: $miles, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sales count by make, model, year, trim or taxonomy vin
#
# GET /sales/car
# Returns: record<city: string, counts: int, cpo: int, dom_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, inventory_type: string, make: string, miles_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, model: string, non-cpo: int, price_stats: record<absolute_mean_deviation: float, iqr: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float, weighted_mean: float>, state: string, taxonomy_vin: string, trim: string, year: string>
# operationId: getSalesCount
export def "get-sales-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --car-type: string@car-type-completer-1 # Inventory type for which sales count is to be searched, default is used (format: string, default: used)
  --make: string # Make for which sales count is to be searched (format: string)
  --mm: string # Make-Model for which sales count is to be searched, pipe seperated like mm=ford|f-150 (format: string)
  --ymm: string # Year-Make-Model for which sales count is to be searched, pipe seperated like ymm=2015|ford|f-150 (format: string)
  --ymmt: string # Year-Make-Model-Trim for which sales count is to be searched, pipe seperated like ymmt=2015|ford|f-150|platinum (format: string)
  --taxonomy-vin: string # taxonomy_vin for which sales count is to be searched (format: string)
  --state: string # State level sales count (format: string)
  --city-state: string # City level sales count, pipe seperated like city_state=jacksonville|FL (format: string)
  --vin: string # VIN that will be transformed to taxonomy_vin (format: string)
  --country: string@country-completer-3 # Country for which the sales records are to be searched (default: us)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sales/car"
    query: [{name: api_key, var: api_key}, {name: car_type, var: car_type}, {name: make, var: make}, {name: mm, var: mm}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: taxonomy_vin, var: taxonomy_vin}, {name: state, var: state}, {name: city_state, var: city_state}, {name: vin, var: vin}, {name: country, var: country}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, car_type: $car_type, make: $make, mm: $mm, ymm: $ymm, ymmt: $ymmt, taxonomy_vin: $taxonomy_vin, state: $state, city_state: $city_state, vin: $vin, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active car listings for the given search criteria
#
# GET /search/car/active
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-search-car-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --source: string # To filter listing on their source only for widget requests
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --price-change: string@price-change-completer # Query to filter listings based on their positive and negative price change
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --high-value-features: string # To filter listings on their high_value_features. Results will be intersection of provided HVFs
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/active"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: mm, var: mm}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: source, var: source}, {name: state, var: state}, {name: city, var: city}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: include_relevant_links, var: include_relevant_links}, {name: inventory_count_range, var: inventory_count_range}, {name: dealer_id, var: dealer_id}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: in_transit, var: in_transit}, {name: seating_capacity, var: seating_capacity}, {name: powertrain_type, var: powertrain_type}, {name: price_change, var: price_change}, {name: price_change_range, var: price_change_range}, {name: active_inventory_date_range, var: active_inventory_date_range}, {name: engine_size_range, var: engine_size_range}, {name: high_value_features, var: high_value_features}, {name: min_photo_links, var: min_photo_links}, {name: min_photo_links_cached, var: min_photo_links_cached}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, mm: $mm, ymm: $ymm, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, source: $source, state: $state, city: $city, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, include_relevant_links: $include_relevant_links, inventory_count_range: $inventory_count_range, dealer_id: $dealer_id, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, in_transit: $in_transit, seating_capacity: $seating_capacity, powertrain_type: $powertrain_type, price_change: $price_change, price_change_range: $price_change_range, active_inventory_date_range: $active_inventory_date_range, engine_size_range: $engine_size_range, high_value_features: $high_value_features, min_photo_links: $min_photo_links, min_photo_links_cached: $min_photo_links_cached
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute relative rank for car listings.
#
# POST /search/car/active/rank
# Returns: record<num_ranked: int, ranked_listings: table<ranked_listing: record>>
# operationId: searchAndRankCar
export def "search-and-rank-car" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string, default: 1-)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string, default: 1-)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --page: float # Page number to fetch the results for the given criteria. Default is 1. (format: number)
  --listing-ids: list<string>
  --ranking-criteria: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/car/active/rank"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: inventory_type, var: inventory_type}, {name: page, var: page}]
    body: {content_type: "application/json", kind: json, fields: [{name: listing_ids, var: listing_ids}, {name: ranking_criteria, var: ranking_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, inventory_type: $inventory_type, page: $page, listing_ids: $listing_ids, ranking_criteria: $ranking_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute relative rank for car listings.
#
# POST /search/car/active/rank/listings
# Returns: record<num_ranked: int, ranked_listings: table<ranked_listing: record>>
# operationId: rankCar
export def "rank-car" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --listing-ids: list<string>
  --ranking-criteria: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/search/car/active/rank/listings"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: listing_ids, var: listing_ids}, {name: ranking_criteria, var: ranking_criteria}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, listing_ids: $listing_ids, ranking_criteria: $ranking_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active auction car listings for the given search criteria
#
# GET /search/car/auction/active
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-search-car-auction-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --title-type: string@title-type-completer # To filter on title type
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/auction/active"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: mm, var: mm}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: source, var: source}, {name: dealer_id, var: dealer_id}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: include_relevant_links, var: include_relevant_links}, {name: inventory_count_range, var: inventory_count_range}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: in_transit, var: in_transit}, {name: title_type, var: title_type}, {name: seating_capacity, var: seating_capacity}, {name: engine_size_range, var: engine_size_range}, {name: min_photo_links, var: min_photo_links}, {name: min_photo_links_cached, var: min_photo_links_cached}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, mm: $mm, ymm: $ymm, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, source: $source, dealer_id: $dealer_id, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, include_relevant_links: $include_relevant_links, inventory_count_range: $inventory_count_range, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, in_transit: $in_transit, title_type: $title_type, seating_capacity: $seating_capacity, engine_size_range: $engine_size_range, min_photo_links: $min_photo_links, min_photo_links_cached: $min_photo_links_cached
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for auto-completion of inputs
#
# GET /search/car/auto-complete
# Returns: record<terms: table<count: int, item: string>>
# operationId: autoComplete
export def "auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer # Field name for which you want auto-completion (required, format: string)
  --input: string # Input entered so far (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --car-type: string@car-type-completer-1 # Car type. Allowed values are - new / used
  --include-non-vin-listings: string@include-non-vin-listings-completer # Flag to indicate whether to include non vin listing terms in results or not. Default is false to avoid un-normalised terms from non vin listings out of results (default: false)
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/auto-complete"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: input, var: input, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_block, var: engine_block}, {name: state, var: state}, {name: city, var: city}, {name: source, var: source}, {name: dealer_id, var: dealer_id}, {name: country, var: country}, {name: car_type, var: car_type}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: ignore_case, var: ignore_case}, {name: term_counts, var: term_counts}, {name: sort_by, var: sort_by}, {name: seller_type, var: seller_type}, {name: radius, var: radius}, {name: zip, var: zip}, {name: inventory_count_range, var: inventory_count_range}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: in_transit, var: in_transit}, {name: facet_min_count, var: facet_min_count}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, input: $input, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, exterior_color: $exterior_color, interior_color: $interior_color, engine: $engine, engine_size: $engine_size, engine_block: $engine_block, state: $state, city: $city, source: $source, dealer_id: $dealer_id, country: $country, car_type: $car_type, include_non_vin_listings: $include_non_vin_listings, ignore_case: $ignore_case, term_counts: $term_counts, sort_by: $sort_by, seller_type: $seller_type, radius: $radius, zip: $zip, inventory_count_range: $inventory_count_range, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, in_transit: $in_transit, facet_min_count: $facet_min_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active private party car listings for the given search criteria
#
# GET /search/car/fsbo/active
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-search-car-fsbo-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --mm: string # Make-Model concatenated string. To help passing the results of auto-complete API on mm field, use this parameter and pass in the selected value as is
  --ymm: string # Year-Make-Model concatenated string. To help passing the results of auto-complete API on ymm field, use this parameter and pass in the selected value as is
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --exclude-dealer-listings: oneof<nothing, bool> # A list of fsbo listings to exclude from result
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/fsbo/active"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: mm, var: mm}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: source, var: source}, {name: dealer_id, var: dealer_id}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: include_relevant_links, var: include_relevant_links}, {name: inventory_count_range, var: inventory_count_range}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: exclude_dealer_listings, var: exclude_dealer_listings}, {name: in_transit, var: in_transit}, {name: seating_capacity, var: seating_capacity}, {name: engine_size_range, var: engine_size_range}, {name: min_photo_links, var: min_photo_links}, {name: min_photo_links_cached, var: min_photo_links_cached}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, mm: $mm, ymm: $ymm, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, source: $source, dealer_id: $dealer_id, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, include_relevant_links: $include_relevant_links, inventory_count_range: $inventory_count_range, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, exclude_dealer_listings: $exclude_dealer_listings, in_transit: $in_transit, seating_capacity: $seating_capacity, engine_size_range: $engine_size_range, min_photo_links: $min_photo_links, min_photo_links_cached: $min_photo_links_cached
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets oem incentive listings for the given search criteria
#
# GET /search/car/incentive/oem
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
# operationId: oemSearch
export def "oem-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --offer-type: string@offer-type-completer # The type of the incentive
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --msrp: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --apr: string # APR range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --monthly: string # To filter listing on Monthly payment amount, usually populated in Lease offers
  --monthly-per-thousand: string # To filter listing on monthly amount to be paid by customer for every $1000 financed at the advertised APR rate
  --down-payment: string # To filter listing on down payment offer on car
  --due-at-signing: string # To filter listing on total amount due at signing, that usually includes first month payment, down payment, acquisition fee etc
  --security-deposit: string # To filter listing on security deposit required for the offer
  --disposition-fee: string # To filter listing on disposition fee of the car
  --acquisition-fee: string # To filter listing on acquisition fee of the car
  --duration: string # To filter listing on offer duration in months
  --dealer-contribution: string # To filter listing on any contribution from dealer's side
  --mileage-charge: string # Mileage Charge Range range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 100-1000 (format: string)
  --mileage-charge-limit: string # To filter listing on mileage charge limit the offer is valid up to under the default clauses
  --cashback-amount: string # To filter listing on cashback amounts listed in offer
  --cashback-target-group: string # To filter listing on the demographic or any other entity for whom this cashback offer is for. Not all target groups are identified but the most common ones are tagged like Military, Grad students Current owners etc
  --lease-end-purchase-option: string # To filter listing on amount at the lease end to pay for buying the car
  --net-capitalised-cost: string # To filter listing on net capitalised cost of the car
  --gross-capitalised-cost: string # To filter listing on gross capitalised cost of the car
  --total-monthly-payment: string # To filter listing on gross capitalised cost of the car
  --zip: string # To filter listing on ZIP around which they are listed
  --city: string # To filter listing on City in which they are listed
  --state: string # To filter listing on State in which they are listed
  --country: string@country-completer-3 # To filter listing on Country in which they are listed (default: US)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/incentive/oem"
    query: [{name: api_key, var: api_key}, {name: offer_type, var: offer_type}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: msrp, var: msrp}, {name: apr, var: apr}, {name: monthly, var: monthly}, {name: monthly_per_thousand, var: monthly_per_thousand}, {name: down_payment, var: down_payment}, {name: due_at_signing, var: due_at_signing}, {name: security_deposit, var: security_deposit}, {name: disposition_fee, var: disposition_fee}, {name: acquisition_fee, var: acquisition_fee}, {name: duration, var: duration}, {name: dealer_contribution, var: dealer_contribution}, {name: mileage_charge, var: mileage_charge}, {name: mileage_charge_limit, var: mileage_charge_limit}, {name: cashback_amount, var: cashback_amount}, {name: cashback_target_group, var: cashback_target_group}, {name: lease_end_purchase_option, var: lease_end_purchase_option}, {name: net_capitalised_cost, var: net_capitalised_cost}, {name: gross_capitalised_cost, var: gross_capitalised_cost}, {name: total_monthly_payment, var: total_monthly_payment}, {name: zip, var: zip}, {name: city, var: city}, {name: state, var: state}, {name: country, var: country}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: search_text, var: search_text}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, offer_type: $offer_type, year: $year, make: $make, model: $model, trim: $trim, msrp: $msrp, apr: $apr, monthly: $monthly, monthly_per_thousand: $monthly_per_thousand, down_payment: $down_payment, due_at_signing: $due_at_signing, security_deposit: $security_deposit, disposition_fee: $disposition_fee, acquisition_fee: $acquisition_fee, duration: $duration, dealer_contribution: $dealer_contribution, mileage_charge: $mileage_charge, mileage_charge_limit: $mileage_charge_limit, cashback_amount: $cashback_amount, cashback_target_group: $cashback_target_group, lease_end_purchase_option: $lease_end_purchase_option, net_capitalised_cost: $net_capitalised_cost, gross_capitalised_cost: $gross_capitalised_cost, total_monthly_payment: $total_monthly_payment, zip: $zip, city: $city, state: $state, country: $country, latitude: $latitude, longitude: $longitude, radius: $radius, search_text: $search_text, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Recent car listings for the given search criteria
#
# GET /search/car/recents
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fuel_type: list<record>, interior_color: list<record>, make: list<record>, model: list<record>, seller_name: list<record>, seller_name_o: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, trim_o: list<record>, trim_r: list<record>, vehicle_type: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, carfax_1_owner: bool, carfax_clean_title: bool, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, vdp_url: string, vin: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-search-car-recents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer # To filter listing on Country in which they are listed (default: US)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --sold: oneof<nothing, bool> # sold parameter to fetch only sold listings
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --expired: string@expired-completer # Boolean falg to either fetch only the expired listings or active ones
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/recents"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: dealer_id, var: dealer_id}, {name: vin, var: vin}, {name: source, var: source}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: msa_code, var: msa_code}, {name: dealer_name, var: dealer_name}, {name: dealership_group_name, var: dealership_group_name}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: sold, var: sold}, {name: include_relevant_links, var: include_relevant_links}, {name: expired, var: expired}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: in_transit, var: in_transit}, {name: seating_capacity, var: seating_capacity}, {name: active_inventory_date_range, var: active_inventory_date_range}, {name: engine_size_range, var: engine_size_range}, {name: price_change_range, var: price_change_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, dealer_id: $dealer_id, vin: $vin, source: $source, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, msa_code: $msa_code, dealer_name: $dealer_name, dealership_group_name: $dealership_group_name, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, sold: $sold, include_relevant_links: $include_relevant_links, expired: $expired, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, in_transit: $in_transit, seating_capacity: $seating_capacity, active_inventory_date_range: $active_inventory_date_range, engine_size_range: $engine_size_range, price_change_range: $price_change_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active car listings in UK for the given search criteria
#
# GET /search/car/uk/active
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
# operationId: search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --postal-code: string # To filter listing on postal code around which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --car-type: string@car-type-completer-1 # Car type. Allowed values are - new / used
  --year: string # To filter listing on their year
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --variant: string # To filter listing on their variant
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --body-type: string # To filter listing on their body type
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --msa-code: string # To filter listing on msa code in which they are listed
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer-5 # To filter listing on Country in which they are listed (default: uk)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --county: string # To filter listing on county in which they are listed
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --fuel-type: string # To filter listing on their fuel type
  --stock-no: string # To filter listing on their stock number on lot
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --co2-emissions: string # CO2 emissions
  --insurance-group: string # Insurance Group
  --vehicle-registration-mark: string # Vehicle Registration Mark
  --vehicle-registration-date-range: string # Vehicle registration date range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --num-owners: string # Number of owners. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --inventory-count-range: string # Inventory count range to filter listings with count of total listings in dealers inventory. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --source: string # To filter listing on their source only for widget requests
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --cylinders: string # To filter listing on their cylinders
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --write-off-category: string # write off category (format: string)
  --exclude-write-off-category: string # To exclude write off category (format: string)
  --fca-status: string # To filter on fca status (format: string)
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --vrm: string # To filter on vrm (format: string)
  --powertrain-type: string # To filter on powertrain_type (format: string)
  --client-filters: oneof<nothing, bool> # Flag to add explicit filters set on client level in solr (default: true)
  --boost: oneof<nothing, bool> # Flag to sort listings based on client filter score in solr (default: true)
  --car-location-seller-name: string # Filter cars on seller name
  --car-location-street: string # Filter cars on street name
  --car-location-city: string # Filter cars on city
  --car-location-county: string # Filter cars on county
  --car-location-zip: string # To filter listing on car ZIP around which they are listed
  --car-location-latitude: float # Latitude component of car location (format: double)
  --car-location-longitude: float # Longitude component of car location (format: double)
  --price-change: string@price-change-completer # Query to filter listings based on their positive and negative price change
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --uvc-id: string # To filter on uvc id (format: string)
  --highway-mpg-range: string # Highway mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --combined-mpg-range: string # Combined mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --min-photo-links: string # Filter listings based by number of photo links within given range (format: string)
  --min-photo-links-cached: string # Filter listings based by number of cached photo links within given range (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/uk/active"
    query: [{name: api_key, var: api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: postal_code, var: postal_code}, {name: zip, var: zip}, {name: car_type, var: car_type}, {name: year, var: year}, {name: year_range, var: year_range}, {name: make, var: make}, {name: model, var: model}, {name: variant, var: variant}, {name: trim, var: trim}, {name: vin, var: vin}, {name: body_type, var: body_type}, {name: ymmt, var: ymmt}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: engine, var: engine}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: msa_code, var: msa_code}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: county, var: county}, {name: state, var: state}, {name: city, var: city}, {name: fuel_type, var: fuel_type}, {name: stock_no, var: stock_no}, {name: dom_range, var: dom_range}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: co2_emissions, var: co2_emissions}, {name: insurance_group, var: insurance_group}, {name: vehicle_registration_mark, var: vehicle_registration_mark}, {name: vehicle_registration_date_range, var: vehicle_registration_date_range}, {name: num_owners, var: num_owners}, {name: inventory_count_range, var: inventory_count_range}, {name: source, var: source}, {name: dealer_id, var: dealer_id}, {name: exclude_sources, var: exclude_sources}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: in_transit, var: in_transit}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: cylinders, var: cylinders}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: write_off_category, var: write_off_category}, {name: exclude_write_off_category, var: exclude_write_off_category}, {name: fca_status, var: fca_status}, {name: seating_capacity, var: seating_capacity}, {name: vrm, var: vrm}, {name: powertrain_type, var: powertrain_type}, {name: client_filters, var: client_filters}, {name: boost, var: boost}, {name: car_location_seller_name, var: car_location_seller_name}, {name: car_location_street, var: car_location_street}, {name: car_location_city, var: car_location_city}, {name: car_location_county, var: car_location_county}, {name: car_location_zip, var: car_location_zip}, {name: car_location_latitude, var: car_location_latitude}, {name: car_location_longitude, var: car_location_longitude}, {name: price_change, var: price_change}, {name: price_change_range, var: price_change_range}, {name: active_inventory_date_range, var: active_inventory_date_range}, {name: engine_size, var: engine_size}, {name: engine_size_range, var: engine_size_range}, {name: uvc_id, var: uvc_id}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: combined_mpg_range, var: combined_mpg_range}, {name: owned, var: owned}, {name: min_photo_links, var: min_photo_links}, {name: min_photo_links_cached, var: min_photo_links_cached}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, latitude: $latitude, longitude: $longitude, radius: $radius, postal_code: $postal_code, zip: $zip, car_type: $car_type, year: $year, year_range: $year_range, make: $make, model: $model, variant: $variant, trim: $trim, vin: $vin, body_type: $body_type, ymmt: $ymmt, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, engine: $engine, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, msa_code: $msa_code, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, county: $county, state: $state, city: $city, fuel_type: $fuel_type, stock_no: $stock_no, dom_range: $dom_range, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, co2_emissions: $co2_emissions, insurance_group: $insurance_group, vehicle_registration_mark: $vehicle_registration_mark, vehicle_registration_date_range: $vehicle_registration_date_range, num_owners: $num_owners, inventory_count_range: $inventory_count_range, source: $source, dealer_id: $dealer_id, exclude_sources: $exclude_sources, exclude_dealer_ids: $exclude_dealer_ids, in_transit: $in_transit, include_non_vin_listings: $include_non_vin_listings, cylinders: $cylinders, photo_links: $photo_links, photo_links_cached: $photo_links_cached, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, write_off_category: $write_off_category, exclude_write_off_category: $exclude_write_off_category, fca_status: $fca_status, seating_capacity: $seating_capacity, vrm: $vrm, powertrain_type: $powertrain_type, client_filters: $client_filters, boost: $boost, car_location_seller_name: $car_location_seller_name, car_location_street: $car_location_street, car_location_city: $car_location_city, car_location_county: $car_location_county, car_location_zip: $car_location_zip, car_location_latitude: $car_location_latitude, car_location_longitude: $car_location_longitude, price_change: $price_change, price_change_range: $price_change_range, active_inventory_date_range: $active_inventory_date_range, engine_size: $engine_size, engine_size_range: $engine_size_range, uvc_id: $uvc_id, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, combined_mpg_range: $combined_mpg_range, owned: $owned, min_photo_links: $min_photo_links, min_photo_links_cached: $min_photo_links_cached
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Recent UK car listings for the given search criteria
#
# GET /search/car/uk/recents
# Returns: record<facets: record<base_exterior_color: list<record>, base_interior_color: list<record>, body_subtype: list<record>, body_type: list<record>, car_location_city: list<record>, car_location_county: list<record>, car_location_seller_name: list<record>, car_location_street: list<record>, car_location_zip: list<record>, car_type: list<record>, carfax_1_owner: list<record>, carfax_clean_title: list<record>, city: list<record>, co2_emissions: list<record>, cylinders: list<record>, data_source: list<record>, dealer_id: list<record>, dealer_type: list<record>, dealership_group_name: list<record>, doors: list<record>, drivetrain: list<record>, engine: list<record>, engine_aspiration: list<record>, engine_block: list<record>, engine_size: list<record>, exterior_color: list<record>, fca_status: list<record>, fuel_type: list<record>, in_transit: list<record>, insurance_group: list<record>, interior_color: list<record>, make: list<record>, mas_code: list<record>, model: list<record>, num_owners: list<record>, powertrain_type: list<record>, seating_capacity: list<record>, seller_name: list<record>, seller_type: list<record>, source: list<record>, state: list<record>, transmission: list<record>, trim: list<record>, vehicle_registration_mark: list<record>, vehicle_type: list<record>, vrm: list<record>, year: list<record>>, listings: table<base_ext_color: string, base_int_color: string, build: record, car_location: record, carfax_1_owner: bool, carfax_clean_title: bool, co2_emissions: string, data_source: string, dealer: record, dist: float, dom: int, dom_180: int, dom_active: int, exterior_color: string, financing_options: list, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, in_transit: bool, insurance_group: string, interior_color: string, inventory_type: string, is_certified: int, is_translated: bool, last_seen_at: int, last_seen_at_date: string, leasing_options: list, media: record, miles: int, model_code: string, msrp: int, num_owners: string, price: int, price_change_percent: float, ref_miles: string, ref_miles_dt: int, ref_price: string, ref_price_dt: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, title_type: string, uvc_id: string, vdp_url: string, vehicle_registration_mark: string>, num_found: int, range_facets: record<dom: record, dom_180: record, dom_active: record, finance_down_payment: record, finance_emp: record, finance_loan_apr: record, finance_loan_term: record, lease_down_payment: record, lease_emp: record, lease_term: record, miles: record, msrp: record, price: record>, stats: record<dom: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_180: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, dom_active: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_down_payment_per: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_apr: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, finance_loan_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_down_payment: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_emp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, lease_term: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, miles: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, msrp: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>, price: record<count: int, max: int, mean: float, median: float, min: int, missing: int, stddev: float, sum: int, sum_of_squares: float>>>
export def "get-search-car-uk-recents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --append-api-key: oneof<nothing, bool> # Flag on whether to include api_key in response API urls (if any) (default: true)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --include-lease: oneof<nothing, bool> # Boolean param to search for listings that include leasing options in them
  --include-finance: oneof<nothing, bool> # Boolean param to search for listings that include finance options in them
  --lease-term: string # Search listings with exact lease term, or inside a range with min and max seperated by a dash like lease_term=30-60
  --lease-down-payment: string # Search listings with exact down payment in lease offers, or inside a range with min and max seperated by a dash like lease_down_payment=30-60
  --lease-emp: string # Search listings with lease offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like lease_emp=30-60
  --finance-loan-term: string # Search listings with exact finance loan term, or inside a range with min and max seperated by a dash like finance_loan_term=30-60
  --finance-loan-apr: string # Search listings with finance offers exactly matching loans Annual Percentage Rate, or inside a range with min and max seperated by a dash like finance_loan_apr=30-60
  --finance-emp: string # Search listings with finance offers exactly matching Estimated Monthly Payment(EMI), or inside a range with min and max seperated by a dash like finance_emp=30-60
  --finance-down-payment: string # Search listings with exact down payment in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment=30-60
  --finance-down-payment-per: string # Search listings with exact down payment percentage in finance offers, or inside a range with min and max seperated by a dash like finance_down_payment_per=30-60
  --car-type: string@car-type-completer # Car type. Allowed values are - new / used / certified
  --carfax-1-owner: string@carfax-1-owner-completer # Indicates whether car has had only one owner or not
  --carfax-clean-title: string@carfax-clean-title-completer # Indicates whether car has clean ownership records
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --vin: string # To filter listing on their VIN
  --source: string # To filter listing on their source
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --vins: string # Comma separated list of 17 digit vins to search the matching cars for. Only 10 VINs allowed per request. If the request contains more than 10 VINs the first 10 VINs will be considered. Could be used as a More Like This or Similar Vehicles search for the given VINs. Ths vins parameter is an alternative to taxonomy_vins or ymmt parameters available with the search API. vins and taxonomy_vins parameters could be used to filter our cars with the exact build represented by the vins or taxonomy_vins whereas ymmt is a top level filter that does not filter cars by the build attributes like doors, drivetrain, cylinders, body type, body subtype, vehicle type etc
  --taxonomy-vins: string # Comma separated list of 10 letters excert from the 17 letter VIN. The 10 letters to be picked up from the 17 letter VIN are - first 8 letters and the 10th and 11th letter. E.g. For a VIN - 1FTFW1EF3EKE57182 the taxonomy vin would be - 1FTFW1EFEK A taxonomy VIN identified a build of a car and could be used to filter our cars of a particular build. This is an alternative to the vin or ymmt parameters to the search API.
  --ymmt: string # Comma separated list of Year, Make, Model, Trim combinations. Each combination needs to have the year,make,model, trim values separated by a pipe '|' character in the form year|make|model|trim. e.g. 2010|Audi|A5,2014|Nissan|Sentra|S 6MT,|Honda|City| You could just provide strings of the form - 'year|make||' or 'year|make|model' or '|make|model|' combinations. Individual year / make / model filters provied with the API calls will take precedence over the Year, Make, Model, Trim combinations. The Make, Model, Trim values must be valid values as per the Marketcheck Vin Decoder. If you are using a separate vin decoder then look at using the 'vins' or 'taxonomy_vins' parameter to the search api instead the year|make|model|trim combinations.
  --match: string # Comma separated list of Year, Make, Model, Trim fields. For example - year,make,model,trim fields for which user wants to do an exact match
  --cylinders: string # To filter listing on their cylinders
  --transmission: string # To filter listing on their transmission
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --drivetrain: string # To filter listing on their drivetrain
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-aspiration: string # Engine Aspiration to match. Valid filter values are those that our Search facets API returns for unique Engine Aspirations. You can pass in multiple Engine aspirations values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --highway-mpg-range: string # Highway mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --city-mpg-range: string # City mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --combined-mpg-range: string # Combined mileage range for UK to filter listings with the mileage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --dom-range: string # Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-source-range: string # First seen at source date range to filter listings with the first seen at source in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-at-mc-range: string # First seen at MC date range to filter listings with the first seen at MC in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-source-days: string # First seen at source days range to filter listings with the first seen at source in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-at-mc-days: string # First seen at MC days range to filter listings with the first seen at MC in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --include-non-vin-listings: oneof<nothing, bool> # To include non vin listings. Default is false (default: false)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --country: string@country-completer-5 # To filter listing on Country in which they are listed (default: uk)
  --plot: oneof<nothing, bool> # If plot has value true results in around 25k coordinates with limited fields to plot respective graph
  --nodedup: oneof<nothing, bool> # If nodedup is set to true then API will give results without is_searchable i.e multiple listings for single vin
  --dedup: oneof<nothing, bool> # If dedup is set to true then will give results with is_searchable irrespecive of dealer_id or source
  --owned: oneof<nothing, bool> # Used in combination with dealer_id or source, when true returns the listings actually owned by dealer himself
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --dealer-name: string # Filter listings on dealer_name
  --dealership-group-name: string # Name of the dealership group to search for (format: string)
  --trim-o: string # Filter listings on web scraped trim
  --trim-r: string # Filter trim on custom possible matches
  --dom-active-range: string # Active Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --dom-180-range: string # Last 180 Days on Market range to filter cars with the DOM within the given range. Range to be given in the format - min-max e.g. 10-50 (format: string)
  --exclude-certified: oneof<nothing, bool> # Boolean param to exclude certified cars from search results
  --fuel-type: string # To filter listing on their fuel type
  --dealer-type: string@dealer-type-completer # Filter based on dealer type independant or franchise
  --photo-links: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links in search results, And discard those that don't have them
  --photo-links-cached: oneof<nothing, bool> # A boolean indicating whether to include only those listings that have photo_links_cached in search results, And discard those that don't have them
  --stock-no: string # To filter listing on their stock number on lot
  --sold: oneof<nothing, bool> # sold parameter to fetch only sold listings
  --include-relevant-links: oneof<nothing, bool> # To include_relevant_links. Default is true (default: false)
  --expired: string@expired-completer # Boolean falg to either fetch only the expired listings or active ones
  --exclude-dealer-ids: string # A list of dealer ids to exclude from result (format: string)
  --exclude-sources: string # A list of sources to exclude from result (format: string)
  --in-transit: string@in-transit-completer # A boolean to filter in transit vehicles
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --insurance-group: string # Insurance Group
  --vrm: string # To filter on vrm (format: string)
  --num-owners: string # Number of owners. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --variant: string # To filter listing on their variant
  --postal-code: string # To filter listing on postal code around which they are listed
  --write-off-category: string # write off category (format: string)
  --fca-status: string # To filter on fca status (format: string)
  --active-inventory-date-range: string # date range to filter listings that were active within given date range. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --engine-size-range: string # Engine size range to filter listings with engine size in the given range. Range to be given in the format - min-max e.g. 1.0-2 (format: string)
  --price-change-range: string # Price change range to filter listings with price change within given price_change_range. Range to be given in the format - min-max e.g. 10-500 (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/car/uk/recents"
    query: [{name: api_key, var: api_key}, {name: append_api_key, var: append_api_key}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: zip, var: zip}, {name: include_lease, var: include_lease}, {name: include_finance, var: include_finance}, {name: lease_term, var: lease_term}, {name: lease_down_payment, var: lease_down_payment}, {name: lease_emp, var: lease_emp}, {name: finance_loan_term, var: finance_loan_term}, {name: finance_loan_apr, var: finance_loan_apr}, {name: finance_emp, var: finance_emp}, {name: finance_down_payment, var: finance_down_payment}, {name: finance_down_payment_per, var: finance_down_payment_per}, {name: car_type, var: car_type}, {name: carfax_1_owner, var: carfax_1_owner}, {name: carfax_clean_title, var: carfax_clean_title}, {name: year_range, var: year_range}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: dealer_id, var: dealer_id}, {name: vin, var: vin}, {name: source, var: source}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: vins, var: vins}, {name: taxonomy_vins, var: taxonomy_vins}, {name: ymmt, var: ymmt}, {name: match, var: match}, {name: cylinders, var: cylinders}, {name: transmission, var: transmission}, {name: doors, var: doors}, {name: drivetrain, var: drivetrain}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_aspiration, var: engine_aspiration}, {name: engine_block, var: engine_block}, {name: highway_mpg_range, var: highway_mpg_range}, {name: city_mpg_range, var: city_mpg_range}, {name: combined_mpg_range, var: combined_mpg_range}, {name: miles_range, var: miles_range}, {name: price_range, var: price_range}, {name: msrp_range, var: msrp_range}, {name: dom_range, var: dom_range}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: first_seen_at_source_range, var: first_seen_at_source_range}, {name: first_seen_at_mc_range, var: first_seen_at_mc_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: first_seen_at_source_days, var: first_seen_at_source_days}, {name: first_seen_at_mc_days, var: first_seen_at_mc_days}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: include_non_vin_listings, var: include_non_vin_listings}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: country, var: country}, {name: plot, var: plot}, {name: nodedup, var: nodedup}, {name: dedup, var: dedup}, {name: owned, var: owned}, {name: state, var: state}, {name: city, var: city}, {name: msa_code, var: msa_code}, {name: dealer_name, var: dealer_name}, {name: dealership_group_name, var: dealership_group_name}, {name: trim_o, var: trim_o}, {name: trim_r, var: trim_r}, {name: dom_active_range, var: dom_active_range}, {name: dom_180_range, var: dom_180_range}, {name: exclude_certified, var: exclude_certified}, {name: fuel_type, var: fuel_type}, {name: dealer_type, var: dealer_type}, {name: photo_links, var: photo_links}, {name: photo_links_cached, var: photo_links_cached}, {name: stock_no, var: stock_no}, {name: sold, var: sold}, {name: include_relevant_links, var: include_relevant_links}, {name: expired, var: expired}, {name: exclude_dealer_ids, var: exclude_dealer_ids}, {name: exclude_sources, var: exclude_sources}, {name: in_transit, var: in_transit}, {name: seating_capacity, var: seating_capacity}, {name: insurance_group, var: insurance_group}, {name: vrm, var: vrm}, {name: num_owners, var: num_owners}, {name: variant, var: variant}, {name: postal_code, var: postal_code}, {name: write_off_category, var: write_off_category}, {name: fca_status, var: fca_status}, {name: active_inventory_date_range, var: active_inventory_date_range}, {name: engine_size_range, var: engine_size_range}, {name: price_change_range, var: price_change_range}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, append_api_key: $append_api_key, latitude: $latitude, longitude: $longitude, radius: $radius, zip: $zip, include_lease: $include_lease, include_finance: $include_finance, lease_term: $lease_term, lease_down_payment: $lease_down_payment, lease_emp: $lease_emp, finance_loan_term: $finance_loan_term, finance_loan_apr: $finance_loan_apr, finance_emp: $finance_emp, finance_down_payment: $finance_down_payment, finance_down_payment_per: $finance_down_payment_per, car_type: $car_type, carfax_1_owner: $carfax_1_owner, carfax_clean_title: $carfax_clean_title, year_range: $year_range, year: $year, make: $make, model: $model, trim: $trim, dealer_id: $dealer_id, vin: $vin, source: $source, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, vins: $vins, taxonomy_vins: $taxonomy_vins, ymmt: $ymmt, match: $match, cylinders: $cylinders, transmission: $transmission, doors: $doors, drivetrain: $drivetrain, exterior_color: $exterior_color, interior_color: $interior_color, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, engine: $engine, engine_size: $engine_size, engine_aspiration: $engine_aspiration, engine_block: $engine_block, highway_mpg_range: $highway_mpg_range, city_mpg_range: $city_mpg_range, combined_mpg_range: $combined_mpg_range, miles_range: $miles_range, price_range: $price_range, msrp_range: $msrp_range, dom_range: $dom_range, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, first_seen_at_source_range: $first_seen_at_source_range, first_seen_at_mc_range: $first_seen_at_mc_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, first_seen_at_source_days: $first_seen_at_source_days, first_seen_at_mc_days: $first_seen_at_mc_days, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, include_non_vin_listings: $include_non_vin_listings, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, country: $country, plot: $plot, nodedup: $nodedup, dedup: $dedup, owned: $owned, state: $state, city: $city, msa_code: $msa_code, dealer_name: $dealer_name, dealership_group_name: $dealership_group_name, trim_o: $trim_o, trim_r: $trim_r, dom_active_range: $dom_active_range, dom_180_range: $dom_180_range, exclude_certified: $exclude_certified, fuel_type: $fuel_type, dealer_type: $dealer_type, photo_links: $photo_links, photo_links_cached: $photo_links_cached, stock_no: $stock_no, sold: $sold, include_relevant_links: $include_relevant_links, expired: $expired, exclude_dealer_ids: $exclude_dealer_ids, exclude_sources: $exclude_sources, in_transit: $in_transit, seating_capacity: $seating_capacity, insurance_group: $insurance_group, vrm: $vrm, num_owners: $num_owners, variant: $variant, postal_code: $postal_code, write_off_category: $write_off_category, fca_status: $fca_status, active_inventory_date_range: $active_inventory_date_range, engine_size_range: $engine_size_range, price_change_range: $price_change_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active heavy equipment listings for the given search criteria
#
# GET /search/heavy-equipment/active
# Returns: record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>
export def "get-search-heavy-equipment-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --body-type: string # To filter listing on their body type
  --category: string # To filter heavy equipments on their category
  --sub-category: string # To filter heavy equipments on their sub-category
  --hours-used-range: string # Hours used range to filter heavy equipments with the their usage in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/heavy-equipment/active"
    query: [{name: api_key, var: api_key}, {name: price_range, var: price_range}, {name: miles_range, var: miles_range}, {name: msrp_range, var: msrp_range}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: search_text, var: search_text}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: inventory_type, var: inventory_type}, {name: stock_no, var: stock_no}, {name: source, var: source}, {name: dealer_name, var: dealer_name}, {name: dealer_id, var: dealer_id}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: engine, var: engine}, {name: fuel_type, var: fuel_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: body_type, var: body_type}, {name: category, var: category}, {name: sub_category, var: sub_category}, {name: hours_used_range, var: hours_used_range}, {name: state, var: state}, {name: city, var: city}, {name: zip, var: zip}, {name: msa_code, var: msa_code}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, price_range: $price_range, miles_range: $miles_range, msrp_range: $msrp_range, latitude: $latitude, longitude: $longitude, radius: $radius, search_text: $search_text, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, inventory_type: $inventory_type, stock_no: $stock_no, source: $source, dealer_name: $dealer_name, dealer_id: $dealer_id, exterior_color: $exterior_color, interior_color: $interior_color, engine: $engine, fuel_type: $fuel_type, transmission: $transmission, drivetrain: $drivetrain, body_type: $body_type, category: $category, sub_category: $sub_category, hours_used_range: $hours_used_range, state: $state, city: $city, zip: $zip, msa_code: $msa_code, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for auto-completion of inputs
#
# GET /search/heavy-equipment/auto-complete
# Returns: record<terms: table<count: int, item: string>>
export def "get-search-heavy-equipment-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-1 # Field name for which you want auto-completion (required, format: string)
  --input: string # Input entered so far (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/heavy-equipment/auto-complete"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: input, var: input, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: color, var: color}, {name: engine, var: engine}, {name: state, var: state}, {name: city, var: city}, {name: inventory_type, var: inventory_type}, {name: ignore_case, var: ignore_case}, {name: term_counts, var: term_counts}, {name: sort_by, var: sort_by}, {name: seller_type, var: seller_type}, {name: radius, var: radius}, {name: zip, var: zip}, {name: facet_min_count, var: facet_min_count}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, input: $input, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, color: $color, engine: $engine, state: $state, city: $city, inventory_type: $inventory_type, ignore_case: $ignore_case, term_counts: $term_counts, sort_by: $sort_by, seller_type: $seller_type, radius: $radius, zip: $zip, facet_min_count: $facet_min_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active motorcycle listings for the given search criteria
#
# GET /search/motorcycle/active
# Returns: record<facets: record, listings: table<build: record, color: string, dealer: record, dist: float, dp_url: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>
export def "get-search-motorcycle-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --search-text: string # To search a substring across entire document
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --vin: string # To filter listing on their VIN
  --taxonomy-vin: string # Taxonomy VIN of the motorcycle
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --source: string # To filter listing on their source
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --color: string # Color of the vehicle
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --cylinders: string # To filter listing on their cylinders
  --drivetrain: string # To filter listing on their drivetrain
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/motorcycle/active"
    query: [{name: api_key, var: api_key}, {name: price_range, var: price_range}, {name: miles_range, var: miles_range}, {name: msrp_range, var: msrp_range}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: search_text, var: search_text}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: vin, var: vin}, {name: taxonomy_vin, var: taxonomy_vin}, {name: inventory_type, var: inventory_type}, {name: stock_no, var: stock_no}, {name: source, var: source}, {name: dealer_id, var: dealer_id}, {name: color, var: color}, {name: body_type, var: body_type}, {name: vehicle_type, var: vehicle_type}, {name: cylinders, var: cylinders}, {name: drivetrain, var: drivetrain}, {name: engine, var: engine}, {name: fuel_type, var: fuel_type}, {name: transmission, var: transmission}, {name: state, var: state}, {name: city, var: city}, {name: zip, var: zip}, {name: msa_code, var: msa_code}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, price_range: $price_range, miles_range: $miles_range, msrp_range: $msrp_range, latitude: $latitude, longitude: $longitude, radius: $radius, search_text: $search_text, year: $year, make: $make, model: $model, trim: $trim, vin: $vin, taxonomy_vin: $taxonomy_vin, inventory_type: $inventory_type, stock_no: $stock_no, source: $source, dealer_id: $dealer_id, color: $color, body_type: $body_type, vehicle_type: $vehicle_type, cylinders: $cylinders, drivetrain: $drivetrain, engine: $engine, fuel_type: $fuel_type, transmission: $transmission, state: $state, city: $city, zip: $zip, msa_code: $msa_code, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for auto-completion of inputs
#
# GET /search/motorcycle/auto-complete
# Returns: record<terms: table<count: int, item: string>>
export def "get-search-motorcycle-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-2 # Field name for which you want auto-completion (required, format: string)
  --input: string # Input entered so far (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/motorcycle/auto-complete"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: input, var: input, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: color, var: color}, {name: engine, var: engine}, {name: state, var: state}, {name: city, var: city}, {name: inventory_type, var: inventory_type}, {name: ignore_case, var: ignore_case}, {name: term_counts, var: term_counts}, {name: sort_by, var: sort_by}, {name: seller_type, var: seller_type}, {name: radius, var: radius}, {name: zip, var: zip}, {name: facet_min_count, var: facet_min_count}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, input: $input, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, color: $color, engine: $engine, state: $state, city: $city, inventory_type: $inventory_type, ignore_case: $ignore_case, term_counts: $term_counts, sort_by: $sort_by, seller_type: $seller_type, radius: $radius, zip: $zip, facet_min_count: $facet_min_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active RV listings for the given search criteria
#
# GET /search/rv/active
# Returns: record<facets: record, listings: table<build: record, dealer: record, dist: float, dp_url: string, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, msrp: int, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vin: string>, num_found: int, range_facets: record, stats: record>
export def "get-search-rv-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --search-text: string # To search a substring across entire document
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --model-o: string # To filter listings on their model orig (as described on the webpage)
  --vin: string # To filter listing on their VIN
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --stock-no: string # To filter listing on their stock number on lot
  --source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine: string # To filter listing on their engine
  --fuel-type: string # To filter listing on their fuel type
  --transmission: string # To filter listing on their transmission
  --class: string # Filter RV listings on class
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --msa-code: string # To filter listing on msa code in which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --slideouts: string # Filter RV listings on slideouts
  --length-range: string # length range to filter listings with the length in the range given. Range to be given in the format - min-max e.g. 50-200 (format: string)
  --length: string # Filter RV listings on length
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --fresh-water-capacity: string # To filter on fresh water capacity of vehicle
  --sleeps: string # To filter data based on sleeps (format: string)
  --cylinders: string # To filter listing on their cylinders
  --number-of-awnings: string # To filter on number_of_awnings (format: string)
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --gvwr: string # To filter on the maximum total weight of your vehicle
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/rv/active"
    query: [{name: api_key, var: api_key}, {name: price_range, var: price_range}, {name: miles_range, var: miles_range}, {name: msrp_range, var: msrp_range}, {name: year_range, var: year_range}, {name: search_text, var: search_text}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: model_o, var: model_o}, {name: vin, var: vin}, {name: inventory_type, var: inventory_type}, {name: stock_no, var: stock_no}, {name: source, var: source}, {name: dealer_name, var: dealer_name}, {name: dealer_id, var: dealer_id}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: engine, var: engine}, {name: fuel_type, var: fuel_type}, {name: transmission, var: transmission}, {name: class, var: class}, {name: state, var: state}, {name: city, var: city}, {name: zip, var: zip}, {name: msa_code, var: msa_code}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: slideouts, var: slideouts}, {name: length_range, var: length_range}, {name: length, var: length}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: seating_capacity, var: seating_capacity}, {name: fresh_water_capacity, var: fresh_water_capacity}, {name: sleeps, var: sleeps}, {name: cylinders, var: cylinders}, {name: number_of_awnings, var: number_of_awnings}, {name: doors, var: doors}, {name: gvwr, var: gvwr}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, price_range: $price_range, miles_range: $miles_range, msrp_range: $msrp_range, year_range: $year_range, search_text: $search_text, latitude: $latitude, longitude: $longitude, radius: $radius, year: $year, make: $make, model: $model, model_o: $model_o, vin: $vin, inventory_type: $inventory_type, stock_no: $stock_no, source: $source, dealer_name: $dealer_name, dealer_id: $dealer_id, exterior_color: $exterior_color, interior_color: $interior_color, engine: $engine, fuel_type: $fuel_type, transmission: $transmission, class: $class, state: $state, city: $city, zip: $zip, msa_code: $msa_code, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, slideouts: $slideouts, length_range: $length_range, length: $length, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, seating_capacity: $seating_capacity, fresh_water_capacity: $fresh_water_capacity, sleeps: $sleeps, cylinders: $cylinders, number_of_awnings: $number_of_awnings, doors: $doors, gvwr: $gvwr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for auto-completion of inputs
#
# GET /search/rv/auto-complete
# Returns: record<terms: table<count: int, item: string>>
export def "get-search-rv-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-3 # Field name for which you want auto-completion (required, format: string)
  --input: string # Input entered so far (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --color: string # Color of the vehicle
  --engine: string # To filter listing on their engine
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --term-counts: oneof<nothing, bool> # Boolean variable to indicate wheather to include term counts as well in response (default: false)
  --sort-by: string@sort-by-completer # Sort the response, either by index or count(default) (default: index)
  --seller-type: string # seller type for autocomplete
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --zip: string # To filter listing on ZIP around which they are listed
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/rv/auto-complete"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: input, var: input, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: color, var: color}, {name: engine, var: engine}, {name: state, var: state}, {name: city, var: city}, {name: inventory_type, var: inventory_type}, {name: ignore_case, var: ignore_case}, {name: term_counts, var: term_counts}, {name: sort_by, var: sort_by}, {name: seller_type, var: seller_type}, {name: radius, var: radius}, {name: zip, var: zip}, {name: facet_min_count, var: facet_min_count}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, input: $input, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, color: $color, engine: $engine, state: $state, city: $city, inventory_type: $inventory_type, ignore_case: $ignore_case, term_counts: $term_counts, sort_by: $sort_by, seller_type: $seller_type, radius: $radius, zip: $zip, facet_min_count: $facet_min_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets active RV listings for the given search criteria
#
# GET /search/rv/uk/active
# Returns: record<facets: record, listings: table<availability_status: string, build: record, currency_indicator: string, dealer: record, dist: float, exterior_color: string, first_seen_at: int, first_seen_at_date: string, heading: string, id: string, interior_color: string, inventory_type: string, last_seen_at: int, last_seen_at_date: string, media: record, miles: int, miles_indicator: string, mot_expires: string, motorhome_build: string, msrp: int, origin: string, price: int, scraped_at: float, scraped_at_date: string, seller_type: string, source: string, stock_no: string, vdp_url: string, vin: string>, num_found: int, range_facets: record, stats: record>
export def "get-search-rv-uk-active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --price-range: string # Price range to filter listings with the price in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --miles-range: string # Miles range to filter listings with miles in the given range. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --msrp-range: string # MSRP range to filter listings with the msrp in the range given. Range to be given in the format - min-max e.g. 1000-5000 (format: string)
  --year-range: string # Year range to filter listings with the year in the range given. Range to be given in the format - min-max e.g. 2019-2021 (format: string)
  --search-text: string # To search a substring across entire document
  --latitude: float # Latitude component of location (format: double)
  --longitude: float # Longitude component of location (format: double)
  --radius: int # Radius around the search location (Unit - Miles) (format: int32)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --vin: string # To filter listing on their VIN
  --source: string # To filter listing on their source
  --dealer-name: string # Filter listings on dealer_name
  --dealer-id: string # Dealer id to filter the listings. (format: string)
  --exterior-color: string # Exterior color to match. Valid filter values are those that our Search facets API returns for unique exterior colors. You can pass in multiple exterior color values comma separated
  --interior-color: string # Interior color to match. Valid filter values are those that our Search facets API returns for unique interior colors. You can pass in multiple interior color values comma separated
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --fuel-type: string # To filter listing on their fuel type
  --category: string # Filter RV listings on category
  --state: string # To filter listing on State in which they are listed
  --city: string # To filter listing on City in which they are listed
  --county: string # To filter listing on county in which they are listed
  --postal-code: string # To filter listing on postal code around which they are listed
  --zip: string # To filter listing on ZIP around which they are listed
  --sort-by: string # Sort by field. Default sort field is distance from the given point (format: string)
  --sort-order: string@sort-order-completer # Sort order - asc or desc. Default sort order is asc (format: string)
  --rows: int # Number of results to return. Default is 10. Max is 50 (format: int32, default: 10)
  --start: int # Page number to fetch the results for the given criteria. Default is 0. Pagination is allowed only till first 10000 results for the search and sort criteria. The page value can be only between 1 to 10000/rows (format: int32, default: 0)
  --facets: string # The comma separated list of fields for which facets are requested. Facets could be requested in addition to the listings for the search. Please note - The API calls with lots of facet fields may take longer to respond.
  --range-facets: string # The comma separated list of numeric fields for which range facets are requested. Range facets could be requested in addition to the listings for the search. Please note - The API calls with lots of range facet fields may take longer to respond.
  --facet-sort: string@facet-sort-completer # Control sort order of facets with this parameter with default sort being on count, Other available sort is alphabetical sort, which can be obtained by using index as value for this param (default: count)
  --stats: string # The list of fields for which stats need to be generated based on the matching listings for the search criteria. The stats consists of mean, max, average and count of listings based on which the stats are calculated for the field. Stats could be requested in addition to the listings for the search. Please note - The API calls with the stats fields may take longer to respond.
  --last-seen-range: string # Last seen date range to filter listings with the last seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --first-seen-range: string # First seen date range to filter listings with the first seen in the range given. Range to be given in the format [YYYYMMDD] - min-max e.g. 20190523-20190623 (format: string)
  --last-seen-days: string # Last seen days range to filter listings with the last seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --first-seen-days: string # First seen days range to filter listings with the first seen in the range given. Range to be given in the format - min-max e.g. 25-12 (format: string)
  --base-exterior-color: string # Base exterior color to match. Valid filter values are those that our Search facets API returns for unique base exterior colors. You can pass in multiple base interior color values comma separated
  --base-interior-color: string # Base interior color to match. Valid filter values are those that our Search facets API returns for unique base interior colors. You can pass in multiple base interior color values comma separated
  --seating-capacity: string # To filter on vehicle seating capacity (format: string)
  --cylinders: string # To filter listing on their cylinders
  --doors: string # Doors to filter the cars on. Valid filter values are those that our Search facets API returns for unique doors. You can pass in multiple doors values comma separated (format: string)
  --mtplm: string # To filter rv on mtplm
  --sub-category: string # To filter rv on their sub-category
  --availability-status: string # To filter rv on their availability_status
  --berths: string # To filter rv on their berths
  --inventory-type: string@inventory-type-completer # To filter listing on their condition. Either used or new
  --width-range: string # width range to filter listings on width in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --exterior-length-range: string # width range to filter listings on exterior_length in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --interior-length-range: string # width range to filter listings on interior_length in the range given. Range to be given in the format - min-max e.g. 4-8 (format: string)
  --drive-type: string # To filter rv on their drive_type
  --steering: string # To filter rv on their steering
  --chassis: string # To filter rv on their chassis
  --transmission: string # To filter listing on their transmission
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/rv/uk/active"
    query: [{name: api_key, var: api_key}, {name: price_range, var: price_range}, {name: miles_range, var: miles_range}, {name: msrp_range, var: msrp_range}, {name: year_range, var: year_range}, {name: search_text, var: search_text}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: vin, var: vin}, {name: source, var: source}, {name: dealer_name, var: dealer_name}, {name: dealer_id, var: dealer_id}, {name: exterior_color, var: exterior_color}, {name: interior_color, var: interior_color}, {name: engine_size, var: engine_size}, {name: fuel_type, var: fuel_type}, {name: category, var: category}, {name: state, var: state}, {name: city, var: city}, {name: county, var: county}, {name: postal_code, var: postal_code}, {name: zip, var: zip}, {name: sort_by, var: sort_by}, {name: sort_order, var: sort_order}, {name: rows, var: rows}, {name: start, var: start}, {name: facets, var: facets}, {name: range_facets, var: range_facets}, {name: facet_sort, var: facet_sort}, {name: stats, var: stats}, {name: last_seen_range, var: last_seen_range}, {name: first_seen_range, var: first_seen_range}, {name: last_seen_days, var: last_seen_days}, {name: first_seen_days, var: first_seen_days}, {name: base_exterior_color, var: base_exterior_color}, {name: base_interior_color, var: base_interior_color}, {name: seating_capacity, var: seating_capacity}, {name: cylinders, var: cylinders}, {name: doors, var: doors}, {name: mtplm, var: mtplm}, {name: sub_category, var: sub_category}, {name: availability_status, var: availability_status}, {name: berths, var: berths}, {name: inventory_type, var: inventory_type}, {name: width_range, var: width_range}, {name: exterior_length_range, var: exterior_length_range}, {name: interior_length_range, var: interior_length_range}, {name: drive_type, var: drive_type}, {name: steering, var: steering}, {name: chassis, var: chassis}, {name: transmission, var: transmission}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, price_range: $price_range, miles_range: $miles_range, msrp_range: $msrp_range, year_range: $year_range, search_text: $search_text, latitude: $latitude, longitude: $longitude, radius: $radius, year: $year, make: $make, model: $model, vin: $vin, source: $source, dealer_name: $dealer_name, dealer_id: $dealer_id, exterior_color: $exterior_color, interior_color: $interior_color, engine_size: $engine_size, fuel_type: $fuel_type, category: $category, state: $state, city: $city, county: $county, postal_code: $postal_code, zip: $zip, sort_by: $sort_by, sort_order: $sort_order, rows: $rows, start: $start, facets: $facets, range_facets: $range_facets, facet_sort: $facet_sort, stats: $stats, last_seen_range: $last_seen_range, first_seen_range: $first_seen_range, last_seen_days: $last_seen_days, first_seen_days: $first_seen_days, base_exterior_color: $base_exterior_color, base_interior_color: $base_interior_color, seating_capacity: $seating_capacity, cylinders: $cylinders, doors: $doors, mtplm: $mtplm, sub_category: $sub_category, availability_status: $availability_status, berths: $berths, inventory_type: $inventory_type, width_range: $width_range, exterior_length_range: $exterior_length_range, interior_length_range: $interior_length_range, drive_type: $drive_type, steering: $steering, chassis: $chassis, transmission: $transmission
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for auto-completion of inputs based on taxonomy
#
# GET /specs/car/auto-complete
# Returns: record<terms: list<string>>
export def "get-specs-car-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string@field-completer-4 # Field name for which you want auto-completion (required, format: string)
  --input: string # Input entered so far (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
  --ignore-case: oneof<nothing, bool> # Boolean variable to indicate ignore case of current input (default: true)
  --facet-min-count: float # Provide minimum count value for facets (format: number, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/specs/car/auto-complete"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: input, var: input, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_block, var: engine_block}, {name: ignore_case, var: ignore_case}, {name: facet_min_count, var: facet_min_count}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, input: $input, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, engine: $engine, engine_size: $engine_size, engine_block: $engine_block, ignore_case: $ignore_case, facet_min_count: $facet_min_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API for getting terms from taxonomy
#
# GET /specs/car/terms
# Returns: record<terms: list<string>>
# operationId: getTaxonomyTerms
export def "get-taxonomy-terms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --field: string # Comma separated list of fields to get terms for (required, format: string)
  --year: string # To filter listing on their year
  --make: string # To filter listings on their make
  --model: string # To filter listings on their model
  --trim: string # To filter listing on their trim
  --body-type: string # To filter listing on their body type
  --body-subtype: string # Body subtype to filter the listings on. Valid filter values are those that our Search facets API returns for unique body subtypes. You can pass in multiple body subtype values comma separated (format: string)
  --vehicle-type: string # To filter listing on their vehicle type
  --transmission: string # To filter listing on their transmission
  --drivetrain: string # To filter listing on their drivetrain
  --fuel-type: string # To filter listing on their fuel type
  --engine: string # To filter listing on their engine
  --engine-size: string # Engine Size to match. Valid filter values are those that our Search facets API returns for unique engine size. You can pass in multiple engine size values comma separated
  --engine-block: string # Engine Block to match. Valid filter values are those that our Search facets API returns for unique Engine Block. You can pass in multiple Engine Block values comma separated
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/specs/car/terms"
    query: [{name: api_key, var: api_key}, {name: field, var: field, required: true}, {name: year, var: year}, {name: make, var: make}, {name: model, var: model}, {name: trim, var: trim}, {name: body_type, var: body_type}, {name: body_subtype, var: body_subtype}, {name: vehicle_type, var: vehicle_type}, {name: transmission, var: transmission}, {name: drivetrain, var: drivetrain}, {name: fuel_type, var: fuel_type}, {name: engine, var: engine}, {name: engine_size, var: engine_size}, {name: engine_block, var: engine_block}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, field: $field, year: $year, make: $make, model: $model, trim: $trim, body_type: $body_type, body_subtype: $body_subtype, vehicle_type: $vehicle_type, transmission: $transmission, drivetrain: $drivetrain, fuel_type: $fuel_type, engine: $engine, engine_size: $engine_size, engine_block: $engine_block
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Price, Miles and Days on Market stats
#
# GET /stats/car
# Returns: record<dom: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, miles_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, price_stats: record<interquartile_range: float, mean: float, median: float, population_standard_deviation: float, standard_deviation: float, trimmed_mean: float, variance: float>, units_for_sale: float>
# operationId: getDailyStats
export def "get-daily-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The API Authentication Key. Mandatory with all API calls.
  --country: string@country-completer-4 # Country for which the stats are to be searched (format: string, default: us)
  --car-type: string@car-type-completer-1 # Inventory type for which stats are to be searched, default is used (format: string, default: used)
  --ymm: string # Year, Make, Model of the car, Separated by pipe e.g. ymm=2015|ford|f-150 (format: string)
  --ymmt: string # Year, Make, Model, Trim of the car, Separated by pipe e.g. ymmt=2015|ford|f-150|platinum (format: string)
  --taxonomy-vin: string # Taxonomy vin for referance to find stats of similar cars (format: string)
  --vin: string # VIN that will be transformed to taxonomy_vin (format: string)
  --state: string # State level stats (format: string)
  --city-state: string # City level stats, pipe seperated like city_state=jacksonville|FL (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stats/car"
    query: [{name: api_key, var: api_key}, {name: country, var: country}, {name: car_type, var: car_type}, {name: ymm, var: ymm}, {name: ymmt, var: ymmt}, {name: taxonomy_vin, var: taxonomy_vin}, {name: vin, var: vin}, {name: state, var: state}, {name: city_state, var: city_state}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    api_key: $api_key, country: $country, car_type: $car_type, ymm: $ymm, ymmt: $ymmt, taxonomy_vin: $taxonomy_vin, vin: $vin, state: $state, city_state: $city_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
