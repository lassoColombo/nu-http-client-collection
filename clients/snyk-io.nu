# Auto-generated client for Snyk API v1.0.0
# Source: https://api.apis.guru/v2/specs/snyk.io/1.0.0/openapi.json
# Auth: --token flag or $env.SNYK_API_TOKEN

const CLIENT = {
  base_url: "https://api.snyk.io/api/v1"
  token_env_var: "SNYK_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://api.snyk.io/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-by-completer [] { ["dependenciesWithIssues" "dependency" "projects" "severity"] }
def order-completer [] { ["asc" "desc"] }
def entitlement-key-completer [] { ["fullVulnDB" "licenses" "reports"] }
def type-completer [] { ["acr" "artifactory-cr" "azure-repos" "bitbucket-cloud" "bitbucket-server" "digitalocean-cr" "docker-hub" "ecr" "gcr" "github" "github-cr" "github-enterprise" "gitlab" "gitlab-cr" "google-artifact-cr" "harbor-cr" "nexus-cr" "quay-cr"] }
def sort-by-completer-1 [] { ["dependencies" "license" "projects" "severity"] }
def reason-type-completer [] { ["not-vulnerable" "temporary-ignore" "wont-fix"] }
def group-by-completer [] { ["fixable" "project,[severity|fixable]" "severity"] }
def group-by-completer-1 [] { ["isPrivate" "issuesPrevented"] }
def sort-by-completer-2 [] { ["introducedDate" "isFixed" "isIgnored" "isPatchable" "isPatched" "isUpgradable" "issueTitle" "priorityScore" "projectName" "severity"] }
def group-by-completer-2 [] { ["issue"] }
def encoding-completer [] { ["base64" "plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-all-members-in-a-group: "list<any>"
    view-group-settings: "record<requestAccess: record<enabled: bool>, sessionLength: float>"
    update-group-settings: "record<requestAccess: record<enabled: bool>, sessionLength: float>"
    list-all-tags-in-a-group: "record<tags: list<any>>"
    delete-tag-from-group: "record<force: bool, key: string, value: string>"
    list-all-dependencies: "record<results: table<copyright: list, dependenciesWithIssues: list, deprecatedVersions: list, firstPublishedDate: string, id: string, isDeprecated: bool, issuesCritical: float, issuesHigh: float, issuesLow: float, issuesMedium: float, latestVersion: string, latestVersionPublishedDate: string, licenses: list, name: string, projects: list, type: string, version: string>, total: float>"
    list: "record"
    get-import-job-details: "record<created: string, id: string, logs: list<any>, status: string>"
    retrieve: "record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, dockerfileSCMEnabled: bool, manualRemediationPrs: record<usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>"
    put-org-org-id-integrations-integration-id-settings: "record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, dockerfileSCMEnabled: bool, manualRemediationPrs: record<usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>"
    get-existing-integration-by-type: "record<id: string>"
    list-all-licenses: "record<results: table<dependencies: list, id: string, instructions: string, projects: list, severity: string>, total: float>"
    list-members: "list<any>"
    get-org-org-id-notification-settings: "record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>"
    set-notification-settings: "record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>"
    retrieve-a-single-project: "record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>, branch: string, browseUrl: string, created: string, hostname: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record<email: string, id: string, name: string, username: string>, isMonitored: bool, issueCountsBySeverity: record<critical: float, high: float, low: float, medium: float>, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remediation: record<patch: record, pin: record, upgrade: record>, remoteRepoUrl: string, tags: list<any>, targetReference: string, testFrequency: string, totalDependencies: float, type: string>"
    update-a-project: "record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>, branch: string, browseUrl: string, created: string, hostname: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record<email: string, id: string, name: string, username: string>, isMonitored: bool, issueCountsBySeverity: record<critical: float, high: float, low: float, medium: float>, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remediation: record<patch: record, pin: record, upgrade: record>, remoteRepoUrl: string, tags: list<any>, targetReference: string, testFrequency: string, totalDependencies: float, type: string>"
    list-all-aggregated-issues: "record<issues: table<fixInfo: record, id: string, ignoreReasons: list, introducedThrough: list, isIgnored: bool, isPatched: bool, issueData: record, issueType: string, links: record, pkgName: string, pkgVersions: list, priority: record>>"
    applying-attributes: "record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>>"
    get-project-dependency-graph: "record<depGraph: record<graph: record<nodes: list, rootNodeId: string>, pkgManager: record<name: string, repositories: list, version: string>, pkgs: list<record>, schemaVersion: string>>"
    list-all-project-snapshots: "record<snapshots: table<created: string, id: string, imageBaseImage: string, imageId: string, imagePlatform: string, imageTag: string, issueCounts: record, method: string, totalDependencies: float>, total: float>"
    list-all-project-snapshot-aggregated-issues: "record<issues: table<fixInfo: record, id: string, ignoreReasons: list, introducedThrough: list, isIgnored: bool, isPatched: bool, issueData: record, issueType: string, links: record, pkgName: string, pkgVersions: list, priority: record>>"
    list-all-project-snapshot-issue-paths: "record<links: record<last: string, next: string, prev: string>, paths: list<list<record>>, snapshotId: string, total: float>"
    replace-ignores: "list<any>"
    create-jira-issue: "record<jiraIssue: record<id: string, key: string>>"
    list-all-project-issue-paths: "record<links: record<last: string, next: string, prev: string>, paths: list<list<record>>, snapshotId: string, total: float>"
    list-project-settings: "record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>"
    update-project-settings: "record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>"
    add-a-tag-to-a-project: "record<tags: list<any>>"
    remove-a-tag-from-a-project: "record<tags: list<any>>"
    list-all-projects: "record<org: record<id: string, name: string>, projects: table<attributes: record, branch: string, browseUrl: string, created: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record, isMonitored: bool, issueCountsBySeverity: record, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remoteRepoUrl: string, tags: list, targetReference: string, testFrequency: string, totalDependencies: float, type: string>>"
    delete-pending-user-provision: "record<ok: bool>"
    list-pending-user-provisions: "list<any>"
    provision-a-user-to-the-organization: "record<created: string, email: string, role: string, rolePublicId: string>"
    view-organization-settings: "record<requestAccess: record<enabled: bool>>"
    update-organization-settings: "record<requestAccess: record<enabled: bool>>"
    get-issue-counts: "record<results: table<count: float, day: string, fixable: record, severity: record>>"
    get-latest-issue-counts: "record<results: table<count: float, day: string, fixable: record, severity: record>>"
    get-project-counts: "record<results: table<count: float, day: string>>"
    get-latest-project-counts: "record<results: table<count: float, day: string>>"
    get-test-counts: "record<results: table<count: float, isPrivate: record, issuesPrevented: record>>"
    get-list-of-issues: "record<results: table<fixedDate: string, introducedDate: string, isFixed: bool, issue: record, patchedDate: string>, total: float>"
    get-list-of-latest-issues: "record<results: table<fixedDate: string, introducedDate: string, isFixed: bool, issue: record, patchedDate: string>, total: float>"
    get-my-details: "record<email: string, id: string, orgs: any, username: string>"
    get-organization-notification-settings: "record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>"
    modify-organization-notification-settings: "record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>"
    get-project-notification-settings: "record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>"
    get-user-details: "record<email: string, id: string, name: string, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-group-level-audit-logs" "list-all-members-in-a-group" "add-a-member-to-an-organization-within-a-group" "list-all-organizations-in-a-group" "list-all-roles-in-a-group" "view-group-settings" "update-group-settings" "list-all-tags-in-a-group" "delete-tag-from-group" "monitor-dep-graph" "create-a-new-organization" "remove-organization" "get-organization-level-audit-logs" "list-all-dependencies" "get-an-organizations-entitlement-value" "list-all-entitlements" "list" "add-new-integration" "update-existing-integration" "delete-credentials" "provision-new-broker-token" "switch-between-broker-tokens" "clone-an-integration-with-settings-and-credentials" "import-targets" "get-import-job-details" "retrieve" "put-org-org-id-integrations-integration-id-settings" "get-existing-integration-by-type" "invite-users" "list-all-licenses" "list-members" "update-a-members-role-in-the-organization" "remove-a-member-from-the-organization" "update-a-member-in-the-organization" "get-org-org-id-notification-settings" "set-notification-settings" "delete-a-project" "retrieve-a-single-project" "update-a-project" "activate" "list-all-aggregated-issues" "applying-attributes" "deactivate" "get-project-dependency-graph" "list-all-project-snapshots" "list-all-project-snapshot-aggregated-issues" "list-all-project-snapshot-issue-paths" "delete-ignores" "retrieve-ignore" "add-ignore" "replace-ignores" "list-all-ignores" "create-jira-issue" "list-all-project-issue-paths" "list-all-jira-issues" "move-project-to-a-different-organization" "delete-project-settings" "list-project-settings" "update-project-settings" "add-a-tag-to-a-project" "remove-a-tag-from-a-project" "list-all-projects" "delete-pending-user-provision" "list-pending-user-provisions" "provision-a-user-to-the-organization" "view-organization-settings" "update-organization-settings" "list-webhooks" "create-a-webhook" "delete-a-webhook" "retrieve-a-webhook" "ping-a-webhook" "list-all-the-organizations-a-user-belongs-to" "get-issue-counts" "get-latest-issue-counts" "get-project-counts" "get-latest-project-counts" "get-test-counts" "get-list-of-issues" "get-list-of-latest-issues" "test-composer-json-composer-lock-file" "test-dep-graph" "test-gopkg-toml-gopkg-lock-file" "test-vendor-json-file" "test-gradle-file" "test-for-issues-in-a-public-package-by-group-name-and-version" "test-maven-file" "test-for-issues-in-a-public-package-by-group-id-artifact-id-and-version" "test-package-json-package-lock-json-file" "test-for-issues-in-a-public-package-by-name-and-version" "test-requirements-txt-file" "get-test-pip-package-name-version" "test-gemfile-lock-file" "test-for-issues-in-a-public-gem-by-name-and-version" "test-sbt-file" "get-test-sbt-group-id-artifact-id-version" "test-package-json-yarn-lock-file" "get-my-details" "get-organization-notification-settings" "modify-organization-notification-settings" "get-project-notification-settings" "modify-project-notification-settings" "get-user-details" "commands"] | sort) } | get name | first)
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

# Get group level audit logs
#
# POST /group/{groupId}/audit
# operationId: Get group level audit logs
export def "get-group-level-audit-logs" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to fetch results from, in the format YYYY-MM-DD. Default is 3 months ago. Please note that logs are only available for past 3 months. (e.g. 2019-07-01)
  --to: string # The date you wish to fetch results until, in the format YYYY-MM-DD. Default is today. Please note that logs are only available for past 3 months. (e.g. 2019-07-07)
  --page: float # The page of results to request. Audit logs are returned in page sizes of 100 (e.g. 1)
  --sort-order: string # The sort order of the returned audit logs by date. Values: `ASC`, `DESC`. Default: `DESC`. (e.g. ASC)
  --filters: record # shape: {email?: string, ... (4 more fields)}
]: any -> any {
  $in | http-request {
    method: post
    path: "/group/{groupId}/audit"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: from, var: from}, {name: to, var: to}, {name: page, var: page}, {name: sortOrder, var: sort_order}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, from: $from, to: $to, page: $page, sort_order: $sort_order, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all members in a group
#
# GET /group/{groupId}/members
# Returns: list<any>
# operationId: List all members in a group
export def "list-all-members-in-a-group" [
  group_id: string
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
    path: "/group/{groupId}/members"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a member to an organization within a group
#
# POST /group/{groupId}/org/{orgId}/members
# operationId: Add a member to an organization within a group
export def "add-a-member-to-an-organization-within-a-group" [
  group_id: string
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # The role of the user, "admin" or "collaborator".
  --user-id: string # The id of the user.
]: any -> any {
  $in | http-request {
    method: post
    path: "/group/{groupId}/org/{orgId}/members"
    path_params: [{name: groupId, var: group_id}, {name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, org_id: $org_id, role: $role, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all organizations in a group
#
# GET /group/{groupId}/orgs
# operationId: List all organizations in a group
export def "list-all-organizations-in-a-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (maximum is 100). (default: 100, e.g. 100)
  --page: float # For pagination - offset (from which to start returning results). (e.g. 1)
  --name: string # Only organizations that have a name that **starts with** this value (case insensitive) will be returned. (e.g. my)
]: nothing -> any {
  http-request {
    method: get
    path: "/group/{groupId}/orgs"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: perPage, var: per_page}, {name: page, var: page}, {name: name, var: name}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, per_page: $per_page, page: $page, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all roles in a group
#
# GET /group/{groupId}/roles
# operationId: List all roles in a group
export def "list-all-roles-in-a-group" [
  group_id: string
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
    path: "/group/{groupId}/roles"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View group settings
#
# GET /group/{groupId}/settings
# Returns: record<requestAccess: record<enabled: bool>, sessionLength: float>
# operationId: View group settings
export def "view-group-settings" [
  group_id: string
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
    path: "/group/{groupId}/settings"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group settings
#
# PUT /group/{groupId}/settings
# Returns: record<requestAccess: record<enabled: bool>, sessionLength: float>
# operationId: Update group settings
export def "update-group-settings" [
  group_id: string
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
    method: put
    path: "/group/{groupId}/settings"
    path_params: [{name: groupId, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tags in a group
#
# GET /group/{groupId}/tags
# Returns: record<tags: list<any>>
# operationId: List all tags in a group
export def "list-all-tags-in-a-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (the default is 1000). (e.g. 10)
  --page: float # The offset from which to start returning results from. (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/group/{groupId}/tags"
    path_params: [{name: groupId, var: group_id}]
    query: [{name: perPage, var: per_page}, {name: page, var: page}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, per_page: $per_page, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete tag from group
#
# POST /group/{groupId}/tags/delete
# Returns: record<force: bool, key: string, value: string>
# operationId: Delete tag from group
export def "delete-tag-from-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # force delete tag that has entities (default is `false`).
  --key: string # Valid tag key.
  --value: string # Valid tag value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/group/{groupId}/tags/delete"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: force, var: force}, {name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, force: $force, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monitor Dep Graph
#
# POST /monitor/dep-graph
# operationId: Monitor Dep Graph
export def "monitor-dep-graph" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  dep_graph: record # A [DepGraph data object](https://github.com/snyk/dep-graph#depgraphdata) defining all packages and their relationships. — shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
  --meta: record # Project metadata — shape: {targetFramework?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/monitor/dep-graph"
    query: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: depGraph, var: dep_graph}, {name: meta, var: meta}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org: $org, dep_graph: $dep_graph, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new organization
#
# POST /org
# operationId: Create a new organization
export def "create-a-new-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # The group ID. The `API_KEY` must have access to this group.
  name: string # The name of the new organization
  --source-org-id: string # The id of an organization to copy settings from. If provided, this organization must be associated with the same group. The items that will be copied are: Source control integrations (GitHub, GitLab, BitBucket) \+ Container registries integrations (ACR, Docker Hub, ECR, GCR) \+ Container orchestrators integrations (Kubernetes) \+ PaaS and Serverless Integrations (Heroku, AWS Lambda) \+ Notification integrations (Slack, Jira) \+ Policies \+ Ignore settings \+ Language settings \+ Infrastructure as Code settings \+ Snyk Code settings The following will not be copied across: Service accounts \+ Members \+ Projects \+ Notification preferences
]: any -> any {
  $in | http-request {
    method: post
    path: "/org"
    body: {content_type: "application/json", kind: json, fields: [{name: groupId, var: group_id}, {name: name, var: name}, {name: sourceOrgId, var: source_org_id}]}
    accept: ["application/json; charset=utf-8"]
    ok: [201]
    auth: bearer
  } {
    group_id: $group_id, name: $name, source_org_id: $source_org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove organization
#
# DELETE /org/{orgId}
# operationId: Remove organization
export def "remove-organization" [
  org_id: string
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
    path: "/org/{orgId}"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization level audit logs
#
# POST /org/{orgId}/audit
# operationId: Get organization level audit logs
export def "get-organization-level-audit-logs" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to fetch results from, in the format YYYY-MM-DD. Default is 3 months ago. Please note that logs are only available for past 3 months. (e.g. 2019-07-01)
  --to: string # The date you wish to fetch results until, in the format YYYY-MM-DD. Default is today. Please note that logs are only available for past 3 months. (e.g. 2019-07-07)
  --page: float # The page of results to request. Audit logs are returned in page sizes of 100. (e.g. 1)
  --sort-order: string # The sort order of the returned audit logs by date. Values: `ASC`, `DESC`. Default: `DESC`. (e.g. ASC)
  --filters: record # shape: {email?: string, ... (4 more fields)}
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/audit"
    path_params: [{name: orgId, var: org_id}]
    query: [{name: from, var: from}, {name: to, var: to}, {name: page, var: page}, {name: sortOrder, var: sort_order}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, from: $from, to: $to, page: $page, sort_order: $sort_order, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all dependencies
#
# POST /org/{orgId}/dependencies
# Returns: record<results: table<copyright: list, dependenciesWithIssues: list, deprecatedVersions: list, firstPublishedDate: string, id: string, isDeprecated: bool, issuesCritical: float, issuesHigh: float, issuesLow: float, issuesMedium: float, latestVersion: string, latestVersionPublishedDate: string, licenses: list, name: string, projects: list, type: string, version: string>, total: float>
# operationId: List all dependencies
export def "list-all-dependencies" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # The field to sort results by. (default: dependency, e.g. dependency)
  --order: string@order-completer # The direction to sort results by. (default: asc)
  --page: float # The page of results to fetch. (default: 1)
  --per-page: float # The number of results to fetch per page (maximum is 1000). (default: 20)
  --filters: record # shape: {depStatus?: string, dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/dependencies"
    path_params: [{name: orgId, var: org_id}]
    query: [{name: sortBy, var: sort_by}, {name: order, var: order}, {name: page, var: page}, {name: perPage, var: per_page}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, sort_by: $sort_by, order: $order, page: $page, per_page: $per_page, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization's entitlement value
#
# GET /org/{orgId}/entitlement/{entitlementKey}
# operationId: Get an organization's entitlement value
export def "get-an-organizations-entitlement-value" [
  org_id: string
  entitlement_key: string@entitlement-key-completer
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
    path: "/org/{orgId}/entitlement/{entitlementKey}"
    path_params: [{name: orgId, var: org_id}, {name: entitlementKey, var: entitlement_key}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, entitlement_key: $entitlement_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all entitlements
#
# GET /org/{orgId}/entitlements
# operationId: List all entitlements
export def "list-all-entitlements" [
  org_id: string
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
    path: "/org/{orgId}/entitlements"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List
#
# GET /org/{orgId}/integrations
# Returns: record
# operationId: List
export def "list" [
  org_id: string
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
    path: "/org/{orgId}/integrations"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new integration
#
# POST /org/{orgId}/integrations
# operationId: Add new integration
export def "add-new-integration" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credentials: record # credentials for given integration — shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
  type: string@type-completer # integration type
  --broker: record # brokered integration settings — shape: {enabled?: bool}
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/integrations"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: credentials, var: credentials}, {name: type, var: type}, {name: broker, var: broker}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, credentials: $credentials, type: $type, broker: $broker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing integration
#
# PUT /org/{orgId}/integrations/{integrationId}
# operationId: Update existing integration
export def "update-existing-integration" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --broker: record # brokered integration settings — shape: {enabled?: bool}
  type: string@type-completer # integration type
  --credentials: record # credentials for given integration — shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
]: any -> any {
  $in | http-request {
    method: put
    path: "/org/{orgId}/integrations/{integrationId}"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: broker, var: broker}, {name: type, var: type}, {name: credentials, var: credentials}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id, broker: $broker, type: $type, credentials: $credentials
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete credentials
#
# DELETE /org/{orgId}/integrations/{integrationId}/authentication
# operationId: Delete credentials
export def "delete-credentials" [
  org_id: string
  integration_id: string
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
    path: "/org/{orgId}/integrations/{integrationId}/authentication"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provision new broker token
#
# POST /org/{orgId}/integrations/{integrationId}/authentication/provision-token
# operationId: Provision new broker token
export def "provision-new-broker-token" [
  org_id: string
  integration_id: string
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
    path: "/org/{orgId}/integrations/{integrationId}/authentication/provision-token"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Switch between broker tokens
#
# POST /org/{orgId}/integrations/{integrationId}/authentication/switch-token
# operationId: Switch between broker tokens
export def "switch-between-broker-tokens" [
  org_id: string
  integration_id: string
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
    path: "/org/{orgId}/integrations/{integrationId}/authentication/switch-token"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clone an integration (with settings and credentials)
#
# POST /org/{orgId}/integrations/{integrationId}/clone
# operationId: Clone an integration (with settings and credentials)
export def "clone-an-integration-with-settings-and-credentials" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_org_public_id: string # The organization public ID. The `API_KEY` must have access to this organization.
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/integrations/{integrationId}/clone"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinationOrgPublicId, var: destination_org_public_id}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id, destination_org_public_id: $destination_org_public_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import targets
#
# POST /org/{orgId}/integrations/{integrationId}/import
# operationId: Import targets
export def "import-targets" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclusion-globs: string # a comma-separated list of up to 10 folder names to exclude from scanning (each folder name must not exceed 100 characters). If not specified, it will default to "fixtures, tests, \_\_tests\_\_, node_modules". If an empty string is provided - no folders will be excluded. This attribute is only respected with Open Source and Container scan targets.
  --files: list # an array of file objects
  --target: record # shape: {branch: string, name: string, owner: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/integrations/{integrationId}/import"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: exclusionGlobs, var: exclusion_globs}, {name: files, var: files}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id, exclusion_globs: $exclusion_globs, files: $files, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get import job details
#
# GET /org/{orgId}/integrations/{integrationId}/import/{jobId}
# Returns: record<created: string, id: string, logs: list<any>, status: string>
# operationId: Get import job details
export def "get-import-job-details" [
  org_id: string
  integration_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/org/{orgId}/integrations/{integrationId}/import/{jobId}"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}, {name: jobId, var: job_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve
#
# GET /org/{orgId}/integrations/{integrationId}/settings
# Returns: record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, dockerfileSCMEnabled: bool, manualRemediationPrs: record<usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>
# operationId: Retrieve
export def "retrieve" [
  org_id: string
  integration_id: string
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
    path: "/org/{orgId}/integrations/{integrationId}/settings"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update
#
# PUT /org/{orgId}/integrations/{integrationId}/settings
# Returns: record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, dockerfileSCMEnabled: bool, manualRemediationPrs: record<usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>
# operationId: Update
export def "put-org-org-id-integrations-integration-id-settings" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-dep-upgrade-enabled: oneof<nothing, bool> # Defines if the functionality is enabled
  --auto-dep-upgrade-ignored-dependencies: list # A list of strings defining what dependencies should be ignored
  --auto-dep-upgrade-limit: float # A limit on how many automatic dependency upgrade PRs can be opened simultaneously
  --auto-dep-upgrade-min-age: float # The age (in days) that an automatic dependency check is valid for
  --auto-remediation-prs: record # Defines automatic remediation policies — shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
  --dockerfile-scm-enabled: oneof<nothing, bool> # If true, will automatically detect and scan Dockerfiles in your Git repositories, surface base image vulnerabilities and recommend possible fixes
  --manual-remediation-prs: record # Defines manual remediation policies — shape: {usePatchRemediation?: bool}
  --pull-request-assignment: record # assign Snyk pull requests — shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
  --pull-request-fail-on-any-vulns: oneof<nothing, bool> # If an opened PR should fail to be validated if any vulnerable dependencies have been detected
  --pull-request-fail-only-for-high-severity: oneof<nothing, bool> # If an opened PR only should fail its validation if any dependencies are marked as being of high severity
  --pull-request-test-enabled: oneof<nothing, bool> # If opened PRs should be tested
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/{orgId}/integrations/{integrationId}/settings"
    path_params: [{name: orgId, var: org_id}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoDepUpgradeEnabled, var: auto_dep_upgrade_enabled}, {name: autoDepUpgradeIgnoredDependencies, var: auto_dep_upgrade_ignored_dependencies}, {name: autoDepUpgradeLimit, var: auto_dep_upgrade_limit}, {name: autoDepUpgradeMinAge, var: auto_dep_upgrade_min_age}, {name: autoRemediationPrs, var: auto_remediation_prs}, {name: dockerfileSCMEnabled, var: dockerfile_scm_enabled}, {name: manualRemediationPrs, var: manual_remediation_prs}, {name: pullRequestAssignment, var: pull_request_assignment}, {name: pullRequestFailOnAnyVulns, var: pull_request_fail_on_any_vulns}, {name: pullRequestFailOnlyForHighSeverity, var: pull_request_fail_only_for_high_severity}, {name: pullRequestTestEnabled, var: pull_request_test_enabled}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, integration_id: $integration_id, auto_dep_upgrade_enabled: $auto_dep_upgrade_enabled, auto_dep_upgrade_ignored_dependencies: $auto_dep_upgrade_ignored_dependencies, auto_dep_upgrade_limit: $auto_dep_upgrade_limit, auto_dep_upgrade_min_age: $auto_dep_upgrade_min_age, auto_remediation_prs: $auto_remediation_prs, dockerfile_scm_enabled: $dockerfile_scm_enabled, manual_remediation_prs: $manual_remediation_prs, pull_request_assignment: $pull_request_assignment, pull_request_fail_on_any_vulns: $pull_request_fail_on_any_vulns, pull_request_fail_only_for_high_severity: $pull_request_fail_only_for_high_severity, pull_request_test_enabled: $pull_request_test_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get existing integration by type
#
# GET /org/{orgId}/integrations/{type}
# Returns: record<id: string>
# operationId: Get existing integration by type
export def "get-existing-integration-by-type" [
  org_id: string
  type: string
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
    path: "/org/{orgId}/integrations/{type}"
    path_params: [{name: orgId, var: org_id}, {name: type, var: type}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite users
#
# POST /org/{orgId}/invite
# operationId: Invite users
export def "invite-users" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user.
  --is-admin: oneof<nothing, bool> # (optional) Set the role as admin.
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/invite"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: isAdmin, var: is_admin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, email: $email, is_admin: $is_admin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all licenses
#
# POST /org/{orgId}/licenses
# Returns: record<results: table<dependencies: list, id: string, instructions: string, projects: list, severity: string>, total: float>
# operationId: List all licenses
export def "list-all-licenses" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer-1 # The field to sort results by. (default: license, e.g. license)
  --order: string@order-completer # The direction to sort results by. (default: asc)
  --filters: record # shape: {dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/licenses"
    path_params: [{name: orgId, var: org_id}]
    query: [{name: sortBy, var: sort_by}, {name: order, var: order}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, sort_by: $sort_by, order: $order, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Members
#
# GET /org/{orgId}/members
# Returns: list<any>
# operationId: List Members
export def "list-members" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-group-admins: oneof<nothing, bool> # Include group administrators who also have access to this organization. (default: false, e.g. true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/org/{orgId}/members"
    path_params: [{name: orgId, var: org_id}]
    query: [{name: includeGroupAdmins, var: include_group_admins}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, include_group_admins: $include_group_admins
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a member's role in the organization
#
# PUT /org/{orgId}/members/update/{userId}
# operationId: Update a member's role in the organization
export def "update-a-members-role-in-the-organization" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-public-id: string # The new role public ID to update the user to.
]: any -> any {
  $in | http-request {
    method: put
    path: "/org/{orgId}/members/update/{userId}"
    path_params: [{name: orgId, var: org_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rolePublicId, var: role_public_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, user_id: $user_id, role_public_id: $role_public_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a member from the organization
#
# DELETE /org/{orgId}/members/{userId}
# operationId: Remove a member from the organization
export def "remove-a-member-from-the-organization" [
  org_id: string
  user_id: string
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
    path: "/org/{orgId}/members/{userId}"
    path_params: [{name: orgId, var: org_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a member in the organization
#
# PUT /org/{orgId}/members/{userId}
# operationId: Update a member in the organization
export def "update-a-member-in-the-organization" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # The new role of the user, "admin" or "collaborator".
]: any -> any {
  $in | http-request {
    method: put
    path: "/org/{orgId}/members/{userId}"
    path_params: [{name: orgId, var: org_id}, {name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, user_id: $user_id, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization notification settings
#
# GET /org/{orgId}/notification-settings
# Returns: record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>
export def "get-org-org-id-notification-settings" [
  org_id: string
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
    path: "/org/{orgId}/notification-settings"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set notification settings
#
# PUT /org/{orgId}/notification-settings
# Returns: record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>
# operationId: Set notification settings
export def "set-notification-settings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
  --project-imported: record # shape: {enabled: bool}
  --test-limit: record # shape: {enabled: bool}
  --weekly-report: record # shape: {enabled: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/{orgId}/notification-settings"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: new-issues-remediations, var: new_issues_remediations}, {name: project-imported, var: project_imported}, {name: test-limit, var: test_limit}, {name: weekly-report, var: weekly_report}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, new_issues_remediations: $new_issues_remediations, project_imported: $project_imported, test_limit: $test_limit, weekly_report: $weekly_report
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /org/{orgId}/project/{projectId}
# operationId: Delete a project
export def "delete-a-project" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single project
#
# GET /org/{orgId}/project/{projectId}
# Returns: record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>, branch: string, browseUrl: string, created: string, hostname: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record<email: string, id: string, name: string, username: string>, isMonitored: bool, issueCountsBySeverity: record<critical: float, high: float, low: float, medium: float>, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remediation: record<patch: record, pin: record, upgrade: record>, remoteRepoUrl: string, tags: list<any>, targetReference: string, testFrequency: string, totalDependencies: float, type: string>
# operationId: Retrieve a single project
export def "retrieve-a-single-project" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project
#
# PUT /org/{orgId}/project/{projectId}
# Returns: record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>, branch: string, browseUrl: string, created: string, hostname: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record<email: string, id: string, name: string, username: string>, isMonitored: bool, issueCountsBySeverity: record<critical: float, high: float, low: float, medium: float>, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remediation: record<patch: record, pin: record, upgrade: record>, remoteRepoUrl: string, tags: list<any>, targetReference: string, testFrequency: string, totalDependencies: float, type: string>
# operationId: Update a project
export def "update-a-project" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # The branch that this project should be monitoring
  --owner: record # Set to `null` to remove all ownership. User must be a member of the same organization as the project. — shape: {id?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/{orgId}/project/{projectId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: owner, var: owner}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, branch: $branch, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate
#
# POST /org/{orgId}/project/{projectId}/activate
# operationId: Activate
export def "activate" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/activate"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Aggregated issues
#
# POST /org/{orgId}/project/{projectId}/aggregated-issues
# Returns: record<issues: table<fixInfo: record, id: string, ignoreReasons: list, introducedThrough: list, isIgnored: bool, isPatched: bool, issueData: record, issueType: string, links: record, pkgName: string, pkgVersions: list, priority: record>>
# operationId: List all Aggregated issues
export def "list-all-aggregated-issues" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
  --include-description: oneof<nothing, bool> # If set to `true`, Include issue's description, if set to `false` (by default), it won't (Non-IaC projects only)
  --include-introduced-through: oneof<nothing, bool> # If set to `true`, Include issue's introducedThrough, if set to `false` (by default), it won't. It's for container only projects (Non-IaC projects only)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/aggregated-issues"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: includeDescription, var: include_description}, {name: includeIntroducedThrough, var: include_introduced_through}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, filters: $filters, include_description: $include_description, include_introduced_through: $include_introduced_through
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applying attributes
#
# POST /org/{orgId}/project/{projectId}/attributes
# Returns: record<attributes: record<criticality: list<any>, environment: list<any>, lifecycle: list<any>>>
# operationId: Applying attributes
export def "applying-attributes" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --criticality: list
  --environment: list
  --lifecycle: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/attributes"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: criticality, var: criticality}, {name: environment, var: environment}, {name: lifecycle, var: lifecycle}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, criticality: $criticality, environment: $environment, lifecycle: $lifecycle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deactivate
#
# POST /org/{orgId}/project/{projectId}/deactivate
# operationId: Deactivate
export def "deactivate" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/deactivate"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Project dependency graph
#
# GET /org/{orgId}/project/{projectId}/dep-graph
# Returns: record<depGraph: record<graph: record<nodes: list, rootNodeId: string>, pkgManager: record<name: string, repositories: list, version: string>, pkgs: list<record>, schemaVersion: string>>
# operationId: Get Project dependency graph
export def "get-project-dependency-graph" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/dep-graph"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all project snapshots
#
# POST /org/{orgId}/project/{projectId}/history
# Returns: record<snapshots: table<created: string, id: string, imageBaseImage: string, imageId: string, imagePlatform: string, imageTag: string, issueCounts: record, method: string, totalDependencies: float>, total: float>
# operationId: List all project snapshots
export def "list-all-project-snapshots" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (the default is 10, the maximum is 100). (e.g. 10)
  --page: float # The offset from which to start returning results from. (e.g. 1)
  --filters: record # shape: {imageId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/history"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    query: [{name: perPage, var: per_page}, {name: page, var: page}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, per_page: $per_page, page: $page, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all project snapshot aggregated issues
#
# POST /org/{orgId}/project/{projectId}/history/{snapshotId}/aggregated-issues
# Returns: record<issues: table<fixInfo: record, id: string, ignoreReasons: list, introducedThrough: list, isIgnored: bool, isPatched: bool, issueData: record, issueType: string, links: record, pkgName: string, pkgVersions: list, priority: record>>
# operationId: List all project snapshot aggregated issues
export def "list-all-project-snapshot-aggregated-issues" [
  org_id: string
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
  --include-description: oneof<nothing, bool> # If set to `true`, Include issue's description, if set to `false` (by default), it won't (Non-IaC projects only)
  --include-introduced-through: oneof<nothing, bool> # If set to `true`, Include issue's introducedThrough, if set to `false` (by default), it won't. It's for container only projects (Non-IaC projects only)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/history/{snapshotId}/aggregated-issues"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: snapshotId, var: snapshot_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: includeDescription, var: include_description}, {name: includeIntroducedThrough, var: include_introduced_through}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, snapshot_id: $snapshot_id, filters: $filters, include_description: $include_description, include_introduced_through: $include_introduced_through
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all project snapshot issue paths
#
# GET /org/{orgId}/project/{projectId}/history/{snapshotId}/issue/{issueId}/paths
# Returns: record<links: record<last: string, next: string, prev: string>, paths: list<list<record>>, snapshotId: string, total: float>
# operationId: List all project snapshot issue paths
export def "list-all-project-snapshot-issue-paths" [
  org_id: string
  project_id: string
  snapshot_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return per page (1 - 1000, inclusive). (default: 100, e.g. 3)
  --page: float # The page of results to return. (default: 1, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/org/{orgId}/project/{projectId}/history/{snapshotId}/issue/{issueId}/paths"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: snapshotId, var: snapshot_id}, {name: issueId, var: issue_id}]
    query: [{name: perPage, var: per_page}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, snapshot_id: $snapshot_id, issue_id: $issue_id, per_page: $per_page, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete ignores
#
# DELETE /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Delete ignores
export def "delete-ignores" [
  org_id: string
  project_id: string
  issue_id: string
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
    path: "/org/{orgId}/project/{projectId}/ignore/{issueId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve ignore
#
# GET /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Retrieve ignore
export def "retrieve-ignore" [
  org_id: string
  project_id: string
  issue_id: string
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
    path: "/org/{orgId}/project/{projectId}/ignore/{issueId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add ignore
#
# POST /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Add ignore
export def "add-ignore" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disregard-if-fixable: oneof<nothing, bool> # Only ignore the issue if no upgrade or patch is available.
  --expires: string # The timestamp that the issue will no longer be ignored.
  --ignore-path: string # The path to ignore (default is `*` which represents all paths).
  --reason: string # The reason that the issue was ignored.
  reason_type: string@reason-type-completer # The classification of the ignore.
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/ignore/{issueId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: disregardIfFixable, var: disregard_if_fixable, required: true}, {name: expires, var: expires}, {name: ignorePath, var: ignore_path}, {name: reason, var: reason}, {name: reasonType, var: reason_type}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id, disregard_if_fixable: $disregard_if_fixable, expires: $expires, ignore_path: $ignore_path, reason: $reason, reason_type: $reason_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace ignores
#
# PUT /org/{orgId}/project/{projectId}/ignore/{issueId}
# Returns: list<any>
# operationId: Replace ignores
export def "replace-ignores" [
  org_id: string
  project_id: string
  issue_id: string
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
    method: put
    path: "/org/{orgId}/project/{projectId}/ignore/{issueId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all ignores
#
# GET /org/{orgId}/project/{projectId}/ignores
# operationId: List all ignores
export def "list-all-ignores" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/ignores"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create jira issue
#
# POST /org/{orgId}/project/{projectId}/issue/{issueId}/jira-issue
# Returns: record<jiraIssue: record<id: string, key: string>>
# operationId: Create jira issue
export def "create-jira-issue" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: record # shape: {issuetype?: record, project?: record, summary?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/issue/{issueId}/jira-issue"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all project issue paths
#
# GET /org/{orgId}/project/{projectId}/issue/{issueId}/paths
# Returns: record<links: record<last: string, next: string, prev: string>, paths: list<list<record>>, snapshotId: string, total: float>
# operationId: List all project issue paths
export def "list-all-project-issue-paths" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-id: string # The project snapshot ID for which to return issue paths. If set to `latest`, the most recent snapshot will be used. Use the "List all project snapshots" endpoint to find suitable values for this. (default: latest, e.g. 6d5813be-7e6d-4ab8-80c2-1e3e2a454553)
  --per-page: float # The number of results to return per page (1 - 1000, inclusive). (default: 100, e.g. 3)
  --page: float # The page of results to return. (default: 1, e.g. 2)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/org/{orgId}/project/{projectId}/issue/{issueId}/paths"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}, {name: issueId, var: issue_id}]
    query: [{name: snapshotId, var: snapshot_id}, {name: perPage, var: per_page}, {name: page, var: page}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, issue_id: $issue_id, snapshot_id: $snapshot_id, per_page: $per_page, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all jira issues
#
# GET /org/{orgId}/project/{projectId}/jira-issues
# operationId: List all jira issues
export def "list-all-jira-issues" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/jira-issues"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move project to a different organization
#
# PUT /org/{orgId}/project/{projectId}/move
# operationId: Move project to a different organization
export def "move-project-to-a-different-organization" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-org-id: string # The ID of the organization that the project should be moved to. The API_KEY must have group admin permissions. If the project is moved to a new group, a personal level API key is needed.
]: any -> any {
  $in | http-request {
    method: put
    path: "/org/{orgId}/project/{projectId}/move"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetOrgId, var: target_org_id}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, target_org_id: $target_org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project settings
#
# DELETE /org/{orgId}/project/{projectId}/settings
# operationId: Delete project settings
export def "delete-project-settings" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/settings"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List project settings
#
# GET /org/{orgId}/project/{projectId}/settings
# Returns: record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>
# operationId: List project settings
export def "list-project-settings" [
  org_id: string
  project_id: string
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
    path: "/org/{orgId}/project/{projectId}/settings"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project settings
#
# PUT /org/{orgId}/project/{projectId}/settings
# Returns: record<autoDepUpgradeEnabled: bool, autoDepUpgradeIgnoredDependencies: list<any>, autoDepUpgradeLimit: float, autoDepUpgradeMinAge: float, autoRemediationPrs: record<backlogPrsEnabled: bool, freshPrsEnabled: bool, usePatchRemediation: bool>, pullRequestAssignment: record<assignees: list<any>, enabled: bool, type: string>, pullRequestFailOnAnyVulns: bool, pullRequestFailOnlyForHighSeverity: bool, pullRequestTestEnabled: bool>
# operationId: Update project settings
export def "update-project-settings" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-dep-upgrade-enabled: oneof<nothing, bool> # If set to `true`, Snyk will raise dependency upgrade PRs automatically.
  --auto-dep-upgrade-ignored-dependencies: list # An array of comma-separated strings with names of dependencies you wish Snyk to ignore to upgrade.
  --auto-dep-upgrade-limit: float # The limit on auto dependency upgrade PRs.
  --auto-dep-upgrade-min-age: float # The age (in days) that an automatic dependency check is valid for
  --auto-remediation-prs: record # Defines automatic remediation policies — shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
  --pull-request-assignment: record # assign Snyk pull requests — shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
  --pull-request-fail-on-any-vulns: oneof<nothing, bool> # If set to `true`, fail Snyk Test if the repo has any vulnerabilities. Otherwise, fail only when the PR is adding a vulnerable dependency.
  --pull-request-fail-only-for-high-severity: oneof<nothing, bool> # If set to `true`, fail Snyk Test only for high and critical severity vulnerabilities
  --pull-request-test-enabled: oneof<nothing, bool> # If set to `true`, Snyk Test checks PRs for vulnerabilities.:cq
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/{orgId}/project/{projectId}/settings"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoDepUpgradeEnabled, var: auto_dep_upgrade_enabled}, {name: autoDepUpgradeIgnoredDependencies, var: auto_dep_upgrade_ignored_dependencies}, {name: autoDepUpgradeLimit, var: auto_dep_upgrade_limit}, {name: autoDepUpgradeMinAge, var: auto_dep_upgrade_min_age}, {name: autoRemediationPrs, var: auto_remediation_prs}, {name: pullRequestAssignment, var: pull_request_assignment}, {name: pullRequestFailOnAnyVulns, var: pull_request_fail_on_any_vulns}, {name: pullRequestFailOnlyForHighSeverity, var: pull_request_fail_only_for_high_severity}, {name: pullRequestTestEnabled, var: pull_request_test_enabled}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, auto_dep_upgrade_enabled: $auto_dep_upgrade_enabled, auto_dep_upgrade_ignored_dependencies: $auto_dep_upgrade_ignored_dependencies, auto_dep_upgrade_limit: $auto_dep_upgrade_limit, auto_dep_upgrade_min_age: $auto_dep_upgrade_min_age, auto_remediation_prs: $auto_remediation_prs, pull_request_assignment: $pull_request_assignment, pull_request_fail_on_any_vulns: $pull_request_fail_on_any_vulns, pull_request_fail_only_for_high_severity: $pull_request_fail_only_for_high_severity, pull_request_test_enabled: $pull_request_test_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tag to a project
#
# POST /org/{orgId}/project/{projectId}/tags
# Returns: record<tags: list<any>>
# operationId: Add a tag to a project
export def "add-a-tag-to-a-project" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Alphanumeric including - and _ with a limit of 30 characters
  --value: string # Alphanumeric including - and _ with a limit of 50 characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/tags"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a tag from a project
#
# POST /org/{orgId}/project/{projectId}/tags/remove
# Returns: record<tags: list<any>>
# operationId: Remove a tag from a project
export def "remove-a-tag-from-a-project" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Alphanumeric including - and _ with a limit of 30 characters
  --value: string # Alphanumeric including - and _ with a limit of 50 characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/project/{projectId}/tags/remove"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all projects
#
# POST /org/{orgId}/projects
# Returns: record<org: record<id: string, name: string>, projects: table<attributes: record, branch: string, browseUrl: string, created: string, id: string, imageBaseImage: string, imageCluster: string, imageId: string, imagePlatform: string, imageTag: string, importingUser: record, isMonitored: bool, issueCountsBySeverity: record, lastTestedDate: string, name: string, origin: string, owner: record, readOnly: bool, remoteRepoUrl: string, tags: list, targetReference: string, testFrequency: string, totalDependencies: float, type: string>>
# operationId: List all projects
export def "list-all-projects" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {attributes?: record, isMonitored?: bool, name?: string, origin?: string, tags?: record, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/projects"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pending user provision
#
# DELETE /org/{orgId}/provision
# Returns: record<ok: bool>
# operationId: Delete pending user provision
export def "delete-pending-user-provision" [
  org_id: string
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
    method: delete
    path: "/org/{orgId}/provision"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pending user provisions
#
# GET /org/{orgId}/provision
# Returns: list<any>
# operationId: List pending user provisions
export def "list-pending-user-provisions" [
  org_id: string
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
    path: "/org/{orgId}/provision"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provision a user to the organization
#
# POST /org/{orgId}/provision
# Returns: record<created: string, email: string, role: string, rolePublicId: string>
# operationId: Provision a user to the organization
export def "provision-a-user-to-the-organization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user.
  --role: string # Deprecated. Name of the role to grant this user. Must be one of `ADMIN`, `COLLABORATOR`, or `RESTRICTED_COLLABORATOR`. This field is invalid if `rolePublicId` is supplied with the request.
  --role-public-id: string # ID of the role to grant this user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/org/{orgId}/provision"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: role, var: role}, {name: rolePublicId, var: role_public_id}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, email: $email, role: $role, role_public_id: $role_public_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View organization settings
#
# GET /org/{orgId}/settings
# Returns: record<requestAccess: record<enabled: bool>>
# operationId: View organization settings
export def "view-organization-settings" [
  org_id: string
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
    path: "/org/{orgId}/settings"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization settings
#
# PUT /org/{orgId}/settings
# Returns: record<requestAccess: record<enabled: bool>>
# operationId: Update organization settings
export def "update-organization-settings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-access: record # Can only be updated if `API_KEY` has edit access to request access settings. — shape: {enabled: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/{orgId}/settings"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: requestAccess, var: request_access}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, request_access: $request_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhooks
#
# GET /org/{orgId}/webhooks
# operationId: List webhooks
export def "list-webhooks" [
  org_id: string
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
    path: "/org/{orgId}/webhooks"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook
#
# POST /org/{orgId}/webhooks
# operationId: Create a webhook
export def "create-a-webhook" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret: string # This is a password you create, that Snyk uses to sign our transports to you, so you be sure the notification is authentic. Your `secret` should: Be a random string with high entropy; Not be used for anything else; Only known to Snyk and your webhook transport consuming code;
  --url: string # Webhooks can only be configured for URLs using the `https` protocol. `http` is not allowed.
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/{orgId}/webhooks"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: secret, var: secret}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, secret: $secret, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook
#
# DELETE /org/{orgId}/webhooks/{webhookId}
# operationId: Delete a webhook
export def "delete-a-webhook" [
  org_id: string
  webhook_id: string
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
    path: "/org/{orgId}/webhooks/{webhookId}"
    path_params: [{name: orgId, var: org_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a webhook
#
# GET /org/{orgId}/webhooks/{webhookId}
# operationId: Retrieve a webhook
export def "retrieve-a-webhook" [
  org_id: string
  webhook_id: string
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
    path: "/org/{orgId}/webhooks/{webhookId}"
    path_params: [{name: orgId, var: org_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping a webhook
#
# POST /org/{orgId}/webhooks/{webhookId}/ping
# operationId: Ping a webhook
export def "ping-a-webhook" [
  org_id: string
  webhook_id: string
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
    path: "/org/{orgId}/webhooks/{webhookId}/ping"
    path_params: [{name: orgId, var: org_id}, {name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the organizations a user belongs to
#
# GET /orgs
# operationId: List all the organizations a user belongs to
export def "list-all-the-organizations-a-user-belongs-to" [
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
    path: "/orgs"
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get issue counts
#
# POST /reporting/counts/issues
# Returns: record<results: table<count: float, day: string, fixable: record, severity: record>>
# operationId: Get issue counts
export def "get-issue-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (required, e.g. 2017-07-01)
  --to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (required, e.g. 2017-07-03)
  --group-by: string@group-by-completer # The field to group results by (e.g. severity)
  --filters: record # shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/counts/issues"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: groupBy, var: group_by}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, group_by: $group_by, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get latest issue counts
#
# POST /reporting/counts/issues/latest
# Returns: record<results: table<count: float, day: string, fixable: record, severity: record>>
# operationId: Get latest issue counts
export def "get-latest-issue-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-by: string@group-by-completer # The field to group results by (e.g. severity)
  --filters: record # shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/counts/issues/latest"
    query: [{name: groupBy, var: group_by}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_by: $group_by, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project counts
#
# POST /reporting/counts/projects
# Returns: record<results: table<count: float, day: string>>
# operationId: Get project counts
export def "get-project-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (required, e.g. 2017-07-01)
  --to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (required, e.g. 2017-07-03)
  --filters: record # shape: {languages?: list, orgs: any, projects?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/counts/projects"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get latest project counts
#
# POST /reporting/counts/projects/latest
# Returns: record<results: table<count: float, day: string>>
# operationId: Get latest project counts
export def "get-latest-project-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {languages?: list, orgs: any, projects?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/counts/projects/latest"
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get test counts
#
# POST /reporting/counts/tests
# Returns: record<results: table<count: float, isPrivate: record, issuesPrevented: record>>
# operationId: Get test counts
export def "get-test-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to count tests from, in the format `YYYY-MM-DD` (required, e.g. 2017-07-01)
  --to: string # The date you wish to count tests until, in the format `YYYY-MM-DD` (required, e.g. 2017-07-03)
  --group-by: string@group-by-completer-1 # The field to group results by (e.g. isPrivate)
  --filters: record # shape: {isPrivate?: bool, issuesPrevented?: bool, orgs: any, projects?: any}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/counts/tests"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: groupBy, var: group_by}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, group_by: $group_by, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of issues
#
# POST /reporting/issues/
# Returns: record<results: table<fixedDate: string, introducedDate: string, isFixed: bool, issue: record, patchedDate: string>, total: float>
# operationId: Get list of issues
export def "get-list-of-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (required, e.g. 2017-07-01)
  --to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (required, e.g. 2017-07-07)
  --page: float # The page of results to request (e.g. 1)
  --per-page: float # The number of results to return per page (Maximum: 1000) (e.g. 100)
  --sort-by: string@sort-by-completer-2 # The key to sort results by (e.g. issueTitle)
  --order: string # The direction to sort results. (e.g. asc)
  --group-by: string@group-by-completer-2 # Set to issue to group the same issue in multiple projects (e.g. issue)
  --filters: record # shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/issues/"
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}, {name: page, var: page}, {name: perPage, var: per_page}, {name: sortBy, var: sort_by}, {name: order, var: order}, {name: groupBy, var: group_by}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    from: $from, to: $to, page: $page, per_page: $per_page, sort_by: $sort_by, order: $order, group_by: $group_by, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of latest issues
#
# POST /reporting/issues/latest
# Returns: record<results: table<fixedDate: string, introducedDate: string, isFixed: bool, issue: record, patchedDate: string>, total: float>
# operationId: Get list of latest issues
export def "get-list-of-latest-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page of results to request (e.g. 1)
  --per-page: float # The number of results to return per page (Maximum: 1000) (e.g. 100)
  --sort-by: string@sort-by-completer-2 # The key to sort results by (e.g. issueTitle)
  --order: string # The direction to sort results. (e.g. asc)
  --group-by: string@group-by-completer-2 # Set to issue to group the same issue in multiple projects (e.g. issue)
  --filters: record # shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reporting/issues/latest"
    query: [{name: page, var: page}, {name: perPage, var: per_page}, {name: sortBy, var: sort_by}, {name: order, var: order}, {name: groupBy, var: group_by}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, sort_by: $sort_by, order: $order, group_by: $group_by, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test composer.json & composer.lock file
#
# POST /test/composer
# operationId: Test composer.json & composer.lock file
export def "test-composer-json-composer-lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional: list, target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/composer"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Dep Graph
#
# POST /test/dep-graph
# operationId: Test Dep Graph
export def "test-dep-graph" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  dep_graph: record # A [DepGraph data object](https://github.com/snyk/dep-graph#depgraphdata) defining all packages and their relationships. — shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/dep-graph"
    query: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: depGraph, var: dep_graph}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org: $org, dep_graph: $dep_graph
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Gopkg.toml & Gopkg.lock File
#
# POST /test/golangdep
# operationId: Test Gopkg.toml & Gopkg.lock File
export def "test-gopkg-toml-gopkg-lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional: list, target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/golangdep"
    query: [{name: org, var: org}]
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org: $org, encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test vendor.json File
#
# POST /test/govendor
# operationId: Test vendor.json File
export def "test-vendor-json-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/govendor"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test gradle file
#
# POST /test/gradle
# operationId: Test gradle file
export def "test-gradle-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/gradle"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public package by group, name and version
#
# GET /test/gradle/{group}/{name}/{version}
# operationId: Test for issues in a public package by group, name and version
export def "test-for-issues-in-a-public-package-by-group-name-and-version" [
  group: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/gradle/{group}/{name}/{version}"
    path_params: [{name: group, var: group}, {name: name, var: name}, {name: version, var: version}]
    query: [{name: org, var: org}, {name: repository, var: repository}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group: $group, name: $name, version: $version, org: $org, repository: $repository
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test maven file
#
# POST /test/maven
# operationId: Test maven file
export def "test-maven-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The Maven repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/maven"
    query: [{name: org, var: org}, {name: repository, var: repository}]
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org: $org, repository: $repository, encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public package by group id, artifact id and version
#
# GET /test/maven/{groupId}/{artifactId}/{version}
# operationId: Test for issues in a public package by group id, artifact id and version
export def "test-for-issues-in-a-public-package-by-group-id-artifact-id-and-version" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The Maven repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/maven/{groupId}/{artifactId}/{version}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    query: [{name: org, var: org}, {name: repository, var: repository}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version, org: $org, repository: $repository
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test package.json & package-lock.json File
#
# POST /test/npm
# operationId: Test package.json & package-lock.json File
export def "test-package-json-package-lock-json-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/npm"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public package by name and version
#
# GET /test/npm/{packageName}/{version}
# operationId: Test for issues in a public package by name and version
export def "test-for-issues-in-a-public-package-by-name-and-version" [
  package_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/npm/{packageName}/{version}"
    path_params: [{name: packageName, var: package_name}, {name: version, var: version}]
    query: [{name: org, var: org}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version: $version, org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test requirements.txt file
#
# POST /test/pip
# operationId: Test requirements.txt file
export def "test-requirements-txt-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/pip"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public package by name and version
#
# GET /test/pip/{packageName}/{version}
export def "get-test-pip-package-name-version" [
  package_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/pip/{packageName}/{version}"
    path_params: [{name: packageName, var: package_name}, {name: version, var: version}]
    query: [{name: org, var: org}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    package_name: $package_name, version: $version, org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test gemfile.lock file
#
# POST /test/rubygems
# operationId: Test gemfile.lock file
export def "test-gemfile-lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/rubygems"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public gem by name and version
#
# GET /test/rubygems/{gemName}/{version}
# operationId: Test for issues in a public gem by name and version
export def "test-for-issues-in-a-public-gem-by-name-and-version" [
  gem_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/rubygems/{gemName}/{version}"
    path_params: [{name: gemName, var: gem_name}, {name: version, var: version}]
    query: [{name: org, var: org}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    gem_name: $gem_name, version: $version, org: $org
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test sbt file
#
# POST /test/sbt
# operationId: Test sbt file
export def "test-sbt-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/sbt"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test for issues in a public package by group id, artifact id and version
#
# GET /test/sbt/{groupId}/{artifactId}/{version}
export def "get-test-sbt-group-id-artifact-id-version" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  http-request {
    method: get
    path: "/test/sbt/{groupId}/{artifactId}/{version}"
    path_params: [{name: groupId, var: group_id}, {name: artifactId, var: artifact_id}, {name: version, var: version}]
    query: [{name: org, var: org}, {name: repository, var: repository}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, artifact_id: $artifact_id, version: $version, org: $org, repository: $repository
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test package.json & yarn.lock File
#
# POST /test/yarn
# operationId: Test package.json & yarn.lock File
export def "test-package-json-yarn-lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: plain)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/test/yarn"
    body: {content_type: "application/json", kind: json, fields: [{name: encoding, var: encoding}, {name: files, var: files}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    encoding: $encoding, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get My Details
#
# GET /user/me
# Returns: record<email: string, id: string, orgs: any, username: string>
# operationId: Get My Details
export def "get-my-details" [
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
    path: "/user/me"
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization notification settings
#
# GET /user/me/notification-settings/org/{orgId}
# Returns: record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>
# operationId: Get organization notification settings
export def "get-organization-notification-settings" [
  org_id: string
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
    path: "/user/me/notification-settings/org/{orgId}"
    path_params: [{name: orgId, var: org_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify organization notification settings
#
# PUT /user/me/notification-settings/org/{orgId}
# Returns: record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>
# operationId: Modify organization notification settings
export def "modify-organization-notification-settings" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
  --project-imported: record # shape: {enabled: bool}
  --test-limit: record # shape: {enabled: bool}
  --weekly-report: record # shape: {enabled: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user/me/notification-settings/org/{orgId}"
    path_params: [{name: orgId, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: new-issues-remediations, var: new_issues_remediations}, {name: project-imported, var: project_imported}, {name: test-limit, var: test_limit}, {name: weekly-report, var: weekly_report}]}
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, new_issues_remediations: $new_issues_remediations, project_imported: $project_imported, test_limit: $test_limit, weekly_report: $weekly_report
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project notification settings
#
# GET /user/me/notification-settings/org/{orgId}/project/{projectId}
# Returns: record<new-issues-remediations: record<enabled: bool, inherited: bool, issueSeverity: string, issueType: string>, project-imported: record<enabled: bool, inherited: bool>, test-limit: record<enabled: bool, inherited: bool>, weekly-report: record<enabled: bool, inherited: bool>>
# operationId: Get project notification settings
export def "get-project-notification-settings" [
  org_id: string
  project_id: string
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
    path: "/user/me/notification-settings/org/{orgId}/project/{projectId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify project notification settings
#
# PUT /user/me/notification-settings/org/{orgId}/project/{projectId}
# operationId: Modify project notification settings
export def "modify-project-notification-settings" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
]: any -> any {
  $in | http-request {
    method: put
    path: "/user/me/notification-settings/org/{orgId}/project/{projectId}"
    path_params: [{name: orgId, var: org_id}, {name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: new-issues-remediations, var: new_issues_remediations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, project_id: $project_id, new_issues_remediations: $new_issues_remediations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Details
#
# GET /user/{userId}
# Returns: record<email: string, id: string, name: string, username: string>
# operationId: Get User Details
export def "get-user-details" [
  user_id: string
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
    path: "/user/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json; charset=utf-8"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
