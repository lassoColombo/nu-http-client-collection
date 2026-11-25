# Auto-generated client for Application Integration API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/integrations/v1/openapi.json
# Auth: --token flag or $env.APPLICATION_INTEGRATION_API_TOKEN

const CLIENT = {
  base_url: "https://integrations.googleapis.com"
  token_env_var: "APPLICATION_INTEGRATION_API_TOKEN"
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

def base-url-completer [] { ["https://integrations.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def product-completer [] { ["APIGEE" "IP" "SECURITY" "UNSPECIFIED_PRODUCT"] }
def file-format-completer [] { ["FILE_FORMAT_UNSPECIFIED" "JSON" "YAML"] }
def credential-type-completer [] { ["API_KEY" "AUTH_TOKEN" "CLIENT_CERTIFICATE_ONLY" "CREDENTIAL_TYPE_UNSPECIFIED" "JWT" "OAUTH2_AUTHORIZATION_CODE" "OAUTH2_CLIENT_CREDENTIALS" "OAUTH2_IMPLICIT" "OAUTH2_RESOURCE_OWNER_CREDENTIALS" "OIDC_TOKEN" "SERVICE_ACCOUNT" "USERNAME_AND_PASSWORD"] }
def state-completer [] { ["EXPIRED" "INVALID" "SOFT_DELETED" "STATE_UNSPECIFIED" "UNAUTHORIZED" "UNSUPPORTED" "VALID"] }
def visibility-completer [] { ["AUTH_CONFIG_VISIBILITY_UNSPECIFIED" "CLIENT_VISIBLE" "PRIVATE"] }
def certificate-status-completer [] { ["ACTIVE" "EXPIRED" "STATE_UNSPECIFIED"] }
def database-persistence-policy-completer [] { ["DATABASE_PERSISTENCE_DISABLED" "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED"] }
def origin-completer [] { ["APPLICATION_IP_PROVISIONING" "PIPER_V2" "PIPER_V3" "UI" "UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    integrations-callback-generate-token: "record<message: string>"
    integrations-connector-platform-regions-enumerate: "record<regions: list<string>>"
    integrations-projects-locations-products-integrations-versions-takeover-edit-lock: "record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>>"
    integrations-projects-locations-sfdc-instances-sfdc-channels-delete: "record"
    integrations-projects-locations-sfdc-instances-sfdc-channels-get: "record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>"
    integrations-projects-locations-sfdc-instances-sfdc-channels-patch: "record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>"
    integrations-projects-locations-products-integrations-executions-cancel: "record<isCanceled: bool>"
    integrations-projects-locations-products-integrations-versions-download: "record<content: string>"
    integrations-projects-locations-products-integrations-execute: "record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, outputParameters: record, parameterEntries: table<dataType: string, key: string, value: record>>"
    integrations-projects-locations-products-integrations-executions-suspensions-lift: "record<eventExecutionInfoId: string>"
    integrations-projects-locations-products-integrations-versions-publish: "record"
    integrations-projects-locations-products-integrations-executions-suspensions-resolve: "record"
    integrations-projects-locations-products-integrations-schedule: "record<executionInfoIds: list<string>>"
    integrations-projects-locations-products-integrations-test: "record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, parameterEntries: table<dataType: string, key: string, value: record>, parameters: record>"
    integrations-projects-locations-products-integrations-versions-unpublish: "record"
    integrations-projects-locations-apps-script-projects-create: "record<projectId: string>"
    integrations-projects-locations-apps-script-projects-link: "record<scriptId: string>"
    integrations-projects-locations-products-auth-configs-list: "record<authConfigs: table<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string>, nextPageToken: string>"
    integrations-projects-locations-products-auth-configs-create: "record<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record<authToken: record<token: string, type: string>, credentialType: string, jwt: record<jwt: string, jwtHeader: string, jwtPayload: string, secret: string>, oauth2AuthorizationCode: record<accessToken: record, applyReauthPolicy: bool, authCode: string, authEndpoint: string, authParams: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ClientCredentials: record<accessToken: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ResourceOwnerCredentials: record<accessToken: record, clientId: string, clientSecret: string, password: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record, username: string>, oidcToken: record<audience: string, serviceAccountEmail: string, token: string, tokenExpireTime: string>, serviceAccountCredentials: record<scope: string, serviceAccount: string>, usernameAndPassword: record<password: string, username: string>>, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list<string>, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string>"
    integrations-projects-locations-products-certificates-list: "record<certificates: table<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record, requestorId: string, validEndTime: string, validStartTime: string>, nextPageToken: string>"
    integrations-projects-locations-products-certificates-create: "record<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record<encryptedPrivateKey: string, passphrase: string, sslCertificate: string>, requestorId: string, validEndTime: string, validStartTime: string>"
    integrations-projects-get-clientmetadata: "record<properties: record<ipEnablementState: string, provisionedRegions: list<string>>>"
    integrations-projects-locations-get-clients: "record<client: record<billingType: string, clientState: string, cloudKmsConfig: record<key: string, keyVersion: string, kmsLocation: string, kmsProjectId: string, kmsRing: string>, cloudLoggingConfig: record<bucket: string, enableCloudLogging: bool>, createTime: string, description: string, id: string, p4ServiceAccount: string, projectId: string, region: string>>"
    integrations-projects-locations-clients-deprovision: "record"
    integrations-projects-locations-clients-provision: "record"
    integrations-projects-locations-clients-switch: "record"
    integrations-projects-locations-products-cloud-functions-create: "record<triggerUrl: string>"
    integrations-projects-locations-connections-list: "record<connections: table<authConfig: record, configVariables: list, connectorVersion: string, createTime: string, description: string, destinationConfigs: list, envoyImageLocation: string, imageLocation: string, labels: record, lockConfig: record, logConfig: record, name: string, nodeConfig: record, serviceAccount: string, serviceDirectory: string, sslConfig: record, status: record, suspended: bool, updateTime: string>, nextPageToken: string>"
    integrations-projects-locations-products-integrations-executions-list: "record<executionInfos: table<clientId: string, createTime: string, errorCode: record, errors: list, eventExecutionDetails: record, eventExecutionInfoId: string, executionTraceInfo: record, lastModifiedTime: string, postMethod: string, product: string, requestId: string, requestParams: record, responseParams: record, snapshotNumber: string, tenant: string, triggerId: string, workflowId: string, workflowName: string, workflowRetryBackoffIntervalSeconds: string>, executions: table<createTime: string, directSubExecutions: list, eventExecutionDetails: record, executionDetails: record, executionMethod: string, name: string, requestParameters: record, requestParams: list, responseParameters: record, responseParams: list, triggerId: string, updateTime: string>, nextPageToken: string>"
    integrations-projects-locations-products-integrations-list: "record<integrations: table<active: bool, description: string, name: string, updateTime: string>, nextPageToken: string>"
    integrations-projects-locations-connections-runtime-action-schemas-list: "record<nextPageToken: string, runtimeActionSchemas: table<action: string, inputSchema: string, outputSchema: string>>"
    integrations-projects-locations-connections-runtime-entity-schemas-list: "record<nextPageToken: string, runtimeEntitySchemas: table<arrayFieldSchema: string, entity: string, fieldSchema: string>>"
    integrations-projects-locations-sfdc-instances-sfdc-channels-list: "record<nextPageToken: string, sfdcChannels: table<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>>"
    integrations-projects-locations-sfdc-instances-sfdc-channels-create: "record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>"
    integrations-projects-locations-sfdc-instances-list: "record<nextPageToken: string, sfdcInstances: table<authConfigId: list, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string>>"
    integrations-projects-locations-sfdc-instances-create: "record<authConfigId: list<string>, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string>"
    integrations-projects-locations-products-integrations-executions-suspensions-list: "record<nextPageToken: string, suspensions: table<approvalConfig: record, audit: record, createTime: string, eventExecutionInfoId: string, integration: string, lastModifyTime: string, name: string, state: string, suspensionConfig: record, taskId: string>>"
    integrations-projects-locations-products-integrations-versions-list: "record<integrationVersions: table<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list, integrationParameters: list, integrationParametersInternal: record, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list, taskConfigsInternal: list, teardown: record, triggerConfigs: list, triggerConfigsInternal: list, updateTime: string, userLabel: string>, nextPageToken: string, noPermission: bool>"
    integrations-projects-locations-products-integrations-versions-create: "record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: table<description: string, errorCatcherId: string, errorCatcherNumber: string, label: string, position: record, startErrorTasks: list>, integrationParameters: table<dataType: string, defaultValue: record, displayName: string, inputOutputType: string, isTransient: bool, jsonSchema: string, key: string, producer: string, searchable: bool>, integrationParametersInternal: record<parameters: list<record>>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: table<description: string, displayName: string, errorCatcherId: string, externalTaskType: string, failurePolicy: record, jsonValidationOption: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, successPolicy: record, synchronousCallFailurePolicy: record, task: string, taskExecutionStrategy: string, taskId: string, taskTemplate: string>, taskConfigsInternal: table<alertConfigs: list, createTime: string, creatorEmail: string, description: string, disableStrictTypeValidation: bool, errorCatcherId: string, externalTaskType: string, failurePolicy: record, incomingEdgeCount: int, jsonValidationOption: string, label: string, lastModifiedTime: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, precondition: string, preconditionLabel: string, rollbackStrategy: record, successPolicy: record, synchronousCallFailurePolicy: record, taskEntity: record, taskExecutionStrategy: string, taskName: string, taskNumber: string, taskSpec: string, taskTemplateName: string, taskType: string>, teardown: record<teardownTaskConfigs: list<record>>, triggerConfigs: table<alertConfig: list, cloudSchedulerConfig: record, description: string, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, position: record, properties: record, startTasks: list, triggerId: string, triggerNumber: string, triggerType: string>, triggerConfigsInternal: table<alertConfig: list, cloudSchedulerConfig: record, description: string, enabledClients: list, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, pauseWorkflowExecutions: bool, position: record, properties: record, startTasks: list, triggerCriteria: record, triggerId: string, triggerNumber: string, triggerType: string>, updateTime: string, userLabel: string>"
    integrations-projects-locations-products-integrations-versions-upload: "record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["integrations-callback-generate-token" "integrations-connector-platform-regions-enumerate" "integrations-projects-locations-products-integrations-versions-takeover-edit-lock" "integrations-projects-locations-sfdc-instances-sfdc-channels-delete" "integrations-projects-locations-sfdc-instances-sfdc-channels-get" "integrations-projects-locations-sfdc-instances-sfdc-channels-patch" "integrations-projects-locations-products-integrations-executions-cancel" "integrations-projects-locations-products-integrations-versions-download" "integrations-projects-locations-products-integrations-execute" "integrations-projects-locations-products-integrations-executions-suspensions-lift" "integrations-projects-locations-products-integrations-versions-publish" "integrations-projects-locations-products-integrations-executions-suspensions-resolve" "integrations-projects-locations-products-integrations-schedule" "integrations-projects-locations-products-integrations-test" "integrations-projects-locations-products-integrations-versions-unpublish" "integrations-projects-locations-apps-script-projects-create" "integrations-projects-locations-apps-script-projects-link" "integrations-projects-locations-products-auth-configs-list" "integrations-projects-locations-products-auth-configs-create" "integrations-projects-locations-products-certificates-list" "integrations-projects-locations-products-certificates-create" "integrations-projects-get-clientmetadata" "integrations-projects-locations-get-clients" "integrations-projects-locations-clients-deprovision" "integrations-projects-locations-clients-provision" "integrations-projects-locations-clients-switch" "integrations-projects-locations-products-cloud-functions-create" "integrations-projects-locations-connections-list" "integrations-projects-locations-products-integrations-executions-list" "integrations-projects-locations-products-integrations-list" "integrations-projects-locations-connections-runtime-action-schemas-list" "integrations-projects-locations-connections-runtime-entity-schemas-list" "integrations-projects-locations-sfdc-instances-sfdc-channels-list" "integrations-projects-locations-sfdc-instances-sfdc-channels-create" "integrations-projects-locations-sfdc-instances-list" "integrations-projects-locations-sfdc-instances-create" "integrations-projects-locations-products-integrations-executions-suspensions-list" "integrations-projects-locations-products-integrations-versions-list" "integrations-projects-locations-products-integrations-versions-create" "integrations-projects-locations-products-integrations-versions-upload" "commands"] | sort) } | get name | first)
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

# Receives the auth code and auth config id to combine that with the client id and secret to retrieve access tokens from the token endpoint. Returns either a success or error message when it's done.
#
# GET /v1/callback:generateToken
# Returns: record<message: string>
# operationId: integrations.callback.generateToken
export def "integrations-callback-generate-token" [
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
  --code: string # The auth code for the given request
  --gcp-project-id: string # The gcp project id of the request
  --product: string@product-completer # Which product sends the request
  --redirect-uri: string # Redirect uri of the auth code request
  --state: string # The auth config id for the given request
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/callback:generateToken"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: code, var: code}, {name: gcpProjectId, var: gcp_project_id}, {name: product, var: product}, {name: redirectUri, var: redirect_uri}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, code: $code, gcp_project_id: $gcp_project_id, product: $product, redirect_uri: $redirect_uri, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enumerates the regions for which Connector Platform is provisioned.
#
# GET /v1/connectorPlatformRegions:enumerate
# Returns: record<regions: list<string>>
# operationId: integrations.connectorPlatformRegions.enumerate
export def "integrations-connector-platform-regions-enumerate" [
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
    path: "/v1/connectorPlatformRegions:enumerate"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clears the `locked_by` and `locked_at_timestamp`in the DRAFT version of this integration. It then performs the same action as the CreateDraftIntegrationVersion (i.e., copies the DRAFT version of the integration as a SNAPSHOT and then creates a new DRAFT version with the `locked_by` set to the `user_taking_over` and the `locked_at_timestamp` set to the current timestamp). Both the `locked_by` and `user_taking_over` are notified via email about the takeover. This RPC throws an exception if the integration is not in DRAFT status or if the `locked_by` and `locked_at_timestamp` fields are not set.The TakeoverEdit lock is treated the same as an edit of the integration, and hence shares ACLs with edit. Audit fields updated include last_modified_timestamp, last_modified_by.
#
# POST /v1/{integrationVersion}:takeoverEditLock
# Returns: record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>>
# operationId: integrations.projects.locations.products.integrations.versions.takeoverEditLock
export def "integrations-projects-locations-products-integrations-versions-takeover-edit-lock" [
  integration_version: string
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
    path: "/v1/{integrationVersion}:takeoverEditLock"
    path_params: [{name: integrationVersion, var: integration_version}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    integration_version: $integration_version, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an sfdc channel.
#
# DELETE /v1/{name}
# Returns: record
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.delete
export def "integrations-projects-locations-sfdc-instances-sfdc-channels-delete" [
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

# Gets an sfdc channel. If the channel doesn't exist, Code.NOT_FOUND exception will be thrown.
#
# GET /v1/{name}
# Returns: record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.get
export def "integrations-projects-locations-sfdc-instances-sfdc-channels-get" [
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

# Updates an sfdc channel. Updates the sfdc channel in spanner. Returns the sfdc channel.
#
# PATCH /v1/{name}
# Returns: record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.patch
export def "integrations-projects-locations-sfdc-instances-sfdc-channels-patch" [
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
  --update-mask: string # Field mask specifying the fields in the above SfdcChannel that have been modified and need to be updated.
  --client-certificate-passphrase: string # 'passphrase' should be left unset if private key is not encrypted. Note that 'passphrase' is not the password for web server, but an extra layer of security to protected private key.
  --client-certificate-ssl-certificate: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --channel-topic: string # The Channel topic defined by salesforce once an channel is opened
  --description: string # The description for this channel
  --display-name: string # Client level unique name/alias to easily reference a channel.
  --is-active: oneof<nothing, bool> # Indicated if a channel has any active integrations referencing it. Set to false when the channel is created, and set to true if there is any integration published with the channel configured in it.
  --last-replay-id: string # Last sfdc messsage replay id for channel
  --body-name: string # Resource name of the SFDC channel projects/{project}/locations/{location}/sfdcInstances/{sfdc_instance}/sfdcChannels/{sfdc_channel}. (spec name: name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}, {name: "clientCertificate.passphrase", var: client_certificate_passphrase}, {name: "clientCertificate.sslCertificate", var: client_certificate_ssl_certificate}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelTopic, var: channel_topic}, {name: description, var: description}, {name: displayName, var: display_name}, {name: isActive, var: is_active}, {name: lastReplayId, var: last_replay_id}, {name: name, var: body_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, client_certificate_passphrase: $client_certificate_passphrase, client_certificate_ssl_certificate: $client_certificate_ssl_certificate, channel_topic: $channel_topic, description: $description, display_name: $display_name, is_active: $is_active, last_replay_id: $last_replay_id, body_name: $body_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancellation of an execution
#
# POST /v1/{name}:cancel
# Returns: record<isCanceled: bool>
# operationId: integrations.projects.locations.products.integrations.executions.cancel
export def "integrations-projects-locations-products-integrations-executions-cancel" [
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
    path: "/v1/{name}:cancel"
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

# Downloads an integration. Retrieves the `IntegrationVersion` for a given `integration_id` and returns the response as a string.
#
# GET /v1/{name}:download
# Returns: record<content: string>
# operationId: integrations.projects.locations.products.integrations.versions.download
export def "integrations-projects-locations-products-integrations-versions-download" [
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
  --file-format: string@file-format-completer # File format for download request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}:download"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fileFormat, var: file_format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, file_format: $file_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes integrations synchronously by passing the trigger id in the request body. The request is not returned until the requested executions are either fulfilled or experienced an error. If the integration name is not specified (passing `-`), all of the associated integration under the given trigger_id will be executed. Otherwise only the specified integration for the given `trigger_id` is executed. This is helpful for execution the integration from UI.
#
# POST /v1/{name}:execute
# Returns: record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, outputParameters: record, parameterEntries: table<dataType: string, key: string, value: record>>
# operationId: integrations.projects.locations.products.integrations.execute
export def "integrations-projects-locations-products-integrations-execute" [
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
  --do-not-propagate-error: oneof<nothing, bool> # Optional. Flag to determine how to should propagate errors. If this flag is set to be true, it will not throw an exception. Instead, it will return a {@link ExecuteIntegrationsResponse} with an execution id and error messages as PostWithTriggerIdExecutionException in {@link EventParameters}. The flag is set to be false by default.
  --execution-id: string # Optional. The id of the ON_HOLD execution to be resumed.
  --input-parameters: record # Optional. Input parameters used by integration execution.
  --parameter-entries: list # Optional. Parameters are a part of Event and can be used to communicate between different tasks that are part of the same integration execution. — item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --request-id: string # Optional. This is used to de-dup incoming request: if the duplicate request was detected, the response from the previous execution is returned.
  --trigger-id: string # Required. Matched against all {@link TriggerConfig}s across all integrations. i.e. TriggerConfig.trigger_id.equals(trigger_id). The trigger_id is in the format of `api_trigger/TRIGGER_NAME`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:execute"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: doNotPropagateError, var: do_not_propagate_error}, {name: executionId, var: execution_id}, {name: inputParameters, var: input_parameters}, {name: parameterEntries, var: parameter_entries}, {name: parameters, var: parameters}, {name: requestId, var: request_id}, {name: triggerId, var: trigger_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, do_not_propagate_error: $do_not_propagate_error, execution_id: $execution_id, input_parameters: $input_parameters, parameter_entries: $parameter_entries, parameters: $parameters, request_id: $request_id, trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# * Lifts suspension for advanced suspension task. Fetch corresponding suspension with provided suspension Id, resolve suspension, and set up suspension result for the Suspension Task.
#
# POST /v1/{name}:lift
# Returns: record<eventExecutionInfoId: string>
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.lift
export def "integrations-projects-locations-products-integrations-executions-suspensions-lift" [
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
  --suspension-result: string # User passed in suspension result and will be used to control workflow execution branching behavior by setting up corresponnding edge condition with suspension result. For example, if you want to lift the suspension, you can pass "Approved", or if you want to reject the suspension and terminate workfloe execution, you can pass "Rejected" and terminate the workflow execution with configuring the edge condition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:lift"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: suspensionResult, var: suspension_result}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, suspension_result: $suspension_result
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This RPC throws an exception if the integration is in ARCHIVED or ACTIVE state. This RPC throws an exception if the version being published is DRAFT, and if the `locked_by` user is not the same as the user performing the Publish. Audit fields updated include last_published_timestamp, last_published_by, last_modified_timestamp, last_modified_by. Any existing lock is on this integration is released.
#
# POST /v1/{name}:publish
# Returns: record
# operationId: integrations.projects.locations.products.integrations.versions.publish
export def "integrations-projects-locations-products-integrations-versions-publish" [
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
    path: "/v1/{name}:publish"
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

# * Resolves (lifts/rejects) any number of suspensions. If the integration is already running, only the status of the suspension is updated. Otherwise, the suspended integration will begin execution again.
#
# POST /v1/{name}:resolve
# Returns: record
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.resolve
export def "integrations-projects-locations-products-integrations-executions-suspensions-resolve" [
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
  --suspension: record # A record representing a suspension. — shape: {approvalConfig?: record, audit?: record, eventExecutionInfoId?: string, integration?: string, name?: string, state?: "RESOLUTION_STATE_UNSPECIFIED"|"PENDING"|"REJECTED"|"LIFTED", suspensionConfig?: record, taskId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:resolve"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: suspension, var: suspension}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, suspension: $suspension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedules an integration for execution by passing the trigger id and the scheduled time in the request body.
#
# POST /v1/{name}:schedule
# Returns: record<executionInfoIds: list<string>>
# operationId: integrations.projects.locations.products.integrations.schedule
export def "integrations-projects-locations-products-integrations-schedule" [
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
  --input-parameters: record # Optional. Input parameters used by integration execution.
  --parameter-entries: list # Parameters are a part of Event and can be used to communicate between different tasks that are part of the same integration execution. — item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --request-id: string # This is used to de-dup incoming request: if the duplicate request was detected, the response from the previous execution is returned.
  --schedule-time: string # The time that the integration should be executed. If the time is less or equal to the current time, the integration is executed immediately. (format: google-datetime)
  --trigger-id: string # Matched against all {@link TriggerConfig}s across all integrations. i.e. TriggerConfig.trigger_id.equals(trigger_id)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:schedule"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: inputParameters, var: input_parameters}, {name: parameterEntries, var: parameter_entries}, {name: parameters, var: parameters}, {name: requestId, var: request_id}, {name: scheduleTime, var: schedule_time}, {name: triggerId, var: trigger_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, input_parameters: $input_parameters, parameter_entries: $parameter_entries, parameters: $parameters, request_id: $request_id, schedule_time: $schedule_time, trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Execute the integration in draft state
#
# POST /v1/{name}:test
# Returns: record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, parameterEntries: table<dataType: string, key: string, value: record>, parameters: record>
# operationId: integrations.projects.locations.products.integrations.test
export def "integrations-projects-locations-products-integrations-test" [
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
  --client-id: string # Required. This is used to identify the client on whose behalf the event will be executed.
  --deadline-seconds-time: string # Optional. custom deadline of the rpc (format: google-datetime)
  --input-parameters: record # Optional. Input parameters used during integration execution.
  --integration-version: record # The integration version definition. — shape: {databasePersistencePolicy?: "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED"|"DATABASE_PERSISTENCE_DISABLED", description?: string, errorCatcherConfigs?: list, integrationParameters?: list, integrationParametersInternal?: record, lastModifierEmail?: string, lockHolder?: string, origin?: "UNSPECIFIED"|"UI"|"PIPER_V2"|"PIPER_V3"|"APPLICATION_IP_PROVISIONING", parentTemplateId?: string, runAsServiceAccount?: string, snapshotNumber?: string, taskConfigs?: list, taskConfigsInternal?: list, teardown?: record, ... (3 more fields)}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --test-mode: oneof<nothing, bool> # Optional. Can be specified in the event request, otherwise false (default). If true, enables tasks with condition "test_mode = true". If false, disables tasks with condition "test_mode = true" if global test mode (set by platform) is also false {@link EventBusConfig}.
  --trigger-id: string # Required. The trigger id of the integration trigger config. If both trigger_id and client_id is present, the integration is executed from the start tasks provided by the matching trigger config otherwise it is executed from the default start tasks.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:test"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: deadlineSecondsTime, var: deadline_seconds_time}, {name: inputParameters, var: input_parameters}, {name: integrationVersion, var: integration_version}, {name: parameters, var: parameters}, {name: testMode, var: test_mode}, {name: triggerId, var: trigger_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_id: $client_id, deadline_seconds_time: $deadline_seconds_time, input_parameters: $input_parameters, integration_version: $integration_version, parameters: $parameters, test_mode: $test_mode, trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the status of the ACTIVE integration to SNAPSHOT with a new tag "PREVIOUSLY_PUBLISHED" after validating it. The "HEAD" and "PUBLISH_REQUESTED" tags do not change. This RPC throws an exception if the version being snapshot is not ACTIVE. Audit fields added include action, action_by, action_timestamp.
#
# POST /v1/{name}:unpublish
# Returns: record
# operationId: integrations.projects.locations.products.integrations.versions.unpublish
export def "integrations-projects-locations-products-integrations-versions-unpublish" [
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
    path: "/v1/{name}:unpublish"
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

# Creates an Apps Script project.
#
# POST /v1/{parent}/appsScriptProjects
# Returns: record<projectId: string>
# operationId: integrations.projects.locations.appsScriptProjects.create
export def "integrations-projects-locations-apps-script-projects-create" [
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
  --apps-script-project: string # The name of the Apps Script project to be created.
  --auth-config-id: string # The auth config id necessary to fetch the necessary credentials to create the project for external clients
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/appsScriptProjects"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: appsScriptProject, var: apps_script_project}, {name: authConfigId, var: auth_config_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, apps_script_project: $apps_script_project, auth_config_id: $auth_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Links a existing Apps Script project.
#
# POST /v1/{parent}/appsScriptProjects:link
# Returns: record<scriptId: string>
# operationId: integrations.projects.locations.appsScriptProjects.link
export def "integrations-projects-locations-apps-script-projects-link" [
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
  --script-id: string # The id of the Apps Script project to be linked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/appsScriptProjects:link"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: scriptId, var: script_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, script_id: $script_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all auth configs that match the filter. Restrict to auth configs belong to the current client only.
#
# GET /v1/{parent}/authConfigs
# Returns: record<authConfigs: table<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string>, nextPageToken: string>
# operationId: integrations.projects.locations.products.authConfigs.list
export def "integrations-projects-locations-products-auth-configs-list" [
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
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --page-size: int # The size of entries in the response. If unspecified, defaults to 100.
  --page-token: string # The token returned in the previous response.
  --read-mask: string # The mask which specifies fields that need to be returned in the AuthConfig's response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/authConfigs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an auth config record. Fetch corresponding credentials for specific auth types, e.g. access token for OAuth 2.0, JWT token for JWT. Encrypt the auth config with Cloud KMS and store the encrypted credentials in Spanner. Returns the encrypted auth config.
#
# POST /v1/{parent}/authConfigs
# Returns: record<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record<authToken: record<token: string, type: string>, credentialType: string, jwt: record<jwt: string, jwtHeader: string, jwtPayload: string, secret: string>, oauth2AuthorizationCode: record<accessToken: record, applyReauthPolicy: bool, authCode: string, authEndpoint: string, authParams: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ClientCredentials: record<accessToken: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ResourceOwnerCredentials: record<accessToken: record, clientId: string, clientSecret: string, password: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record, username: string>, oidcToken: record<audience: string, serviceAccountEmail: string, token: string, tokenExpireTime: string>, serviceAccountCredentials: record<scope: string, serviceAccount: string>, usernameAndPassword: record<password: string, username: string>>, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list<string>, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string>
# operationId: integrations.projects.locations.products.authConfigs.create
export def "integrations-projects-locations-products-auth-configs-create" [
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
  --client-certificate-encrypted-private-key: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --client-certificate-passphrase: string # 'passphrase' should be left unset if private key is not encrypted. Note that 'passphrase' is not the password for web server, but an extra layer of security to protected private key.
  --client-certificate-ssl-certificate: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --certificate-id: string # Certificate id for client certificate
  --creator-email: string # The creator's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --credential-type: string@credential-type-completer # Credential type of the encrypted credential.
  --decrypted-credential: record # Defines parameters for a single, canonical credential. — shape: {authToken?: record, credentialType?: "CREDENTIAL_TYPE_UNSPECIFIED"|"USERNAME_AND_PASSWORD"|"API_KEY"|"OAUTH2_AUTHORIZATION_CODE"|"OAUTH2_IMPLICIT"|"OAUTH2_CLIENT_CREDENTIALS"|"OAUTH2_RESOURCE_OWNER_CREDENTIALS"|"JWT"|"AUTH_TOKEN"|"SERVICE_ACCOUNT"|"CLIENT_CERTIFICATE_ONLY"|"OIDC_TOKEN", jwt?: record, oauth2AuthorizationCode?: record, oauth2ClientCredentials?: record, oauth2ResourceOwnerCredentials?: record, oidcToken?: record, serviceAccountCredentials?: record, usernameAndPassword?: record}
  --description: string # A description of the auth config.
  --display-name: string # The name of the auth config.
  --encrypted-credential: string # Auth credential encrypted by Cloud KMS. Can be decrypted as Credential with proper KMS key. (format: byte)
  --expiry-notification-duration: list<string> # User can define the time to receive notification after which the auth config becomes invalid. Support up to 30 days. Support granularity in hours.
  --last-modifier-email: string # The last modifier's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --name: string # Resource name of the SFDC instance projects/{project}/locations/{location}/authConfigs/{authConfig}.
  --override-valid-time: string # User provided expiry time to override. For the example of Salesforce, username/password credentials can be valid for 6 months depending on the instance settings. (format: google-datetime)
  --reason: string # The reason / details of the current status.
  --state: string@state-completer # The status of the auth config.
  --valid-time: string # The time until the auth config is valid. Empty or max value is considered the auth config won't expire. (format: google-datetime)
  --visibility: string@visibility-completer # The visibility of the auth config.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/authConfigs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "clientCertificate.encryptedPrivateKey", var: client_certificate_encrypted_private_key}, {name: "clientCertificate.passphrase", var: client_certificate_passphrase}, {name: "clientCertificate.sslCertificate", var: client_certificate_ssl_certificate}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateId, var: certificate_id}, {name: creatorEmail, var: creator_email}, {name: credentialType, var: credential_type}, {name: decryptedCredential, var: decrypted_credential}, {name: description, var: description}, {name: displayName, var: display_name}, {name: encryptedCredential, var: encrypted_credential}, {name: expiryNotificationDuration, var: expiry_notification_duration}, {name: lastModifierEmail, var: last_modifier_email}, {name: name, var: name}, {name: overrideValidTime, var: override_valid_time}, {name: reason, var: reason}, {name: state, var: state}, {name: validTime, var: valid_time}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_certificate_encrypted_private_key: $client_certificate_encrypted_private_key, client_certificate_passphrase: $client_certificate_passphrase, client_certificate_ssl_certificate: $client_certificate_ssl_certificate, certificate_id: $certificate_id, creator_email: $creator_email, credential_type: $credential_type, decrypted_credential: $decrypted_credential, description: $description, display_name: $display_name, encrypted_credential: $encrypted_credential, expiry_notification_duration: $expiry_notification_duration, last_modifier_email: $last_modifier_email, name: $name, override_valid_time: $override_valid_time, reason: $reason, state: $state, valid_time: $valid_time, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the certificates that match the filter. Restrict to certificate of current client only.
#
# GET /v1/{parent}/certificates
# Returns: record<certificates: table<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record, requestorId: string, validEndTime: string, validStartTime: string>, nextPageToken: string>
# operationId: integrations.projects.locations.products.certificates.list
export def "integrations-projects-locations-products-certificates-list" [
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
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --page-size: int # The size of entries in the response. If unspecified, defaults to 100.
  --page-token: string # The token returned in the previous response.
  --read-mask: string # The mask which specifies fields that need to be returned in the Certificate's response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/certificates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new certificate. The certificate will be registered to the trawler service and will be encrypted using cloud KMS and stored in Spanner Returns the certificate.
#
# POST /v1/{parent}/certificates
# Returns: record<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record<encryptedPrivateKey: string, passphrase: string, sslCertificate: string>, requestorId: string, validEndTime: string, validStartTime: string>
# operationId: integrations.projects.locations.products.certificates.create
export def "integrations-projects-locations-products-certificates-create" [
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
  --certificate-status: string@certificate-status-completer # Status of the certificate
  --credential-id: string # Immutable. Credential id that will be used to register with trawler INTERNAL_ONLY
  --description: string # Description of the certificate
  --display-name: string # Name of the certificate
  --raw-certificate: record # Contains client certificate information — shape: {encryptedPrivateKey?: string, passphrase?: string, sslCertificate?: string}
  --requestor-id: string # Immutable. Requestor ID to be used to register certificate with trawler
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/certificates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: certificateStatus, var: certificate_status}, {name: credentialId, var: credential_id}, {name: description, var: description}, {name: displayName, var: display_name}, {name: rawCertificate, var: raw_certificate}, {name: requestorId, var: requestor_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, certificate_status: $certificate_status, credential_id: $credential_id, description: $description, display_name: $display_name, raw_certificate: $raw_certificate, requestor_id: $requestor_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the metadata info for the requested client
#
# GET /v1/{parent}/clientmetadata
# Returns: record<properties: record<ipEnablementState: string, provisionedRegions: list<string>>>
# operationId: integrations.projects.getClientmetadata
export def "integrations-projects-get-clientmetadata" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/clientmetadata"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the client configuration for the given project and location resource name
#
# GET /v1/{parent}/clients
# Returns: record<client: record<billingType: string, clientState: string, cloudKmsConfig: record<key: string, keyVersion: string, kmsLocation: string, kmsProjectId: string, kmsRing: string>, cloudLoggingConfig: record<bucket: string, enableCloudLogging: bool>, createTime: string, description: string, id: string, p4ServiceAccount: string, projectId: string, region: string>>
# operationId: integrations.projects.locations.getClients
export def "integrations-projects-locations-get-clients" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/clients"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform the deprovisioning steps to disable a user GCP project to use IP and purge all related data in a wipeout-compliant way.
#
# POST /v1/{parent}/clients:deprovision
# Returns: record
# operationId: integrations.projects.locations.clients.deprovision
export def "integrations-projects-locations-clients-deprovision" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/clients:deprovision"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Perform the provisioning steps to enable a user GCP project to use IP. If GCP project already registered on IP end via Apigee Integration, provisioning will fail.
#
# POST /v1/{parent}/clients:provision
# Returns: record
# operationId: integrations.projects.locations.clients.provision
export def "integrations-projects-locations-clients-provision" [
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
  --cloud-kms-config: record # Configuration information for Client's Cloud KMS information — shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
  --create-sample-workflows: oneof<nothing, bool> # Optional. Indicates if sample workflow should be created along with provisioning
  --provision-gmek: oneof<nothing, bool> # Optional. Indicates provision with GMEK or CMEK
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/clients:provision"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudKmsConfig, var: cloud_kms_config}, {name: createSampleWorkflows, var: create_sample_workflows}, {name: provisionGmek, var: provision_gmek}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cloud_kms_config: $cloud_kms_config, create_sample_workflows: $create_sample_workflows, provision_gmek: $provision_gmek
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update client from GMEK to CMEK
#
# POST /v1/{parent}/clients:switch
# Returns: record
# operationId: integrations.projects.locations.clients.switch
export def "integrations-projects-locations-clients-switch" [
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
  --cloud-kms-config: record # Configuration information for Client's Cloud KMS information — shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/clients:switch"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudKmsConfig, var: cloud_kms_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cloud_kms_config: $cloud_kms_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an cloud function project.
#
# POST /v1/{parent}/cloudFunctions
# Returns: record<triggerUrl: string>
# operationId: integrations.projects.locations.products.cloudFunctions.create
export def "integrations-projects-locations-products-cloud-functions-create" [
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
  --function-name: string # The function name of CF to be created
  --function-region: string # The function region of CF to be created
  --project-id: string # Indicates the id of the GCP project that the function will be created in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/cloudFunctions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: functionName, var: function_name}, {name: functionRegion, var: function_region}, {name: projectId, var: project_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, function_name: $function_name, function_region: $function_region, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Connections in a given project and location.
#
# GET /v1/{parent}/connections
# Returns: record<connections: table<authConfig: record, configVariables: list, connectorVersion: string, createTime: string, description: string, destinationConfigs: list, envoyImageLocation: string, imageLocation: string, labels: record, lockConfig: record, logConfig: record, name: string, nodeConfig: record, serviceAccount: string, serviceDirectory: string, sslConfig: record, status: record, suspended: bool, updateTime: string>, nextPageToken: string>
# operationId: integrations.projects.locations.connections.list
export def "integrations-projects-locations-connections-list" [
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
  --filter: string # Filter.
  --order-by: string # Order by parameters.
  --page-size: int # Page size.
  --page-token: string # Page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/connections"
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

# Lists the results of all the integration executions. The response includes the same information as the [execution log](https://cloud.google.com/application-integration/docs/viewing-logs) in the Integration UI.
#
# GET /v1/{parent}/executions
# Returns: record<executionInfos: table<clientId: string, createTime: string, errorCode: record, errors: list, eventExecutionDetails: record, eventExecutionInfoId: string, executionTraceInfo: record, lastModifiedTime: string, postMethod: string, product: string, requestId: string, requestParams: record, responseParams: record, snapshotNumber: string, tenant: string, triggerId: string, workflowId: string, workflowName: string, workflowRetryBackoffIntervalSeconds: string>, executions: table<createTime: string, directSubExecutions: list, eventExecutionDetails: record, executionDetails: record, executionMethod: string, name: string, requestParameters: record, requestParams: list, responseParameters: record, responseParams: list, triggerId: string, updateTime: string>, nextPageToken: string>
# operationId: integrations.projects.locations.products.integrations.executions.list
export def "integrations-projects-locations-products-integrations-executions-list" [
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
  --filter: string # Optional. Standard filter field, we support filtering on following fields: workflow_name: the name of the integration. CreateTimestamp: the execution created time. event_execution_state: the state of the executions. execution_id: the id of the execution. trigger_id: the id of the trigger. parameter_type: the type of the parameters involved in the execution. All fields support for EQUALS, in additional: CreateTimestamp support for LESS_THAN, GREATER_THAN ParameterType support for HAS For example: "parameter_type" HAS \"string\" Also supports operators like AND, OR, NOT For example, trigger_id=\"id1\" AND workflow_name=\"testWorkflow\"
  --filter-params-custom-filter: string # Optional user-provided custom filter.
  --filter-params-end-time: string # End timestamp.
  --filter-params-event-statuses: list<string> # List of possible event statuses.
  --filter-params-execution-id: string # Execution id.
  --filter-params-parameter-key: string # Param key. DEPRECATED. User parameter_pair_key instead.
  --filter-params-parameter-pair-key: string # Param key in the key value pair filter.
  --filter-params-parameter-pair-value: string # Param value in the key value pair filter.
  --filter-params-parameter-type: string # Param type.
  --filter-params-parameter-value: string # Param value. DEPRECATED. User parameter_pair_value instead.
  --filter-params-start-time: string # Start timestamp.
  --filter-params-task-statuses: list<string> # List of possible task statuses.
  --filter-params-workflow-name: string # Workflow name.
  --order-by: string # Optional. The results would be returned in order you specified here. Currently supporting "last_modified_time" and "create_time".
  --page-size: int # Optional. The size of entries in the response.
  --page-token: string # Optional. The token returned in the previous response.
  --read-mask: string # Optional. View mask for the response data. If set, only the field specified will be returned as part of the result. If not set, all fields in event execution info will be filled and returned.
  --refresh-acl: oneof<nothing, bool> # Optional. If true, the service will use the most recent acl information to list event execution infos and renew the acl cache. Note that fetching the most recent acl is synchronous, so it will increase RPC call latency.
  --truncate-params: oneof<nothing, bool> # Optional. If true, the service will truncate the params to only keep the first 1000 characters of string params and empty the executions in order to make response smaller. Only works for UI and when the params fields are not filtered out.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/executions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: "filterParams.customFilter", var: filter_params_custom_filter}, {name: "filterParams.endTime", var: filter_params_end_time}, {name: "filterParams.eventStatuses", var: filter_params_event_statuses, style: multi}, {name: "filterParams.executionId", var: filter_params_execution_id}, {name: "filterParams.parameterKey", var: filter_params_parameter_key}, {name: "filterParams.parameterPairKey", var: filter_params_parameter_pair_key}, {name: "filterParams.parameterPairValue", var: filter_params_parameter_pair_value}, {name: "filterParams.parameterType", var: filter_params_parameter_type}, {name: "filterParams.parameterValue", var: filter_params_parameter_value}, {name: "filterParams.startTime", var: filter_params_start_time}, {name: "filterParams.taskStatuses", var: filter_params_task_statuses, style: multi}, {name: "filterParams.workflowName", var: filter_params_workflow_name}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}, {name: refreshAcl, var: refresh_acl}, {name: truncateParams, var: truncate_params}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, filter_params_custom_filter: $filter_params_custom_filter, filter_params_end_time: $filter_params_end_time, filter_params_event_statuses: $filter_params_event_statuses, filter_params_execution_id: $filter_params_execution_id, filter_params_parameter_key: $filter_params_parameter_key, filter_params_parameter_pair_key: $filter_params_parameter_pair_key, filter_params_parameter_pair_value: $filter_params_parameter_pair_value, filter_params_parameter_type: $filter_params_parameter_type, filter_params_parameter_value: $filter_params_parameter_value, filter_params_start_time: $filter_params_start_time, filter_params_task_statuses: $filter_params_task_statuses, filter_params_workflow_name: $filter_params_workflow_name, order_by: $order_by, page_size: $page_size, page_token: $page_token, read_mask: $read_mask, refresh_acl: $refresh_acl, truncate_params: $truncate_params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of all integrations in the specified project.
#
# GET /v1/{parent}/integrations
# Returns: record<integrations: table<active: bool, description: string, name: string, updateTime: string>, nextPageToken: string>
# operationId: integrations.projects.locations.products.integrations.list
export def "integrations-projects-locations-products-integrations-list" [
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
  --filter: string # Filter on fields of IntegrationVersion. Fields can be compared with literal values by use of ":" (containment), "=" (equality), ">" (greater), "<" (less than), >=" (greater than or equal to), "<=" (less than or equal to), and "!=" (inequality) operators. Negation, conjunction, and disjunction are written using NOT, AND, and OR keywords. For example, organization_id=\"1\" AND state=ACTIVE AND description:"test". Filtering cannot be performed on repeated fields like `task_config`.
  --order-by: string # The results would be returned in order you specified here. Supported sort keys are: Descending sort order by "last_modified_time", "created_time", "snapshot_number". Ascending sort order by the integration name.
  --page-size: int # The page size for the resquest.
  --page-token: string # The page token for the resquest.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/integrations"
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

# Lists the JSON schemas for the inputs and outputs of actions, filtered by action name.
#
# GET /v1/{parent}/runtimeActionSchemas
# Returns: record<nextPageToken: string, runtimeActionSchemas: table<action: string, inputSchema: string, outputSchema: string>>
# operationId: integrations.projects.locations.connections.runtimeActionSchemas.list
export def "integrations-projects-locations-connections-runtime-action-schemas-list" [
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
  --filter: string # Filter. Only the action field with literal equality operator is supported.
  --page-size: int # Page size.
  --page-token: string # Page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/runtimeActionSchemas"
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

# Lists the JSON schemas for the properties of runtime entities, filtered by entity name.
#
# GET /v1/{parent}/runtimeEntitySchemas
# Returns: record<nextPageToken: string, runtimeEntitySchemas: table<arrayFieldSchema: string, entity: string, fieldSchema: string>>
# operationId: integrations.projects.locations.connections.runtimeEntitySchemas.list
export def "integrations-projects-locations-connections-runtime-entity-schemas-list" [
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
  --filter: string # Filter. Only the entity field with literal equality operator is supported.
  --page-size: int # Page size.
  --page-token: string # Page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/runtimeEntitySchemas"
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

# Lists all sfdc channels that match the filter. Restrict to sfdc channels belonging to the current client only.
#
# GET /v1/{parent}/sfdcChannels
# Returns: record<nextPageToken: string, sfdcChannels: table<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>>
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.list
export def "integrations-projects-locations-sfdc-instances-sfdc-channels-list" [
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
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --page-size: int # The size of entries in the response. If unspecified, defaults to 100.
  --page-token: string # The token returned in the previous response.
  --read-mask: string # The mask which specifies fields that need to be returned in the SfdcChannel's response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/sfdcChannels"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an sfdc channel record. Store the sfdc channel in Spanner. Returns the sfdc channel.
#
# POST /v1/{parent}/sfdcChannels
# Returns: record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.create
export def "integrations-projects-locations-sfdc-instances-sfdc-channels-create" [
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
  --channel-topic: string # The Channel topic defined by salesforce once an channel is opened
  --description: string # The description for this channel
  --display-name: string # Client level unique name/alias to easily reference a channel.
  --is-active: oneof<nothing, bool> # Indicated if a channel has any active integrations referencing it. Set to false when the channel is created, and set to true if there is any integration published with the channel configured in it.
  --last-replay-id: string # Last sfdc messsage replay id for channel
  --name: string # Resource name of the SFDC channel projects/{project}/locations/{location}/sfdcInstances/{sfdc_instance}/sfdcChannels/{sfdc_channel}.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/sfdcChannels"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelTopic, var: channel_topic}, {name: description, var: description}, {name: displayName, var: display_name}, {name: isActive, var: is_active}, {name: lastReplayId, var: last_replay_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, channel_topic: $channel_topic, description: $description, display_name: $display_name, is_active: $is_active, last_replay_id: $last_replay_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all sfdc instances that match the filter. Restrict to sfdc instances belonging to the current client only.
#
# GET /v1/{parent}/sfdcInstances
# Returns: record<nextPageToken: string, sfdcInstances: table<authConfigId: list, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string>>
# operationId: integrations.projects.locations.sfdcInstances.list
export def "integrations-projects-locations-sfdc-instances-list" [
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
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --page-size: int # The size of entries in the response. If unspecified, defaults to 100.
  --page-token: string # The token returned in the previous response.
  --read-mask: string # The mask which specifies fields that need to be returned in the SfdcInstance's response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/sfdcInstances"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an sfdc instance record. Store the sfdc instance in Spanner. Returns the sfdc instance.
#
# POST /v1/{parent}/sfdcInstances
# Returns: record<authConfigId: list<string>, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string>
# operationId: integrations.projects.locations.sfdcInstances.create
export def "integrations-projects-locations-sfdc-instances-create" [
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
  --auth-config-id: list<string> # A list of AuthConfigs that can be tried to open the channel to SFDC
  --description: string # A description of the sfdc instance.
  --display-name: string # User selected unique name/alias to easily reference an instance.
  --name: string # Resource name of the SFDC instance projects/{project}/locations/{location}/sfdcInstances/{sfdcInstance}.
  --service-authority: string # URL used for API calls after authentication (the login authority is configured within the referenced AuthConfig).
  --sfdc-org-id: string # The SFDC Org Id. This is defined in salesforce.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/sfdcInstances"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: authConfigId, var: auth_config_id}, {name: description, var: description}, {name: displayName, var: display_name}, {name: name, var: name}, {name: serviceAuthority, var: service_authority}, {name: sfdcOrgId, var: sfdc_org_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, auth_config_id: $auth_config_id, description: $description, display_name: $display_name, name: $name, service_authority: $service_authority, sfdc_org_id: $sfdc_org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# * Lists suspensions associated with a specific execution. Only those with permissions to resolve the relevant suspensions will be able to view them.
#
# GET /v1/{parent}/suspensions
# Returns: record<nextPageToken: string, suspensions: table<approvalConfig: record, audit: record, createTime: string, eventExecutionInfoId: string, integration: string, lastModifyTime: string, name: string, state: string, suspensionConfig: record, taskId: string>>
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.list
export def "integrations-projects-locations-products-integrations-executions-suspensions-list" [
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
  --filter: string # Standard filter field.
  --order-by: string # Field name to order by.
  --page-size: int # Maximum number of entries in the response.
  --page-token: string # Token to retrieve a specific page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/suspensions"
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

# Returns the list of all integration versions in the specified project.
#
# GET /v1/{parent}/versions
# Returns: record<integrationVersions: table<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list, integrationParameters: list, integrationParametersInternal: record, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list, taskConfigsInternal: list, teardown: record, triggerConfigs: list, triggerConfigsInternal: list, updateTime: string, userLabel: string>, nextPageToken: string, noPermission: bool>
# operationId: integrations.projects.locations.products.integrations.versions.list
export def "integrations-projects-locations-products-integrations-versions-list" [
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
  --field-mask: string # The field mask which specifies the particular data to be returned.
  --filter: string # Filter on fields of IntegrationVersion. Fields can be compared with literal values by use of ":" (containment), "=" (equality), ">" (greater), "<" (less than), >=" (greater than or equal to), "<=" (less than or equal to), and "!=" (inequality) operators. Negation, conjunction, and disjunction are written using NOT, AND, and OR keywords. For example, organization_id=\"1\" AND state=ACTIVE AND description:"test". Filtering cannot be performed on repeated fields like `task_config`.
  --order-by: string # The results would be returned in order you specified here. Currently supported sort keys are: Descending sort order for "last_modified_time", "created_time", "snapshot_number" Ascending sort order for "name".
  --page-size: int # The maximum number of versions to return. The service may return fewer than this value. If unspecified, at most 50 versions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListIntegrationVersions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListIntegrationVersions` must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fieldMask, var: field_mask}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, field_mask: $field_mask, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a integration with a draft version in the specified project.
#
# POST /v1/{parent}/versions
# Returns: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: table<description: string, errorCatcherId: string, errorCatcherNumber: string, label: string, position: record, startErrorTasks: list>, integrationParameters: table<dataType: string, defaultValue: record, displayName: string, inputOutputType: string, isTransient: bool, jsonSchema: string, key: string, producer: string, searchable: bool>, integrationParametersInternal: record<parameters: list<record>>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: table<description: string, displayName: string, errorCatcherId: string, externalTaskType: string, failurePolicy: record, jsonValidationOption: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, successPolicy: record, synchronousCallFailurePolicy: record, task: string, taskExecutionStrategy: string, taskId: string, taskTemplate: string>, taskConfigsInternal: table<alertConfigs: list, createTime: string, creatorEmail: string, description: string, disableStrictTypeValidation: bool, errorCatcherId: string, externalTaskType: string, failurePolicy: record, incomingEdgeCount: int, jsonValidationOption: string, label: string, lastModifiedTime: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, precondition: string, preconditionLabel: string, rollbackStrategy: record, successPolicy: record, synchronousCallFailurePolicy: record, taskEntity: record, taskExecutionStrategy: string, taskName: string, taskNumber: string, taskSpec: string, taskTemplateName: string, taskType: string>, teardown: record<teardownTaskConfigs: list<record>>, triggerConfigs: table<alertConfig: list, cloudSchedulerConfig: record, description: string, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, position: record, properties: record, startTasks: list, triggerId: string, triggerNumber: string, triggerType: string>, triggerConfigsInternal: table<alertConfig: list, cloudSchedulerConfig: record, description: string, enabledClients: list, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, pauseWorkflowExecutions: bool, position: record, properties: record, startTasks: list, triggerCriteria: record, triggerId: string, triggerNumber: string, triggerType: string>, updateTime: string, userLabel: string>
# operationId: integrations.projects.locations.products.integrations.versions.create
export def "integrations-projects-locations-products-integrations-versions-create" [
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
  --new-integration: oneof<nothing, bool> # Set this flag to true, if draft version is to be created for a brand new integration. False, if the request is for an existing integration. For backward compatibility reasons, even if this flag is set to `false` and no existing integration is found, a new draft integration will still be created.
  --database-persistence-policy: string@database-persistence-policy-completer # Optional. Flag to disable database persistence for execution data, including event execution info, execution export info, execution metadata index and execution param index.
  --description: string # Optional. The integration description.
  --error-catcher-configs: list # Optional. Error Catch Task configuration for the integration. It's optional. — item shape: {description?: string, errorCatcherId?: string, errorCatcherNumber?: string, label?: string, position?: record, startErrorTasks?: list}
  --integration-parameters: list # Optional. Parameters that are expected to be passed to the integration when an event is triggered. This consists of all the parameters that are expected in the integration execution. This gives the user the ability to provide default values, add information like PII and also provide data types of each parameter. — item shape: {dataType?: "INTEGRATION_PARAMETER_DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"BOOLEAN_ARRAY"|"JSON_VALUE"|"PROTO_VALUE"|"PROTO_ARRAY", defaultValue?: record, displayName?: string, inputOutputType?: "IN_OUT_TYPE_UNSPECIFIED"|"IN"|"OUT"|"IN_OUT", isTransient?: bool, jsonSchema?: string, key?: string, producer?: string, searchable?: bool}
  --integration-parameters-internal: record # LINT.IfChange This is the frontend version of WorkflowParameters. It's exactly like the backend version except that instead of flattening protobuf parameters and treating every field and subfield of a protobuf parameter as a separate parameter, the fields/subfields of a protobuf parameter will be nested as "children" (see 'children' field below) parameters of the parent parameter. Please refer to enterprise/crm/eventbus/proto/workflow_parameters.proto for more information about WorkflowParameters. — shape: {parameters?: list}
  --last-modifier-email: string # Optional. The last modifier's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --lock-holder: string # Optional. The edit lock holder's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --origin: string@origin-completer # Optional. The origin that indicates where this integration is coming from.
  --parent-template-id: string # Optional. The id of the template which was used to create this integration_version.
  --run-as-service-account: string # Optional. The run-as service account email, if set and auth config is not configured, that will be used to generate auth token to be used in Connector task, Rest caller task and Cloud function task.
  --snapshot-number: string # Optional. An increasing sequence that is set when a new snapshot is created. The last created snapshot can be identified by [workflow_name, org_id latest(snapshot_number)]. However, last created snapshot need not be same as the HEAD. So users should always use "HEAD" tag to identify the head. (format: int64)
  --task-configs: list # Optional. Task configuration for the integration. It's optional, but the integration doesn't do anything without task_configs. — item shape: {description?: string, displayName?: string, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, jsonValidationOption?: "JSON_VALIDATION_OPTION_UNSPECIFIED"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", nextTasks?: list, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", parameters?: record, position?: record, successPolicy?: record, ... (5 more fields)}
  --task-configs-internal: list # Optional. Task configuration for the integration. It's optional, but the integration doesn't do anything without task_configs. — item shape: {alertConfigs?: list, createTime?: string, creatorEmail?: string, description?: string, disableStrictTypeValidation?: bool, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, incomingEdgeCount?: int, jsonValidationOption?: "UNSPECIFIED_JSON_VALIDATION_OPTION"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", label?: string, lastModifiedTime?: string, nextTasks?: list, ... (15 more fields)}
  --teardown: record # shape: {teardownTaskConfigs?: list}
  --trigger-configs: list # Optional. Trigger configurations. — item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", position?: record, properties?: record, startTasks?: list, triggerId?: string, triggerNumber?: string, triggerType?: "TRIGGER_TYPE_UNSPECIFIED"|"CRON"|"API"|"SFDC_CHANNEL"|"CLOUD_PUBSUB_EXTERNAL"|"SFDC_CDC_CHANNEL"|"CLOUD_SCHEDULER"}
  --trigger-configs-internal: list # Optional. Trigger configurations. — item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, enabledClients?: list<string>, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", pauseWorkflowExecutions?: bool, position?: record, properties?: record, startTasks?: list, triggerCriteria?: record, triggerId?: string, triggerNumber?: string, ... (1 more fields)}
  --user-label: string # Optional. A user-defined label that annotates an integration version. Typically, this is only set when the integration version is created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/versions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: newIntegration, var: new_integration}]
    body: {content_type: "application/json", kind: json, fields: [{name: databasePersistencePolicy, var: database_persistence_policy}, {name: description, var: description}, {name: errorCatcherConfigs, var: error_catcher_configs}, {name: integrationParameters, var: integration_parameters}, {name: integrationParametersInternal, var: integration_parameters_internal}, {name: lastModifierEmail, var: last_modifier_email}, {name: lockHolder, var: lock_holder}, {name: origin, var: origin}, {name: parentTemplateId, var: parent_template_id}, {name: runAsServiceAccount, var: run_as_service_account}, {name: snapshotNumber, var: snapshot_number}, {name: taskConfigs, var: task_configs}, {name: taskConfigsInternal, var: task_configs_internal}, {name: teardown, var: teardown}, {name: triggerConfigs, var: trigger_configs}, {name: triggerConfigsInternal, var: trigger_configs_internal}, {name: userLabel, var: user_label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, new_integration: $new_integration, database_persistence_policy: $database_persistence_policy, description: $description, error_catcher_configs: $error_catcher_configs, integration_parameters: $integration_parameters, integration_parameters_internal: $integration_parameters_internal, last_modifier_email: $last_modifier_email, lock_holder: $lock_holder, origin: $origin, parent_template_id: $parent_template_id, run_as_service_account: $run_as_service_account, snapshot_number: $snapshot_number, task_configs: $task_configs, task_configs_internal: $task_configs_internal, teardown: $teardown, trigger_configs: $trigger_configs, trigger_configs_internal: $trigger_configs_internal, user_label: $user_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads an integration. The content can be a previously downloaded integration. Performs the same function as CreateDraftIntegrationVersion, but accepts input in a string format, which holds the complete representation of the IntegrationVersion content.
#
# POST /v1/{parent}/versions:upload
# Returns: record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>>
# operationId: integrations.projects.locations.products.integrations.versions.upload
export def "integrations-projects-locations-products-integrations-versions-upload" [
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
  --content: string # The textproto of the integration_version.
  --file-format: string@file-format-completer # File format for upload request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/versions:upload"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: fileFormat, var: file_format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content: $content, file_format: $file_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
