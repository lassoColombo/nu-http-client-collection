# Auto-generated client for Rumble API (deprecated) v2.15.0
# Source: https://api.apis.guru/v2/specs/rumble.run/2.15.0/openapi.json
# Auth: --token flag or $env.RUMBLE_API_DEPRECATED_TOKEN

const CLIENT = {
  base_url: "https://console.rumble.run/api/v1.0"
  token_env_var: "RUMBLE_API_DEPRECATED_TOKEN"
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

def base-url-completer [] { ["https://console.rumble.run/api/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["aws_access_secret" "miradore_api_key_v1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account-agents: "table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>"
    get-account-credentials: "table<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>"
    create-account-credential: "record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>"
    get-account-credential: "record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>"
    export-events-json: "table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string>"
    export-events-jsonl: "table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string>"
    get-account-groups: "record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>"
    create-account-group: "record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>"
    update-account-group: "record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>"
    get-account-group: "record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>"
    get-account-keys: "table<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    create-account-key: "record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    get-account-key: "record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    rotate-account-key: "record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    get-account-license: "record<activated_at: int, address_city: string, address_country: string, address_postal: string, address_region: string, address_street: string, created_at: int, id: string, license_expiration: int, license_live_asset_count: int, license_max_assets: int, license_project_asset_count: int, license_type: string, name: string, partner: string, phone: string, settings: record, sso_default_role: string, sso_domain: string, sso_login_issuer_url: string, sso_login_login_url: string, sso_login_logout_url: string, sso_login_message: string, sso_mode: string, sso_type: string, subscription_cancel_at: int, subscription_canceled_at: int, subscription_period_end: int, subscription_period_start: int, updated_at: int, via_reseller: bool>"
    get-account-organizations: "table<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    create-account-organization: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    get-account-organization: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    update-account-organization: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    rotate-account-organization-export-token: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    get-account-sites: "table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    get-account-group-mappings: "record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>"
    create-account-group-mapping: "record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>"
    update-account-group-mapping: "record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>"
    get-account-group-mapping: "record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>"
    get-account-tasks: "table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-account-scan-templates: "table<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    create-account-scan-template: "record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    update-account-scan-template: "record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    remove-account-scan-template: "record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-account-scan-template: "record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-account-users: "table<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    create-account-user: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    create-account-user-invite: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    get-account-user: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    update-account-user: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    reset-account-user-lockout: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    reset-account-user-mfa: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    reset-account-user-password: "record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>"
    export-assets-cisco-csv: "binary"
    export-assets-csv: "binary"
    export-assets-json: "table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    export-assets-jsonl: "binary"
    snow-export-assets-csv: "binary"
    snow-export-assets-json: "table<addresses_extra: string, addresses_scope: string, alive: bool, asset_id: string, comments: string, detected_by: string, domains: string, first_discovered: string, hw_product: string, hw_vendor: string, hw_version: string, ip_address: string, last_discovered: string, last_updated: string, lowest_rtt: int, lowest_ttl: int, mac_address: string, mac_manufacturer: string, mac_vendors: string, macs: string, name: string, newest_mac_age: string, organization: string, os_product: string, os_vendor: string, os_version: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, site: string, sys_class_name: string, tags: string, type: string>"
    splunk-asset-sync-created-json: "record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int>"
    splunk-asset-sync-updated-json: "record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int>"
    export-services-csv: "binary"
    export-services-json: "table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    export-services-jsonl: "binary"
    snow-export-services-csv: "binary"
    export-sites-csv: "binary"
    export-sites-json: "table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    export-sites-jsonl: "binary"
    export-wireless-csv: "binary"
    export-wireless-json: "table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>"
    export-wireless-jsonl: "binary"
    get-organization: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    update-organization: "record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>"
    get-agents: "table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>"
    get-agent: "record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>"
    update-agent-site: "record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>"
    get-assets: "table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    export-asset-top-hwcsv: "binary"
    export-asset-top-oscsv: "binary"
    export-asset-top-tags-csv: "binary"
    export-asset-top-types-csv: "binary"
    get-asset: "record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    update-asset-comments: "record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    update-asset-tags: "record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    get-key: "record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    rotate-key: "record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>"
    get-services: "table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    export-subnet-utilization-stats-csv: "binary"
    export-services-top-products-csv: "binary"
    export-services-top-protocols-csv: "binary"
    export-services-top-tcpcsv: "binary"
    export-services-top-udpcsv: "binary"
    get-service: "record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>"
    get-sites: "table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    create-site: "record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    get-site: "record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    update-site: "record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>"
    import-scan-data: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    import-nessus-scan-data: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    create-scan: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-tasks: "table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-task: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    update-task: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-task-change-report: "record<id: string>"
    get-task-scan-data: "record<id: string>"
    hide-task: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-task-log: "record<id: string>"
    stop-task: "record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>"
    get-wireless-la-ns: "table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>"
    get-wireless-lan: "record<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>"
    get-latest-agent-version: "record<id: string, version: string>"
    get-latest-platform-version: "record<id: string, version: string>"
    get-latest-scanner-version: "record<id: string, version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account-agents" "get-account-credentials" "create-account-credential" "remove-account-credential" "get-account-credential" "export-events-json" "export-events-jsonl" "get-account-groups" "create-account-group" "update-account-group" "remove-account-group" "get-account-group" "get-account-keys" "create-account-key" "remove-account-key" "get-account-key" "rotate-account-key" "get-account-license" "get-account-organizations" "create-account-organization" "remove-account-organization" "get-account-organization" "update-account-organization" "delete-account-organization-export-token" "rotate-account-organization-export-token" "get-account-sites" "get-account-group-mappings" "create-account-group-mapping" "update-account-group-mapping" "remove-account-group-mapping" "get-account-group-mapping" "get-account-tasks" "get-account-scan-templates" "create-account-scan-template" "update-account-scan-template" "remove-account-scan-template" "get-account-scan-template" "get-account-users" "create-account-user" "create-account-user-invite" "remove-account-user" "get-account-user" "update-account-user" "reset-account-user-lockout" "reset-account-user-mfa" "reset-account-user-password" "export-assets-cisco-csv" "export-assets-csv" "export-assets-json" "export-assets-jsonl" "export-assets-nmap-xml" "snow-export-assets-csv" "snow-export-assets-json" "splunk-asset-sync-created-json" "splunk-asset-sync-updated-json" "export-services-csv" "export-services-json" "export-services-jsonl" "snow-export-services-csv" "export-sites-csv" "export-sites-json" "export-sites-jsonl" "export-wireless-csv" "export-wireless-json" "export-wireless-jsonl" "get-organization" "update-organization" "get-agents" "remove-agent" "get-agent" "update-agent-site" "upgrade-agent" "get-assets" "clear-bulk-asset-tags" "update-bulk-asset-tags" "export-asset-top-hwcsv" "export-asset-top-oscsv" "export-asset-top-tags-csv" "export-asset-top-types-csv" "remove-asset" "get-asset" "update-asset-comments" "update-asset-tags" "remove-key" "get-key" "rotate-key" "get-services" "export-subnet-utilization-stats-csv" "export-services-top-products-csv" "export-services-top-protocols-csv" "export-services-top-tcpcsv" "export-services-top-udpcsv" "remove-service" "get-service" "get-sites" "create-site" "remove-site" "get-site" "update-site" "import-scan-data" "import-nessus-scan-data" "create-scan" "get-tasks" "get-task" "update-task" "get-task-change-report" "get-task-scan-data" "hide-task" "get-task-log" "stop-task" "get-wireless-la-ns" "remove-wireless-lan" "get-wireless-lan" "get-latest-agent-version" "get-latest-platform-version" "get-latest-scanner-version" "commands"] | sort) } | get name | first)
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

# Get all agents across all organizations
#
# GET /account/agents
# Returns: table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>
# operationId: getAccountAgents
export def "get-account-agents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/agents"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all account credentials
#
# GET /account/credentials
# Returns: table<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>
# operationId: getAccountCredentials
export def "get-account-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/credentials"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new credential
#
# PUT /account/credentials
# Returns: record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>
# operationId: createAccountCredential
export def "create-account-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user, e77602e0-3fb8-4734-aef9-fbc6fdcb0fa9: none}
  --cidrs: string # e.g. 10.0.0.17/32, 192.168.1.0/24
  --global: oneof<nothing, bool> # e.g. false
  --name: string # e.g. credentials_name
  --secret: any
  --type: string@type-completer # e.g. miradore_api_key_v1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: cidrs, var: cidrs}, {name: global, var: global}, {name: name, var: name}, {name: secret, var: secret}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    acl: $acl, cidrs: $cidrs, global: $global, name: $name, secret: $secret, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this credential
#
# DELETE /account/credentials/{credential_id}
# operationId: removeAccountCredential
export def "remove-account-credential" [
  credential_id: string
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
    path: "/account/credentials/{credential_id}"
    path_params: [{name: credential_id, var: credential_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get credential details
#
# GET /account/credentials/{credential_id}
# Returns: record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string>
# operationId: getAccountCredential
export def "get-account-credential" [
  credential_id: string
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
    path: "/account/credentials/{credential_id}"
    path_params: [{name: credential_id, var: credential_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    credential_id: $credential_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# System event log as JSON
#
# GET /account/events.json
# Returns: table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string>
# operationId: exportEventsJSON
export def "export-events-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/events.json"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# System event log as JSON line-delimited
#
# GET /account/events.jsonl
# Returns: table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string>
# operationId: exportEventsJSONL
export def "export-events-jsonl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/events.jsonl"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all groups
#
# GET /account/groups
# Returns: record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>
# operationId: getAccountGroups
export def "get-account-groups" [
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
    path: "/account/groups"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new group
#
# POST /account/groups
# Returns: record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>
# operationId: createAccountGroup
export def "create-account-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Viewers Group
  --expires-at: int # format: int64, e.g. 1576300370
  --name: string # e.g. Viewers
  --org-default-role: string # e.g. admin
  --org-roles: record # e.g. {1a5e612e-4d64-45fe-aa3e-afba5cf3b9bf: viewer, fd6d6662-732b-4c4b-8331-051178994384: admin}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: name, var: name}, {name: org_default_role, var: org_default_role}, {name: org_roles, var: org_roles}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    description: $description, expires_at: $expires_at, name: $name, org_default_role: $org_default_role, org_roles: $org_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing group
#
# PUT /account/groups
# Returns: record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>
# operationId: updateAccountGroup
export def "update-account-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Viewers Group
  --expires-at: int # format: int64, e.g. 1576300370
  --id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --name: string # e.g. Viewers
  --org-default-role: string # e.g. admin
  --org-roles: record # e.g. {1a5e612e-4d64-45fe-aa3e-afba5cf3b9bf: viewer, fd6d6662-732b-4c4b-8331-051178994384: admin}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expires_at, var: expires_at}, {name: id, var: id}, {name: name, var: name}, {name: org_default_role, var: org_default_role}, {name: org_roles, var: org_roles}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    description: $description, expires_at: $expires_at, id: $id, name: $name, org_default_role: $org_default_role, org_roles: $org_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this group
#
# DELETE /account/groups/{group_id}
# operationId: removeAccountGroup
export def "remove-account-group" [
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
    method: delete
    path: "/account/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group details
#
# GET /account/groups/{group_id}
# Returns: record<created_at: int, created_by_email: string, description: string, expires_at: int, id: string, name: string, org_default_role: string, org_roles: record, role_summary: string, updated_at: int, user_count: int>
# operationId: getAccountGroup
export def "get-account-group" [
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
    path: "/account/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all active API keys
#
# GET /account/keys
# Returns: table<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: getAccountKeys
export def "get-account-keys" [
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
    path: "/account/keys"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new key
#
# PUT /account/keys
# Returns: record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: createAccountKey
export def "create-account-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. Splunk integration key
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/keys"
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: organization_id, var: organization_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment: $comment, organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this key
#
# DELETE /account/keys/{key_id}
# operationId: removeAccountKey
export def "remove-account-key" [
  key_id: string
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
    path: "/account/keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get key details
#
# GET /account/keys/{key_id}
# Returns: record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: getAccountKey
export def "get-account-key" [
  key_id: string
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
    path: "/account/keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotates the key secret
#
# PATCH /account/keys/{key_id}/rotate
# Returns: record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: rotateAccountKey
export def "rotate-account-key" [
  key_id: string
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
    method: patch
    path: "/account/keys/{key_id}/rotate"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get license details
#
# GET /account/license
# Returns: record<activated_at: int, address_city: string, address_country: string, address_postal: string, address_region: string, address_street: string, created_at: int, id: string, license_expiration: int, license_live_asset_count: int, license_max_assets: int, license_project_asset_count: int, license_type: string, name: string, partner: string, phone: string, settings: record, sso_default_role: string, sso_domain: string, sso_login_issuer_url: string, sso_login_login_url: string, sso_login_logout_url: string, sso_login_message: string, sso_mode: string, sso_type: string, subscription_cancel_at: int, subscription_canceled_at: int, subscription_period_end: int, subscription_period_start: int, updated_at: int, via_reseller: bool>
# operationId: getAccountLicense
export def "get-account-license" [
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
    path: "/account/license"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all organization details
#
# GET /account/orgs
# Returns: table<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: getAccountOrganizations
export def "get-account-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/orgs"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new organization
#
# PUT /account/orgs
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: createAccountOrganization
export def "create-account-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/orgs"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expiration_assets_offline, var: expiration_assets_offline}, {name: expiration_assets_stale, var: expiration_assets_stale}, {name: expiration_scans, var: expiration_scans}, {name: export_token, var: export_token}, {name: name, var: name}, {name: parent_id, var: parent_id}, {name: project, var: project}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this organization
#
# DELETE /account/orgs/{org_id}
# operationId: removeAccountOrganization
export def "remove-account-organization" [
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
    path: "/account/orgs/{org_id}"
    path_params: [{name: org_id, var: org_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization details
#
# GET /account/orgs/{org_id}
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: getAccountOrganization
export def "get-account-organization" [
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
    path: "/account/orgs/{org_id}"
    path_params: [{name: org_id, var: org_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization details
#
# PATCH /account/orgs/{org_id}
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: updateAccountOrganization
export def "update-account-organization" [
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
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/orgs/{org_id}"
    path_params: [{name: org_id, var: org_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expiration_assets_offline, var: expiration_assets_offline}, {name: expiration_assets_stale, var: expiration_assets_stale}, {name: expiration_scans, var: expiration_scans}, {name: export_token, var: export_token}, {name: name, var: name}, {name: parent_id, var: parent_id}, {name: project, var: project}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id, description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the export token from the specified organization
#
# DELETE /account/orgs/{org_id}/exportToken
# operationId: deleteAccountOrganizationExportToken
export def "delete-account-organization-export-token" [
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
    path: "/account/orgs/{org_id}/exportToken"
    path_params: [{name: org_id, var: org_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotates the organization export token and returns the updated organization
#
# PATCH /account/orgs/{org_id}/exportToken/rotate
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: rotateAccountOrganizationExportToken
export def "rotate-account-organization-export-token" [
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
    method: patch
    path: "/account/orgs/{org_id}/exportToken/rotate"
    path_params: [{name: org_id, var: org_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org_id: $org_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sites details across all organizations
#
# GET /account/sites
# Returns: table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: getAccountSites
export def "get-account-sites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/sites"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all SSO group mappings
#
# GET /account/sso/groups
# Returns: record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>
# operationId: getAccountGroupMappings
export def "get-account-group-mappings" [
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
    path: "/account/sso/groups"
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new SSO group mapping
#
# POST /account/sso/groups
# Returns: record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>
# operationId: createAccountGroupMapping
export def "create-account-group-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: int # format: int64, e.g. 1576300370
  --created-by-email: string # e.g. jsmith@example.com
  --description: string # e.g. Maps basic-attribute to Viewers Group
  group_id: string # format: uuid, e.g. 2b096711-4d28-4417-8635-64af4f62c1ae
  --group-name: string # e.g. Viewers Group
  id: string # format: uuid, e.g. f6cfb91a-52ea-4a86-bf9a-5a891a26f52b
  sso_attribute: string # e.g. basic-attribute
  sso_value: string # e.g. basic-attribute-value
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/sso/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: created_by_email, var: created_by_email}, {name: description, var: description}, {name: group_id, var: group_id}, {name: group_name, var: group_name}, {name: id, var: id}, {name: sso_attribute, var: sso_attribute}, {name: sso_value, var: sso_value}, {name: updated_at, var: updated_at}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    created_at: $created_at, created_by_email: $created_by_email, description: $description, group_id: $group_id, group_name: $group_name, id: $id, sso_attribute: $sso_attribute, sso_value: $sso_value, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing SSO group mapping
#
# PUT /account/sso/groups
# Returns: record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>
# operationId: updateAccountGroupMapping
export def "update-account-group-mapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: int # format: int64, e.g. 1576300370
  --created-by-email: string # e.g. jsmith@example.com
  --description: string # e.g. Maps basic-attribute to Viewers Group
  group_id: string # format: uuid, e.g. 2b096711-4d28-4417-8635-64af4f62c1ae
  --group-name: string # e.g. Viewers Group
  id: string # format: uuid, e.g. f6cfb91a-52ea-4a86-bf9a-5a891a26f52b
  sso_attribute: string # e.g. basic-attribute
  sso_value: string # e.g. basic-attribute-value
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/sso/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: created_by_email, var: created_by_email}, {name: description, var: description}, {name: group_id, var: group_id}, {name: group_name, var: group_name}, {name: id, var: id}, {name: sso_attribute, var: sso_attribute}, {name: sso_value, var: sso_value}, {name: updated_at, var: updated_at}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    created_at: $created_at, created_by_email: $created_by_email, description: $description, group_id: $group_id, group_name: $group_name, id: $id, sso_attribute: $sso_attribute, sso_value: $sso_value, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this SSO group mapping
#
# DELETE /account/sso/groups/{group_mapping_id}
# operationId: removeAccountGroupMapping
export def "remove-account-group-mapping" [
  group_mapping_id: string
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
    path: "/account/sso/groups/{group_mapping_id}"
    path_params: [{name: group_mapping_id, var: group_mapping_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_mapping_id: $group_mapping_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SSO group mapping details
#
# GET /account/sso/groups/{group_mapping_id}
# Returns: record<created_at: int, created_by_email: string, description: string, group_id: string, group_name: string, id: string, sso_attribute: string, sso_value: string, updated_at: int>
# operationId: getAccountGroupMapping
export def "get-account-group-mapping" [
  group_mapping_id: string
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
    path: "/account/sso/groups/{group_mapping_id}"
    path_params: [{name: group_mapping_id, var: group_mapping_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    group_mapping_id: $group_mapping_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all task details across all organizations (up to 1000)
#
# GET /account/tasks
# Returns: table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: getAccountTasks
export def "get-account-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/tasks"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all scan templates across all organizations (up to 1000)
#
# GET /account/tasks/templates
# Returns: table<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: getAccountScanTemplates
export def "get-account-scan-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/account/tasks/templates"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new scan template
#
# POST /account/tasks/templates
# Returns: record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: createAccountScanTemplate
export def "create-account-scan-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user}
  --description: string # e.g. My Scan Template
  --global: oneof<nothing, bool> # e.g. false
  name: string # e.g. My Scan Template
  --params: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/tasks/templates"
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: description, var: description}, {name: global, var: global, required: true}, {name: name, var: name}, {name: params, var: params}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    acl: $acl, description: $description, global: $global, name: $name, params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update scan template
#
# PUT /account/tasks/templates
# Returns: record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: updateAccountScanTemplate
export def "update-account-scan-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user}
  --agent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --client-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --created-at: int # format: int64, e.g. 1576300370
  --created-by: string # format: email, e.g. user@example.com
  --created-by-user-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --cruncher-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --description: string # e.g. My Scan Template
  --error: string # e.g. agent unavailable
  --global: oneof<nothing, bool> # e.g. false
  --grace-period: string # e.g. 4
  --hidden: oneof<nothing, bool> # e.g. false
  --hosted-zone-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --linked-task-count: int # format: int32, e.g. 1
  --name: string # e.g. My Scan Template
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --params: record
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur: oneof<nothing, bool> # e.g. false
  --recur-frequency: string # e.g. hour
  --recur-last: int # format: int64, e.g. 1576300370
  --recur-last-task-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur-next: int # format: int64, e.g. 1576300370
  --site-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --size-data: int # format: int64, e.g. 0
  --size-results: int # format: int64, e.g. 0
  --size-site: int # format: int64, e.g. 0
  --source-id: string # e.g. 1
  --start-time: int # format: int64, e.g. 1576300370
  --stats: record
  --status: string # e.g. processed
  --template-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --type: string # e.g. scan
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/tasks/templates"
    body: {content_type: "application/json", kind: json, fields: [{name: acl, var: acl}, {name: agent_id, var: agent_id}, {name: client_id, var: client_id}, {name: created_at, var: created_at}, {name: created_by, var: created_by}, {name: created_by_user_id, var: created_by_user_id}, {name: cruncher_id, var: cruncher_id}, {name: description, var: description}, {name: error, var: error}, {name: global, var: global, required: true}, {name: grace_period, var: grace_period}, {name: hidden, var: hidden}, {name: hosted_zone_id, var: hosted_zone_id}, {name: id, var: id}, {name: linked_task_count, var: linked_task_count}, {name: name, var: name}, {name: organization_id, var: organization_id}, {name: params, var: params}, {name: parent_id, var: parent_id}, {name: recur, var: recur}, {name: recur_frequency, var: recur_frequency}, {name: recur_last, var: recur_last}, {name: recur_last_task_id, var: recur_last_task_id}, {name: recur_next, var: recur_next}, {name: site_id, var: site_id}, {name: size_data, var: size_data}, {name: size_results, var: size_results}, {name: size_site, var: size_site}, {name: source_id, var: source_id}, {name: start_time, var: start_time}, {name: stats, var: stats}, {name: status, var: status}, {name: template_id, var: template_id}, {name: type, var: type}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    acl: $acl, agent_id: $agent_id, client_id: $client_id, created_at: $created_at, created_by: $created_by, created_by_user_id: $created_by_user_id, cruncher_id: $cruncher_id, description: $description, error: $error, global: $global, grace_period: $grace_period, hidden: $hidden, hosted_zone_id: $hosted_zone_id, id: $id, linked_task_count: $linked_task_count, name: $name, organization_id: $organization_id, params: $params, parent_id: $parent_id, recur: $recur, recur_frequency: $recur_frequency, recur_last: $recur_last, recur_last_task_id: $recur_last_task_id, recur_next: $recur_next, site_id: $site_id, size_data: $size_data, size_results: $size_results, size_site: $size_site, source_id: $source_id, start_time: $start_time, stats: $stats, status: $status, template_id: $template_id, type: $type, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove scan template
#
# DELETE /account/tasks/templates/{scan_template_id}
# Returns: record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: removeAccountScanTemplate
export def "remove-account-scan-template" [
  scan_template_id: string
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
    path: "/account/tasks/templates/{scan_template_id}"
    path_params: [{name: scan_template_id, var: scan_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scan_template_id: $scan_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scan template details
#
# GET /account/tasks/templates/{scan_template_id}
# Returns: record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: getAccountScanTemplate
export def "get-account-scan-template" [
  scan_template_id: string
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
    path: "/account/tasks/templates/{scan_template_id}"
    path_params: [{name: scan_template_id, var: scan_template_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scan_template_id: $scan_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users
#
# GET /account/users
# Returns: table<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: getAccountUsers
export def "get-account-users" [
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
    path: "/account/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user account
#
# PUT /account/users
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: createAccountUser
export def "create-account-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --org-default-role: string # e.g. admin
  --org-roles: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/users"
    body: {content_type: "application/json", kind: json, fields: [{name: client_admin, var: client_admin}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: org_default_role, var: org_default_role}, {name: org_roles, var: org_roles}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, org_default_role: $org_default_role, org_roles: $org_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user account and send an email invite
#
# PUT /account/users/invite
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: createAccountUserInvite
export def "create-account-user-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --message: string # e.g. You have been invited to the Rumble Network Discovery platform
  --org-default-role: string # e.g. admin
  --org-roles: record
  --subject: string # e.g. Welcome to Rumble
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/account/users/invite"
    body: {content_type: "application/json", kind: json, fields: [{name: client_admin, var: client_admin}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: message, var: message}, {name: org_default_role, var: org_default_role}, {name: org_roles, var: org_roles}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, message: $message, org_default_role: $org_default_role, org_roles: $org_roles, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove this user
#
# DELETE /account/users/{user_id}
# operationId: removeAccountUser
export def "remove-account-user" [
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
    path: "/account/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user details
#
# GET /account/users/{user_id}
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: getAccountUser
export def "get-account-user" [
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
    path: "/account/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user's details
#
# PATCH /account/users/{user_id}
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: updateAccountUser
export def "update-account-user" [
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
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --org-default-role: string # e.g. admin
  --org-roles: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: client_admin, var: client_admin}, {name: email, var: email}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: org_default_role, var: org_default_role}, {name: org_roles, var: org_roles}]}
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, org_default_role: $org_default_role, org_roles: $org_roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the user's lockout status
#
# PATCH /account/users/{user_id}/resetLockout
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: resetAccountUserLockout
export def "reset-account-user-lockout" [
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
    method: patch
    path: "/account/users/{user_id}/resetLockout"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the user's MFA tokens
#
# PATCH /account/users/{user_id}/resetMFA
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: resetAccountUserMFA
export def "reset-account-user-mfa" [
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
    method: patch
    path: "/account/users/{user_id}/resetMFA"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends the user a password reset email
#
# PATCH /account/users/{user_id}/resetPassword
# Returns: record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int>
# operationId: resetAccountUserPassword
export def "reset-account-user-password" [
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
    method: patch
    path: "/account/users/{user_id}/resetPassword"
    path_params: [{name: user_id, var: user_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cisco serial number and model name export for Cisco Smart Net Total Care Service.
#
# GET /export/org/assets.cisco.csv
# Returns: binary
# operationId: exportAssetsCiscoCSV
export def "export-assets-cisco-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/assets.cisco.csv"
    query: [{name: search, var: search}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Asset inventory as CSV
#
# GET /export/org/assets.csv
# Returns: binary
# operationId: exportAssetsCSV
export def "export-assets-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/assets.csv"
    query: [{name: search, var: search}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the asset inventory
#
# GET /export/org/assets.json
# Returns: table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: exportAssetsJSON
export def "export-assets-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/assets.json"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Asset inventory as JSON line-delimited
#
# GET /export/org/assets.jsonl
# Returns: binary
# operationId: exportAssetsJSONL
export def "export-assets-jsonl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/assets.jsonl"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Asset inventory as Nmap-style XML
#
# GET /export/org/assets.nmap.xml
# operationId: exportAssetsNmapXML
export def "export-assets-nmap-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/assets.nmap.xml"
    query: [{name: search, var: search}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export an asset inventory as CSV for ServiceNow integration
#
# GET /export/org/assets.servicenow.csv
# Returns: binary
# operationId: snowExportAssetsCSV
export def "snow-export-assets-csv" [
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
    path: "/export/org/assets.servicenow.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the asset inventory as JSON
#
# GET /export/org/assets.servicenow.json
# Returns: table<addresses_extra: string, addresses_scope: string, alive: bool, asset_id: string, comments: string, detected_by: string, domains: string, first_discovered: string, hw_product: string, hw_vendor: string, hw_version: string, ip_address: string, last_discovered: string, last_updated: string, lowest_rtt: int, lowest_ttl: int, mac_address: string, mac_manufacturer: string, mac_vendors: string, macs: string, name: string, newest_mac_age: string, organization: string, os_product: string, os_vendor: string, os_version: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, site: string, sys_class_name: string, tags: string, type: string>
# operationId: snowExportAssetsJSON
export def "snow-export-assets-json" [
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
    path: "/export/org/assets.servicenow.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the asset inventory in a sync-friendly manner using created_at as a checkpoint. Requires the Splunk entitlement.
#
# GET /export/org/assets/sync/created/assets.json
# Returns: record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int>
# operationId: splunkAssetSyncCreatedJSON
export def "splunk-asset-sync-created-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
  --since: int # an optional unix timestamp to use as a checkpoint (format: int64, e.g. 1576300370)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/assets/sync/created/assets.json"
    query: [{name: search, var: search}, {name: fields, var: fields}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports the asset inventory in a sync-friendly manner using updated_at as a checkpoint. Requires the Splunk entitlement.
#
# GET /export/org/assets/sync/updated/assets.json
# Returns: record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int>
# operationId: splunkAssetSyncUpdatedJSON
export def "splunk-asset-sync-updated-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
  --since: int # an optional unix timestamp to use as a checkpoint (format: int64, e.g. 1576300370)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/assets/sync/updated/assets.json"
    query: [{name: search, var: search}, {name: fields, var: fields}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service inventory as CSV
#
# GET /export/org/services.csv
# Returns: binary
# operationId: exportServicesCSV
export def "export-services-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/services.csv"
    query: [{name: search, var: search}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service inventory as JSON
#
# GET /export/org/services.json
# Returns: table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: exportServicesJSON
export def "export-services-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/services.json"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service inventory as JSON line-delimited
#
# GET /export/org/services.jsonl
# Returns: binary
# operationId: exportServicesJSONL
export def "export-services-jsonl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/services.jsonl"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export a service inventory as CSV for ServiceNow integration
#
# GET /export/org/services.servicenow.csv
# Returns: binary
# operationId: snowExportServicesCSV
export def "snow-export-services-csv" [
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
    path: "/export/org/services.servicenow.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Site list as CSV
#
# GET /export/org/sites.csv
# Returns: binary
# operationId: exportSitesCSV
export def "export-sites-csv" [
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
    path: "/export/org/sites.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export all sites
#
# GET /export/org/sites.json
# Returns: table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: exportSitesJSON
export def "export-sites-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/sites.json"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Site list as JSON line-delimited
#
# GET /export/org/sites.jsonl
# Returns: binary
# operationId: exportSitesJSONL
export def "export-sites-jsonl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/sites.jsonl"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wireless inventory as CSV
#
# GET /export/org/wireless.csv
# Returns: binary
# operationId: exportWirelessCSV
export def "export-wireless-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/wireless.csv"
    query: [{name: search, var: search}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wireless inventory as JSON
#
# GET /export/org/wireless.json
# Returns: table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>
# operationId: exportWirelessJSON
export def "export-wireless-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/export/org/wireless.json"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wireless inventory as JSON line-delimited
#
# GET /export/org/wireless.jsonl
# Returns: binary
# operationId: exportWirelessJSONL
export def "export-wireless-jsonl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --fields: string # an optional list of fields to export, comma-separated
]: nothing -> any {
  http-request {
    method: get
    path: "/export/org/wireless.jsonl"
    query: [{name: search, var: search}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization details
#
# GET /org
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: getOrganization
export def "get-organization" [
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
    path: "/org"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization details
#
# PATCH /org
# Returns: record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int>
# operationId: updateOrganization
export def "update-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: expiration_assets_offline, var: expiration_assets_offline}, {name: expiration_assets_stale, var: expiration_assets_stale}, {name: expiration_scans, var: expiration_scans}, {name: export_token, var: export_token}, {name: name, var: name}, {name: parent_id, var: parent_id}, {name: project, var: project}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all agents
#
# GET /org/agents
# Returns: table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>
# operationId: getAgents
export def "get-agents" [
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
    path: "/org/agents"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove and uninstall an agent
#
# DELETE /org/agents/{agent_id}
# operationId: removeAgent
export def "remove-agent" [
  agent_id: string
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
    path: "/org/agents/{agent_id}"
    path_params: [{name: agent_id, var: agent_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details for a single agent
#
# GET /org/agents/{agent_id}
# Returns: record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>
# operationId: getAgent
export def "get-agent" [
  agent_id: string
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
    path: "/org/agents/{agent_id}"
    path_params: [{name: agent_id, var: agent_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the site associated with agent
#
# PATCH /org/agents/{agent_id}
# Returns: record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string>
# operationId: updateAgentSite
export def "update-agent-site" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  site_id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org/agents/{agent_id}"
    path_params: [{name: agent_id, var: agent_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: site_id, var: site_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    agent_id: $agent_id, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Force an agent to update and restart
#
# POST /org/agents/{agent_id}/update
# operationId: upgradeAgent
export def "upgrade-agent" [
  agent_id: string
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
    path: "/org/agents/{agent_id}/update"
    path_params: [{name: agent_id, var: agent_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    agent_id: $agent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all assets
#
# GET /org/assets
# Returns: table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: getAssets
export def "get-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/org/assets"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear all tags across multiple assets based on a search query
#
# POST /org/assets/bulk/clearTags
# operationId: clearBulkAssetTags
export def "clear-bulk-asset-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # e.g. alive:true and os:windows
]: any -> any {
  $in | http-request {
    method: post
    path: "/org/assets/bulk/clearTags"
    body: {content_type: "application/json", kind: json, fields: [{name: search, var: search}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update tags across multiple assets based on a search query
#
# PATCH /org/assets/bulk/tags
# operationId: updateBulkAssetTags
export def "update-bulk-asset-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # e.g. alive:true and os:windows
  tags: string # e.g. ThisTag=Value -OldTag
]: any -> any {
  $in | http-request {
    method: patch
    path: "/org/assets/bulk/tags"
    body: {content_type: "application/json", kind: json, fields: [{name: search, var: search}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top asset hardware products as CSV
#
# GET /org/assets/top.hw.csv
# Returns: binary
# operationId: exportAssetTopHWCSV
export def "export-asset-top-hwcsv" [
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
    path: "/org/assets/top.hw.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top asset operating systems as CSV
#
# GET /org/assets/top.os.csv
# Returns: binary
# operationId: exportAssetTopOSCSV
export def "export-asset-top-oscsv" [
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
    path: "/org/assets/top.os.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top asset tags as CSV
#
# GET /org/assets/top.tags.csv
# Returns: binary
# operationId: exportAssetTopTagsCSV
export def "export-asset-top-tags-csv" [
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
    path: "/org/assets/top.tags.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top asset types as CSV
#
# GET /org/assets/top.types.csv
# Returns: binary
# operationId: exportAssetTopTypesCSV
export def "export-asset-top-types-csv" [
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
    path: "/org/assets/top.types.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an asset
#
# DELETE /org/assets/{asset_id}
# operationId: removeAsset
export def "remove-asset" [
  asset_id: string
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
    path: "/org/assets/{asset_id}"
    path_params: [{name: asset_id, var: asset_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get asset details
#
# GET /org/assets/{asset_id}
# Returns: record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: getAsset
export def "get-asset" [
  asset_id: string
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
    path: "/org/assets/{asset_id}"
    path_params: [{name: asset_id, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update asset comments
#
# PATCH /org/assets/{asset_id}/comments
# Returns: record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: updateAssetComments
export def "update-asset-comments" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  comments: string # e.g. Sales Laptop
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org/assets/{asset_id}/comments"
    path_params: [{name: asset_id, var: asset_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, comments: $comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update asset tags
#
# PATCH /org/assets/{asset_id}/tags
# Returns: record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: updateAssetTags
export def "update-asset-tags" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tags: string # e.g. ThisTag=Value -OldTag
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org/assets/{asset_id}/tags"
    path_params: [{name: asset_id, var: asset_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the current API key
#
# DELETE /org/key
# operationId: removeKey
export def "remove-key" [
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
    path: "/org/key"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get API key details
#
# GET /org/key
# Returns: record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: getKey
export def "get-key" [
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
    path: "/org/key"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotate the API key secret and return the updated key
#
# PATCH /org/key/rotate
# Returns: record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int>
# operationId: rotateKey
export def "rotate-key" [
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
    method: patch
    path: "/org/key/rotate"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all services
#
# GET /org/services
# Returns: table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: getServices
export def "get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/org/services"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subnet utilization statistics as as CSV
#
# GET /org/services/subnet.stats.csv
# Returns: binary
# operationId: exportSubnetUtilizationStatsCSV
export def "export-subnet-utilization-stats-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: string # an optional subnet mask size (ex:24)
]: nothing -> any {
  http-request {
    method: get
    path: "/org/services/subnet.stats.csv"
    query: [{name: mask, var: mask}]
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    mask: $mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top service products as CSV
#
# GET /org/services/top.products.csv
# Returns: binary
# operationId: exportServicesTopProductsCSV
export def "export-services-top-products-csv" [
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
    path: "/org/services/top.products.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top service protocols as CSV
#
# GET /org/services/top.protocols.csv
# Returns: binary
# operationId: exportServicesTopProtocolsCSV
export def "export-services-top-protocols-csv" [
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
    path: "/org/services/top.protocols.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top TCP services as CSV
#
# GET /org/services/top.tcp.csv
# Returns: binary
# operationId: exportServicesTopTCPCSV
export def "export-services-top-tcpcsv" [
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
    path: "/org/services/top.tcp.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top UDP services as CSV
#
# GET /org/services/top.udp.csv
# Returns: binary
# operationId: exportServicesTopUDPCSV
export def "export-services-top-udpcsv" [
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
    path: "/org/services/top.udp.csv"
    accept: ["text/csv"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a service
#
# DELETE /org/services/{service_id}
# operationId: removeService
export def "remove-service" [
  service_id: string
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
    path: "/org/services/{service_id}"
    path_params: [{name: service_id, var: service_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service details
#
# GET /org/services/{service_id}
# Returns: record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>
# operationId: getService
export def "get-service" [
  service_id: string
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
    path: "/org/services/{service_id}"
    path_params: [{name: service_id, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sites
#
# GET /org/sites
# Returns: table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: getSites
export def "get-sites" [
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
    path: "/org/sites"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new site
#
# PUT /org/sites
# Returns: record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: createSite
export def "create-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. County Office
  --excludes: string # e.g. 192.168.10.1
  name: string # e.g. New Site
  --scope: string # e.g. 192.168.10.0/24
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/sites"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: excludes, var: excludes}, {name: name, var: name}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, excludes: $excludes, name: $name, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a site and associated assets
#
# DELETE /org/sites/{site_id}
# operationId: removeSite
export def "remove-site" [
  site_id: string
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
    path: "/org/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get site details
#
# GET /org/sites/{site_id}
# Returns: record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: getSite
export def "get-site" [
  site_id: string
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
    path: "/org/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a site definition
#
# PATCH /org/sites/{site_id}
# Returns: record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int>
# operationId: updateSite
export def "update-site" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. County Office
  --excludes: string # e.g. 192.168.10.1
  name: string # e.g. New Site
  --scope: string # e.g. 192.168.10.0/24
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org/sites/{site_id}"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: excludes, var: excludes}, {name: name, var: name}, {name: scope, var: scope}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, description: $description, excludes: $excludes, name: $name, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a scan data file into a site
#
# PUT /org/sites/{site_id}/import
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: importScanData
export def "import-scan-data" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/sites/{site_id}/import"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a Nessus scan data file into a site
#
# PUT /org/sites/{site_id}/import/nessus
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: importNessusScanData
export def "import-nessus-scan-data" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/sites/{site_id}/import/nessus"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a scan task for a given site
#
# PUT /org/sites/{site_id}/scan
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: createScan
export def "create-scan" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/org/sites/{site_id}/scan"
    path_params: [{name: site_id, var: site_id}]
    body: {content_type: "text/json", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    site_id: $site_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tasks (last 1000)
#
# GET /org/tasks
# Returns: table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: getTasks
export def "get-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # an optional status string for filtering results
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/org/tasks"
    query: [{name: status, var: status}, {name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task details
#
# GET /org/tasks/{task_id}
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: getTask
export def "get-task" [
  task_id: string
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
    path: "/org/tasks/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update task parameters
#
# PATCH /org/tasks/{task_id}
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: updateTask
export def "update-task" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --client-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --created-at: int # format: int64, e.g. 1576300370
  --created-by: string # format: email, e.g. user@example.com
  --created-by-user-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --cruncher-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --description: string # e.g. Scan the headquarters hourly
  --error: string # e.g. agent unavailable
  --hidden: oneof<nothing, bool> # e.g. false
  id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --name: string # e.g. Hourly Scan
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --params: record
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur: oneof<nothing, bool> # e.g. false
  --recur-frequency: string # e.g. hour
  --recur-last: int # format: int64, e.g. 1576300370
  --recur-last-task-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur-next: int # format: int64, e.g. 1576300370
  --site-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --start-time: int # format: int64, e.g. 1576300370
  --stats: record
  --status: string # e.g. processed
  --template-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --type: string # e.g. scan
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/org/tasks/{task_id}"
    path_params: [{name: task_id, var: task_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: agent_id, var: agent_id}, {name: client_id, var: client_id}, {name: created_at, var: created_at}, {name: created_by, var: created_by}, {name: created_by_user_id, var: created_by_user_id}, {name: cruncher_id, var: cruncher_id}, {name: description, var: description}, {name: error, var: error}, {name: hidden, var: hidden}, {name: id, var: id}, {name: name, var: name}, {name: organization_id, var: organization_id}, {name: params, var: params}, {name: parent_id, var: parent_id}, {name: recur, var: recur}, {name: recur_frequency, var: recur_frequency}, {name: recur_last, var: recur_last}, {name: recur_last_task_id, var: recur_last_task_id}, {name: recur_next, var: recur_next}, {name: site_id, var: site_id}, {name: start_time, var: start_time}, {name: stats, var: stats}, {name: status, var: status}, {name: template_id, var: template_id}, {name: type, var: type}, {name: updated_at, var: updated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, agent_id: $agent_id, client_id: $client_id, created_at: $created_at, created_by: $created_by, created_by_user_id: $created_by_user_id, cruncher_id: $cruncher_id, description: $description, error: $error, hidden: $hidden, id: $id, name: $name, organization_id: $organization_id, params: $params, parent_id: $parent_id, recur: $recur, recur_frequency: $recur_frequency, recur_last: $recur_last, recur_last_task_id: $recur_last_task_id, recur_next: $recur_next, site_id: $site_id, start_time: $start_time, stats: $stats, status: $status, template_id: $template_id, type: $type, updated_at: $updated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a temporary task change report data url
#
# GET /org/tasks/{task_id}/changes
# Returns: record<id: string>
# operationId: getTaskChangeReport
export def "get-task-change-report" [
  task_id: string
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
    path: "/org/tasks/{task_id}/changes"
    path_params: [{name: task_id, var: task_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a temporary task scan data url
#
# GET /org/tasks/{task_id}/data
# Returns: record<id: string>
# operationId: getTaskScanData
export def "get-task-scan-data" [
  task_id: string
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
    path: "/org/tasks/{task_id}/data"
    path_params: [{name: task_id, var: task_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Signal that a completed task should be hidden
#
# POST /org/tasks/{task_id}/hide
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: hideTask
export def "hide-task" [
  task_id: string
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
    path: "/org/tasks/{task_id}/hide"
    path_params: [{name: task_id, var: task_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a temporary task log data url
#
# GET /org/tasks/{task_id}/log
# Returns: record<id: string>
# operationId: getTaskLog
export def "get-task-log" [
  task_id: string
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
    path: "/org/tasks/{task_id}/log"
    path_params: [{name: task_id, var: task_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Signal that a task should be stopped or canceledThis will also remove recurring and scheduled tasks
#
# POST /org/tasks/{task_id}/stop
# Returns: record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int>
# operationId: stopTask
export def "stop-task" [
  task_id: string
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
    path: "/org/tasks/{task_id}/stop"
    path_params: [{name: task_id, var: task_id}]
    accept: ["*/*"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all wireless LANs
#
# GET /org/wireless
# Returns: table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>
# operationId: getWirelessLANs
export def "get-wireless-la-ns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/org/wireless"
    query: [{name: search, var: search}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a wireless LAN
#
# DELETE /org/wireless/{wireless_id}
# operationId: removeWirelessLAN
export def "remove-wireless-lan" [
  wireless_id: string
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
    path: "/org/wireless/{wireless_id}"
    path_params: [{name: wireless_id, var: wireless_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    wireless_id: $wireless_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get wireless LAN details
#
# GET /org/wireless/{wireless_id}
# Returns: record<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string>
# operationId: getWirelessLAN
export def "get-wireless-lan" [
  wireless_id: string
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
    path: "/org/wireless/{wireless_id}"
    path_params: [{name: wireless_id, var: wireless_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wireless_id: $wireless_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns latest agent version
#
# GET /releases/agent/version
# Returns: record<id: string, version: string>
# operationId: getLatestAgentVersion
export def "get-latest-agent-version" [
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
    path: "/releases/agent/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns latest platform version
#
# GET /releases/platform/version
# Returns: record<id: string, version: string>
# operationId: getLatestPlatformVersion
export def "get-latest-platform-version" [
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
    path: "/releases/platform/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns latest scanner version
#
# GET /releases/scanner/version
# Returns: record<id: string, version: string>
# operationId: getLatestScannerVersion
export def "get-latest-scanner-version" [
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
    path: "/releases/scanner/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
