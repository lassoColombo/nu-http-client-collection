# Auto-generated client for Fire Financial Services Business API v1.0
# Source: https://api.apis.guru/v2/specs/fire.com/1.0/openapi.json
# Auth: --token flag or $env.FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN

const CLIENT = {
  base_url: "https://api.fire.com/business"
  token_env_var: "FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN"
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

def base-url-completer [] { ["https://api.fire.com/business"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def currency-completer [] { ["EUR" "GBP"] }
def grant-type-completer [] { ["AccessToken"] }
def batch-status-completer [] { ["FAILED" "REMOVED" "SUBMITTED" "SUCCEEDED"] }
def batch-types-completer [] { ["BANK_TRANSFER" "INTERNAL_TRANSFER" "NEW_PAYEE"] }
def order-by-completer [] { ["DATE"] }
def order-completer [] { ["ASC" "DESC"] }
def type-completer [] { ["BANK_TRANSFER" "INTERNAL_TRANSFER"] }
def payee-type-completer [] { ["ACCOUNT_DETAILS"] }
def address-type-completer [] { ["BUSINESS" "HOME"] }
def type-completer-1 [] { ["OTHER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts: "record<accounts: table<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>>"
    add-account: "record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>"
    get-account-by-id: "record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>"
    get-transactions-by-idv1: "record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>>"
    get-transactions-filtered-by-id: "record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>>"
    create-api-application: "record<applicationId: int, clientId: string, clientKey: string, enabled: bool, expiry: string, ican: int, numberOfPayeeApprovalsRequired: int, numberOfPaymentApprovalsRequired: int, refreshToken: string>"
    authenticate: "record<accessToken: string, apiApplicationId: int, businessId: int, expiry: string, permissions: list<string>>"
    get-list-of-aspsps: "record<aspsps: table<alias: string, aspspUuid: string, country: record, currency: record, dateCreated: string, lastUpdated: string, logoUrl: string>, total: int>"
    get-batches: "record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>"
    create-batch-payment: "record<batchUuid: string>"
    get-details-single-batch: "record<batchName: string, batchUuid: string, callbackUrl: string, currency: string, dateCreated: string, jobNumber: string, lastUpdated: string, numberOfItemsFailed: int, numberOfItemsSubmitted: int, numberOfItemsSucceeded: int, sourceName: string, status: string, type: string, valueOfItemsFailed: int, valueOfItemsSubmitted: int, valueOfItemsSucceeded: int>"
    get-listof-approvers-for-batch: "record<approvals: table<emailAddress: string, firstName: string, lastName: string, lastUpdated: string, mobileNumber: string, status: string, userId: int>>"
    get-items-batch-bank-transfer: "record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>"
    add-bank-transfer-batch-payment: "record<batchItemUuid: string>"
    get-items-batch-internal-trasnfer: "record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>"
    add-internal-transfer-batch-payment: "record<batchItemUuid: string>"
    get-listof-cards: "record<cards: table<blocked: bool, cardId: int, dateCreated: string, emailAddress: string, eurIcan: int, expiryDate: string, firstName: string, gbpIcan: int, lastName: string, maskedPan: string, provider: string, status: string, statusReason: string, userId: int>>"
    create-new-card: "record<cardId: int, expiryDate: string, maskedPan: string, status: string>"
    get-listof-card-transactions: "table<dateRangeTo: int, total: int, transactions: list<record>>"
    get-direct-debits-for-mandate-uuid: "record<directdebits: table<amount: int, currency: record, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>, total: int>"
    get-direct-debit-by-uuid: "record<amount: int, currency: record<code: string, description: string>, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>"
    get-direct-debit-mandates: "record<mandates: table<alias: string, currency: record, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>, total: int>"
    get-mandate: "record<alias: string, currency: record<code: string, description: string>, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>"
    get-payees: "record<fundingSources: table<accountHolderName: string, accountName: string, accountNumber: string, bic: string, createdBy: string, currency: record, dateCreated: string, iban: string, id: int, nsc: string, status: string>, total: int>"
    new-payment-request: "record<code: string, type: string>"
    get-payment-details: "record<additionalFields: string, amount: int, collectFields: string, currency: record<code: string, description: string>, description: string, expiry: string, icanTo: int, mandatoryFields: string, maxNumberPayments: int, myRef: string, orderDetails: record<comment1: string, comment2: string, customerNumber: string, deliveryAddressLine1: string, deliveryAddressLine2: string, deliveryCity: string, deliveryCountry: string, deliveryPostCode: string, merchantCustomerIdentification: string, merchantNumber: string, orderId: string, productId: string, variableReference: string>, paymentRequestCode: string, paymentUuid: string, returnUrl: string, status: string, transactionType: string, type: string, webhookUrl: string>"
    get-user: "record<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string>"
    get-users: "table<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string>"
    get-transactions-by-idv3: "record<content: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>, links: table<href: string, rel: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-accounts" "add-account" "get-account-by-id" "get-transactions-by-idv1" "get-transactions-filtered-by-id" "create-api-application" "authenticate" "get-list-of-aspsps" "get-batches" "create-batch-payment" "cancel-batch-payment" "get-details-single-batch" "submit-batch" "get-listof-approvers-for-batch" "get-items-batch-bank-transfer" "add-bank-transfer-batch-payment" "delete-bank-transfer-batch-payment" "get-items-batch-internal-trasnfer" "add-internal-transfer-batch-payment" "delete-internal-transfer-batch-payment" "get-listof-cards" "create-new-card" "block-card" "get-listof-card-transactions" "unblock-card" "get-direct-debits-for-mandate-uuid" "get-direct-debit-by-uuid" "reject-direct-debit" "get-direct-debit-mandates" "get-mandate" "update-mandate-alias" "activate-mandate" "cancel-mandate-by-uuid" "get-payees" "new-payment-request" "get-payment-details" "get-user" "get-users" "get-transactions-by-idv3" "commands"] | sort) } | get name | first)
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

# List all fire.com Accounts
#
# GET /v1/accounts
# Returns: record<accounts: table<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>>
# operationId: getAccounts
export def "get-accounts" [
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
    path: "/v1/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new account
#
# POST /v1/accounts
# Returns: record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>
# operationId: addAccount
export def "add-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-fees-and-charges: oneof<nothing, bool> # a field to indicate you accept the fee for a new account
  --account-name: string # Name to give the new account (e.g. Operating Account)
  --currency: string@currency-completer # The currency of the new account
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: acceptFeesAndCharges, var: accept_fees_and_charges}, {name: accountName, var: account_name}, {name: currency, var: currency}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    accept_fees_and_charges: $accept_fees_and_charges, account_name: $account_name, currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the details of a fire.com Account
#
# GET /v1/accounts/{ican}
# Returns: record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>
# operationId: getAccountById
export def "get-account-by-id" [
  ican: int
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
    path: "/v1/accounts/{ican}"
    path_params: [{name: ican, var: ican}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ican: $ican
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions
# DEPRECATED
# Returns: record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>>
# operationId: getTransactionsByIdv1
@deprecated
export def "get-transactions-by-idv1" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # required, format: int64
  --offset: int # required, format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{ican}/transactions"
    path_params: [{name: ican, var: ican}]
    query: [{name: limit, var: limit, required: true}, {name: offset, var: offset, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ican: $ican, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Filtered list of transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions/filter
# DEPRECATED
# Returns: record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>>
# operationId: getTransactionsFilteredById
@deprecated
export def "get-transactions-filtered-by-id" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range-from: int # required, format: int64
  --date-range-to: int # required, format: int64
  --search-keyword: string # required
  --transaction-types: list<string> # required
  --offset: int # required, format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/accounts/{ican}/transactions/filter"
    path_params: [{name: ican, var: ican}]
    query: [{name: dateRangeFrom, var: date_range_from, required: true}, {name: dateRangeTo, var: date_range_to, required: true}, {name: searchKeyword, var: search_keyword, required: true}, {name: transactionTypes, var: transaction_types, style: multi, required: true}, {name: offset, var: offset, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ican: $ican, date_range_from: $date_range_from, date_range_to: $date_range_to, search_keyword: $search_keyword, transaction_types: $transaction_types, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new API Application
#
# POST /v1/apps
# Returns: record<applicationId: int, clientId: string, clientKey: string, enabled: bool, expiry: string, ican: int, numberOfPayeeApprovalsRequired: int, numberOfPaymentApprovalsRequired: int, refreshToken: string>
# operationId: createApiApplication
export def "create-api-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-name: string # A name for the API Application to help you identify it (e.g. Batch Processing API)
  --enabled: oneof<nothing, bool> # Whether or not this API Application can be used (e.g. true)
  --expiry: string # The date that this API Application can no longer be used. (format: date-time, e.g. 2019-08-22T07:48:56.460Z)
  --ican: int # The ICAN of one of your Fire accounts. Restrict this API Application to a certan account. (format: int64)
  --number-of-payee-approvals-required: int # Number of approvals required to create a payee in a batch (e.g. 1)
  --number-of-payment-approvals-required: int # Number of approvals required to process a payment in a batch (e.g. 1)
  --permissions: list<string> # The list of permissions required (e.g. [PERM_BUSINESS_POST_PAYMENT_REQUEST, PERM_BUSINESS_GET_ASPSPS])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps"
    body: {content_type: "application/json", kind: json, fields: [{name: applicationName, var: application_name}, {name: enabled, var: enabled}, {name: expiry, var: expiry}, {name: ican, var: ican}, {name: numberOfPayeeApprovalsRequired, var: number_of_payee_approvals_required}, {name: numberOfPaymentApprovalsRequired, var: number_of_payment_approvals_required}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    application_name: $application_name, enabled: $enabled, expiry: $expiry, ican: $ican, number_of_payee_approvals_required: $number_of_payee_approvals_required, number_of_payment_approvals_required: $number_of_payment_approvals_required, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate with the API.
#
# POST /v1/apps/accesstokens
# Returns: record<accessToken: string, apiApplicationId: int, businessId: int, expiry: string, permissions: list<string>>
# operationId: authenticate
export def "authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --client-secret: string # The SHA256 hash of the nonce above and the app’s Client Key. The Client Key will only be shown to you when you create the app, so don’t forget to save it somewhere safe. SECRET=( `/bin/echo -n $NONCE$CLIENT_KEY | sha256sum` ). (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --grant-type: string@grant-type-completer # Always `AccessToken`. (This will change to `refresh_token` in a future release.)
  --nonce: int # A random non-repeating number used as a salt for the `clientSecret` below. The simplest nonce is a unix time. (format: int64, e.g. 728345638475)
  --refresh-token: string # The Refresh Token for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/apps/accesstokens"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: grantType, var: grant_type}, {name: nonce, var: nonce}, {name: refreshToken, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, nonce: $nonce, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of ASPSPs / Banks
#
# GET /v1/aspsps
# Returns: record<aspsps: table<alias: string, aspspUuid: string, country: record, currency: record, dateCreated: string, lastUpdated: string, logoUrl: string>, total: int>
# operationId: getListOfAspsps
export def "get-list-of-aspsps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string # The three letter code for the currency - either `EUR` or `GBP`. Use this to filter the list for banks that can be used to pay in a certain currency. (e.g. EUR)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/aspsps"
    query: [{name: currency, var: currency}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    currency: $currency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List batches
#
# GET /v1/batches
# Returns: record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>
# operationId: getBatches
export def "get-batches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-status: string@batch-status-completer # e.g. SUBMITTED
  --batch-types: string@batch-types-completer # e.g. INTERNAL_TRANSFER
  --order-by: string@order-by-completer # e.g. DATE
  --order: string@order-completer # e.g. DESC
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/batches"
    query: [{name: batchStatus, var: batch_status}, {name: batchTypes, var: batch_types}, {name: orderBy, var: order_by}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_status: $batch_status, batch_types: $batch_types, order_by: $order_by, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new batch of payments
#
# POST /v1/batches
# Returns: record<batchUuid: string>
# operationId: createBatchPayment
export def "create-batch-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-name: string # An optional name you give to the batch at creation time. (e.g. January 2018 Payroll)
  --callback-url: string # An optional POST URL that all events for this batch will be sent to. (e.g. https://my.webserver.com/cb/payroll)
  --currency: string # GBP or EUR (e.g. EUR)
  --job-number: string # An optional job number you can give to the batch to help link it to your own system. (e.g. 2022-01-PR)
  --type: string@type-completer # The type of the batch - can be one of the listed 3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/batches"
    body: {content_type: "application/json", kind: json, fields: [{name: batchName, var: batch_name}, {name: callbackUrl, var: callback_url}, {name: currency, var: currency}, {name: jobNumber, var: job_number}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_name: $batch_name, callback_url: $callback_url, currency: $currency, job_number: $job_number, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a batch
#
# DELETE /v1/batches/{batchUuid}
# operationId: cancelBatchPayment
export def "cancel-batch-payment" [
  batch_uuid: string
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
    path: "/v1/batches/{batchUuid}"
    path_params: [{name: batchUuid, var: batch_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of a single Batch
#
# GET /v1/batches/{batchUuid}
# Returns: record<batchName: string, batchUuid: string, callbackUrl: string, currency: string, dateCreated: string, jobNumber: string, lastUpdated: string, numberOfItemsFailed: int, numberOfItemsSubmitted: int, numberOfItemsSucceeded: int, sourceName: string, status: string, type: string, valueOfItemsFailed: int, valueOfItemsSubmitted: int, valueOfItemsSucceeded: int>
# operationId: getDetailsSingleBatch
export def "get-details-single-batch" [
  batch_uuid: string
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
    path: "/v1/batches/{batchUuid}"
    path_params: [{name: batchUuid, var: batch_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a batch for approval
#
# PUT /v1/batches/{batchUuid}
# operationId: submitBatch
export def "submit-batch" [
  batch_uuid: string
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
    method: put
    path: "/v1/batches/{batchUuid}"
    path_params: [{name: batchUuid, var: batch_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    batch_uuid: $batch_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Approvers for a Batch
#
# GET /v1/batches/{batchUuid}/approvals
# Returns: record<approvals: table<emailAddress: string, firstName: string, lastName: string, lastUpdated: string, mobileNumber: string, status: string, userId: int>>
# operationId: getListofApproversForBatch
export def "get-listof-approvers-for-batch" [
  batch_uuid: string
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
    path: "/v1/batches/{batchUuid}/approvals"
    path_params: [{name: batchUuid, var: batch_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List items in a Batch
#
# GET /v1/batches/{batchUuid}/banktransfers
# Returns: record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>
# operationId: getItemsBatchBankTransfer
export def "get-items-batch-bank-transfer" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/batches/{batchUuid}/banktransfers"
    path_params: [{name: batchUuid, var: batch_uuid}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a bank transfer payment to the batch.
#
# POST /v1/batches/{batchUuid}/banktransfers
# Returns: record<batchItemUuid: string>
# operationId: addBankTransferBatchPayment
export def "add-bank-transfer-batch-payment" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The value of the transaction (format: int64, e.g. 500)
  --dest-account-holder-name: string # The destination account holder name (e.g. John Smith)
  --dest-account-number: string # The destination Account Number if a GBP bank transfer (e.g. 12345678)
  --dest-iban: string # The destination IBAN if a Euro Bank transfer (e.g. IE00AIBK93123412341234)
  --dest-nsc: string # The destination Nsc if a GBP bank transfer (e.g. 123456)
  --ican-from: int # The Fire account ID for the fire.com account the funds are taken from. (format: int64, e.g. 2001)
  --my-ref: string # The reference on the transaction for your records - not shown to the beneficiary. (e.g. Payment to John Smith for Consultancy in device.)
  --payee-type: string@payee-type-completer # Use ACCOUNT_DETAILS if you are providing account numbers/sort codes/IBANs (Mode 2). Specify the account details in the destIban, destAccountHolderName, destNsc or destAccountNumber fields as appropriate. (e.g. ACCOUNT_DETAILS)
  --your-ref: string # The reference on the transaction - displayed on the beneficiary bank statement. (e.g. ACME LTD - INV 23434)
  --payee-id: int # The ID of the existing or automatically created payee (format: int64, e.g. 15002)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/batches/{batchUuid}/banktransfers"
    path_params: [{name: batchUuid, var: batch_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: destAccountHolderName, var: dest_account_holder_name}, {name: destAccountNumber, var: dest_account_number}, {name: destIban, var: dest_iban}, {name: destNsc, var: dest_nsc}, {name: icanFrom, var: ican_from}, {name: myRef, var: my_ref}, {name: payeeType, var: payee_type}, {name: yourRef, var: your_ref}, {name: payeeId, var: payee_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, amount: $amount, dest_account_holder_name: $dest_account_holder_name, dest_account_number: $dest_account_number, dest_iban: $dest_iban, dest_nsc: $dest_nsc, ican_from: $ican_from, my_ref: $my_ref, payee_type: $payee_type, your_ref: $your_ref, payee_id: $payee_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Payment from the Batch (Bank Transfers)
#
# DELETE /v1/batches/{batchUuid}/banktransfers/{itemUuid}
# operationId: deleteBankTransferBatchPayment
export def "delete-bank-transfer-batch-payment" [
  batch_uuid: string
  item_uuid: string
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
    path: "/v1/batches/{batchUuid}/banktransfers/{itemUuid}"
    path_params: [{name: batchUuid, var: batch_uuid}, {name: itemUuid, var: item_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, item_uuid: $item_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List items in a Batch
#
# GET /v1/batches/{batchUuid}/internaltransfers
# Returns: record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int>
# operationId: getItemsBatchInternalTrasnfer
export def "get-items-batch-internal-trasnfer" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/batches/{batchUuid}/internaltransfers"
    path_params: [{name: batchUuid, var: batch_uuid}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an internal transfer payment to the batch
#
# POST /v1/batches/{batchUuid}/internaltransfers
# Returns: record<batchItemUuid: string>
# operationId: addInternalTransferBatchPayment
export def "add-internal-transfer-batch-payment" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # amount of funds to be transfered (format: int64, e.g. 10000)
  --ican-from: int # The account ID for the fire.com account the funds are taken from (format: int64, e.g. 2001)
  --ican-to: int # The account ID for the fire.com account the funds are directed to (format: int64, e.g. 3221)
  --ref: string # The reference on the transaction (e.g. Moving funds to Operating Account)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/batches/{batchUuid}/internaltransfers"
    path_params: [{name: batchUuid, var: batch_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: icanFrom, var: ican_from}, {name: icanTo, var: ican_to}, {name: ref, var: ref}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, amount: $amount, ican_from: $ican_from, ican_to: $ican_to, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Payment from the Batch (Internal Transfer)
#
# DELETE /v1/batches/{batchUuid}/internaltransfers/{itemUuid}
# operationId: deleteInternalTransferBatchPayment
export def "delete-internal-transfer-batch-payment" [
  batch_uuid: string
  item_uuid: string
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
    path: "/v1/batches/{batchUuid}/internaltransfers/{itemUuid}"
    path_params: [{name: batchUuid, var: batch_uuid}, {name: itemUuid, var: item_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_uuid: $batch_uuid, item_uuid: $item_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View List of Cards.
#
# GET /v1/cards
# Returns: record<cards: table<blocked: bool, cardId: int, dateCreated: string, emailAddress: string, eurIcan: int, expiryDate: string, firstName: string, gbpIcan: int, lastName: string, maskedPan: string, provider: string, status: string, statusReason: string, userId: int>>
# operationId: getListofCards
export def "get-listof-cards" [
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
    path: "/v1/cards"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new debit card.
#
# POST /v1/cards
# Returns: record<cardId: int, expiryDate: string, maskedPan: string, status: string>
# operationId: createNewCard
export def "create-new-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-fees-and-charges: oneof<nothing, bool> # e.g. true
  --address-type: string@address-type-completer # e.g. BUSINESS
  --card-pin: string # e.g. 5345
  --eur-ican: int # format: int64, e.g. 2150
  --gbp-ican: int # format: int64, e.g. 2152
  --user-id: int # format: int64, e.g. 3245
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/cards"
    body: {content_type: "application/json", kind: json, fields: [{name: acceptFeesAndCharges, var: accept_fees_and_charges}, {name: addressType, var: address_type}, {name: cardPin, var: card_pin}, {name: eurIcan, var: eur_ican}, {name: gbpIcan, var: gbp_ican}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accept_fees_and_charges: $accept_fees_and_charges, address_type: $address_type, card_pin: $card_pin, eur_ican: $eur_ican, gbp_ican: $gbp_ican, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block a card
#
# POST /v1/cards/{cardId}/block
# operationId: blockCard
export def "block-card" [
  card_id: int
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
    path: "/v1/cards/{cardId}/block"
    path_params: [{name: cardId, var: card_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Card Transactions.
#
# GET /v1/cards/{cardId}/transactions
# Returns: table<dateRangeTo: int, total: int, transactions: list<record>>
# operationId: getListofCardTransactions
export def "get-listof-card-transactions" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --offset: int # format: int64
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/cards/{cardId}/transactions"
    path_params: [{name: cardId, var: card_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock a card
#
# POST /v1/cards/{cardId}/unblock
# operationId: unblockCard
export def "unblock-card" [
  card_id: int
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
    path: "/v1/cards/{cardId}/unblock"
    path_params: [{name: cardId, var: card_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all DD payments associated with a direct debit mandate
#
# GET /v1/directdebits
# Returns: record<directdebits: table<amount: int, currency: record, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>, total: int>
# operationId: getDirectDebitsForMandateUuid
export def "get-direct-debits-for-mandate-uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandate-uuid: string # The mandate UUID to retrieve (required, e.g. 1A07774B-1461-4595-BC4B-423B739712AF)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/directdebits"
    query: [{name: mandateUuid, var: mandate_uuid, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mandate_uuid: $mandate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a direct debit
#
# GET /v1/directdebits/{directDebitUuid}
# Returns: record<amount: int, currency: record<code: string, description: string>, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>
# operationId: getDirectDebitByUuid
export def "get-direct-debit-by-uuid" [
  direct_debit_uuid: string
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
    path: "/v1/directdebits/{directDebitUuid}"
    path_params: [{name: directDebitUuid, var: direct_debit_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    direct_debit_uuid: $direct_debit_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject a direct debit payment
#
# POST /v1/directdebits/{directDebitUuid}/reject
# operationId: rejectDirectDebit
export def "reject-direct-debit" [
  direct_debit_uuid: string
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
    path: "/v1/directdebits/{directDebitUuid}/reject"
    path_params: [{name: directDebitUuid, var: direct_debit_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    direct_debit_uuid: $direct_debit_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all direct debit mandates
#
# GET /v1/mandates
# Returns: record<mandates: table<alias: string, currency: record, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>, total: int>
# operationId: getDirectDebitMandates
export def "get-direct-debit-mandates" [
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
    path: "/v1/mandates"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get direct debit mandate details
#
# GET /v1/mandates/{mandateUuid}
# Returns: record<alias: string, currency: record<code: string, description: string>, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>
# operationId: getMandate
export def "get-mandate" [
  mandate_uuid: string
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
    path: "/v1/mandates/{mandateUuid}"
    path_params: [{name: mandateUuid, var: mandate_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mandate_uuid: $mandate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a direct debit mandate alias
#
# POST /v1/mandates/{mandateUuid}
# operationId: updateMandateAlias
export def "update-mandate-alias" [
  mandate_uuid: string
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
    path: "/v1/mandates/{mandateUuid}"
    path_params: [{name: mandateUuid, var: mandate_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mandate_uuid: $mandate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/activate
# operationId: activateMandate
export def "activate-mandate" [
  mandate_uuid: string
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
    path: "/v1/mandates/{mandateUuid}/activate"
    path_params: [{name: mandateUuid, var: mandate_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mandate_uuid: $mandate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/cancel
# operationId: cancelMandateByUuid
export def "cancel-mandate-by-uuid" [
  mandate_uuid: string
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
    path: "/v1/mandates/{mandateUuid}/cancel"
    path_params: [{name: mandateUuid, var: mandate_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mandate_uuid: $mandate_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Payee Bank Accounts
#
# GET /v1/payees
# Returns: record<fundingSources: table<accountHolderName: string, accountName: string, accountNumber: string, bic: string, createdBy: string, currency: record, dateCreated: string, iban: string, id: int, nsc: string, status: string>, total: int>
# operationId: getPayees
export def "get-payees" [
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
    path: "/v1/payees"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Fire Open Payment request
#
# POST /v1/paymentrequests
# Returns: record<code: string, type: string>
# operationId: newPaymentRequest
export def "new-payment-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fields: string # These fields will be dispalyed to the payer when using the hosted option. You can choose to display any of `ORDER_ID`, `PRODUCT_ID`, `CUSTOMER_ID`, `CUSTOMER_NUMBER` and `COMMENT2` to the payer. (e.g. ORDER_ID|PRODUCT_ID|CUSTOMER_ID|CUSTOMER_NUMBER|COMMENT2)
  --amount: int # The requested amount to pay. Note the last two digits represent pennies/cents, (e.g., £1.00 = 100). (format: int64, e.g. 1000)
  --collect-fields: string # For the hosted option, the payer will be asked to fill in these fields but they will not be mandatory. You can choose to collect any of the payer's `ADDRESS`, `REFERENCE` and/or `COMMENT1`. If you choose to collect these fields from the payer, you cannot set 'delivery’, 'variableReference’ or 'comment1’ fields respectively. (e.g. ADDRESS|REFERENCE|COMMENT1)
  currency: string@currency-completer # Either `EUR` or `GBP`, and must correspond to the currency of the account the funds are being lodged into in the `icanTo`.
  description: string # A public facing description of the request. This will be shown to the user when they tap or scan the request. (e.g. Gym Fees Oct 2020)
  --expiry: string # This is the expiry of the payment request. After this time, the payment cannot be paid. (format: date-time, e.g. 2020-10-22T07:48:56.460Z)
  ican_to: int # The ican of the account to collect the funds into. Must be one of your fire.com Accounts. (format: int64, e.g. 42)
  --mandatory-fields: string # For the hosted option, these fields will be madatory for the payer to fill in on the hosted payment page. You can choose to collect any the payer's `ADDRESS`, `REFERENCE` and/or `COMMENT1`. If you choose to collect these fields from the payer, you cannot set 'delivery’, 'variableReference’ or 'comment1’ fields respectively. (e.g. ADDRESS|REFERENCE|COMMENT1)
  --max-number-payments: int # The max number of people who can pay this request. Must be set to 1 for the ECOMMERCE_GOODS and ECOMMERCE_SERVICES types. (e.g. 1)
  my_ref: string # An internal description of the request. (e.g. Fees)
  --order-details: record # shape: {comment1?: string, comment2?: string, customerNumber?: string, deliveryAddressLine1?: string, deliveryAddressLine2?: string, deliveryCity?: string, deliveryCountry?: string, deliveryPostCode?: string, merchantCustomerIdentification?: string, merchantNumber?: string, orderId?: string, productId?: string, variableReference?: string}
  --return-url: string # The merchant return URL where the customer will be re-directed to with the result of the transaction. (e.g. https://example.com/callback)
  type: string@type-completer-1 # The type of Fire Open Payment that was created
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/paymentrequests"
    body: {content_type: "application/json", kind: json, fields: [{name: additionalFields, var: additional_fields}, {name: amount, var: amount}, {name: collectFields, var: collect_fields}, {name: currency, var: currency}, {name: description, var: description}, {name: expiry, var: expiry}, {name: icanTo, var: ican_to}, {name: mandatoryFields, var: mandatory_fields}, {name: maxNumberPayments, var: max_number_payments}, {name: myRef, var: my_ref}, {name: orderDetails, var: order_details}, {name: returnUrl, var: return_url}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    additional_fields: $additional_fields, amount: $amount, collect_fields: $collect_fields, currency: $currency, description: $description, expiry: $expiry, ican_to: $ican_to, mandatory_fields: $mandatory_fields, max_number_payments: $max_number_payments, my_ref: $my_ref, order_details: $order_details, return_url: $return_url, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Payment Details
#
# GET /v1/payments/{paymentUuid}
# Returns: record<additionalFields: string, amount: int, collectFields: string, currency: record<code: string, description: string>, description: string, expiry: string, icanTo: int, mandatoryFields: string, maxNumberPayments: int, myRef: string, orderDetails: record<comment1: string, comment2: string, customerNumber: string, deliveryAddressLine1: string, deliveryAddressLine2: string, deliveryCity: string, deliveryCountry: string, deliveryPostCode: string, merchantCustomerIdentification: string, merchantNumber: string, orderId: string, productId: string, variableReference: string>, paymentRequestCode: string, paymentUuid: string, returnUrl: string, status: string, transactionType: string, type: string, webhookUrl: string>
# operationId: getPaymentDetails
export def "get-payment-details" [
  payment_uuid: string
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
    path: "/v1/payments/{paymentUuid}"
    path_params: [{name: paymentUuid, var: payment_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_uuid: $payment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details of a specific fire.com user.
#
# GET /v1/user/{userId}
# Returns: record<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string>
# operationId: getUser
export def "get-user" [
  user_id: int
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
    path: "/v1/user/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all users on your fire.com account
#
# GET /v1/users
# Returns: table<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string>
# operationId: getUsers
export def "get-users" [
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
    path: "/v1/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List transactions for an account (v3)
#
# GET /v3/accounts/{ican}/transactions
# Returns: record<content: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>, links: table<href: string, rel: string>>
# operationId: getTransactionsByIdv3
export def "get-transactions-by-idv3" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --date-range-from: int # format: int64
  --date-range-to: int # format: int64
  --start-after: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/accounts/{ican}/transactions"
    path_params: [{name: ican, var: ican}]
    query: [{name: limit, var: limit}, {name: dateRangeFrom, var: date_range_from}, {name: dateRangeTo, var: date_range_to}, {name: startAfter, var: start_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ican: $ican, limit: $limit, date_range_from: $date_range_from, date_range_to: $date_range_to, start_after: $start_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
