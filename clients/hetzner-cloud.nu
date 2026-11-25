# Auto-generated client for Hetzner Cloud API v1.0.0
# Source: https://api.apis.guru/v2/specs/hetzner.cloud/1.0.0/openapi.json
# Auth: --token flag or $env.HETZNER_CLOUD_API_TOKEN

const CLIENT = {
  base_url: "https://api.hetzner.cloud/v1"
  token_env_var: "HETZNER_CLOUD_API_TOKEN"
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

def base-url-completer [] { ["https://api.hetzner.cloud/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["command" "command:asc" "command:desc" "finished" "finished:asc" "finished:desc" "id" "id:asc" "id:desc" "progress" "progress:asc" "progress:desc" "started" "started:asc" "started:desc" "status" "status:asc" "status:desc"] }
def status-completer [] { ["error" "running" "success"] }
def sort-completer-1 [] { ["created" "created:asc" "created:desc" "id" "id:asc" "id:desc" "name" "name:asc" "name:desc"] }
def type-completer [] { ["managed" "uploaded"] }
def sort-completer-2 [] { ["created" "created:asc" "created:desc" "id" "id:asc" "id:desc"] }
def type-completer-1 [] { ["ipv4" "ipv6"] }
def type-completer-2 [] { ["app" "backup" "snapshot" "system"] }
def status-completer-1 [] { ["available" "creating"] }
def type-completer-3 [] { ["snapshot"] }
def protocol-completer [] { ["http" "https" "tcp"] }
def type-completer-4 [] { ["ip" "label_selector" "server"] }
def type-completer-5 [] { ["least_connections" "round_robin"] }
def type-completer-6 [] { ["bandwidth" "connections_per_second" "open_connections" "requests_per_second"] }
def type-completer-7 [] { ["cloud" "server" "vswitch"] }
def type-completer-8 [] { ["spread"] }
def assignee-type-completer [] { ["server"] }
def status-completer-2 [] { ["deleting" "initializing" "migrating" "off" "rebuilding" "running" "starting" "stopping" "unknown"] }
def type-completer-9 [] { ["backup" "snapshot"] }
def type-completer-10 [] { ["linux32" "linux64"] }
def type-completer-11 [] { ["cpu" "disk" "network"] }
def sort-completer-3 [] { ["id" "id:asc" "id:desc" "name" "name:asc" "name:desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    get-actions-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-certificates: "record<certificates: table<certificate: string, created: string, domain_names: list, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record, type: string, used_by: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-certificates: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>"
    get-certificates-id: "record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>"
    put-certificates-id: "record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>"
    get-certificates-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-certificates-id-actions-retry: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-certificates-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-datacenters: "record<datacenters: table<description: string, id: int, location: record, name: string, server_types: record>, recommendation: float>"
    get-datacenters-id: "record<datacenter: record<description: string, id: int, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, server_types: record<available: list, available_for_migration: list, supported: list>>>"
    get-firewalls: "record<firewalls: table<applied_to: list, created: string, id: int, labels: record, name: string, rules: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-firewalls: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>"
    get-firewalls-id: "record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>"
    put-firewalls-id: "record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>"
    get-firewalls-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-firewalls-id-actions-apply-to-resources: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-firewalls-id-actions-remove-from-resources: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-firewalls-id-actions-set-rules: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    get-firewalls-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-floating-ips: "record<floating_ips: table<blocked: bool, created: string, description: string, dns_ptr: list, home_location: record, id: int, ip: string, labels: record, name: string, protection: record, server: int, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-floating-ips: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>"
    get-floating-ips-id: "record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>"
    put-floating-ips-id: "record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>"
    get-floating-ips-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>>"
    post-floating-ips-id-actions-assign: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-floating-ips-id-actions-change-dns-ptr: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-floating-ips-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-floating-ips-id-actions-unassign: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-floating-ips-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-images: "record<images: table<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    get-images-id: "record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>"
    put-images-id: "record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>"
    get-images-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-images-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-images-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-isos: "record<isos: table<deprecated: string, description: string, id: int, name: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    get-isos-id: "record<iso: record<deprecated: string, description: string, id: int, name: string, type: string>>"
    get-load-balancer-types: "record<load_balancer_types: table<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>>"
    get-load-balancer-types-id: "record<load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list<record>>>"
    get-load-balancers: "record<load_balancers: table<algorithm: record, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record, location: record, name: string, outgoing_traffic: int, private_net: list, protection: record, public_net: record, services: list, targets: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-load-balancers: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>"
    get-load-balancers-id: "record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>"
    put-load-balancers-id: "record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>"
    get-load-balancers-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-load-balancers-id-actions-add-service: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-add-target: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-attach-to-network: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-change-algorithm: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-change-dns-ptr: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-change-type: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-delete-service: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-detach-from-network: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-disable-public-interface: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-enable-public-interface: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-remove-target: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-load-balancers-id-actions-update-service: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-load-balancers-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-load-balancers-id-metrics: "record<metrics: record<end: string, start: string, step: float, time_series: record>>"
    get-locations: "record<locations: table<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>>"
    get-locations-id: "record<location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>>"
    get-networks: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, networks: table<created: string, id: int, ip_range: string, labels: record, load_balancers: list, name: string, protection: record, routes: list, servers: list, subnets: list>>"
    post-networks: "record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>"
    get-networks-id: "record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>"
    put-networks-id: "record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>"
    get-networks-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-networks-id-actions-add-route: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-networks-id-actions-add-subnet: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-networks-id-actions-change-ip-range: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-networks-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-networks-id-actions-delete-route: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-networks-id-actions-delete-subnet: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-networks-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-placement-groups: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, placement_groups: table<created: string, id: int, labels: record, name: string, servers: list, type: string>>"
    post-placement-groups: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>"
    get-placement-groups-id: "record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>"
    put-placement-groups-id: "record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>"
    get-pricing: "record<pricing: record<currency: string, floating_ip: record<price_monthly: record>, floating_ips: list<record>, image: record<price_per_gb_month: record>, load_balancer_types: list<record>, primary_ips: list<record>, server_backup: record<percentage: string>, server_types: list<record>, traffic: record<price_per_tb: record>, vat_rate: string, volume: record<price_per_gb_month: record>>>"
    get-primary-ips: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, primary_ips: table<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record, dns_ptr: list, id: int, ip: string, labels: record, name: string, protection: record, type: string>>"
    post-primary-ips: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>"
    get-primary-ips-id: "record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>"
    put-primary-ips-id: "record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>"
    post-primary-ips-id-actions-assign: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-primary-ips-id-actions-change-dns-ptr: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-primary-ips-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-primary-ips-id-actions-unassign: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-server-types: "record<server_types: table<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list, storage_type: string>>"
    get-server-types-id: "record<server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list<record>, storage_type: string>>"
    get-servers: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, servers: table<backup_window: string, created: string, datacenter: record, id: int, image: record, included_traffic: float, ingoing_traffic: float, iso: record, labels: record, load_balancers: list, locked: bool, name: string, outgoing_traffic: float, placement_group: record, primary_disk_size: float, private_net: list, protection: record, public_net: record, rescue_enabled: bool, server_type: record, status: string, volumes: list>>"
    post-servers: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, root_password: string, server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>"
    delete-servers-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-servers-id: "record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>"
    put-servers-id: "record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>"
    get-servers-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-servers-id-actions-add-to-placement-group: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-attach-iso: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-attach-to-network: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-change-alias-ips: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-change-dns-ptr: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-change-type: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-create-image: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>"
    post-servers-id-actions-detach-from-network: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-detach-iso: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-disable-backup: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-disable-rescue: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-enable-backup: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-enable-rescue: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>"
    post-servers-id-actions-poweroff: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-poweron: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-reboot: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-rebuild: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>"
    post-servers-id-actions-remove-from-placement-group: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-request-console: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, password: string, wss_url: string>"
    post-servers-id-actions-reset: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-servers-id-actions-reset-password: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>"
    post-servers-id-actions-shutdown: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-servers-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-servers-id-metrics: "record<metrics: record<end: string, start: string, step: float, time_series: record>>"
    get-ssh-keys: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, ssh_keys: table<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>"
    post-ssh-keys: "record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>"
    get-ssh-keys-id: "record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>"
    put-ssh-keys-id: "record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>"
    get-volumes: "record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, volumes: table<created: string, format: string, id: int, labels: record, linux_device: string, location: record, name: string, protection: record, server: int, size: float, status: string>>"
    post-volumes: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>"
    get-volumes-id: "record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>"
    put-volumes-id: "record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>"
    get-volumes-id-actions: "record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>"
    post-volumes-id-actions-attach: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-volumes-id-actions-change-protection: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-volumes-id-actions-detach: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    post-volumes-id-actions-resize: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
    get-volumes-id-actions-action-id: "record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-actions" "get-actions-id" "get-certificates" "post-certificates" "delete-certificates-id" "get-certificates-id" "put-certificates-id" "get-certificates-id-actions" "post-certificates-id-actions-retry" "get-certificates-id-actions-action-id" "get-datacenters" "get-datacenters-id" "get-firewalls" "post-firewalls" "delete-firewalls-id" "get-firewalls-id" "put-firewalls-id" "get-firewalls-id-actions" "post-firewalls-id-actions-apply-to-resources" "post-firewalls-id-actions-remove-from-resources" "post-firewalls-id-actions-set-rules" "get-firewalls-id-actions-action-id" "get-floating-ips" "post-floating-ips" "delete-floating-ips-id" "get-floating-ips-id" "put-floating-ips-id" "get-floating-ips-id-actions" "post-floating-ips-id-actions-assign" "post-floating-ips-id-actions-change-dns-ptr" "post-floating-ips-id-actions-change-protection" "post-floating-ips-id-actions-unassign" "get-floating-ips-id-actions-action-id" "get-images" "delete-images-id" "get-images-id" "put-images-id" "get-images-id-actions" "post-images-id-actions-change-protection" "get-images-id-actions-action-id" "get-isos" "get-isos-id" "get-load-balancer-types" "get-load-balancer-types-id" "get-load-balancers" "post-load-balancers" "delete-load-balancers-id" "get-load-balancers-id" "put-load-balancers-id" "get-load-balancers-id-actions" "post-load-balancers-id-actions-add-service" "post-load-balancers-id-actions-add-target" "post-load-balancers-id-actions-attach-to-network" "post-load-balancers-id-actions-change-algorithm" "post-load-balancers-id-actions-change-dns-ptr" "post-load-balancers-id-actions-change-protection" "post-load-balancers-id-actions-change-type" "post-load-balancers-id-actions-delete-service" "post-load-balancers-id-actions-detach-from-network" "post-load-balancers-id-actions-disable-public-interface" "post-load-balancers-id-actions-enable-public-interface" "post-load-balancers-id-actions-remove-target" "post-load-balancers-id-actions-update-service" "get-load-balancers-id-actions-action-id" "get-load-balancers-id-metrics" "get-locations" "get-locations-id" "get-networks" "post-networks" "delete-networks-id" "get-networks-id" "put-networks-id" "get-networks-id-actions" "post-networks-id-actions-add-route" "post-networks-id-actions-add-subnet" "post-networks-id-actions-change-ip-range" "post-networks-id-actions-change-protection" "post-networks-id-actions-delete-route" "post-networks-id-actions-delete-subnet" "get-networks-id-actions-action-id" "get-placement-groups" "post-placement-groups" "delete-placement-groups-id" "get-placement-groups-id" "put-placement-groups-id" "get-pricing" "get-primary-ips" "post-primary-ips" "delete-primary-ips-id" "get-primary-ips-id" "put-primary-ips-id" "post-primary-ips-id-actions-assign" "post-primary-ips-id-actions-change-dns-ptr" "post-primary-ips-id-actions-change-protection" "post-primary-ips-id-actions-unassign" "get-server-types" "get-server-types-id" "get-servers" "post-servers" "delete-servers-id" "get-servers-id" "put-servers-id" "get-servers-id-actions" "post-servers-id-actions-add-to-placement-group" "post-servers-id-actions-attach-iso" "post-servers-id-actions-attach-to-network" "post-servers-id-actions-change-alias-ips" "post-servers-id-actions-change-dns-ptr" "post-servers-id-actions-change-protection" "post-servers-id-actions-change-type" "post-servers-id-actions-create-image" "post-servers-id-actions-detach-from-network" "post-servers-id-actions-detach-iso" "post-servers-id-actions-disable-backup" "post-servers-id-actions-disable-rescue" "post-servers-id-actions-enable-backup" "post-servers-id-actions-enable-rescue" "post-servers-id-actions-poweroff" "post-servers-id-actions-poweron" "post-servers-id-actions-reboot" "post-servers-id-actions-rebuild" "post-servers-id-actions-remove-from-placement-group" "post-servers-id-actions-request-console" "post-servers-id-actions-reset" "post-servers-id-actions-reset-password" "post-servers-id-actions-shutdown" "get-servers-id-actions-action-id" "get-servers-id-metrics" "get-ssh-keys" "post-ssh-keys" "delete-ssh-keys-id" "get-ssh-keys-id" "put-ssh-keys-id" "get-volumes" "post-volumes" "delete-volumes-id" "get-volumes-id" "put-volumes-id" "get-volumes-id-actions" "post-volumes-id-actions-attach" "post-volumes-id-actions-change-protection" "post-volumes-id-actions-detach" "post-volumes-id-actions-resize" "get-volumes-id-actions-action-id" "commands"] | sort) } | get name | first)
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

# Get all Actions
#
# GET /actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Can be used multiple times, the response will contain only Actions with specified IDs
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/actions"
    query: [{name: id, var: id}, {name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action
#
# GET /actions/{id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-actions-id" [
  id: int
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
    path: "/actions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Certificates
#
# GET /certificates
# Returns: record<certificates: table<certificate: string, created: string, domain_names: list, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record, type: string, used_by: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --type: string@type-completer # Can be used multiple times. The response will only contain Certificates matching the type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates"
    query: [{name: sort, var: sort}, {name: name, var: name}, {name: label_selector, var: label_selector}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, name: $name, label_selector: $label_selector, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Certificate
#
# POST /certificates
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>
export def "post-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate: string # Certificate and chain in PEM format, in order so that each record directly certifies the one preceding. Required for type `uploaded` Certificates. (e.g. -----BEGIN CERTIFICATE----- ...)
  --domain-names: list<string> # Domains and subdomains that should be contained in the Certificate issued by *Let's Encrypt*. Required for type `managed` Certificates.
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the Certificate (e.g. my website cert)
  --private-key: string # Certificate key in PEM format. Required for type `uploaded` Certificates. (e.g. -----BEGIN PRIVATE KEY----- ...)
  --type: string@type-completer # Choose between uploading a Certificate in PEM format or requesting a managed *Let's Encrypt* Certificate. If omitted defaults to `uploaded`. (e.g. uploaded)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates"
    body: {content_type: "application/json", kind: json, fields: [{name: certificate, var: certificate}, {name: domain_names, var: domain_names}, {name: labels, var: labels}, {name: name, var: name}, {name: private_key, var: private_key}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    certificate: $certificate, domain_names: $domain_names, labels: $labels, name: $name, private_key: $private_key, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Certificate
#
# DELETE /certificates/{id}
export def "delete-certificates-id" [
  id: int
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
    path: "/certificates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Certificate
#
# GET /certificates/{id}
# Returns: record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>
export def "get-certificates-id" [
  id: int
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
    path: "/certificates/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Certificate
#
# PUT /certificates/{id}
# Returns: record<certificate: record<certificate: string, created: string, domain_names: list<string>, fingerprint: string, id: int, labels: record, name: string, not_valid_after: string, not_valid_before: string, status: record<error: record, issuance: string, renewal: string>, type: string, used_by: list<record>>>
export def "put-certificates-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Certificate name (e.g. my website cert)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/certificates/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Certificate
#
# GET /certificates/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-certificates-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retry Issuance or Renewal
#
# POST /certificates/{id}/actions/retry
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-certificates-id-actions-retry" [
  id: int
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
    path: "/certificates/{id}/actions/retry"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Certificate
#
# GET /certificates/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-certificates-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/certificates/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Datacenters
#
# GET /datacenters
# Returns: record<datacenters: table<description: string, id: int, location: record, name: string, server_types: record>, recommendation: float>
export def "get-datacenters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter Datacenters by their name. The response will only contain the Datacenter matching the specified name. When the name does not match the Datacenter name format, an `invalid_input` error is returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datacenters"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Datacenter
#
# GET /datacenters/{id}
# Returns: record<datacenter: record<description: string, id: int, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, server_types: record<available: list, available_for_migration: list, supported: list>>>
export def "get-datacenters-id" [
  id: int
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
    path: "/datacenters/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Firewalls
#
# GET /firewalls
# Returns: record<firewalls: table<applied_to: list, created: string, id: int, labels: record, name: string, rules: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-firewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/firewalls"
    query: [{name: sort, var: sort}, {name: name, var: name}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, name: $name, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Firewall
#
# POST /firewalls
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>
export def "post-firewalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-to: list # Resources the Firewall should be applied to after creation — item shape: {label_selector?: record, server?: record, type: "server"|"label_selector"}
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the Firewall (e.g. Corporate Intranet Protection)
  --rules: list # Array of rules (e.g. [{direction: in, port: 80, protocol: tcp, source_ips: [28.239.13.1/32, 28.239.14.0/24, ff21:1eac:9a3b:ee58:5ca:990c:8bc9:c03b/128]}]) — item shape: {description?: string, destination_ips?: list<string>, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/firewalls"
    body: {content_type: "application/json", kind: json, fields: [{name: apply_to, var: apply_to}, {name: labels, var: labels}, {name: name, var: name}, {name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    apply_to: $apply_to, labels: $labels, name: $name, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Firewall
#
# DELETE /firewalls/{id}
export def "delete-firewalls-id" [
  id: int
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
    path: "/firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Firewall
#
# GET /firewalls/{id}
# Returns: record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>
export def "get-firewalls-id" [
  id: int
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
    path: "/firewalls/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Firewall
#
# PUT /firewalls/{id}
# Returns: record<firewall: record<applied_to: list<record>, created: string, id: int, labels: record, name: string, rules: list<record>>>
export def "put-firewalls-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Firewall name (e.g. new-name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/firewalls/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Firewall
#
# GET /firewalls/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-firewalls-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/firewalls/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Apply to Resources
#
# POST /firewalls/{id}/actions/apply_to_resources
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "post-firewalls-id-actions-apply-to-resources" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  apply_to: list # Resources the Firewall should be applied to — item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/firewalls/{id}/actions/apply_to_resources"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apply_to, var: apply_to}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, apply_to: $apply_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove from Resources
#
# POST /firewalls/{id}/actions/remove_from_resources
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "post-firewalls-id-actions-remove-from-resources" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  remove_from: list # Resources the Firewall should be removed from — item shape: {label_selector?: record, server?: record, type?: "server"|"label_selector"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/firewalls/{id}/actions/remove_from_resources"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: remove_from, var: remove_from}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, remove_from: $remove_from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Rules
#
# POST /firewalls/{id}/actions/set_rules
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "post-firewalls-id-actions-set-rules" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # Array of rules — item shape: {description?: string, destination_ips?: list<string>, direction: "in"|"out", port?: string, protocol: "tcp"|"udp"|"icmp"|"esp"|"gre", source_ips?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/firewalls/{id}/actions/set_rules"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rules, var: rules}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, rules: $rules
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Firewall
#
# GET /firewalls/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-firewalls-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/firewalls/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Floating IPs
#
# GET /floating_ips
# Returns: record<floating_ips: table<blocked: bool, created: string, description: string, dns_ptr: list, home_location: record, id: int, ip: string, labels: record, name: string, protection: record, server: int, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-floating-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter Floating IPs by their name. The response will only contain the Floating IP matching the specified name.
  --label-selector: string # Can be used to filter Floating IPs by labels. The response will only contain Floating IPs matching the label selector.
  --sort: string@sort-completer-2 # Can be used multiple times. Choices id id:asc id:desc created created:asc created:desc
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/floating_ips"
    query: [{name: name, var: name}, {name: label_selector, var: label_selector}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, label_selector: $label_selector, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Floating IP
#
# POST /floating_ips
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>
export def "post-floating-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Web Frontend
  --home-location: string # Home Location (routing is optimized for that Location). Only optional if Server argument is passed. (e.g. fsn1)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # e.g. Web Frontend
  --server: int # Server to assign the Floating IP to (e.g. 42)
  type: string@type-completer-1 # Floating IP type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/floating_ips"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: home_location, var: home_location}, {name: labels, var: labels}, {name: name, var: name}, {name: server, var: server}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    description: $description, home_location: $home_location, labels: $labels, name: $name, server: $server, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Floating IP
#
# DELETE /floating_ips/{id}
export def "delete-floating-ips-id" [
  id: int
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
    path: "/floating_ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Floating IP
#
# GET /floating_ips/{id}
# Returns: record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>
export def "get-floating-ips-id" [
  id: int
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
    path: "/floating_ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Floating IP
#
# PUT /floating_ips/{id}
# Returns: record<floating_ip: record<blocked: bool, created: string, description: string, dns_ptr: list<record>, home_location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, server: int, type: string>>
export def "put-floating-ips-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # New Description to set (e.g. Web Frontend)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New unique name to set (e.g. Web Frontend)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/floating_ips/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Floating IP
#
# GET /floating_ips/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>>
export def "get-floating-ips-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/floating_ips/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a Floating IP to a Server
#
# POST /floating_ips/{id}/actions/assign
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-floating-ips-id-actions-assign" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  server: int # ID of the Server the Floating IP shall be assigned to (e.g. 42)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/floating_ips/{id}/actions/assign"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: server, var: server}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change reverse DNS entry for a Floating IP
#
# POST /floating_ips/{id}/actions/change_dns_ptr
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-floating-ips-id-actions-change-dns-ptr" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, will reset to original default value if `null` (nullable, e.g. server02.example.com)
  ip: string # IP address for which to set the reverse DNS entry (e.g. 1.2.3.4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/floating_ips/{id}/actions/change_dns_ptr"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dns_ptr, var: dns_ptr}, {name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, dns_ptr: $dns_ptr, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Floating IP Protection
#
# POST /floating_ips/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-floating-ips-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Floating IP from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/floating_ips/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign a Floating IP
#
# POST /floating_ips/{id}/actions/unassign
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-floating-ips-id-actions-unassign" [
  id: int
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
    path: "/floating_ips/{id}/actions/unassign"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Floating IP
#
# GET /floating_ips/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-floating-ips-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/floating_ips/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Images
#
# GET /images
# Returns: record<images: table<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Can be used multiple times.
  --type: string@type-completer-2 # Can be used multiple times.
  --status: string@status-completer-1 # Can be used multiple times. The response will only contain Images matching the status.
  --bound-to: string # Can be used multiple times. Server ID linked to the Image. Only available for Images of type `backup`
  --include-deprecated: oneof<nothing, bool> # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images"
    query: [{name: sort, var: sort}, {name: type, var: type}, {name: status, var: status}, {name: bound_to, var: bound_to}, {name: include_deprecated, var: include_deprecated}, {name: name, var: name}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, type: $type, status: $status, bound_to: $bound_to, include_deprecated: $include_deprecated, name: $name, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Image
#
# DELETE /images/{id}
export def "delete-images-id" [
  id: int
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
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Image
#
# GET /images/{id}
# Returns: record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>
export def "get-images-id" [
  id: int
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
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Image
#
# PUT /images/{id}
# Returns: record<image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>
export def "put-images-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # New description of Image (e.g. My new Image description)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --type: string@type-completer-3 # Destination Image type to convert to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/images/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: labels, var: labels}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, labels: $labels, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for an Image
#
# GET /images/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-images-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Image Protection
#
# POST /images/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-images-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the snapshot from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for an Image
#
# GET /images/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-images-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/images/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all ISOs
#
# GET /isos
# Returns: record<isos: table<deprecated: string, description: string, id: int, name: string, type: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-isos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter ISOs by their name. The response will only contain the ISO matching the specified name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/isos"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an ISO
#
# GET /isos/{id}
# Returns: record<iso: record<deprecated: string, description: string, id: int, name: string, type: string>>
export def "get-isos-id" [
  id: int
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
    path: "/isos/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Load Balancer Types
#
# GET /load_balancer_types
# Returns: record<load_balancer_types: table<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>>
export def "get-load-balancer-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter Load Balancer types by their name. The response will only contain the Load Balancer type matching the specified name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/load_balancer_types"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Load Balancer Type
#
# GET /load_balancer_types/{id}
# Returns: record<load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list<record>>>
export def "get-load-balancer-types-id" [
  id: int
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
    path: "/load_balancer_types/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Load Balancers
#
# GET /load_balancers
# Returns: record<load_balancers: table<algorithm: record, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record, location: record, name: string, outgoing_traffic: int, private_net: list, protection: record, public_net: record, services: list, targets: list>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/load_balancers"
    query: [{name: sort, var: sort}, {name: name, var: name}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, name: $name, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Load Balancer
#
# POST /load_balancers
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>
export def "post-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: record # Algorithm of the Load Balancer — shape: {type: "round_robin"|"least_connections"}
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  load_balancer_type: string # ID or name of the Load Balancer type this Load Balancer should be created with (e.g. lb11)
  --location: string # ID or name of Location to create Load Balancer in
  name: string # Name of the Load Balancer (e.g. Web Frontend)
  --network: int # ID of the network the Load Balancer should be attached to on creation (e.g. 123)
  --network-zone: string # Name of network zone (e.g. eu-central)
  --public-interface: oneof<nothing, bool> # Enable or disable the public interface of the Load Balancer (e.g. true)
  --services: list # Array of services — item shape: {destination_port: int, health_check: record, http?: record, listen_port: int, protocol: "tcp"|"http"|"https", proxyprotocol: bool}
  --targets: list # Array of targets — item shape: {health_status?: list, ip?: record, label_selector?: record, server?: record, targets?: list, type: "server"|"label_selector"|"ip", use_private_ip?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: labels, var: labels}, {name: load_balancer_type, var: load_balancer_type}, {name: location, var: location}, {name: name, var: name}, {name: network, var: network}, {name: network_zone, var: network_zone}, {name: public_interface, var: public_interface}, {name: services, var: services}, {name: targets, var: targets}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    algorithm: $algorithm, labels: $labels, load_balancer_type: $load_balancer_type, location: $location, name: $name, network: $network, network_zone: $network_zone, public_interface: $public_interface, services: $services, targets: $targets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Load Balancer
#
# DELETE /load_balancers/{id}
export def "delete-load-balancers-id" [
  id: int
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
    path: "/load_balancers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Load Balancer
#
# GET /load_balancers/{id}
# Returns: record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>
export def "get-load-balancers-id" [
  id: int
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
    path: "/load_balancers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Load Balancer
#
# PUT /load_balancers/{id}
# Returns: record<load_balancer: record<algorithm: record<type: string>, created: string, id: int, included_traffic: int, ingoing_traffic: int, labels: record, load_balancer_type: record<deprecated: string, description: string, id: float, max_assigned_certificates: float, max_connections: float, max_services: float, max_targets: float, name: string, prices: list>, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, outgoing_traffic: int, private_net: list<record>, protection: record<delete: bool>, public_net: record<enabled: bool, ipv4: record, ipv6: record>, services: list<record>, targets: list<record>>>
export def "put-load-balancers-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New Load Balancer name (e.g. new-name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/load_balancers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Load Balancer
#
# GET /load_balancers/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-load-balancers-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/load_balancers/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Service
#
# POST /load_balancers/{id}/actions/add_service
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-add-service" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_port: int # Port the Load Balancer will balance to (e.g. 80)
  health_check: record # Service health check — shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
  --http: record # Configuration option for protocols http and https — shape: {certificates?: list<int>, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
  listen_port: int # Port the Load Balancer listens on (e.g. 443)
  protocol: string@protocol-completer # Protocol of the Load Balancer (e.g. https)
  --proxyprotocol: oneof<nothing, bool> # Is Proxyprotocol enabled or not (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/add_service"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destination_port, var: destination_port}, {name: health_check, var: health_check}, {name: http, var: http}, {name: listen_port, var: listen_port}, {name: protocol, var: protocol}, {name: proxyprotocol, var: proxyprotocol, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, destination_port: $destination_port, health_check: $health_check, http: $http, listen_port: $listen_port, protocol: $protocol, proxyprotocol: $proxyprotocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Target
#
# POST /load_balancers/{id}/actions/add_target
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-add-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: record # IP targets where the traffic should be routed through. It is only possible to use the (Public or vSwitch) IPs of Hetzner Online Root Servers belonging to the project owner. IPs belonging to other users are blocked. Additionally IPs belonging to services provided by Hetzner Cloud (Servers, Load Balancers, ...) are blocked as well. — shape: {ip: string}
  --label-selector: record # Configuration for label selector targets, required if type is `label_selector` — shape: {selector: string}
  --server: record # Configuration for type Server, required if type is `server` — shape: {id: float}
  type: string@type-completer-4 # Type of the resource
  --use-private-ip: oneof<nothing, bool> # Use the private network IP instead of the public IP of the Server, requires the Server and Load Balancer to be in the same network. Default value is false. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/add_target"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: label_selector, var: label_selector}, {name: server, var: server}, {name: type, var: type}, {name: use_private_ip, var: use_private_ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip: $ip, label_selector: $label_selector, server: $server, type: $type, use_private_ip: $use_private_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a Load Balancer to a Network
#
# POST /load_balancers/{id}/actions/attach_to_network
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-attach-to-network" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # IP to request to be assigned to this Load Balancer; if you do not provide this then you will be auto assigned an IP address (e.g. 10.0.1.1)
  network: float # ID of an existing network to attach the Load Balancer to (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/attach_to_network"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip: $ip, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Algorithm
#
# POST /load_balancers/{id}/actions/change_algorithm
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-change-algorithm" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-5 # Algorithm of the Load Balancer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/change_algorithm"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change reverse DNS entry for this Load Balancer
#
# POST /load_balancers/{id}/actions/change_dns_ptr
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-change-dns-ptr" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry (nullable, e.g. lb1.example.com)
  ip: string # Public IP address for which the reverse DNS entry should be set (e.g. 1.2.3.4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/change_dns_ptr"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dns_ptr, var: dns_ptr}, {name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, dns_ptr: $dns_ptr, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Load Balancer Protection
#
# POST /load_balancers/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Load Balancer from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the Type of a Load Balancer
#
# POST /load_balancers/{id}/actions/change_type
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-change-type" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  load_balancer_type: string # ID or name of Load Balancer type the Load Balancer should migrate to (e.g. lb21)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/change_type"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: load_balancer_type, var: load_balancer_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, load_balancer_type: $load_balancer_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Service
#
# POST /load_balancers/{id}/actions/delete_service
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-delete-service" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  listen_port: float # The listen port of the service you want to delete (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/delete_service"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: listen_port, var: listen_port}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, listen_port: $listen_port
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a Load Balancer from a Network
#
# POST /load_balancers/{id}/actions/detach_from_network
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-detach-from-network" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  network: float # ID of an existing network to detach the Load Balancer from (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/detach_from_network"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable the public interface of a Load Balancer
#
# POST /load_balancers/{id}/actions/disable_public_interface
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-disable-public-interface" [
  id: int
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
    path: "/load_balancers/{id}/actions/disable_public_interface"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable the public interface of a Load Balancer
#
# POST /load_balancers/{id}/actions/enable_public_interface
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-enable-public-interface" [
  id: int
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
    path: "/load_balancers/{id}/actions/enable_public_interface"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Target
#
# POST /load_balancers/{id}/actions/remove_target
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-remove-target" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: record # IP targets where the traffic should be routed through. It is only possible to use the (Public or vSwitch) IPs of Hetzner Online Root Servers belonging to the project owner. IPs belonging to other users are blocked. Additionally IPs belonging to services provided by Hetzner Cloud (Servers, Load Balancers, ...) are blocked as well. — shape: {ip: string}
  --label-selector: record # Configuration for label selector targets, required if type is `label_selector` — shape: {selector: string}
  --server: record # Configuration for type Server, required if type is `server` — shape: {id: float}
  type: string@type-completer-4 # Type of the resource
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/remove_target"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}, {name: label_selector, var: label_selector}, {name: server, var: server}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip: $ip, label_selector: $label_selector, server: $server, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Service
#
# POST /load_balancers/{id}/actions/update_service
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-load-balancers-id-actions-update-service" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_port: int # Port the Load Balancer will balance to (e.g. 80)
  health_check: record # Service health check — shape: {http?: record, interval: int, port: int, protocol: "tcp"|"http", retries: int, timeout: int}
  --http: record # Configuration option for protocols http and https — shape: {certificates?: list<int>, cookie_lifetime?: int, cookie_name?: string, redirect_http?: bool, sticky_sessions?: bool}
  listen_port: int # Port the Load Balancer listens on (e.g. 443)
  protocol: string@protocol-completer # Protocol of the Load Balancer (e.g. https)
  --proxyprotocol: oneof<nothing, bool> # Is Proxyprotocol enabled or not (e.g. false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/load_balancers/{id}/actions/update_service"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destination_port, var: destination_port}, {name: health_check, var: health_check}, {name: http, var: http}, {name: listen_port, var: listen_port}, {name: protocol, var: protocol}, {name: proxyprotocol, var: proxyprotocol, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, destination_port: $destination_port, health_check: $health_check, http: $http, listen_port: $listen_port, protocol: $protocol, proxyprotocol: $proxyprotocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Load Balancer
#
# GET /load_balancers/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-load-balancers-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/load_balancers/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Metrics for a LoadBalancer
#
# GET /load_balancers/{id}/metrics
# Returns: record<metrics: record<end: string, start: string, step: float, time_series: record>>
export def "get-load-balancers-id-metrics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-6 # Type of metrics to get (required)
  --start: string # Start of period to get Metrics for (in ISO-8601 format) (required)
  --end: string # End of period to get Metrics for (in ISO-8601 format) (required)
  --step: string # Resolution of results in seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/load_balancers/{id}/metrics"
    path_params: [{name: id, var: id}]
    query: [{name: type, var: type, required: true}, {name: start, var: start, required: true}, {name: end, var: end, required: true}, {name: step, var: step}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, start: $start, end: $end, step: $step
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Locations
#
# GET /locations
# Returns: record<locations: table<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>>
export def "get-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter Locations by their name. The response will only contain the Location matching the specified name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locations"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Location
#
# GET /locations/{id}
# Returns: record<location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>>
export def "get-locations-id" [
  id: int
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
    path: "/locations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Networks
#
# GET /networks
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, networks: table<created: string, id: int, ip_range: string, labels: record, load_balancers: list, name: string, protection: record, routes: list, servers: list, subnets: list>>
export def "get-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter networks by their name. The response will only contain the networks matching the specified name.
  --label-selector: string # Can be used to filter networks by labels. The response will only contain networks with a matching label selector pattern.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks"
    query: [{name: name, var: name}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Network
#
# POST /networks
# Returns: record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>
export def "post-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_range: string # IP range of the whole network which must span all included subnets. Must be one of the private IPv4 ranges of RFC1918. Minimum network size is /24. We highly recommend that you pick a larger network with a /16 netmask. (e.g. 10.0.0.0/16)
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  name: string # Name of the network (e.g. mynet)
  --routes: list # Array of routes set in this network. The destination of the route must be one of the private IPv4 ranges of RFC1918. The gateway must be a subnet/IP of the ip_range of the network object. The destination must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. The gateway cannot be the first IP of the networks ip_range and also cannot be 172.31.1.1. — item shape: {destination: string, gateway: string}
  --subnets: list # Array of subnets allocated. — item shape: {ip_range?: string, network_zone: string, type: "cloud"|"server"|"vswitch"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks"
    body: {content_type: "application/json", kind: json, fields: [{name: ip_range, var: ip_range}, {name: labels, var: labels}, {name: name, var: name}, {name: routes, var: routes}, {name: subnets, var: subnets}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ip_range: $ip_range, labels: $labels, name: $name, routes: $routes, subnets: $subnets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Network
#
# DELETE /networks/{id}
export def "delete-networks-id" [
  id: int
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
    path: "/networks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Network
#
# GET /networks/{id}
# Returns: record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>
export def "get-networks-id" [
  id: int
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
    path: "/networks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Network
#
# PUT /networks/{id}
# Returns: record<network: record<created: string, id: int, ip_range: string, labels: record, load_balancers: list<int>, name: string, protection: record<delete: bool>, routes: list<record>, servers: list<int>, subnets: list<record>>>
export def "put-networks-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  --name: string # New network name (e.g. new-name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/networks/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Network
#
# GET /networks/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-networks-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a route to a Network
#
# POST /networks/{id}/actions/add_route
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-add-route" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Destination network or host of this route. Must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. Must be one of the private IPv4 ranges of RFC1918. (e.g. 10.100.1.0/24)
  gateway: string # Gateway for the route. Cannot be the first IP of the networks ip_range, an IP behind a vSwitch or 172.31.1.1, as this IP is being used as a gateway for the public network interface of Servers. (e.g. 10.0.1.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/add_route"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destination, var: destination}, {name: gateway, var: gateway}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, destination: $destination, gateway: $gateway
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a subnet to a Network
#
# POST /networks/{id}/actions/add_subnet
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-add-subnet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip-range: string # Range to allocate IPs from. Must be a Subnet of the ip_range of the parent network object and must not overlap with any other subnets or with any destinations in routes. If the Subnet is of type vSwitch, it also can not overlap with any gateway in routes. Minimum Network size is /30. We suggest that you pick a bigger Network with a /24 netmask. (e.g. 10.0.1.0/24)
  network_zone: string # Name of Network zone. The Location object contains the `network_zone` property each Location belongs to. (e.g. eu-central)
  type: string@type-completer-7 # Type of Subnetwork
  --vswitch-id: int # ID of the robot vSwitch. Must be supplied if the subnet is of type vswitch. (e.g. 1000)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/add_subnet"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip_range, var: ip_range}, {name: network_zone, var: network_zone}, {name: type, var: type}, {name: vswitch_id, var: vswitch_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip_range: $ip_range, network_zone: $network_zone, type: $type, vswitch_id: $vswitch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change IP range of a Network
#
# POST /networks/{id}/actions/change_ip_range
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-change-ip-range" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_range: string # The new prefix for the whole Network (e.g. 10.0.0.0/12)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/change_ip_range"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip_range, var: ip_range}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip_range: $ip_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Network Protection
#
# POST /networks/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Network from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a route from a Network
#
# POST /networks/{id}/actions/delete_route
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-delete-route" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination: string # Destination network or host of this route. Must not overlap with an existing ip_range in any subnets or with any destinations in other routes or with the first IP of the networks ip_range or with 172.31.1.1. Must be one of the private IPv4 ranges of RFC1918. (e.g. 10.100.1.0/24)
  gateway: string # Gateway for the route. Cannot be the first IP of the networks ip_range, an IP behind a vSwitch or 172.31.1.1, as this IP is being used as a gateway for the public network interface of Servers. (e.g. 10.0.1.1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/delete_route"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: destination, var: destination}, {name: gateway, var: gateway}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, destination: $destination, gateway: $gateway
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subnet from a Network
#
# POST /networks/{id}/actions/delete_subnet
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-networks-id-actions-delete-subnet" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_range: string # IP range of subnet to delete (e.g. 10.0.1.0/24)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/{id}/actions/delete_subnet"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip_range, var: ip_range}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ip_range: $ip_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Network
#
# GET /networks/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-networks-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/networks/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all PlacementGroups
#
# GET /placement_groups
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, placement_groups: table<created: string, id: int, labels: record, name: string, servers: list, type: string>>
export def "get-placement-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --type: string@type-completer-8 # Can be used multiple times. The response will only contain PlacementGroups matching the type.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/placement_groups"
    query: [{name: sort, var: sort}, {name: name, var: name}, {name: label_selector, var: label_selector}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, name: $name, label_selector: $label_selector, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a PlacementGroup
#
# POST /placement_groups
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>
export def "post-placement-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the PlacementGroup (e.g. my Placement Group)
  type: string@type-completer-8 # Define the Placement Group Type. (e.g. spread)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/placement_groups"
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    labels: $labels, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a PlacementGroup
#
# DELETE /placement_groups/{id}
export def "delete-placement-groups-id" [
  id: int
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
    path: "/placement_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a PlacementGroup
#
# GET /placement_groups/{id}
# Returns: record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>
export def "get-placement-groups-id" [
  id: int
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
    path: "/placement_groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a PlacementGroup
#
# PUT /placement_groups/{id}
# Returns: record<placement_group: record<created: string, id: int, labels: record, name: string, servers: list<int>, type: string>>
export def "put-placement-groups-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New PlacementGroup name (e.g. my Placement Group)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/placement_groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all prices
#
# GET /pricing
# Returns: record<pricing: record<currency: string, floating_ip: record<price_monthly: record>, floating_ips: list<record>, image: record<price_per_gb_month: record>, load_balancer_types: list<record>, primary_ips: list<record>, server_backup: record<percentage: string>, server_types: list<record>, traffic: record<price_per_tb: record>, vat_rate: string, volume: record<price_per_gb_month: record>>>
export def "get-pricing" [
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
    path: "/pricing"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Primary IPs
#
# GET /primary_ips
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, primary_ips: table<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record, dns_ptr: list, id: int, ip: string, labels: record, name: string, protection: record, type: string>>
export def "get-primary-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --ip: string # Can be used to filter resources by their ip. The response will only contain the resources matching the specified ip. (e.g. 127.0.0.1)
  --sort: string@sort-completer-2 # Can be used multiple times. Choices id id:asc id:desc created created:asc created:desc
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/primary_ips"
    query: [{name: name, var: name}, {name: label_selector, var: label_selector}, {name: ip, var: ip}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, label_selector: $label_selector, ip: $ip, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Primary IP
#
# POST /primary_ips
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>
export def "post-primary-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-id: int # ID of the resource the Primary IP should be assigned to. Omitted if it should not be assigned. (e.g. 17)
  assignee_type: string@assignee-type-completer # Resource type the Primary IP can be assigned to (e.g. server)
  --auto-delete: oneof<nothing, bool> # Delete the Primary IP when the Server it is assigned to is deleted. If omitted defaults to `false`. (e.g. false)
  --datacenter: string # ID or name of Datacenter the Primary IP will be bound to. Needs to be omitted if `assignee_id` is passed. (e.g. fsn1-dc8)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  name: string # e.g. my-ip
  type: string@type-completer-1 # Primary IP type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/primary_ips"
    body: {content_type: "application/json", kind: json, fields: [{name: assignee_id, var: assignee_id}, {name: assignee_type, var: assignee_type}, {name: auto_delete, var: auto_delete}, {name: datacenter, var: datacenter}, {name: labels, var: labels}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    assignee_id: $assignee_id, assignee_type: $assignee_type, auto_delete: $auto_delete, datacenter: $datacenter, labels: $labels, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Primary IP
#
# DELETE /primary_ips/{id}
export def "delete-primary-ips-id" [
  id: int
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
    path: "/primary_ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Primary IP
#
# GET /primary_ips/{id}
# Returns: record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>
export def "get-primary-ips-id" [
  id: int
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
    path: "/primary_ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Primary IP
#
# PUT /primary_ips/{id}
# Returns: record<primary_ip: record<assignee_id: int, assignee_type: string, auto_delete: bool, blocked: bool, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, dns_ptr: list<record>, id: int, ip: string, labels: record, name: string, protection: record<delete: bool>, type: string>>
export def "put-primary-ips-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-delete: oneof<nothing, bool> # Delete this Primary IP when the resource it is assigned to is deleted (e.g. true)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New unique name to set (e.g. my-ip)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/primary_ips/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: auto_delete, var: auto_delete}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, auto_delete: $auto_delete, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a Primary IP to a resource
#
# POST /primary_ips/{id}/actions/assign
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-primary-ips-id-actions-assign" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assignee_id: int # ID of a resource of type `assignee_type` (e.g. 4711)
  assignee_type: string@assignee-type-completer # Type of resource assigning the Primary IP to (e.g. server)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/primary_ips/{id}/actions/assign"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignee_id, var: assignee_id}, {name: assignee_type, var: assignee_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, assignee_id: $assignee_id, assignee_type: $assignee_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change reverse DNS entry for a Primary IP
#
# POST /primary_ips/{id}/actions/change_dns_ptr
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-primary-ips-id-actions-change-dns-ptr" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, will reset to original default value if `null` (nullable, e.g. server02.example.com)
  ip: string # IP address for which to set the reverse DNS entry (e.g. 1.2.3.4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/primary_ips/{id}/actions/change_dns_ptr"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dns_ptr, var: dns_ptr}, {name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, dns_ptr: $dns_ptr, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Primary IP Protection
#
# POST /primary_ips/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-primary-ips-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Primary IP from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/primary_ips/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign a Primary IP from a resource
#
# POST /primary_ips/{id}/actions/unassign
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-primary-ips-id-actions-unassign" [
  id: int
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
    path: "/primary_ips/{id}/actions/unassign"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Server Types
#
# GET /server_types
# Returns: record<server_types: table<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list, storage_type: string>>
export def "get-server-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter Server types by their name. The response will only contain the Server type matching the specified name.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/server_types"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Server Type
#
# GET /server_types/{id}
# Returns: record<server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: float, memory: float, name: string, prices: list<record>, storage_type: string>>
export def "get-server-types-id" [
  id: int
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
    path: "/server_types/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Servers
#
# GET /servers
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, servers: table<backup_window: string, created: string, datacenter: record, id: int, image: record, included_traffic: float, ingoing_traffic: float, iso: record, labels: record, load_balancers: list, locked: bool, name: string, outgoing_traffic: float, placement_group: record, primary_disk_size: float, private_net: list, protection: record, public_net: record, rescue_enabled: bool, server_type: record, status: string, volumes: list>>
export def "get-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
  --sort: string@sort-completer-1 # Can be used multiple times.
  --status: string@status-completer-2 # Can be used multiple times. The response will only contain Server matching the status
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers"
    query: [{name: name, var: name}, {name: label_selector, var: label_selector}, {name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, label_selector: $label_selector, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Server
#
# POST /servers
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, root_password: string, server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>
export def "post-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --automount: oneof<nothing, bool> # Auto-mount Volumes after attach (e.g. false)
  --datacenter: string # ID or name of Datacenter to create Server in (must not be used together with location) (e.g. nbg1-dc3)
  --firewalls: list # Firewalls which should be applied on the Server's public network interface at creation time (e.g. [{firewall: 38}]) — item shape: {firewall?: int}
  image: string # ID or name of the Image the Server is created from (e.g. ubuntu-20.04)
  --labels: record # User-defined labels (key-value pairs)
  --location: string # ID or name of Location to create Server in (must not be used together with datacenter) (e.g. nbg1)
  name: string # Name of the Server to create (must be unique per Project and a valid hostname as per RFC 1123) (e.g. my-server)
  --networks: list<int> # Network IDs which should be attached to the Server private network interface at the creation time (e.g. [456])
  --placement-group: int # ID of the Placement Group the server should be in (e.g. 1)
  --public-net: record # Public Network options — shape: {enable_ipv4?: bool, enable_ipv6?: bool, ipv4?: int, ipv6?: int}
  server_type: string # ID or name of the Server type this Server should be created with (e.g. cx11)
  --ssh-keys: list<string> # SSH key IDs (`integer`) or names (`string`) which should be injected into the Server at creation time (e.g. [my-ssh-key])
  --start-after-create: oneof<nothing, bool> # Start Server right after creation. Defaults to true. (e.g. true)
  --user-data: string # Cloud-Init user data to use during Server creation. This field is limited to 32KiB. (e.g. #cloud-config runcmd: - [touch, /root/cloud-init-worked] )
  --volumes: list<int> # Volume IDs which should be attached to the Server at the creation time. Volumes must be in the same Location. (e.g. [123])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers"
    body: {content_type: "application/json", kind: json, fields: [{name: automount, var: automount}, {name: datacenter, var: datacenter}, {name: firewalls, var: firewalls}, {name: image, var: image}, {name: labels, var: labels}, {name: location, var: location}, {name: name, var: name}, {name: networks, var: networks}, {name: placement_group, var: placement_group}, {name: public_net, var: public_net}, {name: server_type, var: server_type}, {name: ssh_keys, var: ssh_keys}, {name: start_after_create, var: start_after_create}, {name: user_data, var: user_data}, {name: volumes, var: volumes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    automount: $automount, datacenter: $datacenter, firewalls: $firewalls, image: $image, labels: $labels, location: $location, name: $name, networks: $networks, placement_group: $placement_group, public_net: $public_net, server_type: $server_type, ssh_keys: $ssh_keys, start_after_create: $start_after_create, user_data: $user_data, volumes: $volumes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Server
#
# DELETE /servers/{id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "delete-servers-id" [
  id: int
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
    path: "/servers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Server
#
# GET /servers/{id}
# Returns: record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>
export def "get-servers-id" [
  id: int
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
    path: "/servers/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Server
#
# PUT /servers/{id}
# Returns: record<server: record<backup_window: string, created: string, datacenter: record<description: string, id: int, location: record, name: string, server_types: record>, id: int, image: record<bound_to: int, created: string, created_from: record, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record, rapid_deploy: bool, status: string, type: string>, included_traffic: float, ingoing_traffic: float, iso: record<deprecated: string, description: string, id: int, name: string, type: string>, labels: record, load_balancers: list<int>, locked: bool, name: string, outgoing_traffic: float, placement_group: record<created: string, id: int, labels: record, name: string, servers: list, type: string>, primary_disk_size: float, private_net: list<record>, protection: record<delete: bool, rebuild: bool>, public_net: record<firewalls: list, floating_ips: list, ipv4: record, ipv6: record>, rescue_enabled: bool, server_type: record<cores: float, cpu_type: string, deprecated: bool, description: string, disk: float, id: int, memory: float, name: string, prices: list, storage_type: string>, status: string, volumes: list<int>>>
export def "put-servers-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New name to set (e.g. my-server)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/servers/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Server
#
# GET /servers/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-servers-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Server to a Placement Group
#
# POST /servers/{id}/actions/add_to_placement_group
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-add-to-placement-group" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  placement_group: int # ID of Placement Group the Server should be added to (e.g. 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/add_to_placement_group"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: placement_group, var: placement_group}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, placement_group: $placement_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach an ISO to a Server
#
# POST /servers/{id}/actions/attach_iso
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-attach-iso" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  iso: string # ID or name of ISO to attach to the Server as listed in GET `/isos` (e.g. FreeBSD-11.0-RELEASE-amd64-dvd1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/attach_iso"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: iso, var: iso}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, iso: $iso
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach a Server to a Network
#
# POST /servers/{id}/actions/attach_to_network
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-attach-to-network" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias-ips: list<string> # Additional IPs to be assigned to this Server (e.g. [10.0.1.2])
  --ip: string # IP to request to be assigned to this Server; if you do not provide this then you will be auto assigned an IP address (e.g. 10.0.1.1)
  network: int # ID of an existing network to attach the Server to (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/attach_to_network"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias_ips, var: alias_ips}, {name: ip, var: ip}, {name: network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, alias_ips: $alias_ips, ip: $ip, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change alias IPs of a Network
#
# POST /servers/{id}/actions/change_alias_ips
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-change-alias-ips" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alias_ips: list<string> # New alias IPs to set for this Server (e.g. [10.0.1.2])
  network: int # ID of an existing Network already attached to the Server (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/change_alias_ips"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias_ips, var: alias_ips}, {name: network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, alias_ips: $alias_ips, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change reverse DNS entry for this Server
#
# POST /servers/{id}/actions/change_dns_ptr
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-change-dns-ptr" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dns-ptr: string # Hostname to set as a reverse DNS PTR entry, reset to original value if `null` (nullable, e.g. server01.example.com)
  ip: string # Primary IP address for which the reverse DNS entry should be set (e.g. 1.2.3.4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/change_dns_ptr"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: dns_ptr, var: dns_ptr}, {name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, dns_ptr: $dns_ptr, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Server Protection
#
# POST /servers/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Server from being deleted (currently delete and rebuild attribute needs to have the same value) (e.g. true)
  --rebuild: oneof<nothing, bool> # If true, prevents the Server from being rebuilt (currently delete and rebuild attribute needs to have the same value) (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}, {name: rebuild, var: rebuild}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete, rebuild: $rebuild
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the Type of a Server
#
# POST /servers/{id}/actions/change_type
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-change-type" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  server_type: string # ID or name of Server type the Server should migrate to (e.g. cx11)
  --upgrade-disk: oneof<nothing, bool> # If false, do not upgrade the disk (this allows downgrading the Server type later) (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/change_type"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: server_type, var: server_type}, {name: upgrade_disk, var: upgrade_disk, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, server_type: $server_type, upgrade_disk: $upgrade_disk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Image from a Server
#
# POST /servers/{id}/actions/create_image
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, image: record<bound_to: int, created: string, created_from: record<id: int, name: string>, deleted: string, deprecated: string, description: string, disk_size: float, id: int, image_size: float, labels: record, name: string, os_flavor: string, os_version: string, protection: record<delete: bool>, rapid_deploy: bool, status: string, type: string>>
export def "post-servers-id-actions-create-image" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the Image, will be auto-generated if not set (e.g. my image)
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  --type: string@type-completer-9 # Type of Image to create (default: `snapshot`) (e.g. snapshot)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/create_image"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: labels, var: labels}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, description: $description, labels: $labels, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach a Server from a Network
#
# POST /servers/{id}/actions/detach_from_network
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-detach-from-network" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  network: int # ID of an existing network to detach the Server from (e.g. 4711)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/detach_from_network"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: network, var: network}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, network: $network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach an ISO from a Server
#
# POST /servers/{id}/actions/detach_iso
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-detach-iso" [
  id: int
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
    path: "/servers/{id}/actions/detach_iso"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable Backups for a Server
#
# POST /servers/{id}/actions/disable_backup
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-disable-backup" [
  id: int
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
    path: "/servers/{id}/actions/disable_backup"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable Rescue Mode for a Server
#
# POST /servers/{id}/actions/disable_rescue
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-disable-rescue" [
  id: int
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
    path: "/servers/{id}/actions/disable_rescue"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable and Configure Backups for a Server
#
# POST /servers/{id}/actions/enable_backup
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-enable-backup" [
  id: int
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
    path: "/servers/{id}/actions/enable_backup"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable Rescue Mode for a Server
#
# POST /servers/{id}/actions/enable_rescue
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>
export def "post-servers-id-actions-enable-rescue" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssh-keys: list<int> # Array of SSH key IDs which should be injected into the rescue system. (e.g. [2323])
  --type: string@type-completer-10 # Type of rescue system to boot (default: `linux64`)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/enable_rescue"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ssh_keys, var: ssh_keys}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, ssh_keys: $ssh_keys, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Power off a Server
#
# POST /servers/{id}/actions/poweroff
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-poweroff" [
  id: int
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
    path: "/servers/{id}/actions/poweroff"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Power on a Server
#
# POST /servers/{id}/actions/poweron
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-poweron" [
  id: int
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
    path: "/servers/{id}/actions/poweron"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Soft-reboot a Server
#
# POST /servers/{id}/actions/reboot
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-reboot" [
  id: int
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
    path: "/servers/{id}/actions/reboot"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rebuild a Server from an Image
#
# POST /servers/{id}/actions/rebuild
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>
export def "post-servers-id-actions-rebuild" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # ID or name of Image to rebuilt from. (e.g. ubuntu-20.04)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/servers/{id}/actions/rebuild"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove from Placement Group
#
# POST /servers/{id}/actions/remove_from_placement_group
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-remove-from-placement-group" [
  id: int
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
    path: "/servers/{id}/actions/remove_from_placement_group"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Console for a Server
#
# POST /servers/{id}/actions/request_console
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, password: string, wss_url: string>
export def "post-servers-id-actions-request-console" [
  id: int
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
    path: "/servers/{id}/actions/request_console"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset a Server
#
# POST /servers/{id}/actions/reset
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-reset" [
  id: int
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
    path: "/servers/{id}/actions/reset"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset root Password of a Server
#
# POST /servers/{id}/actions/reset_password
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, root_password: string>
export def "post-servers-id-actions-reset-password" [
  id: int
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
    path: "/servers/{id}/actions/reset_password"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Shutdown a Server
#
# POST /servers/{id}/actions/shutdown
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-servers-id-actions-shutdown" [
  id: int
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
    path: "/servers/{id}/actions/shutdown"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Server
#
# GET /servers/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-servers-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/servers/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Metrics for a Server
#
# GET /servers/{id}/metrics
# Returns: record<metrics: record<end: string, start: string, step: float, time_series: record>>
export def "get-servers-id-metrics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-11 # Type of metrics to get (required)
  --start: string # Start of period to get Metrics for (in ISO-8601 format) (required)
  --end: string # End of period to get Metrics for (in ISO-8601 format) (required)
  --step: string # Resolution of results in seconds
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/servers/{id}/metrics"
    path_params: [{name: id, var: id}]
    query: [{name: type, var: type, required: true}, {name: start, var: start, required: true}, {name: end, var: end, required: true}, {name: step, var: step}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, start: $start, end: $end, step: $step
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all SSH keys
#
# GET /ssh_keys
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, ssh_keys: table<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>
export def "get-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer-3 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --fingerprint: string # Can be used to filter SSH keys by their fingerprint. The response will only contain the SSH key matching the specified fingerprint.
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ssh_keys"
    query: [{name: sort, var: sort}, {name: name, var: name}, {name: fingerprint, var: fingerprint}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, name: $name, fingerprint: $fingerprint, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an SSH key
#
# POST /ssh_keys
# Returns: record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>
export def "post-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --labels: record # User-defined labels (key-value pairs)
  name: string # Name of the SSH key (e.g. My ssh key)
  public_key: string # Public key (e.g. ssh-rsa AAAjjk76kgf...Xt)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ssh_keys"
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}, {name: public_key, var: public_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    labels: $labels, name: $name, public_key: $public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SSH key
#
# DELETE /ssh_keys/{id}
export def "delete-ssh-keys-id" [
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
    path: "/ssh_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a SSH key
#
# GET /ssh_keys/{id}
# Returns: record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>
export def "get-ssh-keys-id" [
  id: int
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
    path: "/ssh_keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an SSH key
#
# PUT /ssh_keys/{id}
# Returns: record<ssh_key: record<created: string, fingerprint: string, id: int, labels: record, name: string, public_key: string>>
export def "put-ssh-keys-id" [
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
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --name: string # New name Name to set (e.g. My ssh key)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ssh_keys/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Volumes
#
# GET /volumes
# Returns: record<meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>, volumes: table<created: string, format: string, id: int, labels: record, linux_device: string, location: record, name: string, protection: record, server: int, size: float, status: string>>
export def "get-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Can be used multiple times. The response will only contain Volumes matching the status.
  --sort: string@sort-completer-1 # Can be used multiple times.
  --name: string # Can be used to filter resources by their name. The response will only contain the resources matching the specified name
  --label-selector: string # Can be used to filter resources by labels. The response will only contain resources matching the label selector.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes"
    query: [{name: status, var: status}, {name: sort, var: sort}, {name: name, var: name}, {name: label_selector, var: label_selector}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, sort: $sort, name: $name, label_selector: $label_selector
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Volume
#
# POST /volumes
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>, next_actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>
export def "post-volumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --automount: oneof<nothing, bool> # Auto-mount Volume after attach. `server` must be provided. (e.g. false)
  --format: string # Format Volume after creation. One of: `xfs`, `ext4` (e.g. xfs)
  --labels: record # User-defined labels (key-value pairs) (e.g. {labelkey: value})
  --location: string # Location to create the Volume in (can be omitted if Server is specified) (e.g. nbg1)
  name: string # Name of the volume (e.g. databases-storage)
  --server: int # Server to which to attach the Volume once it's created (Volume will be created in the same Location as the server)
  size: int # Size of the Volume in GB (e.g. 42)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes"
    body: {content_type: "application/json", kind: json, fields: [{name: automount, var: automount}, {name: format, var: format}, {name: labels, var: labels}, {name: location, var: location}, {name: name, var: name}, {name: server, var: server}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    automount: $automount, format: $format, labels: $labels, location: $location, name: $name, server: $server, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Volume
#
# DELETE /volumes/{id}
export def "delete-volumes-id" [
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
    path: "/volumes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Volume
#
# GET /volumes/{id}
# Returns: record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>
export def "get-volumes-id" [
  id: int
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
    path: "/volumes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Volume
#
# PUT /volumes/{id}
# Returns: record<volume: record<created: string, format: string, id: int, labels: record, linux_device: string, location: record<city: string, country: string, description: string, id: float, latitude: float, longitude: float, name: string, network_zone: string>, name: string, protection: record<delete: bool>, server: int, size: float, status: string>>
export def "put-volumes-id" [
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
  --labels: record # User-defined labels (key-value pairs) — shape: {labelkey?: string}
  name: string # New Volume name (e.g. database-storage)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/volumes/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Actions for a Volume
#
# GET /volumes/{id}/actions
# Returns: record<actions: table<command: string, error: record, finished: string, id: int, progress: float, resources: list, started: string, status: string>, meta: record<pagination: record<last_page: float, next_page: float, page: float, per_page: float, previous_page: float, total_entries: float>>>
export def "get-volumes-id-actions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string@sort-completer # Can be used multiple times.
  --status: string@status-completer # Can be used multiple times, the response will contain only Actions with specified statuses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/{id}/actions"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach Volume to a Server
#
# POST /volumes/{id}/actions/attach
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-volumes-id-actions-attach" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --automount: oneof<nothing, bool> # Auto-mount the Volume after attaching it (e.g. false)
  server: int # ID of the Server the Volume will be attached to (e.g. 43)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{id}/actions/attach"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: automount, var: automount}, {name: server, var: server}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, automount: $automount, server: $server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Volume Protection
#
# POST /volumes/{id}/actions/change_protection
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-volumes-id-actions-change-protection" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete: oneof<nothing, bool> # If true, prevents the Volume from being deleted (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{id}/actions/change_protection"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete, var: delete}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, delete: $delete
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detach Volume
#
# POST /volumes/{id}/actions/detach
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-volumes-id-actions-detach" [
  id: int
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
    path: "/volumes/{id}/actions/detach"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resize Volume
#
# POST /volumes/{id}/actions/resize
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "post-volumes-id-actions-resize" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  size: float # New Volume size in GB (must be greater than current size) (e.g. 50)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/{id}/actions/resize"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: size, var: size}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Action for a Volume
#
# GET /volumes/{id}/actions/{action_id}
# Returns: record<action: record<command: string, error: record<code: string, message: string>, finished: string, id: int, progress: float, resources: list<record>, started: string, status: string>>
export def "get-volumes-id-actions-action-id" [
  id: int
  action_id: int
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
    path: "/volumes/{id}/actions/{action_id}"
    path_params: [{name: id, var: id}, {name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
