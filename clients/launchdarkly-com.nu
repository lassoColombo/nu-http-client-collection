# Auto-generated client for LaunchDarkly REST API v5.3.0
# Source: https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json
# Auth: --token flag or $env.LAUNCHDARKLY_REST_API_TOKEN

const CLIENT = {
  base_url: "https://app.launchdarkly.com/api/v2"
  token_env_var: "LAUNCHDARKLY_REST_API_TOKEN"
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

def base-url-completer [] { ["https://app.launchdarkly.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["google-pubsub" "kinesis" "mparticle" "segment"] }
def kind-completer-1 [] { ["approve" "comment" "decline"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-root: "record<next: record<href: string, type: string>, self: record<href: string, type: string>>"
    get-relay-proxy-configs: "record<items: table<_creator: record, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: list>>"
    post-relay-auto-config: "record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    get-relay-proxy-config: "record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    patch-relay-proxy-config: "record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    reset-relay-proxy-config: "record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    get-audit-log-entries: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, comment: string, date: int, description: string, kind: string, member: record, name: string, shortDescription: string, target: record, title: string, titleVerb: string>>"
    get-audit-log-entry: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, comment: string, date: int, description: string, kind: string, member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, name: string, shortDescription: string, target: record<_links: record<next: record, self: record>, name: string, resources: list<string>>, title: string, titleVerb: string>"
    get-destinations: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, config: record, kind: string, name: string, on: bool, version: int>>"
    post-destination: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>"
    get-destination: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>"
    patch-destination: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>"
    get-feature-flag-status-across-environments: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, environments: record, key: string>"
    get-feature-flag-statuses: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, default: record, lastRequested: string, name: string>>"
    get-feature-flag-status: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, default: record, lastRequested: string, name: string>"
    get-feature-flags: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, _maintainer: record, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record, creationDate: int, customProperties: record, defaults: record, description: string, environments: record, goalIds: list, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list, temporary: bool, variations: list>, totalCount: float>"
    post-feature-flag: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>"
    get-flags-project-key-environment-key-feature-flag-key-dependent-flags: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, key: string, name: string>>"
    get-feature-flag: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>"
    patch-feature-flag: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>"
    copy-feature-flag: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>"
    get-flags-project-key-feature-flag-key-dependent-flags: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, environments: list, key: string, name: string>>"
    get-expiring-user-targets: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>"
    patch-expiring-user-targets: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>"
    get-integrations: "record<_links: record, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>>"
    get-integration-subscriptions: "record<_links: record<self: record<href: string, type: string>>, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>>"
    post-integration-subscription: "record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>"
    get-integration-subscription: "record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>"
    patch-integration-subscription: "record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>"
    get-members: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float>"
    post-members: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float>"
    get-me: "record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>"
    get-member: "record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>"
    patch-member: "record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>"
    get-projects: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, defaultClientSideAvailability: record, environments: list, includeInSnippetByDefault: bool, key: string, name: string, tags: list>>"
    post-project: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>"
    get-project: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>"
    patch-project: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>"
    post-environment: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>"
    get-environment: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>"
    patch-environment: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>"
    reset-environment-sdk-key: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>"
    reset-environment-mobile-key: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>"
    get-approval-requests: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>"
    get-approval-request: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>"
    post-approval-request: "record<_id: string, _version: int, allReviews: table<_id: string, creationDate: int, kind: string, memberId: string>, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: table<kind: string>, notifyMemberIds: list<string>, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>"
    post-apply-approval-request: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>"
    post-review-approval-request: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>"
    get-flag-config-scheduled-changes: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, executionDate: int, instructions: list>>"
    post-flag-config-scheduled-changes: "record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>"
    get-flag-config-scheduled-changes-conflicts: "record<instructions: table<conflicts: list, kind: string>>"
    get-flag-config-scheduled-change: "record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>"
    patch-flag-config-scheduled-change: "record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>"
    get-custom-roles: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, description: string, key: string, name: string, policy: list>>"
    post-custom-role: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    get-custom-role: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    patch-custom-role: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>"
    get-user-segments: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_flags: list, _links: record, creationDate: int, description: string, excluded: list, included: list, key: string, name: string, rules: list, tags: list, unbounded: bool, version: int>>"
    post-user-segment: "record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>"
    get-user-segment: "record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>"
    patch-user-segment: "record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>"
    get-expiring-user-targets-on-segment: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string>"
    patch-expiring-user-targets-on-segment: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string>"
    get-tokens: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _member: record, creationDate: int, customRoleIds: list, defaultApiVersion: int, inlineRole: list, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>>"
    post-token: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>"
    get-token: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>"
    patch-token: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>"
    reset-token: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>"
    get-usage: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, series: table<\"0\": int, time: int>>"
    get-evaluations: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>"
    get-events: "record<links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>>"
    get-event: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>"
    get-mau: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<\"0\": int, time: int>>"
    get-mau-by-category: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: list<record>, series: table<\"0\": int, time: int>>"
    get-streams: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>>"
    get-stream: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<\"0\": int, time: int>>"
    get-stream-by-sdk: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: table<sdk: string, source: string, version: string>, series: table<\"0\": int, time: int>>"
    get-stream-sdk-version: "record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>"
    get-search-users: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float>"
    get-users: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float>"
    get-user: "record<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record<anonymous: bool, avatar: string, country: string, custom: record, email: string, firstName: string, ip: string, key: string, lastName: string, name: string, secondary: string>>"
    get-user-flag-settings: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: record>"
    get-user-flag-setting: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _value: bool, setting: bool>"
    get-expiring-user-targets-for-user: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>"
    patch-expiring-user-targets-for-flags: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>"
    get-webhooks: "record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, name: string, on: bool, secret: string, statements: list, tags: list, url: string>>"
    post-webhook: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>"
    get-webhook: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>"
    patch-webhook: "record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-root" "get-relay-proxy-configs" "post-relay-auto-config" "delete-relay-proxy-config" "get-relay-proxy-config" "patch-relay-proxy-config" "reset-relay-proxy-config" "get-audit-log-entries" "get-audit-log-entry" "get-destinations" "post-destination" "delete-destination" "get-destination" "patch-destination" "get-feature-flag-status-across-environments" "get-feature-flag-statuses" "get-feature-flag-status" "get-feature-flags" "post-feature-flag" "get-flags-project-key-environment-key-feature-flag-key-dependent-flags" "delete-feature-flag" "get-feature-flag" "patch-feature-flag" "copy-feature-flag" "get-flags-project-key-feature-flag-key-dependent-flags" "get-expiring-user-targets" "patch-expiring-user-targets" "get-integrations" "get-integration-subscriptions" "post-integration-subscription" "delete-integration-subscription" "get-integration-subscription" "patch-integration-subscription" "get-members" "post-members" "get-me" "delete-member" "get-member" "patch-member" "get-projects" "post-project" "delete-project" "get-project" "patch-project" "post-environment" "delete-environment" "get-environment" "patch-environment" "reset-environment-sdk-key" "reset-environment-mobile-key" "get-approval-requests" "delete-approval-request" "get-approval-request" "post-approval-request" "post-apply-approval-request" "post-review-approval-request" "get-flag-config-scheduled-changes" "post-flag-config-scheduled-changes" "get-flag-config-scheduled-changes-conflicts" "delete-flag-config-scheduled-changes" "get-flag-config-scheduled-change" "patch-flag-config-scheduled-change" "get-custom-roles" "post-custom-role" "delete-custom-role" "get-custom-role" "patch-custom-role" "get-user-segments" "post-user-segment" "delete-user-segment" "get-user-segment" "patch-user-segment" "update-big-segment-targets" "get-expiring-user-targets-on-segment" "patch-expiring-user-targets-on-segment" "get-tokens" "post-token" "delete-token" "get-token" "patch-token" "reset-token" "get-usage" "get-evaluations" "get-events" "get-event" "get-mau" "get-mau-by-category" "get-streams" "get-stream" "get-stream-by-sdk" "get-stream-sdk-version" "get-search-users" "get-users" "delete-user" "get-user" "get-user-flag-settings" "get-user-flag-setting" "put-flag-setting" "get-expiring-user-targets-for-user" "patch-expiring-user-targets-for-flags" "get-webhooks" "post-webhook" "delete-webhook" "get-webhook" "patch-webhook" "commands"] | sort) } | get name | first)
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

# You can issue a GET request to the root resource to find all of the resource categories supported by the API.
#
# GET /
# Returns: record<next: record<href: string, type: string>, self: record<href: string, type: string>>
# operationId: getRoot
export def "get-root" [
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
    path: "/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of relay proxy configurations in the account.
#
# GET /account/relay-auto-configs
# Returns: record<items: table<_creator: record, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: list>>
# operationId: getRelayProxyConfigs
export def "get-relay-proxy-configs" [
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
    path: "/account/relay-auto-configs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new relay proxy config.
#
# POST /account/relay-auto-configs
# Returns: record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: postRelayAutoConfig
export def "post-relay-auto-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human-friendly name for the relay proxy configuration (e.g. My relay proxy config)
  --policy: list # item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/relay-auto-configs"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a relay proxy configuration by ID.
#
# DELETE /account/relay-auto-configs/{id}
# operationId: deleteRelayProxyConfig
export def "delete-relay-proxy-config" [
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
    method: delete
    path: "/account/relay-auto-configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single relay proxy configuration by ID.
#
# GET /account/relay-auto-configs/{id}
# Returns: record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: getRelayProxyConfig
export def "get-relay-proxy-config" [
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
    method: get
    path: "/account/relay-auto-configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a relay proxy configuration by ID.
#
# PATCH /account/relay-auto-configs/{id}
# Returns: record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: patchRelayProxyConfig
export def "patch-relay-proxy-config" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/relay-auto-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a relay proxy configuration's secret key with an optional expiry time for the old key.
#
# POST /account/relay-auto-configs/{id}/reset
# Returns: record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: resetRelayProxyConfig
export def "reset-relay-proxy-config" [
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
  --expiry: int # An expiration time for the old relay proxy configuration key, expressed as a Unix epoch time in milliseconds. By default, the relay proxy configuration will expire immediately (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/account/relay-auto-configs/{id}/reset"
    path_params: [{name: id, var: id}]
    query: [{name: expiry, var: expiry}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, expiry: $expiry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all audit log entries. The query parameters allow you to restrict the returned results by date ranges, resource specifiers, or a full-text search query.
#
# GET /auditlog
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, comment: string, date: int, description: string, kind: string, member: record, name: string, shortDescription: string, target: record, title: string, titleVerb: string>>
# operationId: getAuditLogEntries
export def "get-audit-log-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have before this timestamp. (format: int64)
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
  --q: string # Text to search for. You can search for the full or partial name of the resource involved or full or partial email address of the member who made the change.
  --limit: float # A limit on the number of audit log entries to be returned, between 1 and 20.
  --spec: string # A resource specifier, allowing you to filter audit log listings by resource.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/auditlog"
    query: [{name: before, var: before}, {name: after, var: after}, {name: q, var: q}, {name: limit, var: limit}, {name: spec, var: spec}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    before: $before, after: $after, q: $q, limit: $limit, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use this endpoint to fetch a single audit log entry by its resouce ID.
#
# GET /auditlog/{resourceId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, comment: string, date: int, description: string, kind: string, member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, name: string, shortDescription: string, target: record<_links: record<next: record, self: record>, name: string, resources: list<string>>, title: string, titleVerb: string>
# operationId: getAuditLogEntry
export def "get-audit-log-entry" [
  resource_id: string
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
    path: "/auditlog/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all data export destinations.
#
# GET /destinations
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, config: record, kind: string, name: string, on: bool, version: int>>
# operationId: getDestinations
export def "get-destinations" [
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
    path: "/destinations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new data export destination
#
# POST /destinations/{projectKey}/{environmentKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>
# operationId: postDestination
export def "post-destination" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: record # destination-specific configuration. (e.g. {project: cool-project, topic: test})
  kind: string@kind-completer # The data export destination type. Available choices are kinesis, google-pubsub, mparticle, or segment. (e.g. google-pubsub)
  name: string # A human-readable name for your data export destination. (e.g. Example Google Pub/Sub Destination)
  --on: oneof<nothing, bool> # Whether the data export destination is on or not. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/destinations/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: kind, var: kind}, {name: name, var: name}, {name: on, var: on}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, config: $config, kind: $kind, name: $name, on: $on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single data export destination by ID
#
# DELETE /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: deleteDestination
export def "delete-destination" [
  project_key: string
  environment_key: string
  destination_id: string
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
    path: "/destinations/{projectKey}/{environmentKey}/{destinationId}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: destinationId, var: destination_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single data export destination by ID
#
# GET /destinations/{projectKey}/{environmentKey}/{destinationId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>
# operationId: getDestination
export def "get-destination" [
  project_key: string
  environment_key: string
  destination_id: string
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
    path: "/destinations/{projectKey}/{environmentKey}/{destinationId}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: destinationId, var: destination_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform a partial update to a data export destination.
#
# PATCH /destinations/{projectKey}/{environmentKey}/{destinationId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, config: record, kind: string, name: string, on: bool, version: int>
# operationId: patchDestination
export def "patch-destination" [
  project_key: string
  environment_key: string
  destination_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/destinations/{projectKey}/{environmentKey}/{destinationId}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: destinationId, var: destination_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, destination_id: $destination_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status for a particular feature flag across environments
#
# GET /flag-status/{projectKey}/{featureFlagKey}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, environments: record, key: string>
# operationId: getFeatureFlagStatusAcrossEnvironments
export def "get-feature-flag-status-across-environments" [
  project_key: string
  feature_flag_key: string
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
    path: "/flag-status/{projectKey}/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of statuses for all feature flags. The status includes the last time the feature flag was requested, as well as the state of the flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, default: record, lastRequested: string, name: string>>
# operationId: getFeatureFlagStatuses
export def "get-feature-flag-statuses" [
  project_key: string
  environment_key: string
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
    path: "/flag-statuses/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status for a particular feature flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}/{featureFlagKey}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, default: record, lastRequested: string, name: string>
# operationId: getFeatureFlagStatus
export def "get-feature-flag-status" [
  project_key: string
  environment_key: string
  feature_flag_key: string
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
    path: "/flag-statuses/{projectKey}/{environmentKey}/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all features in the given project.
#
# GET /flags/{projectKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, _maintainer: record, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record, creationDate: int, customProperties: record, defaults: record, description: string, environments: record, goalIds: list, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list, temporary: bool, variations: list>, totalCount: float>
# operationId: getFeatureFlags
export def "get-feature-flags" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-env: list<string> # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment. (spec name: env)
  --summary: oneof<nothing, bool> # By default in api version >= 1, flags will _not_ include their list of prerequisites, targets or rules. Set summary=0 to include these fields for each flag returned.
  --archived: oneof<nothing, bool> # When set to 1, only archived flags will be included in the list of flags returned. By default, archived flags are not included in the list of flags.
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/flags/{projectKey}"
    path_params: [{name: projectKey, var: project_key}]
    query: [{name: env, var: qp_env, style: multi}, {name: summary, var: summary}, {name: archived, var: archived}, {name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, qp_env: $qp_env, summary: $summary, archived: $archived, limit: $limit, offset: $offset, filter: $filter, sort: $sort, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new feature flag.
#
# POST /flags/{projectKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>
# operationId: postFeatureFlag
export def "post-feature-flag" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clone: string # The key of the feature flag to be cloned. The key identifies the flag in your code. For example, setting clone=flagKey will copy the full targeting configuration for all environments (including on/off state) from the original flag to the new flag.
  --client-side-availability: record # shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
  --defaults: record # Default values to be used when a new environment is created. — shape: {offVariation: int, onVariation: int}
  --description: string # A description of the feature flag. (e.g. This flag controls whether test feature is turned on or not.)
  --include-in-snippet: oneof<nothing, bool> # Whether or not this flag should be made available to the client-side JavaScript SDK.
  key: string # A unique key that will be used to reference the flag in your code. (e.g. new-test-flag)
  name: string # A human-friendly name for the feature flag. Remember to note if this flag is intended to be temporary or permanent. (e.g. new test flag)
  --tags: list<string> # Tags for the feature flag.
  --temporary: oneof<nothing, bool> # Whether or not the flag is a temporary flag.
  variations: list # An array of possible variations for the flag. — item shape: {_id?: string, description?: string, name?: string, value: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/flags/{projectKey}"
    path_params: [{name: projectKey, var: project_key}]
    query: [{name: clone, var: clone}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientSideAvailability, var: client_side_availability}, {name: defaults, var: defaults}, {name: description, var: description}, {name: includeInSnippet, var: include_in_snippet}, {name: key, var: key}, {name: name, var: name}, {name: tags, var: tags}, {name: temporary, var: temporary}, {name: variations, var: variations}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, clone: $clone, client_side_availability: $client_side_availability, defaults: $defaults, description: $description, include_in_snippet: $include_in_snippet, key: $key, name: $name, tags: $tags, temporary: $temporary, variations: $variations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dependent flags for the flag in the environment specified in path parameters
#
# GET /flags/{projectKey}/{environmentKey}/{featureFlagKey}/dependent-flags
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, key: string, name: string>>
export def "get-flags-project-key-environment-key-feature-flag-key-dependent-flags" [
  project_key: string
  environment_key: string
  feature_flag_key: string
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
    path: "/flags/{projectKey}/{environmentKey}/{featureFlagKey}/dependent-flags"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a feature flag in all environments. Be careful-- only delete feature flags that are no longer being used by your application.
#
# DELETE /flags/{projectKey}/{featureFlagKey}
# operationId: deleteFeatureFlag
export def "delete-feature-flag" [
  project_key: string
  feature_flag_key: string
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
    path: "/flags/{projectKey}/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single feature flag by key.
#
# GET /flags/{projectKey}/{featureFlagKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>
# operationId: getFeatureFlag
export def "get-feature-flag" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-env: list<string> # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment. (spec name: env)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/flags/{projectKey}/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    query: [{name: env, var: qp_env, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, qp_env: $qp_env
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform a partial update to a feature.
#
# PATCH /flags/{projectKey}/{featureFlagKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>
# operationId: patchFeatureFlag
export def "patch-feature-flag" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. This is a comment string
  --patch: list # item shape: {op: string, path: string, value: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/flags/{projectKey}/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: patch, var: patch}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, comment: $comment, patch: $patch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies the feature flag configuration from one environment to the same feature flag in another environment.
#
# POST /flags/{projectKey}/{featureFlagKey}/copy
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>>
# operationId: copyFeatureFlag
export def "copy-feature-flag" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. This is a comment string)
  --excluded-actions: list<string> # Define the parts of the flag configuration that will not be copied.
  --included-actions: list<string> # Define the parts of the flag configuration that will be copied.
  --source: record # shape: {currentVersion?: int, key: string}
  --target: record # shape: {currentVersion?: int, key: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/flags/{projectKey}/{featureFlagKey}/copy"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: excludedActions, var: excluded_actions}, {name: includedActions, var: included_actions}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, comment: $comment, excluded_actions: $excluded_actions, included_actions: $included_actions, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dependent flags across all environments for the flag specified in the path parameters
#
# GET /flags/{projectKey}/{featureFlagKey}/dependent-flags
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, environments: list, key: string, name: string>>
export def "get-flags-project-key-feature-flag-key-dependent-flags" [
  project_key: string
  feature_flag_key: string
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
    path: "/flags/{projectKey}/{featureFlagKey}/dependent-flags"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get expiring user targets for feature flag
#
# GET /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>
# operationId: getExpiringUserTargets
export def "get-expiring-user-targets" [
  project_key: string
  feature_flag_key: string
  environment_key: string
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
    path: "/flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update, add, or delete expiring user targets on feature flag
#
# PATCH /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>
# operationId: patchExpiringUserTargets
export def "patch-expiring-user-targets" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all configured audit log event integrations associated with this account.
#
# GET /integrations
# Returns: record<_links: record, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>>
# operationId: getIntegrations
export def "get-integrations" [
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
    path: "/integrations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all configured integrations of a given kind.
#
# GET /integrations/{integrationKey}
# Returns: record<_links: record<self: record<href: string, type: string>>, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>>
# operationId: getIntegrationSubscriptions
export def "get-integration-subscriptions" [
  integration_key: string
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
    path: "/integrations/{integrationKey}"
    path_params: [{name: integrationKey, var: integration_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    integration_key: $integration_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new integration subscription of a given kind.
#
# POST /integrations/{integrationKey}
# Returns: record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>
# operationId: postIntegrationSubscription
export def "post-integration-subscription" [
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: record # Integration-specific configuration fields. (e.g. {apiKey: 582**************************116, hostURL: https://api.datadoghq.com})
  name: string # A human-readable name for your subscription configuration. (e.g. Example Datadog Integration)
  --on: oneof<nothing, bool> # Whether the integration subscription is active or not. (e.g. true)
  --statements: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --tags: list<string> # Tags for the integration subscription. (e.g. [])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/integrations/{integrationKey}"
    path_params: [{name: integrationKey, var: integration_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: name, var: name}, {name: on, var: on}, {name: statements, var: statements}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    integration_key: $integration_key, config: $config, name: $name, on: $on, statements: $statements, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an integration subscription by ID.
#
# DELETE /integrations/{integrationKey}/{integrationId}
# operationId: deleteIntegrationSubscription
export def "delete-integration-subscription" [
  integration_key: string
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
    path: "/integrations/{integrationKey}/{integrationId}"
    path_params: [{name: integrationKey, var: integration_key}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    integration_key: $integration_key, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single integration subscription by ID.
#
# GET /integrations/{integrationKey}/{integrationId}
# Returns: record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>
# operationId: getIntegrationSubscription
export def "get-integration-subscription" [
  integration_key: string
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
    path: "/integrations/{integrationKey}/{integrationId}"
    path_params: [{name: integrationKey, var: integration_key}, {name: integrationId, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    integration_key: $integration_key, integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an integration subscription by ID.
#
# PATCH /integrations/{integrationKey}/{integrationId}
# Returns: record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>>
# operationId: patchIntegrationSubscription
export def "patch-integration-subscription" [
  integration_key: string
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/integrations/{integrationKey}/{integrationId}"
    path_params: [{name: integrationKey, var: integration_key}, {name: integrationId, var: integration_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    integration_key: $integration_key, integration_id: $integration_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all members in the account.
#
# GET /members
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float>
# operationId: getMembers
export def "get-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/members"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: filter, var: filter}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, filter: $filter, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite new members.
#
# POST /members
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float>
# operationId: postMembers
export def "post-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/members"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current team member associated with the token
#
# GET /members/me
# Returns: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>
# operationId: getMe
export def "get-me" [
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
    path: "/members/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a team member by ID.
#
# DELETE /members/{memberId}
# operationId: deleteMember
export def "delete-member" [
  member_id: string
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
    path: "/members/{memberId}"
    path_params: [{name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single team member by ID.
#
# GET /members/{memberId}
# Returns: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>
# operationId: getMember
export def "get-member" [
  member_id: string
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
    path: "/members/{memberId}"
    path_params: [{name: memberId, var: member_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    member_id: $member_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a team member by ID.
#
# PATCH /members/{memberId}
# Returns: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>
# operationId: patchMember
export def "patch-member" [
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/members/{memberId}"
    path_params: [{name: memberId, var: member_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    member_id: $member_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all projects in the account.
#
# GET /projects
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, defaultClientSideAvailability: record, environments: list, includeInSnippetByDefault: bool, key: string, name: string, tags: list>>
# operationId: getProjects
export def "get-projects" [
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
    path: "/projects"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project with the given key and name.
#
# POST /projects
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>
# operationId: postProject
export def "post-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-client-side-availability: record # shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
  --environments: list # item shape: {color: string, confirmChanges?: bool, defaultTrackEvents?: bool, defaultTtl?: float, key: string, name: string, requireComments?: bool, secureMode?: bool, tags?: list<string>}
  --include-in-snippet-by-default: oneof<nothing, bool> # e.g. false
  key: string # e.g. new-project
  name: string # e.g. New Project
  --tags: list<string> # e.g. [ops, dev]
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: defaultClientSideAvailability, var: default_client_side_availability}, {name: environments, var: environments}, {name: includeInSnippetByDefault, var: include_in_snippet_by_default}, {name: key, var: key}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    default_client_side_availability: $default_client_side_availability, environments: $environments, include_in_snippet_by_default: $include_in_snippet_by_default, key: $key, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project by key. Caution-- deleting a project will delete all associated environments and feature flags. You cannot delete the last project in an account.
#
# DELETE /projects/{projectKey}
# operationId: deleteProject
export def "delete-project" [
  project_key: string
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
    path: "/projects/{projectKey}"
    path_params: [{name: projectKey, var: project_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single project by key.
#
# GET /projects/{projectKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>
# operationId: getProject
export def "get-project" [
  project_key: string
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
    path: "/projects/{projectKey}"
    path_params: [{name: projectKey, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a project by ID.
#
# PATCH /projects/{projectKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, defaultClientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, environments: table<_id: string, _links: record, apiKey: string, approvalSettings: record, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list>, includeInSnippetByDefault: bool, key: string, name: string, tags: list<string>>
# operationId: patchProject
export def "patch-project" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectKey}"
    path_params: [{name: projectKey, var: project_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new environment in a specified project with a given name, key, and swatch color.
#
# POST /projects/{projectKey}/environments
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>
# operationId: postEnvironment
export def "post-environment" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # A color swatch (as an RGB hex value with no leading '#', e.g. C8C8C8). (e.g. 417505)
  --confirm-changes: oneof<nothing, bool> # Determines if this environment requires confirmation for flag and segment changes. (e.g. false)
  --default-track-events: oneof<nothing, bool> # Set to true to send detailed event information for newly created flags. (e.g. false)
  --default-ttl: float # The default TTL for the new environment. (e.g. 0)
  key: string # A project-unique key for the new environment. (e.g. dev)
  name: string # The name of the new environment. (e.g. Development)
  --require-comments: oneof<nothing, bool> # Determines if this environment requires comments for flag and segment changes. (e.g. false)
  --secure-mode: oneof<nothing, bool> # Determines whether the environment is in secure mode. (e.g. false)
  --tags: list<string> # An array of tags for this environment. (e.g. [tag1, tag2])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/environments"
    path_params: [{name: projectKey, var: project_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: confirmChanges, var: confirm_changes}, {name: defaultTrackEvents, var: default_track_events}, {name: defaultTtl, var: default_ttl}, {name: key, var: key}, {name: name, var: name}, {name: requireComments, var: require_comments}, {name: secureMode, var: secure_mode}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, color: $color, confirm_changes: $confirm_changes, default_track_events: $default_track_events, default_ttl: $default_ttl, key: $key, name: $name, require_comments: $require_comments, secure_mode: $secure_mode, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an environment in a specific project.
#
# DELETE /projects/{projectKey}/environments/{environmentKey}
# operationId: deleteEnvironment
export def "delete-environment" [
  project_key: string
  environment_key: string
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
    path: "/projects/{projectKey}/environments/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an environment given a project and key.
#
# GET /projects/{projectKey}/environments/{environmentKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>
# operationId: getEnvironment
export def "get-environment" [
  project_key: string
  environment_key: string
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
    path: "/projects/{projectKey}/environments/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an environment by ID. If you try to patch the environment by setting both required and requiredApprovalTags, it will result in an error. Users can specify either required approvals for all flags in an environment or those with specific tags, but not both. Only customers on an Enterprise plan can require approval for flag updates with either mechanism.
#
# PATCH /projects/{projectKey}/environments/{environmentKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>
# operationId: patchEnvironment
export def "patch-environment" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectKey}/environments/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset an environment's SDK key with an optional expiry time for the old key.
#
# POST /projects/{projectKey}/environments/{environmentKey}/apiKey
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>
# operationId: resetEnvironmentSDKKey
export def "reset-environment-sdk-key" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # An expiration time for the old environment SDK key, expressed as a Unix epoch time in milliseconds. By default, the key will expire immediately. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectKey}/environments/{environmentKey}/apiKey"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    query: [{name: expiry, var: expiry}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, expiry: $expiry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset an environment's mobile key. The optional expiry for the old key is deprecated for this endpoint, so the old key will always expire immediately.
#
# POST /projects/{projectKey}/environments/{environmentKey}/mobileKey
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, apiKey: string, approvalSettings: record<canApplyDeclinedChanges: bool, canReviewOwnRequest: bool, minNumApprovals: int, required: bool, requiredApprovalTags: list<string>, serviceKind: string>, color: string, confirmChanges: bool, defaultTrackEvents: bool, defaultTtl: float, key: string, mobileKey: string, name: string, requireComments: bool, secureMode: bool, tags: list<string>>
# operationId: resetEnvironmentMobileKey
export def "reset-environment-mobile-key" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # The expiry parameter is deprecated for this endpoint, so the old mobile key will always expire immediately. This parameter will be removed in an upcoming major API client version. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectKey}/environments/{environmentKey}/mobileKey"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    query: [{name: expiry, var: expiry}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, expiry: $expiry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all approval requests for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>
# operationId: getApprovalRequests
export def "get-approval-requests" [
  project_key: string
  feature_flag_key: string
  environment_key: string
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
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an approval request for a feature flag config
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: deleteApprovalRequest
export def "delete-approval-request" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change.
  description: string # A name that describes the changes you would like to apply to a feature flag configuration
  --execution-date: int # Timestamp for when instructions will be executed (format: int64)
  instructions: list # item shape: {kind?: string}
  notify_member_ids: list<string> # e.g. [memberId, memberId2]
  --operating-on-id: string # ID of scheduled change to edit or delete
]: any -> any {
  $in | http-request {
    method: delete
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: approvalRequestId, var: approval_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: description, var: description}, {name: executionDate, var: execution_date}, {name: instructions, var: instructions}, {name: notifyMemberIds, var: notify_member_ids}, {name: operatingOnId, var: operating_on_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, approval_request_id: $approval_request_id, comment: $comment, description: $description, execution_date: $execution_date, instructions: $instructions, notify_member_ids: $notify_member_ids, operating_on_id: $operating_on_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single approval request for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>
# operationId: getApprovalRequest
export def "get-approval-request" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
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
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: approvalRequestId, var: approval_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, approval_request_id: $approval_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# Returns: record<_id: string, _version: int, allReviews: table<_id: string, creationDate: int, kind: string, memberId: string>, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: table<kind: string>, notifyMemberIds: list<string>, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>
# operationId: postApprovalRequest
export def "post-approval-request" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change.
  description: string # A name that describes the changes you would like to apply to a feature flag configuration
  --execution-date: int # Timestamp for when instructions will be executed (format: int64)
  instructions: list # item shape: {kind?: string}
  notify_member_ids: list<string> # e.g. [memberId, memberId2]
  --operating-on-id: string # ID of scheduled change to edit or delete
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: approvalRequestId, var: approval_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: description, var: description}, {name: executionDate, var: execution_date}, {name: instructions, var: instructions}, {name: notifyMemberIds, var: notify_member_ids}, {name: operatingOnId, var: operating_on_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, approval_request_id: $approval_request_id, comment: $comment, description: $description, execution_date: $execution_date, instructions: $instructions, notify_member_ids: $notify_member_ids, operating_on_id: $operating_on_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/apply
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>
# operationId: postApplyApprovalRequest
export def "post-apply-approval-request" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. Applying approved changes)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/apply"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: approvalRequestId, var: approval_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, approval_request_id: $approval_request_id, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Review approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/review
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>>
# operationId: postReviewApprovalRequest
export def "post-review-approval-request" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. This is a comment string)
  kind: string@kind-completer-1 # One of approve, decline, or comment. (e.g. approve)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/review"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: approvalRequestId, var: approval_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, approval_request_id: $approval_request_id, comment: $comment, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all scheduled workflows for a feature flag by key.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, executionDate: int, instructions: list>>
# operationId: getFlagConfigScheduledChanges
export def "get-flag-config-scheduled-changes" [
  project_key: string
  feature_flag_key: string
  environment_key: string
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
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new scheduled change for a feature flag.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# Returns: record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>
# operationId: postFlagConfigScheduledChanges
export def "post-flag-config-scheduled-changes" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Used to describe the scheduled changes.
  --execution-date: int # A unix epoch time in milliseconds specifying the date the scheduled changes will be applied
  --instructions: list # item shape: {kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: executionDate, var: execution_date}, {name: instructions, var: instructions}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, comment: $comment, execution_date: $execution_date, instructions: $instructions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists conflicts between the given instructions and any existing scheduled changes for the feature flag. The actual HTTP verb should be REPORT, not POST.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes-conflicts
# Returns: record<instructions: table<conflicts: list, kind: string>>
# operationId: getFlagConfigScheduledChangesConflicts
export def "get-flag-config-scheduled-changes-conflicts" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-date: int # A unix epoch time in milliseconds specifying the date the scheduled changes will be applied
  --instructions: list # item shape: {kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes-conflicts"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: executionDate, var: execution_date}, {name: instructions, var: instructions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, execution_date: $execution_date, instructions: $instructions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a scheduled change on a feature flag in an environment.
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: deleteFlagConfigScheduledChanges
export def "delete-flag-config-scheduled-changes" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
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
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: scheduledChangeId, var: scheduled_change_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, scheduled_change_id: $scheduled_change_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a scheduled change on a feature flag by id.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# Returns: record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>
# operationId: getFlagConfigScheduledChange
export def "get-flag-config-scheduled-change" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
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
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: scheduledChangeId, var: scheduled_change_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, scheduled_change_id: $scheduled_change_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing scheduled-change on a feature flag in an environment.
#
# PATCH /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# Returns: record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>>
# operationId: patchFlagConfigScheduledChange
export def "patch-flag-config-scheduled-change" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Used to describe the scheduled changes.
  --instructions: list # item shape: {kind?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}"
    path_params: [{name: projectKey, var: project_key}, {name: featureFlagKey, var: feature_flag_key}, {name: environmentKey, var: environment_key}, {name: scheduledChangeId, var: scheduled_change_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: instructions, var: instructions}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, feature_flag_key: $feature_flag_key, environment_key: $environment_key, scheduled_change_id: $scheduled_change_id, comment: $comment, instructions: $instructions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a complete list of custom roles.
#
# GET /roles
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, description: string, key: string, name: string, policy: list>>
# operationId: getCustomRoles
export def "get-custom-roles" [
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
    path: "/roles"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new custom role.
#
# POST /roles
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: postCustomRole
export def "post-custom-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the custom role. (e.g. Description of revenue team role here)
  key: string # The 20-hexdigit id or the key for a custom role. (e.g. revenue-team)
  name: string # Name of the custom role. (e.g. revenue team)
  policy: list # item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/roles"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}, {name: policy, var: policy}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, key: $key, name: $name, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom role by key.
#
# DELETE /roles/{customRoleKey}
# operationId: deleteCustomRole
export def "delete-custom-role" [
  custom_role_key: string
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
    path: "/roles/{customRoleKey}"
    path_params: [{name: customRoleKey, var: custom_role_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    custom_role_key: $custom_role_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one custom role by key.
#
# GET /roles/{customRoleKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: getCustomRole
export def "get-custom-role" [
  custom_role_key: string
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
    path: "/roles/{customRoleKey}"
    path_params: [{name: customRoleKey, var: custom_role_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_role_key: $custom_role_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a custom role by key.
#
# PATCH /roles/{customRoleKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, description: string, key: string, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>>
# operationId: patchCustomRole
export def "patch-custom-role" [
  custom_role_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/roles/{customRoleKey}"
    path_params: [{name: customRoleKey, var: custom_role_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_role_key: $custom_role_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all user segments in the given project.
#
# GET /segments/{projectKey}/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_flags: list, _links: record, creationDate: int, description: string, excluded: list, included: list, key: string, name: string, rules: list, tags: list, unbounded: bool, version: int>>
# operationId: getUserSegments
export def "get-user-segments" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/segments/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    query: [{name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new user segment.
#
# POST /segments/{projectKey}/{environmentKey}
# Returns: record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>
# operationId: postUserSegment
export def "post-user-segment" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the user segment. (e.g. Users in this segment will have access to beta features.)
  key: string # A unique key that will be used to reference the user segment in feature flags. (e.g. new-segment)
  name: string # A human-friendly name for the user segment. (e.g. new segment)
  --tags: list<string> # Tags for the user segment.
  --unbounded: oneof<nothing, bool> # Controls whether this is considered a "big segment" which can support an unlimited numbers of users. Include/exclude lists sent with this payload are not used in big segments. Contact your account manager for early access to this feature. (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/segments/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: key, var: key}, {name: name, var: name}, {name: tags, var: tags}, {name: unbounded, var: unbounded}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, description: $description, key: $key, name: $name, tags: $tags, unbounded: $unbounded
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user segment.
#
# DELETE /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: deleteUserSegment
export def "delete-user-segment" [
  project_key: string
  environment_key: string
  user_segment_key: string
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
    path: "/segments/{projectKey}/{environmentKey}/{userSegmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userSegmentKey, var: user_segment_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_segment_key: $user_segment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single user segment by key.
#
# GET /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# Returns: record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>
# operationId: getUserSegment
export def "get-user-segment" [
  project_key: string
  environment_key: string
  user_segment_key: string
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
    path: "/segments/{projectKey}/{environmentKey}/{userSegmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userSegmentKey, var: user_segment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_segment_key: $user_segment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform a partial update to a user segment.
#
# PATCH /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# Returns: record<_flags: table<_links: record, _site: record, key: string, name: string>, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, creationDate: int, description: string, excluded: list<string>, included: list<string>, key: string, name: string, rules: table<bucketBy: string, clauses: list, weight: int>, tags: list<string>, unbounded: bool, version: int>
# operationId: patchUserSegment
export def "patch-user-segment" [
  project_key: string
  environment_key: string
  user_segment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/segments/{projectKey}/{environmentKey}/{userSegmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userSegmentKey, var: user_segment_key}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_segment_key: $user_segment_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update targets included or excluded in a big segment
#
# POST /segments/{projectKey}/{environmentKey}/{userSegmentKey}/users
# operationId: updateBigSegmentTargets
export def "update-big-segment-targets" [
  project_key: string
  environment_key: string
  user_segment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excluded: record # shape: {add?: list<string>, remove?: list<string>}
  --included: record # shape: {add?: list<string>, remove?: list<string>}
]: any -> any {
  $in | http-request {
    method: post
    path: "/segments/{projectKey}/{environmentKey}/{userSegmentKey}/users"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userSegmentKey, var: user_segment_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: excluded, var: excluded}, {name: included, var: included}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_segment_key: $user_segment_key, excluded: $excluded, included: $included
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get expiring user targets for user segment
#
# GET /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string>
# operationId: getExpiringUserTargetsOnSegment
export def "get-expiring-user-targets-on-segment" [
  project_key: string
  user_segment_key: string
  environment_key: string
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
    path: "/segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: userSegmentKey, var: user_segment_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, user_segment_key: $user_segment_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update, add, or delete expiring user targets on user segment
#
# PATCH /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string>
# operationId: patchExpiringUserTargetsOnSegment
export def "patch-expiring-user-targets-on-segment" [
  project_key: string
  user_segment_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: userSegmentKey, var: user_segment_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, user_segment_key: $user_segment_key, environment_key: $environment_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of tokens in the account.
#
# GET /tokens
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _member: record, creationDate: int, customRoleIds: list, defaultApiVersion: int, inlineRole: list, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>>
# operationId: getTokens
export def "get-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-all: oneof<nothing, bool> # If set to true, and the authentication access token has the "Admin" role, personal access tokens for all members will be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tokens"
    query: [{name: showAll, var: show_all}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    show_all: $show_all
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new token.
#
# POST /tokens
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>
# operationId: postToken
export def "post-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-role-ids: list<string> # A list of custom role IDs to use as access limits for the access token
  --default-api-version: int # The default API version for this token
  --inline-role: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --name: string # A human-friendly name for the access token (e.g. My access token)
  --role: string # The name of a built-in role for the token (e.g. writer)
  --service-token: oneof<nothing, bool> # Whether the token will be a service token https://docs.launchdarkly.com/home/account-security/api-access-tokens#service-tokens
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: customRoleIds, var: custom_role_ids}, {name: defaultApiVersion, var: default_api_version}, {name: inlineRole, var: inline_role}, {name: name, var: name}, {name: role, var: role}, {name: serviceToken, var: service_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    custom_role_ids: $custom_role_ids, default_api_version: $default_api_version, inline_role: $inline_role, name: $name, role: $role, service_token: $service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an access token by ID.
#
# DELETE /tokens/{tokenId}
# operationId: deleteToken
export def "delete-token" [
  token_id: string
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
    path: "/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single access token by ID.
#
# GET /tokens/{tokenId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>
# operationId: getToken
export def "get-token" [
  token_id: string
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
    path: "/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an access token by ID.
#
# PATCH /tokens/{tokenId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>
# operationId: patchToken
export def "patch-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset an access token's secret key with an optional expiry time for the old key.
#
# POST /tokens/{tokenId}/reset
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>
# operationId: resetToken
export def "reset-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # An expiration time for the old token key, expressed as a Unix epoch time in milliseconds. By default, the token will expire immediately. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tokens/{tokenId}/reset"
    path_params: [{name: tokenId, var: token_id}]
    query: [{name: expiry, var: expiry}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id, expiry: $expiry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns of the usage endpoints available.
#
# GET /usage
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, series: table<"0": int, time: int>>
# operationId: getUsage
export def "get-usage" [
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
    path: "/usage"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events usage by event id and the feature flag key.
#
# GET /usage/evaluations/{envId}/{flagKey}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>
# operationId: getEvaluations
export def "get-evaluations" [
  env_id: string
  flag_key: string
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
    path: "/usage/evaluations/{envId}/{flagKey}"
    path_params: [{name: envId, var: env_id}, {name: flagKey, var: flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    env_id: $env_id, flag_key: $flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events usage endpoints.
#
# GET /usage/events
# Returns: record<links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>>
# operationId: getEvents
export def "get-events" [
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
    path: "/usage/events"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events usage by event type.
#
# GET /usage/events/{type}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>
# operationId: getEvent
export def "get-event" [
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
    path: "/usage/events/{type}"
    path_params: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get monthly active user data.
#
# GET /usage/mau
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<"0": int, time: int>>
# operationId: getMAU
export def "get-mau" [
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
    path: "/usage/mau"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get monthly active user data by category.
#
# GET /usage/mau/bycategory
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: list<record>, series: table<"0": int, time: int>>
# operationId: getMAUByCategory
export def "get-mau-by-category" [
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
    path: "/usage/mau/bycategory"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all streams.
#
# GET /usage/streams
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>>
# operationId: getStreams
export def "get-streams" [
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
    path: "/usage/streams"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a stream endpoint and return timeseries data.
#
# GET /usage/streams/{source}
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<"0": int, time: int>>
# operationId: getStream
export def "get-stream" [
  source: string
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
    path: "/usage/streams/{source}"
    path_params: [{name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a stream timeseries data by source show sdk version metadata.
#
# GET /usage/streams/{source}/bysdkversion
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: table<sdk: string, source: string, version: string>, series: table<"0": int, time: int>>
# operationId: getStreamBySDK
export def "get-stream-by-sdk" [
  source: string
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
    path: "/usage/streams/{source}/bysdkversion"
    path_params: [{name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a stream timeseries data by source and show all sdk version associated.
#
# GET /usage/streams/{source}/sdkversions
# Returns: record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>>
# operationId: getStreamSDKVersion
export def "get-stream-sdk-version" [
  source: string
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
    path: "/usage/streams/{source}/sdkversions"
    path_params: [{name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search users in LaunchDarkly based on their last active date, or a search query. It should not be used to enumerate all users in LaunchDarkly-- use the List users API resource.
#
# GET /user-search/{projectKey}/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float>
# operationId: getSearchUsers
export def "get-search-users" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query.
  --limit: int # Pagination limit.
  --offset: int # Specifies the first item to return in the collection.
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user-search/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    query: [{name: q, var: q}, {name: limit, var: limit}, {name: offset, var: offset}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, q: $q, limit: $limit, offset: $offset, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users in the environment. Includes the total count of users. In each page, there will be up to 'limit' users returned (default 20). This is useful for exporting all users in the system for further analysis. Paginated collections will include a next link containing a URL with the next set of elements in the collection.
#
# GET /users/{projectKey}/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float>
# operationId: getUsers
export def "get-users" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Pagination limit.
  --h: string # This parameter is required when following "next" links.
  --scroll-id: string # This parameter is required when following "next" links.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{projectKey}/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}]
    query: [{name: limit, var: limit}, {name: h, var: h}, {name: scrollId, var: scroll_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, limit: $limit, h: $h, scroll_id: $scroll_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user by ID.
#
# DELETE /users/{projectKey}/{environmentKey}/{userKey}
# operationId: deleteUser
export def "delete-user" [
  project_key: string
  environment_key: string
  user_key: string
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
    path: "/users/{projectKey}/{environmentKey}/{userKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userKey, var: user_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_key: $user_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}
# Returns: record<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record<anonymous: bool, avatar: string, country: string, custom: record, email: string, firstName: string, ip: string, key: string, lastName: string, name: string, secondary: string>>
# operationId: getUser
export def "get-user" [
  project_key: string
  environment_key: string
  user_key: string
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
    path: "/users/{projectKey}/{environmentKey}/{userKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userKey, var: user_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_key: $user_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: record>
# operationId: getUserFlagSettings
export def "get-user-flag-settings" [
  project_key: string
  environment_key: string
  user_key: string
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
    path: "/users/{projectKey}/{environmentKey}/{userKey}/flags"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userKey, var: user_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_key: $user_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _value: bool, setting: bool>
# operationId: getUserFlagSetting
export def "get-user-flag-setting" [
  project_key: string
  environment_key: string
  user_key: string
  feature_flag_key: string
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
    path: "/users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userKey, var: user_key}, {name: featureFlagKey, var: feature_flag_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_key: $user_key, feature_flag_key: $feature_flag_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specifically enable or disable a feature flag for a user based on their key.
#
# PUT /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# operationId: putFlagSetting
export def "put-flag-setting" [
  project_key: string
  environment_key: string
  user_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --setting: oneof<nothing, bool> # The variation value to set for the user. Must match the variation type of the flag.
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}"
    path_params: [{name: projectKey, var: project_key}, {name: environmentKey, var: environment_key}, {name: userKey, var: user_key}, {name: featureFlagKey, var: feature_flag_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: setting, var: setting}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    project_key: $project_key, environment_key: $environment_key, user_key: $user_key, feature_flag_key: $feature_flag_key, setting: $setting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get expiring dates on flags for user
#
# GET /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>
# operationId: getExpiringUserTargetsForUser
export def "get-expiring-user-targets-for-user" [
  project_key: string
  user_key: string
  environment_key: string
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
    path: "/users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: userKey, var: user_key}, {name: environmentKey, var: environment_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, user_key: $user_key, environment_key: $environment_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update, add, or delete expiring user targets for a single user on all flags
#
# PATCH /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>>
# operationId: patchExpiringUserTargetsForFlags
export def "patch-expiring-user-targets-for-flags" [
  project_key: string
  user_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}"
    path_params: [{name: projectKey, var: project_key}, {name: userKey, var: user_key}, {name: environmentKey, var: environment_key}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_key: $project_key, user_key: $user_key, environment_key: $environment_key, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetch a list of all webhooks.
#
# GET /webhooks
# Returns: record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, name: string, on: bool, secret: string, statements: list, tags: list, url: string>>
# operationId: getWebhooks
export def "get-webhooks" [
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
    path: "/webhooks"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook.
#
# POST /webhooks
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>
# operationId: postWebhook
export def "post-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the webhook. (e.g. Example hook)
  --on: oneof<nothing, bool> # Whether this webhook is enabled or not. (e.g. true)
  --secret: string # If sign is true, and the secret attribute is omitted, LaunchDarkly will automatically generate a secret for you. (e.g. <password>)
  --sign: oneof<nothing, bool> # If sign is false, the webhook will not include a signature header, and the secret can be omitted.
  --statements: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --tags: list<string> # Tags for the webhook. (e.g. [])
  url: string # The URL of the remote webhook. (e.g. https://example.com/example)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: on, var: on, required: true}, {name: secret, var: secret}, {name: sign, var: sign, required: true}, {name: statements, var: statements}, {name: tags, var: tags}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, on: $on, secret: $secret, sign: $sign, statements: $statements, tags: $tags, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook by ID.
#
# DELETE /webhooks/{resourceId}
# operationId: deleteWebhook
export def "delete-webhook" [
  resource_id: string
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
    path: "/webhooks/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook by ID.
#
# GET /webhooks/{resourceId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>
# operationId: getWebhook
export def "get-webhook" [
  resource_id: string
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
    path: "/webhooks/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a webhook by ID.
#
# PATCH /webhooks/{resourceId}
# Returns: record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, name: string, on: bool, secret: string, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>, url: string>
# operationId: patchWebhook
export def "patch-webhook" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/webhooks/{resourceId}"
    path_params: [{name: resourceId, var: resource_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_id: $resource_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
