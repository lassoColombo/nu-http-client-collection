# Auto-generated client for Otoroshi Admin API v1.5.0-dev
# Source: https://api.apis.guru/v2/specs/maif.local/otoroshi/1.5.0-dev/openapi.json
# Auth: --token flag or $env.OTOROSHI_ADMIN_API_TOKEN

const CLIENT = {
  base_url: "http://otoroshi-api.oto.tools"
  token_env_var: "OTOROSHI_ADMIN_API_TOKEN"
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

def base-url-completer [] { ["http://otoroshi-api.oto.tools" "http://maif.local"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def typ-completer [] { ["console" "custom" "elastic" "file" "kafka" "mailer" "pulsar"] }
def accept-completer [] { ["application/json" "text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    all-api-keys: "table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    find-all-global-auth-modules: "list<any>"
    delete-global-auth-module: "record<deleted: bool>"
    all-certs: "table<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>"
    create-cert: "record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>"
    delete-cert: "record<deleted: bool>"
    one-cert: "record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>"
    patch-cert: "record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>"
    put-cert: "record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>"
    find-all-client-validators: "table<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>"
    create-client-validator: "record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>"
    delete-client-validator: "record<deleted: bool>"
    find-client-validator-by-id: "record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>"
    patch-client-validator: "record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>"
    update-client-validator: "record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>"
    find-all-data-exporters: "table<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list, include: list>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    create-data-exporter-config: "record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    deletebulk-data-exporter-config: "table<deleted: bool, id: bool, status: string>"
    patch-bulk-data-exporter-config: "table<id: bool, status: string, updated: bool>"
    create-bulk-data-exporter-configs: "table<created: bool, id: bool, status: string>"
    update-bulk-data-exporter-config: "table<id: bool, status: string, updated: bool>"
    data-exporter-template: "record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    delete-data-exporter-config: "record<deleted: bool>"
    find-data-exporter-config-by-id: "record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    patch-data-exporter-config: "record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    update-data-exporter-config: "record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>"
    global-config: "record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>"
    patch-global-config: "record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>"
    put-global-config: "record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>"
    all-service-groups: "table<description: string, id: string, name: string>"
    create-group: "record<description: string, id: string, name: string>"
    api-keys-from-group: "table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    create-api-key-from-group: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    delete-api-key-from-group: "record<deleted: bool>"
    api-key-from-group: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    patch-api-key-from-group: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    update-api-key-from-group: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    reset-api-key-from-group-quotas: "record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>"
    api-key-from-group-quotas: "record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>"
    delete-group: "record<deleted: bool>"
    service-group: "record<description: string, id: string, name: string>"
    patch-group: "record<description: string, id: string, name: string>"
    update-group: "record<description: string, id: string, name: string>"
    service-group-services: "table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    full-import-from-file: "record<done: bool>"
    global-live-stats: "record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float>"
    service-live-stats: "record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float>"
    full-export: "record<admins: table<createdAt: int, label: string, password: string, registration: record, username: string>, apiKeys: table<authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>, appConfig: record, config: record<alertsEmails: list<string>, alertsWebhooks: list<record>, analyticsWebhooks: list<record>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: list<record>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list, whitelist: list>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>, date: string, dateRaw: int, errorTemplates: table<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>, label: string, serviceDescriptors: table<Canary: record, additionalHeaders: record, api: record, authConfigRef: string, buildMode: bool, chaosConfig: record, clientConfig: record, clientValidatorRef: string, cors: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip: record, headersVerification: record, healthCheck: record, id: string, ipFiltering: record, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list, publicPatterns: list, redirectToLocal: bool, redirection: record, root: string, secComExcludedPatterns: list, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record, subdomain: string, targets: list, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>, serviceGroups: table<description: string, id: string, name: string>, simpleAdmins: table<createdAt: int, label: string, password: string, username: string>, stats: record<calls: int, dataIn: int, dataOut: int>>"
    full-import: "record<done: bool>"
    find-all-scripts: "table<code: record, desc: record, id: string, name: string>"
    create-script: "record<code: record, desc: record, id: string, name: string>"
    compile-script: "record<done: bool, error: record<column: string, file: record, line: string, message: record, rawMessage: record>>"
    delete-script: "record<deleted: bool>"
    find-script-by-id: "record<code: record, desc: record, id: string, name: string>"
    patch-script: "record<code: record, desc: record, id: string, name: string>"
    update-script: "record<code: record, desc: record, id: string, name: string>"
    all-services: "table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    create-service: "record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    delete-service: "record<deleted: bool>"
    service: "record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    patch-service: "record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    update-service: "record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    api-keys: "table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    create-api-key: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    delete-api-key: "record<deleted: bool>"
    api-key: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    patch-api-key: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    update-api-key: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    api-key-group: "record<description: string, id: string, name: string>"
    reset-api-key-quotas: "record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>"
    api-key-quotas: "record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>"
    service-delete-target: "table<host: string, scheme: string>"
    service-targets: "table<host: string, scheme: string>"
    update-service-targets: "table<host: string, scheme: string>"
    service-add-target: "table<host: string, scheme: string>"
    delete-service-template: "record<deleted: bool>"
    service-template: "record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>"
    create-service-template: "record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>"
    update-service-template: "record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>"
    start-snow-monkey: "record<done: bool>"
    stop-snow-monkey: "record<done: bool>"
    get-snow-monkey-config: "record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>"
    patch-snow-monkey: "record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>"
    update-snow-monkey: "record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>"
    reset-snow-monkey: "record<done: bool>"
    get-snow-monkey-outages: "table<descriptorId: string, descriptorName: string, duration: int, until: string>"
    find-all-global-jwt-verifiers: "table<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>"
    create-global-jwt-verifier: "record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>"
    delete-global-jwt-verifier: "record<deleted: bool>"
    find-global-jwt-verifiers-by-id: "record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>"
    patch-global-jwt-verifier: "record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>"
    update-global-jwt-verifier: "record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>"
    health: "record<datastore: string, otoroshi: string>"
    all-lines: "string"
    services-for-a-line: "table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
    initiate-api-key: "record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>"
    initiate-service-group: "record<description: string, id: string, name: string>"
    initiate-service: "record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["all-api-keys" "find-all-global-auth-modules" "create-global-auth-module" "delete-global-auth-module" "find-global-auth-module-by-id" "patch-global-auth-module" "update-global-auth-module" "all-certs" "create-cert" "delete-cert" "one-cert" "patch-cert" "put-cert" "find-all-client-validators" "create-client-validator" "delete-client-validator" "find-client-validator-by-id" "patch-client-validator" "update-client-validator" "find-all-data-exporters" "create-data-exporter-config" "deletebulk-data-exporter-config" "patch-bulk-data-exporter-config" "create-bulk-data-exporter-configs" "update-bulk-data-exporter-config" "data-exporter-template" "delete-data-exporter-config" "find-data-exporter-config-by-id" "patch-data-exporter-config" "update-data-exporter-config" "global-config" "patch-global-config" "put-global-config" "all-service-groups" "create-group" "api-keys-from-group" "create-api-key-from-group" "delete-api-key-from-group" "api-key-from-group" "patch-api-key-from-group" "update-api-key-from-group" "reset-api-key-from-group-quotas" "api-key-from-group-quotas" "delete-group" "service-group" "patch-group" "update-group" "service-group-services" "full-import-from-file" "global-live-stats" "service-live-stats" "full-export" "full-import" "find-all-scripts" "create-script" "compile-script" "delete-script" "find-script-by-id" "patch-script" "update-script" "all-services" "create-service" "delete-service" "service" "patch-service" "update-service" "api-keys" "create-api-key" "delete-api-key" "api-key" "patch-api-key" "update-api-key" "api-key-group" "reset-api-key-quotas" "api-key-quotas" "service-delete-target" "service-targets" "update-service-targets" "service-add-target" "delete-service-template" "service-template" "create-service-template" "update-service-template" "start-snow-monkey" "stop-snow-monkey" "get-snow-monkey-config" "patch-snow-monkey" "update-snow-monkey" "reset-snow-monkey" "get-snow-monkey-outages" "find-all-global-jwt-verifiers" "create-global-jwt-verifier" "delete-global-jwt-verifier" "find-global-jwt-verifiers-by-id" "patch-global-jwt-verifier" "update-global-jwt-verifier" "health" "all-lines" "services-for-a-line" "initiate-api-key" "initiate-service-group" "initiate-service" "commands"] | sort) } | get name | first)
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

# Get all api keys
#
# GET /api/apikeys
# Returns: table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: allApiKeys
export def "all-api-keys" [
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
    path: "/api/apikeys"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all global auth. module configs
#
# GET /api/auths
# Returns: list<any>
# operationId: findAllGlobalAuthModules
export def "find-all-global-auth-modules" [
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
    path: "/api/auths"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one global auth. module config
#
# POST /api/auths
# operationId: createGlobalAuthModule
export def "create-global-auth-module" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-password: string # The admin password (e.g. a string value)
  --admin-username: string # The admin username (e.g. a string value)
  desc: string # Description of the config (e.g. a string value)
  --email-field: string # Field name to get email from user profile (e.g. a string value)
  --group-filter: string # Filter for groups (e.g. a string value)
  id: string # Unique id of the config (e.g. a string value)
  name: string # Name of the config (e.g. a string value)
  --name-field: string # Field name to get name from user profile (e.g. a string value)
  --otoroshi-data-field: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --search-base: string # LDAP search base (e.g. a string value)
  --search-filter: string # Filter for users (e.g. a string value)
  --server-url: string # URL of the ldap server (e.g. a string value)
  session_max_age: int # Max age of the session (format: int32, e.g. 123123)
  type: string # Type of settings. value is ldap (e.g. a string value)
  --user-base: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --access-token-field: string # Field name to get access token (e.g. a string value)
  --authorize-url: string # OAuth authorize URL (e.g. a string value)
  --callback-url: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --client-id: string # OAuth Client id (e.g. a string value)
  --client-secret: string # OAuth Client secret (e.g. a string value)
  --jwt-verifier: any # Algo. settings to verify JWT token
  --login-url: string # OAuth login URL (e.g. a string value)
  --logout-url: string # OAuth logout URL (e.g. a string value)
  --oid-config: string # URL of the OIDC config. file (e.g. a string value)
  --read-profile-from-token: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --token-url: string # OAuth token URL (e.g. a string value)
  --use-cookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --use-json: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --user-info-url: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/auths"
    body: {content_type: "application/json", kind: json, fields: [{name: adminPassword, var: admin_password}, {name: adminUsername, var: admin_username}, {name: desc, var: desc}, {name: emailField, var: email_field}, {name: groupFilter, var: group_filter}, {name: id, var: id}, {name: name, var: name}, {name: nameField, var: name_field}, {name: otoroshiDataField, var: otoroshi_data_field}, {name: searchBase, var: search_base}, {name: searchFilter, var: search_filter}, {name: serverUrl, var: server_url}, {name: sessionMaxAge, var: session_max_age}, {name: type, var: type}, {name: userBase, var: user_base}, {name: users, var: users}, {name: accessTokenField, var: access_token_field}, {name: authorizeUrl, var: authorize_url}, {name: callbackUrl, var: callback_url}, {name: claims, var: claims}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: jwtVerifier, var: jwt_verifier}, {name: loginUrl, var: login_url}, {name: logoutUrl, var: logout_url}, {name: oidConfig, var: oid_config}, {name: readProfileFromToken, var: read_profile_from_token}, {name: scope, var: scope}, {name: tokenUrl, var: token_url}, {name: useCookies, var: use_cookies}, {name: useJson, var: use_json}, {name: userInfoUrl, var: user_info_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    admin_password: $admin_password, admin_username: $admin_username, desc: $desc, email_field: $email_field, group_filter: $group_filter, id: $id, name: $name, name_field: $name_field, otoroshi_data_field: $otoroshi_data_field, search_base: $search_base, search_filter: $search_filter, server_url: $server_url, session_max_age: $session_max_age, type: $type, user_base: $user_base, users: $users, access_token_field: $access_token_field, authorize_url: $authorize_url, callback_url: $callback_url, claims: $claims, client_id: $client_id, client_secret: $client_secret, jwt_verifier: $jwt_verifier, login_url: $login_url, logout_url: $logout_url, oid_config: $oid_config, read_profile_from_token: $read_profile_from_token, scope: $scope, token_url: $token_url, use_cookies: $use_cookies, use_json: $use_json, user_info_url: $user_info_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete one global auth. module config
#
# DELETE /api/auths/{id}
# Returns: record<deleted: bool>
# operationId: deleteGlobalAuthModule
export def "delete-global-auth-module" [
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
    method: delete
    path: "/api/auths/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one global auth. module configs
#
# GET /api/auths/{id}
# operationId: findGlobalAuthModuleById
export def "find-global-auth-module-by-id" [
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
    method: get
    path: "/api/auths/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one global auth. module config
#
# PATCH /api/auths/{id}
# operationId: patchGlobalAuthModule
export def "patch-global-auth-module" [
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
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/auths/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one global auth. module config
#
# PUT /api/auths/{id}
# operationId: updateGlobalAuthModule
export def "update-global-auth-module" [
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
  --admin-password: string # The admin password (e.g. a string value)
  --admin-username: string # The admin username (e.g. a string value)
  desc: string # Description of the config (e.g. a string value)
  --email-field: string # Field name to get email from user profile (e.g. a string value)
  --group-filter: string # Filter for groups (e.g. a string value)
  --body-id: string # Unique id of the config (e.g. a string value) (spec name: id)
  name: string # Name of the config (e.g. a string value)
  --name-field: string # Field name to get name from user profile (e.g. a string value)
  --otoroshi-data-field: string # Field name to get otoroshi metadata from. You can specify sub fields using | as separator (e.g. a string value)
  --search-base: string # LDAP search base (e.g. a string value)
  --search-filter: string # Filter for users (e.g. a string value)
  --server-url: string # URL of the ldap server (e.g. a string value)
  session_max_age: int # Max age of the session (format: int32, e.g. 123123)
  type: string # Type of settings. value is ldap (e.g. a string value)
  --user-base: string # LDAP user base DN (e.g. a string value)
  --users: list # List of users — item shape: {email: string, metadata: record, name: string, password: string}
  --access-token-field: string # Field name to get access token (e.g. a string value)
  --authorize-url: string # OAuth authorize URL (e.g. a string value)
  --callback-url: string # Otoroshi callback URL (e.g. a string value)
  --claims: string # The claims of the token (e.g. a string value)
  --client-id: string # OAuth Client id (e.g. a string value)
  --client-secret: string # OAuth Client secret (e.g. a string value)
  --jwt-verifier: any # Algo. settings to verify JWT token
  --login-url: string # OAuth login URL (e.g. a string value)
  --logout-url: string # OAuth logout URL (e.g. a string value)
  --oid-config: string # URL of the OIDC config. file (e.g. a string value)
  --read-profile-from-token: oneof<nothing, bool> # The user profile will be read from the JWT token in id_token (e.g. true)
  --scope: string # The scope of the token (e.g. a string value)
  --token-url: string # OAuth token URL (e.g. a string value)
  --use-cookies: oneof<nothing, bool> # Use for redirection to actual service (e.g. true)
  --use-json: oneof<nothing, bool> # Use JSON or URL Form Encoded as payload with the OAuth provider (e.g. true)
  --user-info-url: string # OAuth userinfo to get user profile (e.g. a string value)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/auths/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminPassword, var: admin_password}, {name: adminUsername, var: admin_username}, {name: desc, var: desc}, {name: emailField, var: email_field}, {name: groupFilter, var: group_filter}, {name: id, var: body_id, required: true}, {name: name, var: name}, {name: nameField, var: name_field}, {name: otoroshiDataField, var: otoroshi_data_field}, {name: searchBase, var: search_base}, {name: searchFilter, var: search_filter}, {name: serverUrl, var: server_url}, {name: sessionMaxAge, var: session_max_age}, {name: type, var: type}, {name: userBase, var: user_base}, {name: users, var: users}, {name: accessTokenField, var: access_token_field}, {name: authorizeUrl, var: authorize_url}, {name: callbackUrl, var: callback_url}, {name: claims, var: claims}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: jwtVerifier, var: jwt_verifier}, {name: loginUrl, var: login_url}, {name: logoutUrl, var: logout_url}, {name: oidConfig, var: oid_config}, {name: readProfileFromToken, var: read_profile_from_token}, {name: scope, var: scope}, {name: tokenUrl, var: token_url}, {name: useCookies, var: use_cookies}, {name: useJson, var: use_json}, {name: userInfoUrl, var: user_info_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, admin_password: $admin_password, admin_username: $admin_username, desc: $desc, email_field: $email_field, group_filter: $group_filter, body_id: $body_id, name: $name, name_field: $name_field, otoroshi_data_field: $otoroshi_data_field, search_base: $search_base, search_filter: $search_filter, server_url: $server_url, session_max_age: $session_max_age, type: $type, user_base: $user_base, users: $users, access_token_field: $access_token_field, authorize_url: $authorize_url, callback_url: $callback_url, claims: $claims, client_id: $client_id, client_secret: $client_secret, jwt_verifier: $jwt_verifier, login_url: $login_url, logout_url: $logout_url, oid_config: $oid_config, read_profile_from_token: $read_profile_from_token, scope: $scope, token_url: $token_url, use_cookies: $use_cookies, use_json: $use_json, user_info_url: $user_info_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all certificates
#
# GET /api/certificates
# Returns: table<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>
# operationId: allCerts
export def "all-certs" [
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
    path: "/api/certificates"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one certificate
#
# POST /api/certificates
# Returns: record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>
# operationId: createCert
export def "create-cert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  auto_renew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  ca_ref: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  from: string # Start date of validity (e.g. a string value)
  id: string # Id of the certificate (e.g. a string value)
  private_key: string # PKCS8 private key in PEM format (e.g. a string value)
  self_signed: string # Certificate is self signed read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/certificates"
    body: {content_type: "application/json", kind: json, fields: [{name: autoRenew, var: auto_renew}, {name: ca, var: ca}, {name: caRef, var: ca_ref}, {name: chain, var: chain}, {name: domain, var: domain}, {name: from, var: from}, {name: id, var: id}, {name: privateKey, var: private_key}, {name: selfSigned, var: self_signed}, {name: subject, var: subject}, {name: to, var: to}, {name: valid, var: valid}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    auto_renew: $auto_renew, ca: $ca, ca_ref: $ca_ref, chain: $chain, domain: $domain, from: $from, id: $id, private_key: $private_key, self_signed: $self_signed, subject: $subject, to: $to, valid: $valid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete one certificate by id
#
# DELETE /api/certificates/{id}
# Returns: record<deleted: bool>
# operationId: deleteCert
export def "delete-cert" [
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
    method: delete
    path: "/api/certificates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one certificate by id
#
# GET /api/certificates/{id}
# Returns: record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>
# operationId: oneCert
export def "one-cert" [
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
    path: "/api/certificates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one certificate by id
#
# PATCH /api/certificates/{id}
# Returns: record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>
# operationId: patchCert
export def "patch-cert" [
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
    path: "/api/certificates/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one certificate by id
#
# PUT /api/certificates/{id}
# Returns: record<autoRenew: string, ca: string, caRef: string, chain: string, domain: string, from: string, id: string, privateKey: string, selfSigned: string, subject: string, to: string, valid: string>
# operationId: putCert
export def "put-cert" [
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
  auto_renew: string # Allow Otoroshi to renew the certificate (if self signed) (e.g. a string value)
  ca: string # Certificate is a CA (read only) (e.g. a string value)
  ca_ref: string # Reference for a CA certificate in otoroshi (e.g. a string value)
  chain: string # Certificate chain of trust in PEM format (e.g. a string value)
  domain: string # Domain of the certificate (read only) (e.g. a string value)
  from: string # Start date of validity (e.g. a string value)
  --body-id: string # Id of the certificate (e.g. a string value) (spec name: id)
  private_key: string # PKCS8 private key in PEM format (e.g. a string value)
  self_signed: string # Certificate is self signed read only) (e.g. a string value)
  subject: string # Subject of the certificate (read only) (e.g. a string value)
  to: string # End date of validity (e.g. a string value)
  valid: string # Certificate is valid (read only) (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/certificates/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoRenew, var: auto_renew}, {name: ca, var: ca}, {name: caRef, var: ca_ref}, {name: chain, var: chain}, {name: domain, var: domain}, {name: from, var: from}, {name: id, var: body_id, required: true}, {name: privateKey, var: private_key}, {name: selfSigned, var: self_signed}, {name: subject, var: subject}, {name: to, var: to}, {name: valid, var: valid}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, auto_renew: $auto_renew, ca: $ca, ca_ref: $ca_ref, chain: $chain, domain: $domain, from: $from, body_id: $body_id, private_key: $private_key, self_signed: $self_signed, subject: $subject, to: $to, valid: $valid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all validation authoritiess
#
# GET /api/client-validators
# Returns: table<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>
# operationId: findAllClientValidators
export def "find-all-client-validators" [
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
    path: "/api/client-validators"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one validation authorities
#
# POST /api/client-validators
# Returns: record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>
# operationId: createClientValidator
export def "create-client-validator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --always-valid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  bad_ttl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  good_ttl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  id: string # The id of the settings (e.g. a string value)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --no-cache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  url: string # The URL of the server (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/client-validators"
    body: {content_type: "application/json", kind: json, fields: [{name: alwaysValid, var: always_valid, required: true}, {name: badTtl, var: bad_ttl}, {name: description, var: description}, {name: goodTtl, var: good_ttl}, {name: headers, var: headers}, {name: host, var: host}, {name: id, var: id}, {name: method, var: method}, {name: name, var: name}, {name: noCache, var: no_cache, required: true}, {name: path, var: path}, {name: timeout, var: timeout}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    always_valid: $always_valid, bad_ttl: $bad_ttl, description: $description, good_ttl: $good_ttl, headers: $headers, host: $host, id: $id, method: $method, name: $name, no_cache: $no_cache, path: $path, timeout: $timeout, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete one validation authorities by id
#
# DELETE /api/client-validators/{id}
# Returns: record<deleted: bool>
# operationId: deleteClientValidator
export def "delete-client-validator" [
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
    method: delete
    path: "/api/client-validators/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one validation authorities by id
#
# GET /api/client-validators/{id}
# Returns: record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>
# operationId: findClientValidatorById
export def "find-client-validator-by-id" [
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
    path: "/api/client-validators/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one validation authorities by id
#
# PATCH /api/client-validators/{id}
# Returns: record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>
# operationId: patchClientValidator
export def "patch-client-validator" [
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
    path: "/api/client-validators/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one validation authorities by id
#
# PUT /api/client-validators/{id}
# Returns: record<alwaysValid: bool, badTtl: int, description: string, goodTtl: int, headers: record, host: string, id: string, method: string, name: string, noCache: bool, path: string, timeout: int, url: string>
# operationId: updateClientValidator
export def "update-client-validator" [
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
  --always-valid: oneof<nothing, bool> # Bypass http calls, every certificates are valids (e.g. true)
  bad_ttl: int # The TTL for invalid access response caching (format: int64, e.g. 123)
  description: string # The description of the settings (e.g. a string value)
  good_ttl: int # The TTL for valid access response caching (format: int64, e.g. 123)
  headers: record # HTTP call headers (e.g. {key: value})
  host: string # The host of the server (e.g. a string value)
  --body-id: string # The id of the settings (e.g. a string value) (spec name: id)
  method: string # The HTTP method (e.g. a string value)
  name: string # The name of the settings (e.g. a string value)
  --no-cache: oneof<nothing, bool> # Avoid caching responses (e.g. true)
  path: string # The URL path (e.g. a string value)
  timeout: int # The call timeout (format: int64, e.g. 123)
  url: string # The URL of the server (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/client-validators/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alwaysValid, var: always_valid, required: true}, {name: badTtl, var: bad_ttl}, {name: description, var: description}, {name: goodTtl, var: good_ttl}, {name: headers, var: headers}, {name: host, var: host}, {name: id, var: body_id, required: true}, {name: method, var: method}, {name: name, var: name}, {name: noCache, var: no_cache, required: true}, {name: path, var: path}, {name: timeout, var: timeout}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, always_valid: $always_valid, bad_ttl: $bad_ttl, description: $description, good_ttl: $good_ttl, headers: $headers, host: $host, body_id: $body_id, method: $method, name: $name, no_cache: $no_cache, path: $path, timeout: $timeout, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all data exporter configs
#
# GET /api/data-exporter-configs
# Returns: table<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list, include: list>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: findAllDataExporters
export def "find-all-data-exporters" [
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
    path: "/api/data-exporter-configs"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new data exporter config
#
# POST /api/data-exporter-configs
# Returns: record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: createDataExporterConfig
export def "create-data-exporter-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buffer-size: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --group-duration: int # duration (format: int64, e.g. 123)
  --group-size: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --json-workers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --send-workers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/data-exporter-configs"
    body: {content_type: "application/json", kind: json, fields: [{name: bufferSize, var: buffer_size}, {name: config, var: config}, {name: desc, var: desc}, {name: enabled, var: enabled}, {name: filtering, var: filtering}, {name: groupDuration, var: group_duration}, {name: groupSize, var: group_size}, {name: id, var: id}, {name: jsonWorkers, var: json_workers}, {name: location, var: location}, {name: metadata, var: metadata}, {name: name, var: name}, {name: projection, var: projection}, {name: sendWorkers, var: send_workers}, {name: typ, var: typ}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    buffer_size: $buffer_size, config: $config, desc: $desc, enabled: $enabled, filtering: $filtering, group_duration: $group_duration, group_size: $group_size, id: $id, json_workers: $json_workers, location: $location, metadata: $metadata, name: $name, projection: $projection, send_workers: $send_workers, typ: $typ
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a data exporter config
#
# DELETE /api/data-exporter-configs/_bulk
# Returns: table<deleted: bool, id: bool, status: string>
# operationId: deletebulkDataExporterConfig
export def "deletebulk-data-exporter-config" [
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/api/data-exporter-configs/_bulk"
    body: {content_type: "application/ndjson", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a data exporter configs with a diff
#
# PATCH /api/data-exporter-configs/_bulk
# Returns: table<id: bool, status: string, updated: bool>
# operationId: patchBulkDataExporterConfig
export def "patch-bulk-data-exporter-config" [
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/data-exporter-configs/_bulk"
    body: {content_type: "application/ndjson", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new data exporter configs
#
# POST /api/data-exporter-configs/_bulk
# Returns: table<created: bool, id: bool, status: string>
# operationId: createBulkDataExporterConfigs
export def "create-bulk-data-exporter-configs" [
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/data-exporter-configs/_bulk"
    body: {content_type: "application/ndjson", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a data exporter configs
#
# PUT /api/data-exporter-configs/_bulk
# Returns: table<id: bool, status: string, updated: bool>
# operationId: updateBulkDataExporterConfig
export def "update-bulk-data-exporter-config" [
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/data-exporter-configs/_bulk"
    body: {content_type: "application/ndjson", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all data exporter configs
#
# GET /api/data-exporter-configs/_template
# Returns: record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: DataExporterTemplate
export def "data-exporter-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The data exporter config type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/data-exporter-configs/_template"
    query: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a data exporter config
#
# DELETE /api/data-exporter-configs/{dataExporterConfigId}
# Returns: record<deleted: bool>
# operationId: deleteDataExporterConfig
export def "delete-data-exporter-config" [
  data_exporter_config_id: string
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
    path: "/api/data-exporter-configs/{dataExporterConfigId}"
    path_params: [{name: dataExporterConfigId, var: data_exporter_config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_exporter_config_id: $data_exporter_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a data exporter config
#
# GET /api/data-exporter-configs/{dataExporterConfigId}
# Returns: record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: findDataExporterConfigById
export def "find-data-exporter-config-by-id" [
  data_exporter_config_id: string
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
    path: "/api/data-exporter-configs/{dataExporterConfigId}"
    path_params: [{name: dataExporterConfigId, var: data_exporter_config_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_exporter_config_id: $data_exporter_config_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a data exporter config with a diff
#
# PATCH /api/data-exporter-configs/{dataExporterConfigId}
# Returns: record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: patchDataExporterConfig
export def "patch-data-exporter-config" [
  data_exporter_config_id: string
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
    path: "/api/data-exporter-configs/{dataExporterConfigId}"
    path_params: [{name: dataExporterConfigId, var: data_exporter_config_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_exporter_config_id: $data_exporter_config_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a data exporter config
#
# PUT /api/data-exporter-configs/{dataExporterConfigId}
# Returns: record<bufferSize: int, config: any, desc: string, enabled: string, filtering: record<exclude: list<record>, include: list<record>>, groupDuration: int, groupSize: int, id: string, jsonWorkers: int, location: record<teams: list<record>, tenant: string>, metadata: record, name: string, projection: record, sendWorkers: int, typ: string>
# operationId: updateDataExporterConfig
export def "update-data-exporter-config" [
  data_exporter_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buffer-size: int # buffer size (format: int32, e.g. 123123)
  --config: any # Data Exporter config
  --desc: string # Description (e.g. a string value)
  --enabled: string # Boolean (e.g. a string value)
  --filtering: record # shape: {exclude?: list, include?: list}
  --group-duration: int # duration (format: int64, e.g. 123)
  --group-size: int # Group size (format: int32, e.g. 123123)
  --id: string # Id (e.g. a string value)
  --json-workers: int # nb workers (format: int32, e.g. 123123)
  --location: record # shape: {teams: list, tenant: string}
  --metadata: record # Metadata (e.g. {key: value})
  --name: string # Name (e.g. a string value)
  --projection: record # projection (e.g. {key: value})
  --send-workers: int # send workers (format: int32, e.g. 123123)
  --typ: string@typ-completer # Type of data exporter
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/data-exporter-configs/{dataExporterConfigId}"
    path_params: [{name: dataExporterConfigId, var: data_exporter_config_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bufferSize, var: buffer_size}, {name: config, var: config}, {name: desc, var: desc}, {name: enabled, var: enabled}, {name: filtering, var: filtering}, {name: groupDuration, var: group_duration}, {name: groupSize, var: group_size}, {name: id, var: id}, {name: jsonWorkers, var: json_workers}, {name: location, var: location}, {name: metadata, var: metadata}, {name: name, var: name}, {name: projection, var: projection}, {name: sendWorkers, var: send_workers}, {name: typ, var: typ}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    data_exporter_config_id: $data_exporter_config_id, buffer_size: $buffer_size, config: $config, desc: $desc, enabled: $enabled, filtering: $filtering, group_duration: $group_duration, group_size: $group_size, id: $id, json_workers: $json_workers, location: $location, metadata: $metadata, name: $name, projection: $projection, send_workers: $send_workers, typ: $typ
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the full configuration of Otoroshi
#
# GET /api/globalconfig
# Returns: record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>
# operationId: globalConfig
export def "global-config" [
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
    path: "/api/globalconfig"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the global configuration with a diff
#
# PATCH /api/globalconfig
# Returns: record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>
# operationId: patchGlobalConfig
export def "patch-global-config" [
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
    path: "/api/globalconfig"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the global configuration
#
# PUT /api/globalconfig
# Returns: record<alertsEmails: list<string>, alertsWebhooks: table<headers: record, url: string>, analyticsWebhooks: table<headers: record, url: string>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: table<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>
# operationId: putGlobalConfig
export def "put-global-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts_emails: list<string> # Email addresses that will receive all Otoroshi alert events
  alerts_webhooks: list # Webhook that will receive all Otoroshi alert events — item shape: {headers: record, url: string}
  analytics_webhooks: list # Webhook that will receive all internal Otoroshi events — item shape: {headers: record, url: string}
  --api-read-only: oneof<nothing, bool> # If enabled, Admin API won't be able to write/update/delete entities (e.g. true)
  --auto-link-to-default-group: oneof<nothing, bool> # If not defined, every new service descriptor will be added to the default group (e.g. true)
  --backoffice-auth0-config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --clever-settings: record # Configuration for CleverCloud client — shape: {consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string}
  --elastic-reads-config: record # The configuration for elastic access — shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  --elastic-writes-configs: list # Configs. for Elastic writes — item shape: {clusterUri: string, headers: record, index: string, password: string, type: string, user: string}
  endless_ip_addresses: list<string> # IP addresses for which any request to Otoroshi will respond with 128 Gb of zeros
  ip_filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list<string>, whitelist: list<string>}
  --limit-concurrent-requests: oneof<nothing, bool> # If enabled, Otoroshi will reject new request if too much at the same time (e.g. true)
  --lines: list<string> # Possibles lines for Otoroshi
  --mailer-settings: record # Configuration for mailgun api client — shape: {apiKey: string, apiKeyPrivate?: string, apiKeyPublic?: string, domain: string, eu?: bool, header?: record, type?: string, url?: string}
  max_concurrent_requests: int # The number of authorized request processed at the same time (format: int64, e.g. 123)
  --max-http10-response-size: int # The max size in bytes of an HTTP 1.0 response (format: int64, e.g. 123)
  --max-logs-size: int # Number of events kept locally (format: int32, e.g. 123123)
  --middle-fingers: oneof<nothing, bool> # Use middle finger emoji as a response character for endless HTTP responses (e.g. true)
  per_ip_throttling_quota: int # Authorized number of calls per second globally per IP address, measured on 10 seconds (format: int64, e.g. 123)
  --private-apps-auth0-config: record # Configuration for Auth0 domain — shape: {callbackUrl: string, clientId: string, clientSecret: string, domain: string}
  --stream-entity-only: oneof<nothing, bool> # HTTP will be streamed only. Doesn't work with old browsers (e.g. true)
  throttling_quota: int # Authorized number of calls per second globally, measured on 10 seconds (format: int64, e.g. 123)
  --u2f-login-only: oneof<nothing, bool> # If enabled, login to backoffice through Auth0 will be disabled (e.g. true)
  --use-circuit-breakers: oneof<nothing, bool> # If enabled, services will be authorized to use circuit breakers (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/globalconfig"
    body: {content_type: "application/json", kind: json, fields: [{name: alertsEmails, var: alerts_emails}, {name: alertsWebhooks, var: alerts_webhooks}, {name: analyticsWebhooks, var: analytics_webhooks}, {name: apiReadOnly, var: api_read_only, required: true}, {name: autoLinkToDefaultGroup, var: auto_link_to_default_group, required: true}, {name: backofficeAuth0Config, var: backoffice_auth0_config}, {name: cleverSettings, var: clever_settings}, {name: elasticReadsConfig, var: elastic_reads_config}, {name: elasticWritesConfigs, var: elastic_writes_configs}, {name: endlessIpAddresses, var: endless_ip_addresses}, {name: ipFiltering, var: ip_filtering}, {name: limitConcurrentRequests, var: limit_concurrent_requests, required: true}, {name: lines, var: lines}, {name: mailerSettings, var: mailer_settings}, {name: maxConcurrentRequests, var: max_concurrent_requests}, {name: maxHttp10ResponseSize, var: max_http10_response_size}, {name: maxLogsSize, var: max_logs_size}, {name: middleFingers, var: middle_fingers}, {name: perIpThrottlingQuota, var: per_ip_throttling_quota}, {name: privateAppsAuth0Config, var: private_apps_auth0_config}, {name: streamEntityOnly, var: stream_entity_only, required: true}, {name: throttlingQuota, var: throttling_quota}, {name: u2fLoginOnly, var: u2f_login_only, required: true}, {name: useCircuitBreakers, var: use_circuit_breakers, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    alerts_emails: $alerts_emails, alerts_webhooks: $alerts_webhooks, analytics_webhooks: $analytics_webhooks, api_read_only: $api_read_only, auto_link_to_default_group: $auto_link_to_default_group, backoffice_auth0_config: $backoffice_auth0_config, clever_settings: $clever_settings, elastic_reads_config: $elastic_reads_config, elastic_writes_configs: $elastic_writes_configs, endless_ip_addresses: $endless_ip_addresses, ip_filtering: $ip_filtering, limit_concurrent_requests: $limit_concurrent_requests, lines: $lines, mailer_settings: $mailer_settings, max_concurrent_requests: $max_concurrent_requests, max_http10_response_size: $max_http10_response_size, max_logs_size: $max_logs_size, middle_fingers: $middle_fingers, per_ip_throttling_quota: $per_ip_throttling_quota, private_apps_auth0_config: $private_apps_auth0_config, stream_entity_only: $stream_entity_only, throttling_quota: $throttling_quota, u2f_login_only: $u2f_login_only, use_circuit_breakers: $use_circuit_breakers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all service groups
#
# GET /api/groups
# Returns: table<description: string, id: string, name: string>
# operationId: allServiceGroups
export def "all-service-groups" [
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
    path: "/api/groups"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new service group
#
# POST /api/groups
# Returns: record<description: string, id: string, name: string>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/groups"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all api keys for the group of a service
#
# GET /api/groups/{groupId}/apikeys
# Returns: table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: apiKeysFromGroup
export def "api-keys-from-group" [
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
    path: "/api/groups/{groupId}/apikeys"
    path_params: [{name: groupId, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new api key for a group
#
# POST /api/groups/{groupId}/apikeys
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: createApiKeyFromGroup
export def "create-api-key-from-group" [
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
  authorized_entities: list<string> # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  client_id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/groups/{groupId}/apikeys"
    path_params: [{name: groupId, var: group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizedEntities, var: authorized_entities}, {name: clientId, var: client_id}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: dailyQuota, var: daily_quota}, {name: enabled, var: enabled, required: true}, {name: metadata, var: metadata}, {name: monthlyQuota, var: monthly_quota}, {name: throttlingQuota, var: throttling_quota}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, authorized_entities: $authorized_entities, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, daily_quota: $daily_quota, enabled: $enabled, metadata: $metadata, monthly_quota: $monthly_quota, throttling_quota: $throttling_quota
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}
# Returns: record<deleted: bool>
# operationId: deleteApiKeyFromGroup
export def "delete-api-key-from-group" [
  group_id: string
  client_id: string
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
    path: "/api/groups/{groupId}/apikeys/{clientId}"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: apiKeyFromGroup
export def "api-key-from-group" [
  group_id: string
  client_id: string
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
    path: "/api/groups/{groupId}/apikeys/{clientId}"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an api key with a diff
#
# PATCH /api/groups/{groupId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: patchApiKeyFromGroup
export def "patch-api-key-from-group" [
  group_id: string
  client_id: string
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
    path: "/api/groups/{groupId}/apikeys/{clientId}"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an api key
#
# PUT /api/groups/{groupId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: updateApiKeyFromGroup
export def "update-api-key-from-group" [
  group_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list<string> # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-client-id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value) (spec name: clientId)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/groups/{groupId}/apikeys/{clientId}"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizedEntities, var: authorized_entities}, {name: clientId, var: body_client_id, required: true}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: dailyQuota, var: daily_quota}, {name: enabled, var: enabled, required: true}, {name: metadata, var: metadata}, {name: monthlyQuota, var: monthly_quota}, {name: throttlingQuota, var: throttling_quota}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id, authorized_entities: $authorized_entities, body_client_id: $body_client_id, client_name: $client_name, client_secret: $client_secret, daily_quota: $daily_quota, enabled: $enabled, metadata: $metadata, monthly_quota: $monthly_quota, throttling_quota: $throttling_quota
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the quota state of an api key
#
# DELETE /api/groups/{groupId}/apikeys/{clientId}/quotas
# Returns: record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>
# operationId: resetApiKeyFromGroupQuotas
export def "reset-api-key-from-group-quotas" [
  group_id: string
  client_id: string
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
    path: "/api/groups/{groupId}/apikeys/{clientId}/quotas"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the quota state of an api key
#
# GET /api/groups/{groupId}/apikeys/{clientId}/quotas
# Returns: record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>
# operationId: apiKeyFromGroupQuotas
export def "api-key-from-group-quotas" [
  group_id: string
  client_id: string
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
    path: "/api/groups/{groupId}/apikeys/{clientId}/quotas"
    path_params: [{name: groupId, var: group_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    group_id: $group_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service group
#
# DELETE /api/groups/{serviceGroupId}
# Returns: record<deleted: bool>
# operationId: deleteGroup
export def "delete-group" [
  service_group_id: string
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
    path: "/api/groups/{serviceGroupId}"
    path_params: [{name: serviceGroupId, var: service_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_group_id: $service_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a service group
#
# GET /api/groups/{serviceGroupId}
# Returns: record<description: string, id: string, name: string>
# operationId: serviceGroup
export def "service-group" [
  service_group_id: string
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
    path: "/api/groups/{serviceGroupId}"
    path_params: [{name: serviceGroupId, var: service_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_group_id: $service_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service group with a diff
#
# PATCH /api/groups/{serviceGroupId}
# Returns: record<description: string, id: string, name: string>
# operationId: patchGroup
export def "patch-group" [
  service_group_id: string
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
    path: "/api/groups/{serviceGroupId}"
    path_params: [{name: serviceGroupId, var: service_group_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_group_id: $service_group_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service group
#
# PUT /api/groups/{serviceGroupId}
# Returns: record<description: string, id: string, name: string>
# operationId: updateGroup
export def "update-group" [
  service_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/groups/{serviceGroupId}"
    path_params: [{name: serviceGroupId, var: service_group_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_group_id: $service_group_id, description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all services descriptor for a group
#
# GET /api/groups/{serviceGroupId}/services
# Returns: table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: serviceGroupServices
export def "service-group-services" [
  service_group_id: string
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
    path: "/api/groups/{serviceGroupId}/services"
    path_params: [{name: serviceGroupId, var: service_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_group_id: $service_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import the full state of Otoroshi as a file
#
# POST /api/import
# Returns: record<done: bool>
# operationId: fullImportFromFile
export def "full-import-from-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  admins: list # Current U2F admin at the time of export — item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
  api_keys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --app-config: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list<string>, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list<string>, ipFiltering: record, limitConcurrentRequests: bool, lines?: list<string>, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, ... (5 more fields)}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  date_raw: int # format: int64, e.g. 123
  error_templates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  service_descriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, ... (20 more fields)}
  service_groups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simple_admins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/import"
    body: {content_type: "application/json", kind: json, fields: [{name: admins, var: admins}, {name: apiKeys, var: api_keys}, {name: appConfig, var: app_config}, {name: config, var: config}, {name: date, var: date}, {name: dateRaw, var: date_raw}, {name: errorTemplates, var: error_templates}, {name: label, var: label}, {name: serviceDescriptors, var: service_descriptors}, {name: serviceGroups, var: service_groups}, {name: simpleAdmins, var: simple_admins}, {name: stats, var: stats}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    admins: $admins, api_keys: $api_keys, app_config: $app_config, config: $config, date: $date, date_raw: $date_raw, error_templates: $error_templates, label: $label, service_descriptors: $service_descriptors, service_groups: $service_groups, simple_admins: $simple_admins, stats: $stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get global otoroshi stats
#
# GET /api/live
# Returns: record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float>
# operationId: globalLiveStats
export def "global-live-stats" [
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
    path: "/api/live"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get live feed of otoroshi stats
#
# GET /api/live/{id}
# Returns: record<calls: int, concurrentHandledRequests: int, dataIn: int, dataInRate: float, dataOut: int, dataOutRate: float, duration: float, overhead: float, rate: float>
# operationId: serviceLiveStats
export def "service-live-stats" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/live/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/event-stream"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Export the full state of Otoroshi
#
# GET /api/otoroshi.json
# Returns: record<admins: table<createdAt: int, label: string, password: string, registration: record, username: string>, apiKeys: table<authorizedEntities: list, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>, appConfig: record, config: record<alertsEmails: list<string>, alertsWebhooks: list<record>, analyticsWebhooks: list<record>, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, cleverSettings: record<consumerKey: string, consumerSecret: string, orgaId: string, secret: string, token: string>, elasticReadsConfig: record<clusterUri: string, headers: record, index: string, password: string, type: string, user: string>, elasticWritesConfigs: list<record>, endlessIpAddresses: list<string>, ipFiltering: record<blacklist: list, whitelist: list>, limitConcurrentRequests: bool, lines: list<string>, mailerSettings: record<apiKey: string, apiKeyPrivate: string, apiKeyPublic: string, domain: string, eu: bool, header: record, type: string, url: string>, maxConcurrentRequests: int, maxHttp10ResponseSize: int, maxLogsSize: int, middleFingers: bool, perIpThrottlingQuota: int, privateAppsAuth0Config: record<callbackUrl: string, clientId: string, clientSecret: string, domain: string>, streamEntityOnly: bool, throttlingQuota: int, u2fLoginOnly: bool, useCircuitBreakers: bool>, date: string, dateRaw: int, errorTemplates: table<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>, label: string, serviceDescriptors: table<Canary: record, additionalHeaders: record, api: record, authConfigRef: string, buildMode: bool, chaosConfig: record, clientConfig: record, clientValidatorRef: string, cors: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list, gzip: record, headersVerification: record, healthCheck: record, id: string, ipFiltering: record, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list, publicPatterns: list, redirectToLocal: bool, redirection: record, root: string, secComExcludedPatterns: list, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record, subdomain: string, targets: list, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>, serviceGroups: table<description: string, id: string, name: string>, simpleAdmins: table<createdAt: int, label: string, password: string, username: string>, stats: record<calls: int, dataIn: int, dataOut: int>>
# operationId: fullExport
export def "full-export" [
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
    path: "/api/otoroshi.json"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import the full state of Otoroshi
#
# POST /api/otoroshi.json
# Returns: record<done: bool>
# operationId: fullImport
export def "full-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  admins: list # Current U2F admin at the time of export — item shape: {createdAt: int, label: string, password: string, registration: record, username: string}
  api_keys: list # Current apik keys at the time of export — item shape: {authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota?: int, enabled: bool, metadata?: record, monthlyQuota?: int, throttlingQuota?: int}
  --app-config: record # Current env variables at the time of export (e.g. {key: value})
  config: record # The global config object of Otoroshi, used to customize settings of the current Otoroshi instance — shape: {alertsEmails: list<string>, alertsWebhooks: list, analyticsWebhooks: list, apiReadOnly: bool, autoLinkToDefaultGroup: bool, backofficeAuth0Config?: record, cleverSettings?: record, elasticReadsConfig?: record, elasticWritesConfigs?: list, endlessIpAddresses: list<string>, ipFiltering: record, limitConcurrentRequests: bool, lines?: list<string>, mailerSettings?: record, maxConcurrentRequests: int, maxHttp10ResponseSize?: int, maxLogsSize?: int, middleFingers?: bool, perIpThrottlingQuota: int, ... (5 more fields)}
  date: string # format: date-time, e.g. 2017-07-21T17:32:28Z
  date_raw: int # format: int64, e.g. 123
  error_templates: list # Current error templates at the time of export — item shape: {messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string}
  label: string # e.g. a string value
  service_descriptors: list # Current service descriptors at the time of export — item shape: {Canary?: record, additionalHeaders?: record, api?: record, authConfigRef?: string, buildMode: bool, chaosConfig?: record, clientConfig?: record, clientValidatorRef?: string, cors?: record, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip?: record, headersVerification?: record, healthCheck?: record, id: string, ipFiltering?: record, jwtVerifier?: any, localHost?: string, localScheme?: string, maintenanceMode: bool, ... (20 more fields)}
  service_groups: list # Current service groups at the time of export — item shape: {description?: string, id: string, name: string}
  simple_admins: list # Current simple admins at the time of export — item shape: {createdAt: int, label: string, password: string, username: string}
  stats: record # Global stats for the current Otoroshi instances — shape: {calls: int, dataIn: int, dataOut: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/otoroshi.json"
    body: {content_type: "application/json", kind: json, fields: [{name: admins, var: admins}, {name: apiKeys, var: api_keys}, {name: appConfig, var: app_config}, {name: config, var: config}, {name: date, var: date}, {name: dateRaw, var: date_raw}, {name: errorTemplates, var: error_templates}, {name: label, var: label}, {name: serviceDescriptors, var: service_descriptors}, {name: serviceGroups, var: service_groups}, {name: simpleAdmins, var: simple_admins}, {name: stats, var: stats}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    admins: $admins, api_keys: $api_keys, app_config: $app_config, config: $config, date: $date, date_raw: $date_raw, error_templates: $error_templates, label: $label, service_descriptors: $service_descriptors, service_groups: $service_groups, simple_admins: $simple_admins, stats: $stats
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all scripts
#
# GET /api/scripts
# Returns: table<code: record, desc: record, id: string, name: string>
# operationId: findAllScripts
export def "find-all-scripts" [
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
    path: "/api/scripts"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new script
#
# POST /api/scripts
# Returns: record<code: record, desc: record, id: string, name: string>
# operationId: createScript
export def "create-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/scripts"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: desc, var: desc}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    code: $code, desc: $desc, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compile a script
#
# POST /api/scripts/_compile
# Returns: record<done: bool, error: record<column: string, file: record, line: string, message: record, rawMessage: record>>
# operationId: compileScript
export def "compile-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/scripts/_compile"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: desc, var: desc}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    code: $code, desc: $desc, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a script
#
# DELETE /api/scripts/{scriptId}
# Returns: record<deleted: bool>
# operationId: deleteScript
export def "delete-script" [
  script_id: string
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
    path: "/api/scripts/{scriptId}"
    path_params: [{name: scriptId, var: script_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script_id: $script_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a script
#
# GET /api/scripts/{scriptId}
# Returns: record<code: record, desc: record, id: string, name: string>
# operationId: findScriptById
export def "find-script-by-id" [
  script_id: string
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
    path: "/api/scripts/{scriptId}"
    path_params: [{name: scriptId, var: script_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script_id: $script_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a script with a diff
#
# PATCH /api/scripts/{scriptId}
# Returns: record<code: record, desc: record, id: string, name: string>
# operationId: patchScript
export def "patch-script" [
  script_id: string
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
    path: "/api/scripts/{scriptId}"
    path_params: [{name: scriptId, var: script_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script_id: $script_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a script
#
# PUT /api/scripts/{scriptId}
# Returns: record<code: record, desc: record, id: string, name: string>
# operationId: updateScript
export def "update-script" [
  script_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: record # The code of the script (e.g. {key: value})
  desc: record # The description of the script (e.g. {key: value})
  id: string # The id of the script (e.g. a string value)
  name: string # The name of the script (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/scripts/{scriptId}"
    path_params: [{name: scriptId, var: script_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: desc, var: desc}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    script_id: $script_id, code: $code, desc: $desc, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all services
#
# GET /api/services
# Returns: table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: allServices
export def "all-services" [
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
    path: "/api/services"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new service descriptor
#
# POST /api/services
# Returns: record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: createService
export def "create-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additional-headers: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --auth-config-ref: string # A reference to a global auth module config (e.g. a string value)
  --build-mode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaos-config: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --client-config: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --client-validator-ref: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforce-secure-communication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  --body-env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value) (spec name: env)
  --force-https: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list<string> # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>}
  --headers-verification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --health-check: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ip-filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list<string>, whitelist: list<string>}
  --jwt-verifier: any
  --local-host: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --local-scheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenance-mode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matching-headers: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matching-root: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --override-host: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --private-app: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --private-patterns: list<string> # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --public-patterns: list<string> # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirect-to-local: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --sec-com-excluded-patterns: list<string> # URI patterns excluded from secured communications
  --sec-com-settings: any
  --send-otoroshi-headers-back: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsd-config: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformer-ref: string # A reference to a request transformer (e.g. a string value)
  --user-facing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --x-forwarded-headers: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/services"
    body: {content_type: "application/json", kind: json, fields: [{name: Canary, var: canary}, {name: additionalHeaders, var: additional_headers}, {name: api, var: api}, {name: authConfigRef, var: auth_config_ref}, {name: buildMode, var: build_mode, required: true}, {name: chaosConfig, var: chaos_config}, {name: clientConfig, var: client_config}, {name: clientValidatorRef, var: client_validator_ref}, {name: cors, var: cors}, {name: domain, var: domain}, {name: enabled, var: enabled, required: true}, {name: enforceSecureCommunication, var: enforce_secure_communication, required: true}, {name: env, var: body_env, required: true}, {name: forceHttps, var: force_https, required: true}, {name: groups, var: groups}, {name: gzip, var: gzip}, {name: headersVerification, var: headers_verification}, {name: healthCheck, var: health_check}, {name: id, var: id}, {name: ipFiltering, var: ip_filtering}, {name: jwtVerifier, var: jwt_verifier}, {name: localHost, var: local_host}, {name: localScheme, var: local_scheme}, {name: maintenanceMode, var: maintenance_mode, required: true}, {name: matchingHeaders, var: matching_headers}, {name: matchingRoot, var: matching_root}, {name: metadata, var: metadata}, {name: name, var: name}, {name: overrideHost, var: override_host}, {name: privateApp, var: private_app, required: true}, {name: privatePatterns, var: private_patterns}, {name: publicPatterns, var: public_patterns}, {name: redirectToLocal, var: redirect_to_local}, {name: redirection, var: redirection}, {name: root, var: root}, {name: secComExcludedPatterns, var: sec_com_excluded_patterns}, {name: secComSettings, var: sec_com_settings}, {name: sendOtoroshiHeadersBack, var: send_otoroshi_headers_back}, {name: statsdConfig, var: statsd_config}, {name: subdomain, var: subdomain}, {name: targets, var: targets}, {name: transformerRef, var: transformer_ref}, {name: userFacing, var: user_facing}, {name: xForwardedHeaders, var: x_forwarded_headers}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    canary: $canary, additional_headers: $additional_headers, api: $api, auth_config_ref: $auth_config_ref, build_mode: $build_mode, chaos_config: $chaos_config, client_config: $client_config, client_validator_ref: $client_validator_ref, cors: $cors, domain: $domain, enabled: $enabled, enforce_secure_communication: $enforce_secure_communication, body_env: $body_env, force_https: $force_https, groups: $groups, gzip: $gzip, headers_verification: $headers_verification, health_check: $health_check, id: $id, ip_filtering: $ip_filtering, jwt_verifier: $jwt_verifier, local_host: $local_host, local_scheme: $local_scheme, maintenance_mode: $maintenance_mode, matching_headers: $matching_headers, matching_root: $matching_root, metadata: $metadata, name: $name, override_host: $override_host, private_app: $private_app, private_patterns: $private_patterns, public_patterns: $public_patterns, redirect_to_local: $redirect_to_local, redirection: $redirection, root: $root, sec_com_excluded_patterns: $sec_com_excluded_patterns, sec_com_settings: $sec_com_settings, send_otoroshi_headers_back: $send_otoroshi_headers_back, statsd_config: $statsd_config, subdomain: $subdomain, targets: $targets, transformer_ref: $transformer_ref, user_facing: $user_facing, x_forwarded_headers: $x_forwarded_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service descriptor
#
# DELETE /api/services/{serviceId}
# Returns: record<deleted: bool>
# operationId: deleteService
export def "delete-service" [
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
    method: delete
    path: "/api/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a service descriptor
#
# GET /api/services/{serviceId}
# Returns: record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: service
export def "service" [
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
    path: "/api/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service descriptor with a diff
#
# PATCH /api/services/{serviceId}
# Returns: record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: patchService
export def "patch-service" [
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
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service descriptor
#
# PUT /api/services/{serviceId}
# Returns: record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: updateService
export def "update-service" [
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
  --canary: record # The configuration of the canary mode for a service descriptor — shape: {enabled: bool, root: string, targets: list, traffic: int}
  --additional-headers: record # Specify headers that will be added to each client request. Useful to add authentication (e.g. {key: value})
  --api: record # The Open API configuration for your service (if one) — shape: {exposeApi: bool, openApiDescriptorUrl?: string}
  --auth-config-ref: string # A reference to a global auth module config (e.g. a string value)
  --build-mode: oneof<nothing, bool> # Display a construction page when a user try to use the service (e.g. true)
  --chaos-config: record # Configuration for the faults that can be injected in requests — shape: {badResponsesFaultConfig?: record, enabled: bool, largeRequestFaultConfig?: record, largeResponseFaultConfig?: record, latencyInjectionFaultConfig?: record}
  --client-config: record # The configuration of the circuit breaker for a service descriptor — shape: {backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool}
  --client-validator-ref: string # A reference to validation authority (e.g. a string value)
  --cors: record # The configuration for cors support — shape: {allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int}
  domain: string # The domain on which the service is available. (e.g. a string value)
  --enabled: oneof<nothing, bool> # Activate or deactivate your service. Once disabled, users will get an error page saying the service does not exist (e.g. true)
  --enforce-secure-communication: oneof<nothing, bool> # When enabled, Otoroshi will try to exchange headers with downstream service to ensure no one else can use the service from outside (e.g. true)
  --body-env: string # The line on which the service is available. Based on that value, the name of the line will be appended to the subdomain. For line prod, nothing will be appended. For example, if the subdomain is 'foo' and line is 'preprod', then the exposed service will be available at 'foo.preprod.mydomain' (e.g. a string value) (spec name: env)
  --force-https: oneof<nothing, bool> # Will force redirection to https:// if not present (e.g. true)
  groups: list<string> # Each service descriptor is attached to groups. A group can have one or more services. Each API key is linked to a group and allow access to every service in the group (e.g. [a string value])
  --gzip: record # Configuration for gzip of service responses — shape: {blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>}
  --headers-verification: record # Specify headers that will be verified after routing. (e.g. {key: value})
  --health-check: record # The configuration for checking health of a service. Otoroshi will perform GET call on the URL to check if the service is still alive — shape: {enabled: bool, url?: string}
  id: string # A unique random string to identify your service (format: uuid, e.g. 110e8400-e29b-11d4-a716-446655440000)
  --ip-filtering: record # The filtering configuration block for a service of globally. — shape: {blacklist: list<string>, whitelist: list<string>}
  --jwt-verifier: any
  --local-host: string # The host used localy, mainly localhost:xxxx (e.g. a string value)
  --local-scheme: string # The scheme used localy, mainly http (e.g. a string value)
  --maintenance-mode: oneof<nothing, bool> # Display a maintainance page when a user try to use the service (e.g. true)
  --matching-headers: record # Specify headers that MUST be present on client request to route it. Useful to implement versioning (e.g. {key: value})
  --matching-root: string # The root path on which the service is available (e.g. a string value)
  --metadata: record # Just a bunch of random properties (e.g. {key: value})
  name: string # The name of your service. Only for debug and human readability purposes (e.g. a string value)
  --override-host: oneof<nothing, bool> # Host header will be overriden with Host of the target (e.g. true)
  --private-app: oneof<nothing, bool> # When enabled, user will be allowed to use the service (UI) only if they are registered users of the private apps domain (e.g. true)
  --private-patterns: list<string> # If you define a public pattern that is a little bit too much, you can make some of public URL private again
  --public-patterns: list<string> # By default, every services are private only and you'll need an API key to access it. However, if you want to expose a public UI, you can define one or more public patterns (regex) to allow access to anybody. For example if you want to allow anybody on any URL, just use '/.*'
  --redirect-to-local: oneof<nothing, bool> # If you work locally with Otoroshi, you may want to use that feature to redirect one particuliar service to a local host. For example, you can relocate https://foo.preprod.bar.com to http://localhost:8080 to make some tests (e.g. true)
  --redirection: record # The configuration for redirection per service — shape: {code: int, enabled: bool, to: string}
  root: string # Otoroshi will append this root to any target choosen. If the specified root is '/api/foo', then a request to https://yyyyyyy/bar will actually hit https://xxxxxxxxx/api/foo/bar (e.g. a string value)
  --sec-com-excluded-patterns: list<string> # URI patterns excluded from secured communications
  --sec-com-settings: any
  --send-otoroshi-headers-back: oneof<nothing, bool> # When enabled, Otoroshi will send headers to consumer like request id, client latency, overhead, etc ... (e.g. true)
  --statsd-config: record # The configuration for statsd metrics push — shape: {datadog: bool, host: string, port: int}
  subdomain: string # The subdomain on which the service is available (e.g. a string value)
  targets: list # The list of target that Otoroshi will proxy and expose through the subdomain defined before. Otoroshi will do round-robin load balancing between all those targets with circuit breaker mecanism to avoid cascading failures — item shape: {host: string, scheme: string}
  --transformer-ref: string # A reference to a request transformer (e.g. a string value)
  --user-facing: oneof<nothing, bool> # The fact that this service will be seen by users and cannot be impacted by the Snow Monkey (e.g. true)
  --x-forwarded-headers: oneof<nothing, bool> # Send X-Forwarded-* headers (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/services/{serviceId}"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Canary, var: canary}, {name: additionalHeaders, var: additional_headers}, {name: api, var: api}, {name: authConfigRef, var: auth_config_ref}, {name: buildMode, var: build_mode, required: true}, {name: chaosConfig, var: chaos_config}, {name: clientConfig, var: client_config}, {name: clientValidatorRef, var: client_validator_ref}, {name: cors, var: cors}, {name: domain, var: domain}, {name: enabled, var: enabled, required: true}, {name: enforceSecureCommunication, var: enforce_secure_communication, required: true}, {name: env, var: body_env, required: true}, {name: forceHttps, var: force_https, required: true}, {name: groups, var: groups}, {name: gzip, var: gzip}, {name: headersVerification, var: headers_verification}, {name: healthCheck, var: health_check}, {name: id, var: id}, {name: ipFiltering, var: ip_filtering}, {name: jwtVerifier, var: jwt_verifier}, {name: localHost, var: local_host}, {name: localScheme, var: local_scheme}, {name: maintenanceMode, var: maintenance_mode, required: true}, {name: matchingHeaders, var: matching_headers}, {name: matchingRoot, var: matching_root}, {name: metadata, var: metadata}, {name: name, var: name}, {name: overrideHost, var: override_host}, {name: privateApp, var: private_app, required: true}, {name: privatePatterns, var: private_patterns}, {name: publicPatterns, var: public_patterns}, {name: redirectToLocal, var: redirect_to_local}, {name: redirection, var: redirection}, {name: root, var: root}, {name: secComExcludedPatterns, var: sec_com_excluded_patterns}, {name: secComSettings, var: sec_com_settings}, {name: sendOtoroshiHeadersBack, var: send_otoroshi_headers_back}, {name: statsdConfig, var: statsd_config}, {name: subdomain, var: subdomain}, {name: targets, var: targets}, {name: transformerRef, var: transformer_ref}, {name: userFacing, var: user_facing}, {name: xForwardedHeaders, var: x_forwarded_headers}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, canary: $canary, additional_headers: $additional_headers, api: $api, auth_config_ref: $auth_config_ref, build_mode: $build_mode, chaos_config: $chaos_config, client_config: $client_config, client_validator_ref: $client_validator_ref, cors: $cors, domain: $domain, enabled: $enabled, enforce_secure_communication: $enforce_secure_communication, body_env: $body_env, force_https: $force_https, groups: $groups, gzip: $gzip, headers_verification: $headers_verification, health_check: $health_check, id: $id, ip_filtering: $ip_filtering, jwt_verifier: $jwt_verifier, local_host: $local_host, local_scheme: $local_scheme, maintenance_mode: $maintenance_mode, matching_headers: $matching_headers, matching_root: $matching_root, metadata: $metadata, name: $name, override_host: $override_host, private_app: $private_app, private_patterns: $private_patterns, public_patterns: $public_patterns, redirect_to_local: $redirect_to_local, redirection: $redirection, root: $root, sec_com_excluded_patterns: $sec_com_excluded_patterns, sec_com_settings: $sec_com_settings, send_otoroshi_headers_back: $send_otoroshi_headers_back, statsd_config: $statsd_config, subdomain: $subdomain, targets: $targets, transformer_ref: $transformer_ref, user_facing: $user_facing, x_forwarded_headers: $x_forwarded_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all api keys for the group of a service
#
# GET /api/services/{serviceId}/apikeys
# Returns: table<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: apiKeys
export def "api-keys" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/services/{serviceId}/apikeys"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new api key for a service
#
# POST /api/services/{serviceId}/apikeys
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: createApiKey
export def "create-api-key" [
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
  authorized_entities: list<string> # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  client_id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/services/{serviceId}/apikeys"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizedEntities, var: authorized_entities}, {name: clientId, var: client_id}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: dailyQuota, var: daily_quota}, {name: enabled, var: enabled, required: true}, {name: metadata, var: metadata}, {name: monthlyQuota, var: monthly_quota}, {name: throttlingQuota, var: throttling_quota}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, authorized_entities: $authorized_entities, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, daily_quota: $daily_quota, enabled: $enabled, metadata: $metadata, monthly_quota: $monthly_quota, throttling_quota: $throttling_quota
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an api key
#
# DELETE /api/services/{serviceId}/apikeys/{clientId}
# Returns: record<deleted: bool>
# operationId: deleteApiKey
export def "delete-api-key" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: apiKey
export def "api-key" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an api key with a diff
#
# PATCH /api/services/{serviceId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: patchApiKey
export def "patch-api-key" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an api key
#
# PUT /api/services/{serviceId}/apikeys/{clientId}
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: updateApiKey
export def "update-api-key" [
  service_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  authorized_entities: list<string> # The group/service ids (prefixed by group_ or service_ on which the key is authorized (e.g. [a string value])
  --body-client-id: string # The unique id of the Api Key. Usually 16 random alpha numerical characters, but can be anything (e.g. a string value) (spec name: clientId)
  client_name: string # The name of the api key, for humans ;-) (e.g. a string value)
  client_secret: string # The secret of the Api Key. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  --daily-quota: int # Authorized number of calls per day (format: int64, e.g. 123)
  --enabled: oneof<nothing, bool> # Whether or not the key is enabled. If disabled, resources won't be available to calls using this key (e.g. true)
  --metadata: record # Bunch of metadata for the key (e.g. {key: value})
  --monthly-quota: int # Authorized number of calls per month (format: int64, e.g. 123)
  --throttling-quota: int # Authorized number of calls per second, measured on 10 seconds (format: int64, e.g. 123)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/services/{serviceId}/apikeys/{clientId}"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizedEntities, var: authorized_entities}, {name: clientId, var: body_client_id, required: true}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: dailyQuota, var: daily_quota}, {name: enabled, var: enabled, required: true}, {name: metadata, var: metadata}, {name: monthlyQuota, var: monthly_quota}, {name: throttlingQuota, var: throttling_quota}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id, authorized_entities: $authorized_entities, body_client_id: $body_client_id, client_name: $client_name, client_secret: $client_secret, daily_quota: $daily_quota, enabled: $enabled, metadata: $metadata, monthly_quota: $monthly_quota, throttling_quota: $throttling_quota
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the group of an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}/group
# Returns: record<description: string, id: string, name: string>
# operationId: apiKeyGroup
export def "api-key-group" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}/group"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the quota state of an api key
#
# DELETE /api/services/{serviceId}/apikeys/{clientId}/quotas
# Returns: record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>
# operationId: resetApiKeyQuotas
export def "reset-api-key-quotas" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}/quotas"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the quota state of an api key
#
# GET /api/services/{serviceId}/apikeys/{clientId}/quotas
# Returns: record<authorizedCallsPerDay: int, authorizedCallsPerMonth: int, authorizedCallsPerSec: int, currentCallsPerDay: int, currentCallsPerMonth: int, currentCallsPerSec: int, remainingCallsPerDay: int, remainingCallsPerMonth: int, remainingCallsPerSec: int>
# operationId: apiKeyQuotas
export def "api-key-quotas" [
  service_id: string
  client_id: string
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
    path: "/api/services/{serviceId}/apikeys/{clientId}/quotas"
    path_params: [{name: serviceId, var: service_id}, {name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service descriptor target
#
# DELETE /api/services/{serviceId}/targets
# Returns: table<host: string, scheme: string>
# operationId: serviceDeleteTarget
export def "service-delete-target" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: delete
    path: "/api/services/{serviceId}/targets"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a service descriptor targets
#
# GET /api/services/{serviceId}/targets
# Returns: table<host: string, scheme: string>
# operationId: serviceTargets
export def "service-targets" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/services/{serviceId}/targets"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service descriptor targets
#
# PATCH /api/services/{serviceId}/targets
# Returns: table<host: string, scheme: string>
# operationId: updateServiceTargets
export def "update-service-targets" [
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
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/services/{serviceId}/targets"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a target to a service descriptor
#
# POST /api/services/{serviceId}/targets
# Returns: table<host: string, scheme: string>
# operationId: serviceAddTarget
export def "service-add-target" [
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
  host: string # The host on which the HTTP call will be forwarded. Can be a domain name, or an IP address. Can also have a port (format: hostname, e.g. www.google.com)
  scheme: string # The protocol used for communication. Can be http or https (e.g. a string value)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/services/{serviceId}/targets"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: host, var: host}, {name: scheme, var: scheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, host: $host, scheme: $scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service descriptor error template
#
# DELETE /api/services/{serviceId}/template
# Returns: record<deleted: bool>
# operationId: deleteServiceTemplate
export def "delete-service-template" [
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
    method: delete
    path: "/api/services/{serviceId}/template"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a service descriptor error template
#
# GET /api/services/{serviceId}/template
# Returns: record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>
# operationId: serviceTemplate
export def "service-template" [
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
    path: "/api/services/{serviceId}/template"
    path_params: [{name: serviceId, var: service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a service descriptor error template
#
# POST /api/services/{serviceId}/template
# Returns: record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>
# operationId: createServiceTemplate
export def "create-service-template" [
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
  messages: record # Map for custom messages (e.g. {key: value})
  --body-service-id: string # The Id of the service for which the error template is enabled (e.g. a string value) (spec name: serviceId)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  template_build: string # The html template for build page (e.g. a string value)
  template_maintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/services/{serviceId}/template"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: messages, var: messages}, {name: serviceId, var: body_service_id, required: true}, {name: template40x, var: template40x}, {name: template50x, var: template50x}, {name: templateBuild, var: template_build}, {name: templateMaintenance, var: template_maintenance}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, messages: $messages, body_service_id: $body_service_id, template40x: $template40x, template50x: $template50x, template_build: $template_build, template_maintenance: $template_maintenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an error template to a service descriptor
#
# PUT /api/services/{serviceId}/template
# Returns: record<messages: record, serviceId: string, template40x: string, template50x: string, templateBuild: string, templateMaintenance: string>
# operationId: updateServiceTemplate
export def "update-service-template" [
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
  messages: record # Map for custom messages (e.g. {key: value})
  --body-service-id: string # The Id of the service for which the error template is enabled (e.g. a string value) (spec name: serviceId)
  template40x: string # The html template for 40x errors (e.g. a string value)
  template50x: string # The html template for 50x errors (e.g. a string value)
  template_build: string # The html template for build page (e.g. a string value)
  template_maintenance: string # The html template for maintenance page (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/services/{serviceId}/template"
    path_params: [{name: serviceId, var: service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: messages, var: messages}, {name: serviceId, var: body_service_id, required: true}, {name: template40x, var: template40x}, {name: template50x, var: template50x}, {name: templateBuild, var: template_build}, {name: templateMaintenance, var: template_maintenance}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service_id: $service_id, messages: $messages, body_service_id: $body_service_id, template40x: $template40x, template50x: $template50x, template_build: $template_build, template_maintenance: $template_maintenance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start the Snow Monkey
#
# POST /api/snowmonkey/_start
# Returns: record<done: bool>
# operationId: startSnowMonkey
export def "start-snow-monkey" [
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
    path: "/api/snowmonkey/_start"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop the Snow Monkey
#
# POST /api/snowmonkey/_stop
# Returns: record<done: bool>
# operationId: stopSnowMonkey
export def "stop-snow-monkey" [
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
    path: "/api/snowmonkey/_stop"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current Snow Monkey config
#
# GET /api/snowmonkey/config
# Returns: record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>
# operationId: getSnowMonkeyConfig
export def "get-snow-monkey-config" [
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
    path: "/api/snowmonkey/config"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current Snow Monkey config
#
# PATCH /api/snowmonkey/config
# Returns: record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>
# operationId: patchSnowMonkey
export def "patch-snow-monkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api/snowmonkey/config"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current Snow Monkey config
#
# PUT /api/snowmonkey/config
# Returns: record<chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, dryRun: bool, enabled: bool, includeUserFacingDescriptors: bool, outageDurationFrom: int, outageDurationTo: int, outageStrategy: string, startTime: string, stopTime: string, targetGroups: list<string>, timesPerDay: int>
# operationId: updateSnowMonkey
export def "update-snow-monkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The descriptoin of the group (e.g. a string value)
  id: string # The unique id of the group. Usually 64 random alpha numerical characters, but can be anything (e.g. a string value)
  name: string # The name of the group (e.g. a string value)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/snowmonkey/config"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: id, var: id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    description: $description, id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset Snow Monkey Outages for the day
#
# DELETE /api/snowmonkey/outages
# Returns: record<done: bool>
# operationId: resetSnowMonkey
export def "reset-snow-monkey" [
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
    path: "/api/snowmonkey/outages"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all current Snow Monkey ourages
#
# GET /api/snowmonkey/outages
# Returns: table<descriptorId: string, descriptorName: string, duration: int, until: string>
# operationId: getSnowMonkeyOutages
export def "get-snow-monkey-outages" [
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
    path: "/api/snowmonkey/outages"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all global JWT verifiers
#
# GET /api/verifiers
# Returns: table<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>
# operationId: findAllGlobalJwtVerifiers
export def "find-all-global-jwt-verifiers" [
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
    path: "/api/verifiers"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one global JWT verifiers
#
# POST /api/verifiers
# Returns: record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>
# operationId: createGlobalJwtVerifier
export def "create-global-jwt-verifier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algo_settings: any
  desc: string # Verifier description (e.g. a string value)
  --enabled: oneof<nothing, bool> # Is it enabled (e.g. true)
  id: string # Verifier id (e.g. a string value)
  name: string # Verifier name (e.g. a string value)
  source: any
  strategy: any
  --strict: oneof<nothing, bool> # Does it fail if JWT not found (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/verifiers"
    body: {content_type: "application/json", kind: json, fields: [{name: algoSettings, var: algo_settings}, {name: desc, var: desc}, {name: enabled, var: enabled, required: true}, {name: id, var: id}, {name: name, var: name}, {name: source, var: source}, {name: strategy, var: strategy}, {name: strict, var: strict, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    algo_settings: $algo_settings, desc: $desc, enabled: $enabled, id: $id, name: $name, source: $source, strategy: $strategy, strict: $strict
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete one global JWT verifiers
#
# DELETE /api/verifiers/{verifierId}
# Returns: record<deleted: bool>
# operationId: deleteGlobalJwtVerifier
export def "delete-global-jwt-verifier" [
  verifier_id: string
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
    path: "/api/verifiers/{verifierId}"
    path_params: [{name: verifierId, var: verifier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    verifier_id: $verifier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get one global JWT verifiers
#
# GET /api/verifiers/{verifierId}
# Returns: record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>
# operationId: findGlobalJwtVerifiersById
export def "find-global-jwt-verifiers-by-id" [
  verifier_id: string
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
    path: "/api/verifiers/{verifierId}"
    path_params: [{name: verifierId, var: verifier_id}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    verifier_id: $verifier_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one global JWT verifiers
#
# PATCH /api/verifiers/{verifierId}
# Returns: record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>
# operationId: patchGlobalJwtVerifier
export def "patch-global-jwt-verifier" [
  verifier_id: string
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
    path: "/api/verifiers/{verifierId}"
    path_params: [{name: verifierId, var: verifier_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    verifier_id: $verifier_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update one global JWT verifiers
#
# PUT /api/verifiers/{verifierId}
# Returns: record<algoSettings: any, desc: string, enabled: bool, id: string, name: string, source: any, strategy: any, strict: bool>
# operationId: updateGlobalJwtVerifier
export def "update-global-jwt-verifier" [
  verifier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algo_settings: any
  desc: string # Verifier description (e.g. a string value)
  --enabled: oneof<nothing, bool> # Is it enabled (e.g. true)
  id: string # Verifier id (e.g. a string value)
  name: string # Verifier name (e.g. a string value)
  source: any
  strategy: any
  --strict: oneof<nothing, bool> # Does it fail if JWT not found (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/verifiers/{verifierId}"
    path_params: [{name: verifierId, var: verifier_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: algoSettings, var: algo_settings}, {name: desc, var: desc}, {name: enabled, var: enabled, required: true}, {name: id, var: id}, {name: name, var: name}, {name: source, var: source}, {name: strategy, var: strategy}, {name: strict, var: strict, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    verifier_id: $verifier_id, algo_settings: $algo_settings, desc: $desc, enabled: $enabled, id: $id, name: $name, source: $source, strategy: $strategy, strict: $strict
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return current Otoroshi health
#
# GET /health
# Returns: record<datastore: string, otoroshi: string>
# operationId: health
export def "health" [
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
    path: "/health"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all environments
#
# GET /lines
# Returns: string
# operationId: allLines
export def "all-lines" [
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
    path: "/lines"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all services for an environment
#
# GET /lines/{line}/services
# Returns: table<Canary: record<enabled: bool, root: string, targets: list, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record, enabled: bool, largeRequestFaultConfig: record, largeResponseFaultConfig: record, latencyInjectionFaultConfig: record>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list, allowMethods: list, allowOrigin: string, enabled: bool, excludedPatterns: list, exposeHeaders: list, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list, whiteList: list>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list, whitelist: list>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: list<record>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: servicesForALine
export def "services-for-a-line" [
  line: string
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
    path: "/lines/{line}/services"
    path_params: [{name: line, var: line}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    line: $line
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a template of an Otoroshi Api Key
#
# GET /new/apikey
# Returns: record<authorizedEntities: list<string>, clientId: string, clientName: string, clientSecret: string, dailyQuota: int, enabled: bool, metadata: record, monthlyQuota: int, throttlingQuota: int>
# operationId: initiateApiKey
export def "initiate-api-key" [
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
    path: "/new/apikey"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a template of an Otoroshi service group
#
# GET /new/group
# Returns: record<description: string, id: string, name: string>
# operationId: initiateServiceGroup
export def "initiate-service-group" [
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
    path: "/new/group"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a template of an Otoroshi service descriptor
#
# GET /new/service
# Returns: record<Canary: record<enabled: bool, root: string, targets: list<record>, traffic: int>, additionalHeaders: record, api: record<exposeApi: bool, openApiDescriptorUrl: string>, authConfigRef: string, buildMode: bool, chaosConfig: record<badResponsesFaultConfig: record<ratio: float, responses: list>, enabled: bool, largeRequestFaultConfig: record<additionalRequestSize: int, ratio: float>, largeResponseFaultConfig: record<additionalRequestSize: int, ratio: float>, latencyInjectionFaultConfig: record<from: int, ratio: float, to: int>>, clientConfig: record<backoffFactor: int, callTimeout: int, globalTimeout: int, maxErrors: int, retries: int, retryInitialDelay: int, sampleInterval: int, useCircuitBreaker: bool>, clientValidatorRef: string, cors: record<allowCredentials: bool, allowHeaders: list<string>, allowMethods: list<string>, allowOrigin: string, enabled: bool, excludedPatterns: list<string>, exposeHeaders: list<string>, maxAge: int>, domain: string, enabled: bool, enforceSecureCommunication: bool, env: string, forceHttps: bool, groups: list<string>, gzip: record<blackList: list<string>, bufferSize: int, chunkedThreshold: int, compressionLevel: int, enabled: bool, excludedPatterns: list<string>, whiteList: list<string>>, headersVerification: record, healthCheck: record<enabled: bool, url: string>, id: string, ipFiltering: record<blacklist: list<string>, whitelist: list<string>>, jwtVerifier: any, localHost: string, localScheme: string, maintenanceMode: bool, matchingHeaders: record, matchingRoot: string, metadata: record, name: string, overrideHost: bool, privateApp: bool, privatePatterns: list<string>, publicPatterns: list<string>, redirectToLocal: bool, redirection: record<code: int, enabled: bool, to: string>, root: string, secComExcludedPatterns: list<string>, secComSettings: any, sendOtoroshiHeadersBack: bool, statsdConfig: record<datadog: bool, host: string, port: int>, subdomain: string, targets: table<host: string, scheme: string>, transformerRef: string, userFacing: bool, xForwardedHeaders: bool>
# operationId: initiateService
export def "initiate-service" [
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
    path: "/new/service"
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
