# Auto-generated client for Registry API v0.0.1
# Source: https://api.apis.guru/v2/specs/apigee.local/registry/0.0.1/openapi.json
# Auth: --token flag or $env.REGISTRY_API_TOKEN

const CLIENT = {
  base_url: "http://apigee.local"
  token_env_var: "REGISTRY_API_TOKEN"
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

def base-url-completer [] { ["http://apigee.local" "https://apigeeregistry.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    registry-list-apis: "record<apis: table<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>, nextPageToken: string>"
    registry-create-api: "record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>"
    registry-get-api: "record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>"
    registry-update-api: "record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>"
    registry-list-api-deployments: "record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string>"
    registry-create-api-deployment: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-get-api-deployment: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-update-api-deployment: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-delete-api-deployment-revision: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-list-api-deployment-revisions: "record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string>"
    registry-rollback-api-deployment: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-tag-api-deployment-revision: "record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>"
    registry-list-api-versions: "record<apiVersions: table<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>, nextPageToken: string>"
    registry-create-api-version: "record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>"
    registry-get-api-version: "record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>"
    registry-update-api-version: "record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>"
    registry-list-api-specs: "record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string>"
    registry-create-api-spec: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-get-api-spec: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-update-api-spec: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-delete-api-spec-revision: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-list-api-spec-revisions: "record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string>"
    registry-rollback-api-spec: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-tag-api-spec-revision: "record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>"
    registry-list-artifacts: "record<artifacts: table<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>, nextPageToken: string>"
    registry-create-artifact: "record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>"
    registry-get-artifact: "record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>"
    registry-replace-artifact: "record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["registry-list-apis" "registry-create-api" "registry-delete-api" "registry-get-api" "registry-update-api" "registry-list-api-deployments" "registry-create-api-deployment" "registry-delete-api-deployment" "registry-get-api-deployment" "registry-update-api-deployment" "registry-delete-api-deployment-revision" "registry-list-api-deployment-revisions" "registry-rollback-api-deployment" "registry-tag-api-deployment-revision" "registry-list-api-versions" "registry-create-api-version" "registry-delete-api-version" "registry-get-api-version" "registry-update-api-version" "registry-list-api-specs" "registry-create-api-spec" "registry-delete-api-spec" "registry-get-api-spec" "registry-update-api-spec" "registry-delete-api-spec-revision" "registry-get-api-spec-contents" "registry-list-api-spec-revisions" "registry-rollback-api-spec" "registry-tag-api-spec-revision" "registry-list-artifacts" "registry-create-artifact" "registry-delete-artifact" "registry-get-artifact" "registry-replace-artifact" "registry-get-artifact-contents" "commands"] | sort) } | get name | first)
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

# ListApis returns matching APIs.
#
# GET /v1/projects/{project}/locations/{location}/apis
# Returns: record<apis: table<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>, nextPageToken: string>
# operationId: Registry_ListApis
export def "registry-list-apis" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of APIs to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApis` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApis` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, page_size: $page_size, page_token: $page_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateApi creates a specified API.
#
# POST /v1/projects/{project}/locations/{location}/apis
# Returns: record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>
# operationId: Registry_CreateApi
export def "registry-create-api" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-id: string # Required. The ID to use for the api, which will become the final component of the api's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --availability: string # A user-definable description of the availability of this service. Format: free-form, but we expect single words that describe availability, e.g. "NONE", "TESTING", "PREVIEW", "GENERAL", "DEPRECATED", "SHUTDOWN".
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --recommended-deployment: string # The recommended deployment of the API. Format: apis/{api}/deployments/{deployment}
  --recommended-version: string # The recommended version of the API. Format: apis/{api}/versions/{version}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: apiId, var: api_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: availability, var: availability}, {name: description, var: description}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: name, var: name}, {name: recommendedDeployment, var: recommended_deployment}, {name: recommendedVersion, var: recommended_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api_id: $api_id, annotations: $annotations, availability: $availability, description: $description, display_name: $display_name, labels: $labels, name: $name, recommended_deployment: $recommended_deployment, recommended_version: $recommended_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApi removes a specified API and all of the resources that it owns.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}
# operationId: Registry_DeleteApi
export def "registry-delete-api" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/projects/{project}/locations/{location}/apis/{api}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetApi returns a specified API.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}
# Returns: record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>
# operationId: Registry_GetApi
export def "registry-get-api" [
  project: string
  location: string
  api: string
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
    path: "/v1/projects/{project}/locations/{location}/apis/{api}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateApi can be used to modify a specified API.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}
# Returns: record<annotations: record, availability: string, createTime: string, description: string, displayName: string, labels: record, name: string, recommendedDeployment: string, recommendedVersion: string, updateTime: string>
# operationId: Registry_UpdateApi
export def "registry-update-api" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the api is not found, a new api_versions will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --availability: string # A user-definable description of the availability of this service. Format: free-form, but we expect single words that describe availability, e.g. "NONE", "TESTING", "PREVIEW", "GENERAL", "DEPRECATED", "SHUTDOWN".
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --recommended-deployment: string # The recommended deployment of the API. Format: apis/{api}/deployments/{deployment}
  --recommended-version: string # The recommended version of the API. Format: apis/{api}/versions/{version}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{project}/locations/{location}/apis/{api}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: updateMask, var: update_mask}, {name: allowMissing, var: allow_missing}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: availability, var: availability}, {name: description, var: description}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: name, var: name}, {name: recommendedDeployment, var: recommended_deployment}, {name: recommendedVersion, var: recommended_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, update_mask: $update_mask, allow_missing: $allow_missing, annotations: $annotations, availability: $availability, description: $description, display_name: $display_name, labels: $labels, name: $name, recommended_deployment: $recommended_deployment, recommended_version: $recommended_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListApiDeployments returns matching deployments.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments
# Returns: record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string>
# operationId: Registry_ListApiDeployments
export def "registry-list-api-deployments" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of deployments to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiDeployments` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiDeployments` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, page_size: $page_size, page_token: $page_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateApiDeployment creates a specified deployment.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_CreateApiDeployment
export def "registry-create-api-deployment" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-deployment-id: string # Required. The ID to use for the deployment, which will become the final component of the deployment's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --access-guidance: string # Text briefly describing how to access the endpoint. Changes to this value will not affect the revision.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --api-spec-revision: string # The full resource name (including revision id) of the spec of the API being served by the deployment. Changes to this value will update the revision. Format: apis/{api}/deployments/{deployment}
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --endpoint-uri: string # The address where the deployment is serving. Changes to this value will update the revision.
  --external-channel-uri: string # The address of the external channel of the API (e.g. the Developer Portal). Changes to this value will not affect the revision.
  --intended-audience: string # Text briefly identifying the intended audience of the API. Changes to this value will not affect the revision.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "registry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: apiDeploymentId, var: api_deployment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessGuidance, var: access_guidance}, {name: annotations, var: annotations}, {name: apiSpecRevision, var: api_spec_revision}, {name: description, var: description}, {name: displayName, var: display_name}, {name: endpointUri, var: endpoint_uri}, {name: externalChannelUri, var: external_channel_uri}, {name: intendedAudience, var: intended_audience}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, api_deployment_id: $api_deployment_id, access_guidance: $access_guidance, annotations: $annotations, api_spec_revision: $api_spec_revision, description: $description, display_name: $display_name, endpoint_uri: $endpoint_uri, external_channel_uri: $external_channel_uri, intended_audience: $intended_audience, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApiDeployment removes a specified deployment, all revisions, and all child resources (e.g. artifacts).
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# operationId: Registry_DeleteApiDeployment
export def "registry-delete-api-deployment" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetApiDeployment returns a specified deployment.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_GetApiDeployment
export def "registry-get-api-deployment" [
  project: string
  location: string
  api: string
  deployment: string
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
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateApiDeployment can be used to modify a specified deployment.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_UpdateApiDeployment
export def "registry-update-api-deployment" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the deployment is not found, a new deployment will be created. In this situation, `update_mask` is ignored.
  --access-guidance: string # Text briefly describing how to access the endpoint. Changes to this value will not affect the revision.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --api-spec-revision: string # The full resource name (including revision id) of the spec of the API being served by the deployment. Changes to this value will update the revision. Format: apis/{api}/deployments/{deployment}
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --endpoint-uri: string # The address where the deployment is serving. Changes to this value will update the revision.
  --external-channel-uri: string # The address of the external channel of the API (e.g. the Developer Portal). Changes to this value will not affect the revision.
  --intended-audience: string # Text briefly identifying the intended audience of the API. Changes to this value will not affect the revision.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "registry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    query: [{name: updateMask, var: update_mask}, {name: allowMissing, var: allow_missing}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessGuidance, var: access_guidance}, {name: annotations, var: annotations}, {name: apiSpecRevision, var: api_spec_revision}, {name: description, var: description}, {name: displayName, var: display_name}, {name: endpointUri, var: endpoint_uri}, {name: externalChannelUri, var: external_channel_uri}, {name: intendedAudience, var: intended_audience}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment, update_mask: $update_mask, allow_missing: $allow_missing, access_guidance: $access_guidance, annotations: $annotations, api_spec_revision: $api_spec_revision, description: $description, display_name: $display_name, endpoint_uri: $endpoint_uri, external_channel_uri: $external_channel_uri, intended_audience: $intended_audience, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApiDeploymentRevision deletes a revision of a deployment.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:deleteRevision
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_DeleteApiDeploymentRevision
export def "registry-delete-api-deployment-revision" [
  project: string
  location: string
  api: string
  deployment: string
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
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:deleteRevision"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListApiDeploymentRevisions lists all revisions of a deployment. Revisions are returned in descending order of revision creation time.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:listRevisions
# Returns: record<apiDeployments: table<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>, nextPageToken: string>
# operationId: Registry_ListApiDeploymentRevisions
export def "registry-list-api-deployment-revisions" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of revisions to return per page. (format: int32)
  --page-token: string # The page token, received from a previous ListApiDeploymentRevisions call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:listRevisions"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RollbackApiDeployment sets the current revision to a specified prior revision. Note that this creates a new revision with a new revision ID.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:rollback
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_RollbackApiDeployment
export def "registry-rollback-api-deployment" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The deployment being rolled back.
  revision_id: string # Required. The revision ID to roll back to. It must be a revision of the same deployment. Example: c7cfa2a8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:rollback"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: revisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment, name: $name, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TagApiDeploymentRevision adds a tag to a specified revision of a deployment.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:tagRevision
# Returns: record<accessGuidance: string, annotations: record, apiSpecRevision: string, createTime: string, description: string, displayName: string, endpointUri: string, externalChannelUri: string, intendedAudience: string, labels: record, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string>
# operationId: Registry_TagApiDeploymentRevision
export def "registry-tag-api-deployment-revision" [
  project: string
  location: string
  api: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The name of the deployment to be tagged, including the revision ID.
  tag: string # Required. The tag to apply. The tag should be at most 40 characters, and match `[a-z][a-z0-9-]{3,39}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/deployments/{deployment}:tagRevision"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: deployment, var: deployment}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, deployment: $deployment, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListApiVersions returns matching versions.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions
# Returns: record<apiVersions: table<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>, nextPageToken: string>
# operationId: Registry_ListApiVersions
export def "registry-list-api-versions" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of versions to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiVersions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiVersions` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, page_size: $page_size, page_token: $page_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateApiVersion creates a specified version.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions
# Returns: record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>
# operationId: Registry_CreateApiVersion
export def "registry-create-api-version" [
  project: string
  location: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version-id: string # Required. The ID to use for the version, which will become the final component of the version's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --state: string # A user-definable description of the lifecycle phase of this API version. Format: free-form, but we expect single words that describe API maturity, e.g. "CONCEPT", "DESIGN", "DEVELOPMENT", "STAGING", "PRODUCTION", "DEPRECATED", "RETIRED".
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}]
    query: [{name: apiVersionId, var: api_version_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: description, var: description}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: name, var: name}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, api_version_id: $api_version_id, annotations: $annotations, description: $description, display_name: $display_name, labels: $labels, name: $name, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApiVersion removes a specified version and all of the resources that it owns.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# operationId: Registry_DeleteApiVersion
export def "registry-delete-api-version" [
  project: string
  location: string
  api: string
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
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetApiVersion returns a specified version.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# Returns: record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>
# operationId: Registry_GetApiVersion
export def "registry-get-api-version" [
  project: string
  location: string
  api: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateApiVersion can be used to modify a specified version.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}
# Returns: record<annotations: record, createTime: string, description: string, displayName: string, labels: record, name: string, state: string, updateTime: string>
# operationId: Registry_UpdateApiVersion
export def "registry-update-api-version" [
  project: string
  location: string
  api: string
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
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the version is not found, a new version will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --description: string # A detailed description.
  --display-name: string # Human-meaningful name.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --name: string # Resource name.
  --state: string # A user-definable description of the lifecycle phase of this API version. Format: free-form, but we expect single words that describe API maturity, e.g. "CONCEPT", "DESIGN", "DEVELOPMENT", "STAGING", "PRODUCTION", "DEPRECATED", "RETIRED".
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: updateMask, var: update_mask}, {name: allowMissing, var: allow_missing}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: description, var: description}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: name, var: name}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, update_mask: $update_mask, allow_missing: $allow_missing, annotations: $annotations, description: $description, display_name: $display_name, labels: $labels, name: $name, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListApiSpecs returns matching specs.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs
# Returns: record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string>
# operationId: Registry_ListApiSpecs
export def "registry-list-api-specs" [
  project: string
  location: string
  api: string
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
  --page-size: int # The maximum number of specs to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListApiSpecs` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListApiSpecs` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields except contents.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, page_size: $page_size, page_token: $page_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateApiSpec creates a specified spec.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_CreateApiSpec
export def "registry-create-api-spec" [
  project: string
  location: string
  api: string
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
  --api-spec-id: string # Required. The ID to use for the spec, which will become the final component of the spec's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --contents: string # Input only. The contents of the spec. Provided by API callers when specs are created or updated. To access the contents of a spec, use GetApiSpecContents. (format: bytes)
  --description: string # A detailed description.
  --filename: string # A possibly-hierarchical name used to refer to the spec from other specs.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --mime-type: string # A style (format) descriptor for this spec that is specified as a Media Type (https://en.wikipedia.org/wiki/Media_type). Possible values include "application/vnd.apigee.proto", "application/vnd.apigee.openapi", and "application/vnd.apigee.graphql", with possible suffixes representing compression types. These hypothetical names are defined in the vendor tree defined in RFC6838 (https://tools.ietf.org/html/rfc6838) and are not final. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
  --source-uri: string # The original source URI of the spec (if one exists). This is an external location that can be used for reference purposes but which may not be authoritative since this external resource may change after the spec is retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}]
    query: [{name: apiSpecId, var: api_spec_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: contents, var: contents}, {name: description, var: description}, {name: filename, var: filename}, {name: labels, var: labels}, {name: mimeType, var: mime_type}, {name: name, var: name}, {name: sourceUri, var: source_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, api_spec_id: $api_spec_id, annotations: $annotations, contents: $contents, description: $description, filename: $filename, labels: $labels, mime_type: $mime_type, name: $name, source_uri: $source_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApiSpec removes a specified spec, all revisions, and all child resources (e.g. artifacts).
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# operationId: Registry_DeleteApiSpec
export def "registry-delete-api-spec" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to true, any child resources will also be deleted. (Otherwise, the request will only work if there are no child resources.)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetApiSpec returns a specified spec.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_GetApiSpec
export def "registry-get-api-spec" [
  project: string
  location: string
  api: string
  version: string
  spec: string
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
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UpdateApiSpec can be used to modify a specified spec.
#
# PATCH /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_UpdateApiSpec
export def "registry-update-api-spec" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --update-mask: string # The list of fields to be updated. If omitted, all fields are updated that are set in the request message (fields set to default values are ignored). If a "*" is specified, all fields are updated, including fields that are unspecified/default in the request. (format: field-mask)
  --allow-missing: oneof<nothing, bool> # If set to true, and the spec is not found, a new spec will be created. In this situation, `update_mask` is ignored.
  --annotations: record # Annotations attach non-identifying metadata to resources. Annotation keys and values are less restricted than those of labels, but should be generally used for small values of broad interest. Larger, topic- specific metadata should be stored in Artifacts.
  --contents: string # Input only. The contents of the spec. Provided by API callers when specs are created or updated. To access the contents of a spec, use GetApiSpecContents. (format: bytes)
  --description: string # A detailed description.
  --filename: string # A possibly-hierarchical name used to refer to the spec from other specs.
  --labels: record # Labels attach identifying metadata to resources. Identifying metadata can be used to filter list operations. Label keys and values can be no longer than 64 characters (Unicode codepoints), can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. No more than 64 user labels can be associated with one resource (System labels are excluded). See https://goo.gl/xmQnxf for more information and examples of labels. System reserved label keys are prefixed with "apigeeregistry.googleapis.com/" and cannot be changed.
  --mime-type: string # A style (format) descriptor for this spec that is specified as a Media Type (https://en.wikipedia.org/wiki/Media_type). Possible values include "application/vnd.apigee.proto", "application/vnd.apigee.openapi", and "application/vnd.apigee.graphql", with possible suffixes representing compression types. These hypothetical names are defined in the vendor tree defined in RFC6838 (https://tools.ietf.org/html/rfc6838) and are not final. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
  --source-uri: string # The original source URI of the spec (if one exists). This is an external location that can be used for reference purposes but which may not be authoritative since this external resource may change after the spec is retrieved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    query: [{name: updateMask, var: update_mask}, {name: allowMissing, var: allow_missing}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: contents, var: contents}, {name: description, var: description}, {name: filename, var: filename}, {name: labels, var: labels}, {name: mimeType, var: mime_type}, {name: name, var: name}, {name: sourceUri, var: source_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec, update_mask: $update_mask, allow_missing: $allow_missing, annotations: $annotations, contents: $contents, description: $description, filename: $filename, labels: $labels, mime_type: $mime_type, name: $name, source_uri: $source_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteApiSpecRevision deletes a revision of a spec.
#
# DELETE /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:deleteRevision
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_DeleteApiSpecRevision
export def "registry-delete-api-spec-revision" [
  project: string
  location: string
  api: string
  version: string
  spec: string
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
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:deleteRevision"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetApiSpecContents returns the contents of a specified spec. If specs are stored with GZip compression, the default behavior is to return the spec uncompressed (the mime_type response field indicates the exact format returned).
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:getContents
# operationId: Registry_GetApiSpecContents
export def "registry-get-api-spec-contents" [
  project: string
  location: string
  api: string
  version: string
  spec: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:getContents"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ListApiSpecRevisions lists all revisions of a spec. Revisions are returned in descending order of revision creation time.
#
# GET /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:listRevisions
# Returns: record<apiSpecs: table<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>, nextPageToken: string>
# operationId: Registry_ListApiSpecRevisions
export def "registry-list-api-spec-revisions" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of revisions to return per page. (format: int32)
  --page-token: string # The page token, received from a previous ListApiSpecRevisions call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:listRevisions"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# RollbackApiSpec sets the current revision to a specified prior revision. Note that this creates a new revision with a new revision ID.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:rollback
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_RollbackApiSpec
export def "registry-rollback-api-spec" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The spec being rolled back.
  revision_id: string # Required. The revision ID to roll back to. It must be a revision of the same spec. Example: c7cfa2a8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:rollback"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: revisionId, var: revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec, name: $name, revision_id: $revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TagApiSpecRevision adds a tag to a specified revision of a spec.
#
# POST /v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:tagRevision
# Returns: record<annotations: record, contents: string, createTime: string, description: string, filename: string, hash: string, labels: record, mimeType: string, name: string, revisionCreateTime: string, revisionId: string, revisionUpdateTime: string, sizeBytes: int, sourceUri: string>
# operationId: Registry_TagApiSpecRevision
export def "registry-tag-api-spec-revision" [
  project: string
  location: string
  api: string
  version: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Required. The name of the spec to be tagged, including the revision ID.
  tag: string # Required. The tag to apply. The tag should be at most 40 characters, and match `[a-z][a-z0-9-]{3,39}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/apis/{api}/versions/{version}/specs/{spec}:tagRevision"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: api, var: api}, {name: version, var: version}, {name: spec, var: spec}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, api: $api, version: $version, spec: $spec, name: $name, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListArtifacts returns matching artifacts.
#
# GET /v1/projects/{project}/locations/{location}/artifacts
# Returns: record<artifacts: table<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>, nextPageToken: string>
# operationId: Registry_ListArtifacts
export def "registry-list-artifacts" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # The maximum number of artifacts to return. The service may return fewer than this value. If unspecified, at most 50 values will be returned. The maximum is 1000; values above 1000 will be coerced to 1000. (format: int32)
  --page-token: string # A page token, received from a previous `ListArtifacts` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListArtifacts` must match the call that provided the page token.
  --filter: string # An expression that can be used to filter the list. Filters use the Common Expression Language and can refer to all message fields except contents.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/artifacts"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: filter, var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, page_size: $page_size, page_token: $page_token, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateArtifact creates a specified artifact.
#
# POST /v1/projects/{project}/locations/{location}/artifacts
# Returns: record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>
# operationId: Registry_CreateArtifact
export def "registry-create-artifact" [
  project: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-id: string # Required. The ID to use for the artifact, which will become the final component of the artifact's resource name. This value should be 4-63 characters, and valid characters are /[a-z][0-9]-/. Following AIP-162, IDs must not have the form of a UUID.
  --contents: string # Input only. The contents of the artifact. Provided by API callers when artifacts are created or replaced. To access the contents of an artifact, use GetArtifactContents. (format: bytes)
  --mime-type: string # A content type specifier for the artifact. Content type specifiers are Media Types (https://en.wikipedia.org/wiki/Media_type) with a possible "schema" parameter that specifies a schema for the stored information. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/projects/{project}/locations/{location}/artifacts"
    path_params: [{name: project, var: project}, {name: location, var: location}]
    query: [{name: artifactId, var: artifact_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contents, var: contents}, {name: mimeType, var: mime_type}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, artifact_id: $artifact_id, contents: $contents, mime_type: $mime_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DeleteArtifact removes a specified artifact.
#
# DELETE /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# operationId: Registry_DeleteArtifact
export def "registry-delete-artifact" [
  project: string
  location: string
  artifact: string
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
    path: "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: artifact, var: artifact}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, artifact: $artifact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetArtifact returns a specified artifact.
#
# GET /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# Returns: record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>
# operationId: Registry_GetArtifact
export def "registry-get-artifact" [
  project: string
  location: string
  artifact: string
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
    path: "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: artifact, var: artifact}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, artifact: $artifact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ReplaceArtifact can be used to replace a specified artifact.
#
# PUT /v1/projects/{project}/locations/{location}/artifacts/{artifact}
# Returns: record<contents: string, createTime: string, hash: string, mimeType: string, name: string, sizeBytes: int, updateTime: string>
# operationId: Registry_ReplaceArtifact
export def "registry-replace-artifact" [
  project: string
  location: string
  artifact: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: string # Input only. The contents of the artifact. Provided by API callers when artifacts are created or replaced. To access the contents of an artifact, use GetArtifactContents. (format: bytes)
  --mime-type: string # A content type specifier for the artifact. Content type specifiers are Media Types (https://en.wikipedia.org/wiki/Media_type) with a possible "schema" parameter that specifies a schema for the stored information. Content types can specify compression. Currently only GZip compression is supported (indicated with "+gzip").
  --name: string # Resource name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/projects/{project}/locations/{location}/artifacts/{artifact}"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: artifact, var: artifact}]
    body: {content_type: "application/json", kind: json, fields: [{name: contents, var: contents}, {name: mimeType, var: mime_type}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, artifact: $artifact, contents: $contents, mime_type: $mime_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GetArtifactContents returns the contents of a specified artifact. If artifacts are stored with GZip compression, the default behavior is to return the artifact uncompressed (the mime_type response field indicates the exact format returned).
#
# GET /v1/projects/{project}/locations/{location}/artifacts/{artifact}:getContents
# operationId: Registry_GetArtifactContents
export def "registry-get-artifact-contents" [
  project: string
  location: string
  artifact: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/projects/{project}/locations/{location}/artifacts/{artifact}:getContents"
    path_params: [{name: project, var: project}, {name: location, var: location}, {name: artifact, var: artifact}]
    accept: ["*/*", "application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, location: $location, artifact: $artifact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
