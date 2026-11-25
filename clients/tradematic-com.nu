# Auto-generated client for Tradematic Cloud API v1.0.2
# Source: https://api.apis.guru/v2/specs/tradematic.com/1.0.2/swagger.json
# Auth: --token flag or $env.TRADEMATIC_CLOUD_API_TOKEN

const CLIENT = {
  base_url: "https://api.tradematic.com"
  token_env_var: "TRADEMATIC_CLOUD_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: X-API-Key, prefix: ""}
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

def base-url-completer [] { ["https://api.tradematic.com"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-autofollow-strategies: "table<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list, longexit: list>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string>"
    post-autofollow-strategies: "record<strategyid: int>"
    get-autofollow-strategies-strategyid: "record<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list<record>, longexit: list<record>>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string>"
    put-autofollow-strategies-strategyid: "record<result: string>"
    put-autofollow-strategies-strategyid-content: "record<strategyid: string>"
    get-autofollow-strategies-strategyid-positions: "table<date: string, price: string, size: string, symbol: string>"
    get-autofollow-strategies-strategyid-signals: "table<position: string, price: string, shares: string, signalid: string, size: string, symbol: string, timestamp: string, type: string>"
    post-autofollow-strategies-strategyid-signals: "record<signalid: string>"
    get-builder-rules: "table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string>"
    get-builder-rules-ruleid: "table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string>"
    get-client-apikeys: "table<key: string, keyid: string, permissions: string>"
    post-client-apikeys: "record<key: string, keyid: int>"
    delete-client-apikeys-keyid: "record<keyid: int>"
    get-client-users: "table<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string>"
    post-client-users-login: "record<name: string, userid: int>"
    post-client-users-register: "record<userid: int>"
    get-client-users-userid: "record<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string>"
    get-cloud-accounts: "table<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string>"
    get-cloud-accounts-accountid: "record<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string>"
    post-cloud-accounts-accountid-closeall: "record<commandid: int>"
    get-cloud-accounts-accountid-orders: "table<account: string, buy: string, message: string, number: string, orderid: string, price: string, shares: string, status: string, statusname: string, symbol: string, timestamp: string>"
    post-cloud-accounts-accountid-orders: "record<commandid: int>"
    delete-cloud-accounts-accountid-orders-orderid: "record<commandid: int>"
    get-cloud-accounts-accountid-snapshots: "table<cash: string, daynum: string, snapshotid: string, timestamp: string, value: string>"
    post-cloud-accounts-accountid-sync: "record<commandid: int>"
    get-cloud-accounts-accountid-trades: "table<account: string, buy: string, number: string, price: string, shares: string, symbol: string, timestamp: string, tradeid: string>"
    get-cloud-commands: "table<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string>"
    get-cloud-commands-commandid: "record<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string>"
    get-cloud-connections: "table<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string>"
    post-cloud-connections: "record<connectionid: int>"
    delete-cloud-connections-connectionid: "record<connectionid: int>"
    get-cloud-connections-connectionid: "record<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string>"
    put-cloud-connections-connectionid: "record<connectionid: int>"
    get-cloud-connectors: "table<code: string, connectorid: string, connectortypename: string, name: string, typeid: string>"
    get-cloud-connectors-connectorid: "record<code: string, connectorid: string, connectortypename: string, name: string, typeid: string>"
    get-cloud-sessions: "table<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string>"
    get-cloud-sessions-sessionid: "record<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string>"
    get-cloud-strategies: "table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string>"
    post-cloud-strategies-start: "record<commandid: int>"
    get-cloud-strategies-strategyid: "table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string>"
    post-cloud-strategies-strategyid-stop: "record<commandid: int>"
    get-marketdata-markets: "table<code: string, countryid: string, marketid: string, name: string>"
    get-marketdata-markets-marketid: "record<code: string, countryid: string, marketid: string, name: string>"
    get-marketdata-symbols: "list<string>"
    get-marketdata-symbols-symbolid: "string"
    get-marketdata-symbols-symbolid-histdata: "record<adjusted: bool, queryCount: int, results: table<c: float, h: float, l: float, n: int, o: float, t: int, v: int>, resultsCount: int, status: string, ticker: string>"
    get-news-news: "table<body: string, newsid: string, source: string, timestamp: string, title: string>"
    get-news-news-newsid: "record<body: string, newsid: string, source: string, timestamp: string, title: string>"
    get-ping: "record"
    get-taskmanager-tasks: "table<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string>"
    post-taskmanager-tasks: "record<taskid: string>"
    get-taskmanager-tasks-taskid: "record<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string>"
    get-taskmanager-tasks-taskid-bymonths: "table<equitypct: string, period: string>"
    get-taskmanager-tasks-taskid-byquarters: "table<equitypct: string, period: string>"
    get-taskmanager-tasks-taskid-byyears: "table<equitypct: string, period: string>"
    get-taskmanager-tasks-taskid-contribution: "table<pandl: string, share: string, symbol: string>"
    get-taskmanager-tasks-taskid-drawdown: "table<drawdownpct: string, timestamp: string>"
    get-taskmanager-tasks-taskid-equity: "table<cash: string, equity: string, timestamp: string>"
    get-taskmanager-tasks-taskid-equitypct: "table<buyandhold: string, equity: string, timestamp: string>"
    get-taskmanager-tasks-taskid-equitypctsm: "table<buyandhold: string, equity: string, timestamp: string>"
    get-taskmanager-tasks-taskid-folder: "record<folder: string>"
    get-taskmanager-tasks-taskid-performance: "record<buyandhold: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, long: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, longshort: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, short: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>>"
    get-taskmanager-tasks-taskid-result: "record<bymonths_csv: string, bymonths_png: string, byquarters_csv: string, byquarters_png: string, byyears_csv: string, byyears_png: string, contribution_csv: string, contribution_png: string, drawdown_csv: string, drawdown_png: string, equity_csv: string, equity_png: string, equitypct_csv: string, equitypct_png: string, equitypctnofill_csv: string, equitypctnofill_png: string, equitypctsm: string, equitypctsm_csv: string, equitypctsm_png: string, performance_csv: string, performance_png: string, trades_csv: string, trades_png: string>"
    get-taskmanager-tasks-taskid-result2: "record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>"
    get-taskmanager-tasks-taskid-status: "record<status: string>"
    get-taskmanager-tasks-taskid-trades: "table<barsheld: string, changepct: string, commission: string, entrydatetime: string, entryprice: string, entrysignal: string, exitdatetime: string, exitprice: string, exitsignal: string, mae: string, mfe: string, pandl: string, position: string, shares: string, size: string, symbol: string>"
    get-time: "record<servertime: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-autofollow-strategies" "post-autofollow-strategies" "get-autofollow-strategies-strategyid" "put-autofollow-strategies-strategyid" "put-autofollow-strategies-strategyid-content" "get-autofollow-strategies-strategyid-positions" "get-autofollow-strategies-strategyid-signals" "post-autofollow-strategies-strategyid-signals" "get-builder-rules" "get-builder-rules-ruleid" "get-client-apikeys" "post-client-apikeys" "delete-client-apikeys-keyid" "get-client-users" "post-client-users-login" "post-client-users-register" "get-client-users-userid" "get-cloud-accounts" "get-cloud-accounts-accountid" "post-cloud-accounts-accountid-closeall" "get-cloud-accounts-accountid-orders" "post-cloud-accounts-accountid-orders" "delete-cloud-accounts-accountid-orders-orderid" "get-cloud-accounts-accountid-snapshots" "post-cloud-accounts-accountid-sync" "get-cloud-accounts-accountid-trades" "get-cloud-commands" "get-cloud-commands-commandid" "get-cloud-connections" "post-cloud-connections" "delete-cloud-connections-connectionid" "get-cloud-connections-connectionid" "put-cloud-connections-connectionid" "get-cloud-connectors" "get-cloud-connectors-connectorid" "get-cloud-sessions" "get-cloud-sessions-sessionid" "get-cloud-strategies" "post-cloud-strategies-start" "get-cloud-strategies-strategyid" "post-cloud-strategies-strategyid-stop" "get-marketdata-markets" "get-marketdata-markets-marketid" "get-marketdata-symbols" "get-marketdata-symbols-symbolid" "get-marketdata-symbols-symbolid-histdata" "get-news-news" "get-news-news-newsid" "get-ping" "get-taskmanager-tasks" "post-taskmanager-tasks" "get-taskmanager-tasks-taskid" "get-taskmanager-tasks-taskid-bymonths" "get-taskmanager-tasks-taskid-byquarters" "get-taskmanager-tasks-taskid-byyears" "get-taskmanager-tasks-taskid-contribution" "get-taskmanager-tasks-taskid-drawdown" "get-taskmanager-tasks-taskid-equity" "get-taskmanager-tasks-taskid-equitypct" "get-taskmanager-tasks-taskid-equitypctsm" "get-taskmanager-tasks-taskid-folder" "get-taskmanager-tasks-taskid-performance" "get-taskmanager-tasks-taskid-result" "get-taskmanager-tasks-taskid-result2" "get-taskmanager-tasks-taskid-status" "get-taskmanager-tasks-taskid-trades" "get-time" "commands"] | sort) } | get name | first)
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

# Get autofollow strategies list
#
# GET /autofollow/strategies
# Returns: table<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list, longexit: list>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string>
export def "get-autofollow-strategies" [
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
    path: "/autofollow/strategies"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new autofollow strategy
#
# POST /autofollow/strategies
# Returns: record<strategyid: int>
export def "post-autofollow-strategies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {apr?: string, author?: string, content?: string, description?: string, drawdown?: string, guid?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, positionsize?: string, strategytypeid?: string, symbols?: string, timeframe?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/autofollow/strategies"
    body: {content_type: "application/json", kind: json, fields: [{name: strategy, var: strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategy: $strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get autofollow strategy by ID
#
# GET /autofollow/strategies/{strategyid}
# Returns: record<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list<record>, longexit: list<record>>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string>
export def "get-autofollow-strategies-strategyid" [
  strategyid: int
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
    path: "/autofollow/strategies/{strategyid}"
    path_params: [{name: strategyid, var: strategyid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update autofollow strategy
#
# PUT /autofollow/strategies/{strategyid}
# Returns: record<result: string>
export def "put-autofollow-strategies-strategyid" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {author?: string, description?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, symbols?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/autofollow/strategies/{strategyid}"
    path_params: [{name: strategyid, var: strategyid}]
    body: {content_type: "application/json", kind: json, fields: [{name: strategy, var: strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid, strategy: $strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update rules for strategy that was created with strategy builder
#
# PUT /autofollow/strategies/{strategyid}/content
# Returns: record<strategyid: string>
export def "put-autofollow-strategies-strategyid-content" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {rules?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/autofollow/strategies/{strategyid}/content"
    path_params: [{name: strategyid, var: strategyid}]
    body: {content_type: "application/json", kind: json, fields: [{name: strategy, var: strategy}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid, strategy: $strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get positions for strategy
#
# GET /autofollow/strategies/{strategyid}/positions
# Returns: table<date: string, price: string, size: string, symbol: string>
export def "get-autofollow-strategies-strategyid-positions" [
  strategyid: int
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
    path: "/autofollow/strategies/{strategyid}/positions"
    path_params: [{name: strategyid, var: strategyid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trading signals for strategy
#
# GET /autofollow/strategies/{strategyid}/signals
# Returns: table<position: string, price: string, shares: string, signalid: string, size: string, symbol: string, timestamp: string, type: string>
export def "get-autofollow-strategies-strategyid-signals" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # required, format: int64
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/autofollow/strategies/{strategyid}/signals"
    path_params: [{name: strategyid, var: strategyid}]
    query: [{name: count, var: count, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a new signal for autofollow strategy
#
# POST /autofollow/strategies/{strategyid}/signals
# Returns: record<signalid: string>
export def "post-autofollow-strategies-strategyid-signals" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --signal: record # shape: {position?: string, price?: string, shares?: string, size?: string, symbol?: string, timestamp?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/autofollow/strategies/{strategyid}/signals"
    path_params: [{name: strategyid, var: strategyid}]
    body: {content_type: "application/json", kind: json, fields: [{name: signal, var: signal}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid, signal: $signal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get strategy builder rules list
#
# GET /builder/rules
# Returns: table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string>
export def "get-builder-rules" [
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
    path: "/builder/rules"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get strategy builder rules by ID
#
# GET /builder/rules/{ruleid}
# Returns: table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string>
export def "get-builder-rules-ruleid" [
  ruleid: int
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
    path: "/builder/rules/{ruleid}"
    path_params: [{name: ruleid, var: ruleid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ruleid: $ruleid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get API keys
#
# GET /client/apikeys
# Returns: table<key: string, keyid: string, permissions: string>
export def "get-client-apikeys" [
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
    path: "/client/apikeys"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new API key
#
# POST /client/apikeys
# Returns: record<key: string, keyid: int>
export def "post-client-apikeys" [
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
    path: "/client/apikeys"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete API key
#
# DELETE /client/apikeys/{keyid}
# Returns: record<keyid: int>
export def "delete-client-apikeys-keyid" [
  keyid: int
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
    path: "/client/apikeys/{keyid}"
    path_params: [{name: keyid, var: keyid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    keyid: $keyid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users list
#
# GET /client/users
# Returns: table<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string>
export def "get-client-users" [
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
    path: "/client/users"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs user into the system
#
# POST /client/users/login
# Returns: record<name: string, userid: int>
export def "post-client-users-login" [
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
    path: "/client/users/login"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a new user
#
# POST /client/users/register
# Returns: record<userid: int>
export def "post-client-users-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # shape: {name?: string, password?: string, username?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/client/users/register"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user by ID
#
# GET /client/users/{userid}
# Returns: record<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string>
export def "get-client-users-userid" [
  userid: int
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
    path: "/client/users/{userid}"
    path_params: [{name: userid, var: userid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    userid: $userid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trading accounts list
#
# GET /cloud/accounts
# Returns: table<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string>
export def "get-cloud-accounts" [
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
    path: "/cloud/accounts"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trading account by ID
#
# GET /cloud/accounts/{accountid}
# Returns: record<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string>
export def "get-cloud-accounts-accountid" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close all positions by account
#
# POST /cloud/accounts/{accountid}/closeall
# Returns: record<commandid: int>
export def "post-cloud-accounts-accountid-closeall" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}/closeall"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get orders list by account
#
# GET /cloud/accounts/{accountid}/orders
# Returns: table<account: string, buy: string, message: string, number: string, orderid: string, price: string, shares: string, status: string, statusname: string, symbol: string, timestamp: string>
export def "get-cloud-accounts-accountid-orders" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}/orders"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Place a new order
#
# POST /cloud/accounts/{accountid}/orders
# Returns: record<commandid: int>
export def "post-cloud-accounts-accountid-orders" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: record # shape: {buy?: string, price?: string, shares?: string, symbol?: string, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cloud/accounts/{accountid}/orders"
    path_params: [{name: accountid, var: accountid}]
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    accountid: $accountid, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an order by ID
#
# DELETE /cloud/accounts/{accountid}/orders/{orderid}
# Returns: record<commandid: int>
export def "delete-cloud-accounts-accountid-orders-orderid" [
  accountid: int
  orderid: int
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
    path: "/cloud/accounts/{accountid}/orders/{orderid}"
    path_params: [{name: accountid, var: accountid}, {name: orderid, var: orderid}]
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    accountid: $accountid, orderid: $orderid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get account equity and cash snapshots
#
# GET /cloud/accounts/{accountid}/snapshots
# Returns: table<cash: string, daynum: string, snapshotid: string, timestamp: string, value: string>
export def "get-cloud-accounts-accountid-snapshots" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}/snapshots"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Syhchronize an account with account active strategies
#
# POST /cloud/accounts/{accountid}/sync
# Returns: record<commandid: int>
export def "post-cloud-accounts-accountid-sync" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}/sync"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trades list by account
#
# GET /cloud/accounts/{accountid}/trades
# Returns: table<account: string, buy: string, number: string, price: string, shares: string, symbol: string, timestamp: string, tradeid: string>
export def "get-cloud-accounts-accountid-trades" [
  accountid: int
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
    path: "/cloud/accounts/{accountid}/trades"
    path_params: [{name: accountid, var: accountid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    accountid: $accountid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get commands list
#
# GET /cloud/commands
# Returns: table<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string>
export def "get-cloud-commands" [
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
    path: "/cloud/commands"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get command by ID
#
# GET /cloud/commands/{commandid}
# Returns: record<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string>
export def "get-cloud-commands-commandid" [
  commandid: int
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
    path: "/cloud/commands/{commandid}"
    path_params: [{name: commandid, var: commandid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    commandid: $commandid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connections list
#
# GET /cloud/connections
# Returns: table<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string>
export def "get-cloud-connections" [
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
    path: "/cloud/connections"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new connection
#
# POST /cloud/connections
# Returns: record<connectionid: int>
export def "post-cloud-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record # shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cloud/connections"
    body: {content_type: "application/json", kind: json, fields: [{name: connection, var: connection}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    connection: $connection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete connection by ID
#
# DELETE /cloud/connections/{connectionid}
# Returns: record<connectionid: int>
export def "delete-cloud-connections-connectionid" [
  connectionid: int
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
    path: "/cloud/connections/{connectionid}"
    path_params: [{name: connectionid, var: connectionid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    connectionid: $connectionid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connection by ID
#
# GET /cloud/connections/{connectionid}
# Returns: record<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string>
export def "get-cloud-connections-connectionid" [
  connectionid: int
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
    path: "/cloud/connections/{connectionid}"
    path_params: [{name: connectionid, var: connectionid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    connectionid: $connectionid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing connection
#
# PUT /cloud/connections/{connectionid}
# Returns: record<connectionid: int>
export def "put-cloud-connections-connectionid" [
  connectionid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record # shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/cloud/connections/{connectionid}"
    path_params: [{name: connectionid, var: connectionid}]
    body: {content_type: "application/json", kind: json, fields: [{name: connection, var: connection}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    connectionid: $connectionid, connection: $connection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get available connectors list
#
# GET /cloud/connectors
# Returns: table<code: string, connectorid: string, connectortypename: string, name: string, typeid: string>
export def "get-cloud-connectors" [
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
    path: "/cloud/connectors"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get connector by ID
#
# GET /cloud/connectors/{connectorid}
# Returns: record<code: string, connectorid: string, connectortypename: string, name: string, typeid: string>
export def "get-cloud-connectors-connectorid" [
  connectorid: int
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
    path: "/cloud/connectors/{connectorid}"
    path_params: [{name: connectorid, var: connectorid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    connectorid: $connectorid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sessions list
#
# GET /cloud/sessions
# Returns: table<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string>
export def "get-cloud-sessions" [
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
    path: "/cloud/sessions"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get session by ID
#
# GET /cloud/sessions/{sessionid}
# Returns: record<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string>
export def "get-cloud-sessions-sessionid" [
  sessionid: int
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
    path: "/cloud/sessions/{sessionid}"
    path_params: [{name: sessionid, var: sessionid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    sessionid: $sessionid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of active (executing) strategies
#
# GET /cloud/strategies
# Returns: table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string>
export def "get-cloud-strategies" [
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
    path: "/cloud/strategies"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a strategy execution for account
#
# POST /cloud/strategies/start
# Returns: record<commandid: int>
export def "post-cloud-strategies-start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # shape: {accountid?: string, strategyid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cloud/strategies/start"
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get active (executing) strategy by ID
#
# GET /cloud/strategies/{strategyid}
# Returns: table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string>
export def "get-cloud-strategies-strategyid" [
  strategyid: int
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
    path: "/cloud/strategies/{strategyid}"
    path_params: [{name: strategyid, var: strategyid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    strategyid: $strategyid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a strategy execution by ID
#
# POST /cloud/strategies/{strategyid}/stop
# Returns: record<commandid: int>
export def "post-cloud-strategies-strategyid-stop" [
  strategyid: int
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
    path: "/cloud/strategies/{strategyid}/stop"
    path_params: [{name: strategyid, var: strategyid}]
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    strategyid: $strategyid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get markets list
#
# GET /marketdata/markets
# Returns: table<code: string, countryid: string, marketid: string, name: string>
export def "get-marketdata-markets" [
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
    path: "/marketdata/markets"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get market by ID
#
# GET /marketdata/markets/{marketid}
# Returns: record<code: string, countryid: string, marketid: string, name: string>
export def "get-marketdata-markets-marketid" [
  marketid: int
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
    path: "/marketdata/markets/{marketid}"
    path_params: [{name: marketid, var: marketid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    marketid: $marketid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get symbols list
#
# GET /marketdata/symbols
# Returns: list<string>
export def "get-marketdata-symbols" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketid: int # required, format: int64
  --filter: int # required, format: int64
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/marketdata/symbols"
    query: [{name: marketid, var: marketid, required: true}, {name: filter, var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    marketid: $marketid, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get symbol by ID
#
# GET /marketdata/symbols/{symbolid}
# Returns: string
export def "get-marketdata-symbols-symbolid" [
  symbolid: int
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
    path: "/marketdata/symbols/{symbolid}"
    path_params: [{name: symbolid, var: symbolid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    symbolid: $symbolid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get historical data for instrument
#
# GET /marketdata/symbols/{symbolid}/histdata
# Returns: record<adjusted: bool, queryCount: int, results: table<c: float, h: float, l: float, n: int, o: float, t: int, v: int>, resultsCount: int, status: string, ticker: string>
export def "get-marketdata-symbols-symbolid-histdata" [
  symbolid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tf: int # required, format: int64
  --from: int # required, format: int64
  --to: int # required, format: int64
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketdata/symbols/{symbolid}/histdata"
    path_params: [{name: symbolid, var: symbolid}]
    query: [{name: tf, var: tf, required: true}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    symbolid: $symbolid, tf: $tf, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get news list
#
# GET /news/news
# Returns: table<body: string, newsid: string, source: string, timestamp: string, title: string>
export def "get-news-news" [
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
    path: "/news/news"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get news by ID
#
# GET /news/news/{newsid}
# Returns: record<body: string, newsid: string, source: string, timestamp: string, title: string>
export def "get-news-news-newsid" [
  newsid: int
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
    path: "/news/news/{newsid}"
    path_params: [{name: newsid, var: newsid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    newsid: $newsid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping
#
# GET /ping
# Returns: record
export def "get-ping" [
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
    path: "/ping"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks list
#
# GET /taskmanager/tasks
# Returns: table<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string>
export def "get-taskmanager-tasks" [
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
    path: "/taskmanager/tasks"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new task
#
# POST /taskmanager/tasks
# Returns: record<taskid: string>
export def "post-taskmanager-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: record # shape: {isbenchmark?: string, strategyid?: string, tasktypeid?: string, userid2?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/taskmanager/tasks"
    body: {content_type: "application/json", kind: json, fields: [{name: task, var: task}]}
    accept: ["application/json"]
    ok: [202]
    auth: x-api-key
  } {
    task: $task
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task by ID
#
# GET /taskmanager/tasks/{taskid}
# Returns: record<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string>
export def "get-taskmanager-tasks-taskid" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest data for equity chart, grouped by months
#
# GET /taskmanager/tasks/{taskid}/bymonths
# Returns: table<equitypct: string, period: string>
export def "get-taskmanager-tasks-taskid-bymonths" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/bymonths"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest data for equity chart, grouped by quarters
#
# GET /taskmanager/tasks/{taskid}/byquarters
# Returns: table<equitypct: string, period: string>
export def "get-taskmanager-tasks-taskid-byquarters" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/byquarters"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest data for equity chart, grouped by years
#
# GET /taskmanager/tasks/{taskid}/byyears
# Returns: table<equitypct: string, period: string>
export def "get-taskmanager-tasks-taskid-byyears" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/byyears"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest symbol contribution data
#
# GET /taskmanager/tasks/{taskid}/contribution
# Returns: table<pandl: string, share: string, symbol: string>
export def "get-taskmanager-tasks-taskid-contribution" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/contribution"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data for drawdown chart
#
# GET /taskmanager/tasks/{taskid}/drawdown
# Returns: table<drawdownpct: string, timestamp: string>
export def "get-taskmanager-tasks-taskid-drawdown" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/drawdown"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data for equity chart
#
# GET /taskmanager/tasks/{taskid}/equity
# Returns: table<cash: string, equity: string, timestamp: string>
export def "get-taskmanager-tasks-taskid-equity" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/equity"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data for equity chart (%)
#
# GET /taskmanager/tasks/{taskid}/equitypct
# Returns: table<buyandhold: string, equity: string, timestamp: string>
export def "get-taskmanager-tasks-taskid-equitypct" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/equitypct"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spared data for equity chart (%)
#
# GET /taskmanager/tasks/{taskid}/equitypctsm
# Returns: table<buyandhold: string, equity: string, timestamp: string>
export def "get-taskmanager-tasks-taskid-equitypctsm" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/equitypctsm"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task result folder name
#
# GET /taskmanager/tasks/{taskid}/folder
# Returns: record<folder: string>
export def "get-taskmanager-tasks-taskid-folder" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/folder"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest statistics
#
# GET /taskmanager/tasks/{taskid}/performance
# Returns: record<buyandhold: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, long: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, longshort: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, short: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>>
export def "get-taskmanager-tasks-taskid-performance" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/performance"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task result
#
# GET /taskmanager/tasks/{taskid}/result
# Returns: record<bymonths_csv: string, bymonths_png: string, byquarters_csv: string, byquarters_png: string, byyears_csv: string, byyears_png: string, contribution_csv: string, contribution_png: string, drawdown_csv: string, drawdown_png: string, equity_csv: string, equity_png: string, equitypct_csv: string, equitypct_png: string, equitypctnofill_csv: string, equitypctnofill_png: string, equitypctsm: string, equitypctsm_csv: string, equitypctsm_png: string, performance_csv: string, performance_png: string, trades_csv: string, trades_png: string>
export def "get-taskmanager-tasks-taskid-result" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/result"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task result (version 2)
#
# GET /taskmanager/tasks/{taskid}/result2
# Returns: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>
export def "get-taskmanager-tasks-taskid-result2" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/result2"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task status
#
# GET /taskmanager/tasks/{taskid}/status
# Returns: record<status: string>
export def "get-taskmanager-tasks-taskid-status" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/status"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get backtest trades list
#
# GET /taskmanager/tasks/{taskid}/trades
# Returns: table<barsheld: string, changepct: string, commission: string, entrydatetime: string, entryprice: string, entrysignal: string, exitdatetime: string, exitprice: string, exitsignal: string, mae: string, mfe: string, pandl: string, position: string, shares: string, size: string, symbol: string>
export def "get-taskmanager-tasks-taskid-trades" [
  taskid: int
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
    path: "/taskmanager/tasks/{taskid}/trades"
    path_params: [{name: taskid, var: taskid}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    taskid: $taskid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current server time
#
# GET /time
# Returns: record<servertime: int>
export def "get-time" [
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
    path: "/time"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
