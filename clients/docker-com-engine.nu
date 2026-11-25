# Auto-generated client for Docker Engine API v1.33
# Source: https://api.apis.guru/v2/specs/docker.com/engine/1.33/openapi.json
# Auth: --token flag or $env.DOCKER_ENGINE_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/v1.33"
  token_env_var: "DOCKER_ENGINE_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/v1.33" "https://docker.com/1.33"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["application/x-tar"] }
def accept-completer [] { ["application/json" "text/plain"] }
def availability-completer [] { ["active" "drain" "pause"] }
def role-completer [] { ["manager" "worker"] }
def accept-completer-1 [] { ["application/json" "application/vnd.docker.raw-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    system-ping: "string"
    system-auth: "record<IdentityToken: string, Status: string>"
    build-prune: "record<SpaceReclaimed: int>"
    image-commit: "record<Id: string>"
    config-list: "table<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>"
    config-create: "record<ID: string>"
    config-inspect: "record<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>"
    container-create: "record<Id: string, Warnings: list<string>>"
    container-list: "table<Command: string, Created: int, HostConfig: record<NetworkMode: string>, Id: string, Image: string, ImageID: string, Labels: record, Mounts: list<record>, Names: list<string>, NetworkSettings: record<Networks: record>, Ports: list<record>, SizeRootFs: int, SizeRw: int, State: string, Status: string>"
    container-prune: "record<ContainersDeleted: list<string>, SpaceReclaimed: int>"
    container-archive-info: "record"
    container-changes: "table<Kind: int, Path: string>"
    container-exec: "record<Id: string>"
    container-inspect: "record<AppArmorProfile: string, Args: list<string>, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, Driver: string, ExecIDs: string, GraphDriver: record<Data: record, Name: string>, HostConfig: record<BlkioDeviceReadBps: list<record>, BlkioDeviceReadIOps: list<record>, BlkioDeviceWriteBps: list<record>, BlkioDeviceWriteIOps: list<record>, BlkioWeight: int, BlkioWeightDevice: list<record>, CgroupParent: string, CpuCount: int, CpuPercent: int, CpuPeriod: int, CpuQuota: int, CpuRealtimePeriod: int, CpuRealtimeRuntime: int, CpuShares: int, CpusetCpus: string, CpusetMems: string, DeviceCgroupRules: list<string>, Devices: list<record>, DiskQuota: int, IOMaximumBandwidth: int, IOMaximumIOps: int, KernelMemory: int, Memory: int, MemoryReservation: int, MemorySwap: int, MemorySwappiness: int, NanoCPUs: int, OomKillDisable: bool, PidsLimit: int, Ulimits: list<record>, AutoRemove: bool, Binds: list<string>, CapAdd: list<string>, CapDrop: list<string>, Cgroup: string, ConsoleSize: list<int>, ContainerIDFile: string, Dns: list<string>, DnsOptions: list<string>, DnsSearch: list<string>, ExtraHosts: list<string>, GroupAdd: list<string>, IpcMode: string, Isolation: string, Links: list<string>, LogConfig: record<Config: record, Type: string>, Mounts: list<record>, NetworkMode: string, OomScoreAdj: int, PidMode: string, PortBindings: record, Privileged: bool, PublishAllPorts: bool, ReadonlyRootfs: bool, RestartPolicy: record<MaximumRetryCount: int, Name: string>, Runtime: string, SecurityOpt: list<string>, ShmSize: int, StorageOpt: record, Sysctls: record, Tmpfs: record, UTSMode: string, UsernsMode: string, VolumeDriver: string, VolumesFrom: list<string>>, HostnamePath: string, HostsPath: string, Id: string, Image: string, LogPath: string, MountLabel: string, Mounts: table<Destination: string, Driver: string, Mode: string, Name: string, Propagation: string, RW: bool, Source: string, Type: string>, Name: string, NetworkSettings: record<Bridge: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, HairpinMode: bool, IPAddress: string, IPPrefixLen: int, IPv6Gateway: string, LinkLocalIPv6Address: string, LinkLocalIPv6PrefixLen: int, MacAddress: string, Networks: record, Ports: record, SandboxID: string, SandboxKey: string, SecondaryIPAddresses: list<record>, SecondaryIPv6Addresses: list<record>>, Node: record, Path: string, ProcessLabel: string, ResolvConfPath: string, RestartCount: int, SizeRootFs: int, SizeRw: int, State: record<Dead: bool, Error: string, ExitCode: int, FinishedAt: string, OOMKilled: bool, Paused: bool, Pid: int, Restarting: bool, Running: bool, StartedAt: string, Status: string>>"
    container-logs: "string"
    container-stats: "record"
    container-top: "record<Processes: list<list<string>>, Titles: list<string>>"
    container-update: "record<Warnings: list<string>>"
    container-wait: "record<StatusCode: int>"
    distribution-inspect: "record<Descriptor: record<Digest: string, MediaType: string, Size: int, URLs: list<string>>, Platforms: table<Architecture: string, Features: list, OS: string, OSFeatures: list, OSVersion: string, Variant: string>>"
    system-events: "record<Action: string, Actor: record<Attributes: record, ID: string>, Type: string, time: int, timeNano: int>"
    exec-inspect: "record<ContainerID: string, ExitCode: int, ID: string, OpenStderr: bool, OpenStdin: bool, OpenStdout: bool, Pid: int, ProcessConfig: record<arguments: list<string>, entrypoint: string, privileged: bool, tty: bool, user: string>, Running: bool>"
    image-get-all: "binary"
    image-list: "table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list<string>, RepoTags: list<string>, SharedSize: int, Size: int, VirtualSize: int>"
    image-prune: "record<ImagesDeleted: table<Deleted: string, Untagged: string>, SpaceReclaimed: int>"
    image-search: "table<description: string, is_automated: bool, is_official: bool, name: string, star_count: int>"
    image-delete: "table<Deleted: string, Untagged: string>"
    image-get: "binary"
    image-history: "table<Comment: string, Created: int, CreatedBy: string, Id: string, Size: int, Tags: list<string>>"
    image-inspect: "record<Architecture: string, Author: string, Comment: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, DockerVersion: string, GraphDriver: record<Data: record, Name: string>, Id: string, Metadata: record<LastTagTime: string>, Os: string, OsVersion: string, Parent: string, RepoDigests: list<string>, RepoTags: list<string>, RootFS: record<BaseLayer: string, Layers: list<string>, Type: string>, Size: int, VirtualSize: int>"
    system-info: "record<Architecture: string, BridgeNfIp6tables: bool, BridgeNfIptables: bool, CPUSet: bool, CPUShares: bool, CgroupDriver: string, ClusterAdvertise: string, ClusterStore: string, ContainerdCommit: record<Expected: string, ID: string>, Containers: int, ContainersPaused: int, ContainersRunning: int, ContainersStopped: int, CpuCfsPeriod: bool, CpuCfsQuota: bool, Debug: bool, DefaultRuntime: string, DockerRootDir: string, Driver: string, DriverStatus: list<list<string>>, ExperimentalBuild: bool, GenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, HttpProxy: string, HttpsProxy: string, ID: string, IPv4Forwarding: bool, Images: int, IndexServerAddress: string, InitBinary: string, InitCommit: record<Expected: string, ID: string>, Isolation: string, KernelMemory: bool, KernelVersion: string, Labels: list<string>, LiveRestoreEnabled: bool, LoggingDriver: string, MemTotal: int, MemoryLimit: bool, NCPU: int, NEventsListener: int, NFd: int, NGoroutines: int, Name: string, NoProxy: string, OSType: string, OomKillDisable: bool, OperatingSystem: string, Plugins: record<Authorization: list<string>, Log: list<string>, Network: list<string>, Volume: list<string>>, RegistryConfig: record<AllowNondistributableArtifactsCIDRs: list<string>, AllowNondistributableArtifactsHostnames: list<string>, IndexConfigs: record, InsecureRegistryCIDRs: list<string>, Mirrors: list<string>>, RuncCommit: record<Expected: string, ID: string>, Runtimes: record, SecurityOptions: list<string>, ServerVersion: string, SwapLimit: bool, Swarm: record<Cluster: record<CreatedAt: string, ID: string, RootRotationInProgress: bool, Spec: record, TLSInfo: record, UpdatedAt: string, Version: record>, ControlAvailable: bool, Error: string, LocalNodeState: string, Managers: int, NodeAddr: string, NodeID: string, Nodes: int, RemoteManagers: list<record>>, SystemStatus: list<list<string>>, SystemTime: string>"
    network-list: "table<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list, Driver: string, Options: list>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string>"
    network-create: "record<Id: string, Warning: string>"
    network-prune: "record<NetworksDeleted: list<string>>"
    network-inspect: "record<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list<record>, Driver: string, Options: list<record>>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string>"
    node-list: "table<CreatedAt: string, Description: record<Engine: record, Hostname: string, Platform: record, Resources: record, TLSInfo: record>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>>"
    node-inspect: "record<CreatedAt: string, Description: record<Engine: record<EngineVersion: string, Labels: record, Plugins: list>, Hostname: string, Platform: record<Architecture: string, OS: string>, Resources: record<GenericResources: list, MemoryBytes: int, NanoCPUs: int>, TLSInfo: record<CertIssuerPublicKey: string, CertIssuerSubject: string, TrustRoot: string>>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>>"
    plugin-list: "table<Config: record<Args: record, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list, Env: list, Interface: record, IpcHost: bool, Linux: record, Mounts: list, Network: record, PidHost: bool, PropagatedMount: string, User: record, WorkDir: string, rootfs: record>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list, Devices: list, Env: list, Mounts: list>>"
    get-plugin-privileges: "table<Description: string, Name: string, Value: list<string>>"
    plugin-delete: "record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>>"
    plugin-inspect: "record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>>"
    secret-list: "table<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>"
    secret-create: "record<ID: string>"
    secret-inspect: "record<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record<Name: string, Options: record>, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>"
    service-list: "table<CreatedAt: string, Endpoint: record<Ports: list, Spec: record, VirtualIPs: list>, ID: string, Spec: record<EndpointSpec: record, Labels: record, Mode: record, Name: string, Networks: list, RollbackConfig: record, TaskTemplate: record, UpdateConfig: record>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>>"
    service-create: "record<ID: string, Warning: string>"
    service-inspect: "record<CreatedAt: string, Endpoint: record<Ports: list<record>, Spec: record<Mode: string, Ports: list>, VirtualIPs: list<record>>, ID: string, Spec: record<EndpointSpec: record<Mode: string, Ports: list>, Labels: record, Mode: record<Global: record, Replicated: record>, Name: string, Networks: list<record>, RollbackConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>, TaskTemplate: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, UpdateConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>>"
    service-logs: "string"
    service-update: "record<Warnings: list<string>>"
    swarm-inspect: "record<CreatedAt: string, ID: string, RootRotationInProgress: bool, Spec: record<CAConfig: record<ExternalCAs: list, ForceRotate: int, NodeCertExpiry: int, SigningCACert: string, SigningCAKey: string>, Dispatcher: record<HeartbeatPeriod: int>, EncryptionConfig: record<AutoLockManagers: bool>, Labels: record, Name: string, Orchestration: record<TaskHistoryRetentionLimit: int>, Raft: record<ElectionTick: int, HeartbeatTick: int, KeepOldSnapshots: int, LogEntriesForSlowFollowers: int, SnapshotInterval: int>, TaskDefaults: record<LogDriver: record>>, TLSInfo: record<CertIssuerPublicKey: string, CertIssuerSubject: string, TrustRoot: string>, UpdatedAt: string, Version: record<Index: int>, JoinTokens: record<Manager: string, Worker: string>>"
    swarm-init: "string"
    swarm-unlockkey: "record<UnlockKey: string>"
    system-data-usage: "record<Containers: list<list<record>>, Images: table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list, RepoTags: list, SharedSize: int, Size: int, VirtualSize: int>, LayersSize: int, Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>>"
    task-list: "table<AssignedGenericResources: list<record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, Status: record<ContainerStatus: record, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>>"
    task-inspect: "record<AssignedGenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record<Args: list, Command: list, Configs: list, DNSConfig: record, Dir: string, Env: list, Groups: list, HealthCheck: record, Hostname: string, Hosts: list, Image: string, Labels: record, Mounts: list, OpenStdin: bool, Privileges: record, ReadOnly: bool, Secrets: list, StopGracePeriod: int, StopSignal: string, TTY: bool, User: string>, ForceUpdate: int, LogDriver: record<Name: string, Options: record>, Networks: list<record>, Placement: record<Constraints: list, Platforms: list, Preferences: list>, PluginSpec: record<Disabled: bool, Name: string, PluginPrivilege: list, Remote: string>, Resources: record<Limits: record, Reservation: record>, RestartPolicy: record<Condition: string, Delay: int, MaxAttempts: int, Window: int>, Runtime: string>, Status: record<ContainerStatus: record<ContainerID: string, ExitCode: int, PID: int>, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>>"
    task-logs: "string"
    system-version: "record<ApiVersion: string, Arch: string, BuildTime: string, Experimental: bool, GitCommit: string, GoVersion: string, KernelVersion: string, MinAPIVersion: string, Os: string, Version: string>"
    volume-list: "record<Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>, Warnings: list<string>>"
    volume-create: "record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>>"
    volume-prune: "record<SpaceReclaimed: int, VolumesDeleted: list<string>>"
    volume-inspect: "record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["system-ping" "system-auth" "image-build" "build-prune" "image-commit" "config-list" "config-create" "config-delete" "config-inspect" "config-update" "container-create" "container-list" "container-prune" "container-delete" "container-archive" "container-archive-info" "put-container-archive" "container-attach" "container-attach-websocket" "container-changes" "container-exec" "container-export" "container-inspect" "container-kill" "container-logs" "container-pause" "container-rename" "container-resize" "container-restart" "container-start" "container-stats" "container-stop" "container-top" "container-unpause" "container-update" "container-wait" "distribution-inspect" "system-events" "exec-inspect" "exec-resize" "exec-start" "image-create" "image-get-all" "image-list" "image-load" "image-prune" "image-search" "image-delete" "image-get" "image-history" "image-inspect" "image-push" "image-tag" "system-info" "network-list" "network-create" "network-prune" "network-delete" "network-inspect" "network-connect" "network-disconnect" "node-list" "node-delete" "node-inspect" "node-update" "plugin-list" "plugin-create" "get-plugin-privileges" "plugin-pull" "plugin-delete" "plugin-disable" "plugin-enable" "plugin-inspect" "plugin-push" "plugin-set" "plugin-upgrade" "secret-list" "secret-create" "secret-delete" "secret-inspect" "secret-update" "service-list" "service-create" "service-delete" "service-inspect" "service-logs" "service-update" "session" "swarm-inspect" "swarm-init" "swarm-join" "swarm-leave" "swarm-unlock" "swarm-unlockkey" "swarm-update" "system-data-usage" "task-list" "task-inspect" "task-logs" "system-version" "volume-list" "volume-create" "volume-prune" "volume-delete" "volume-inspect" "commands"] | sort) } | get name | first)
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

# Ping
#
# GET /_ping
# Returns: string
# operationId: SystemPing
export def "system-ping" [
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
    path: "/_ping"
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check auth configuration
#
# POST /auth
# Returns: record<IdentityToken: string, Status: string>
# operationId: SystemAuth
export def "system-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --password: string
  --serveraddress: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}, {name: serveraddress, var: serveraddress}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    email: $email, password: $password, serveraddress: $serveraddress, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Build an image
#
# POST /build
# operationId: ImageBuild
export def "image-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dockerfile: string # Path within the build context to the `Dockerfile`. This is ignored if `remote` is specified and points to an external `Dockerfile`. (default: Dockerfile)
  --t: string # A name and optional tag to apply to the image in the `name:tag` format. If you omit the tag the default `latest` value is assumed. You can provide several `t` parameters.
  --extrahosts: string # Extra hosts to add to /etc/hosts
  --remote: string # A Git repository URI or HTTP/HTTPS context URI. If the URI points to a single text file, the file’s contents are placed into a file called `Dockerfile` and the image is built from that file. If the URI points to a tarball, the file is downloaded by the daemon and the contents therein used as the context for the build. If the URI points to a tarball and the `dockerfile` parameter is also specified, there must be a file with the corresponding path inside the tarball.
  --q: oneof<nothing, bool> # Suppress verbose build output. (default: false)
  --nocache: oneof<nothing, bool> # Do not use the cache when building the image. (default: false)
  --cachefrom: string # JSON array of images used for build cache resolution.
  --pull: string # Attempt to pull the image even if an older image exists locally.
  --rm: oneof<nothing, bool> # Remove intermediate containers after a successful build. (default: true)
  --forcerm: oneof<nothing, bool> # Always remove intermediate containers, even upon failure. (default: false)
  --memory: int # Set memory limit for build.
  --memswap: int # Total memory (memory + swap). Set as `-1` to disable swap.
  --cpushares: int # CPU shares (relative weight).
  --cpusetcpus: string # CPUs in which to allow execution (e.g., `0-3`, `0,1`).
  --cpuperiod: int # The length of a CPU period in microseconds.
  --cpuquota: int # Microseconds of CPU time that the container can get in a CPU period.
  --buildargs: int # JSON map of string pairs for build-time variables. Users pass these values at build-time. Docker uses the buildargs as the environment context for commands run via the `Dockerfile` RUN instruction, or for variable expansion in other `Dockerfile` instructions. This is not meant for passing secret values. [Read more about the buildargs instruction.](https://docs.docker.com/engine/reference/builder/#arg)
  --shmsize: int # Size of `/dev/shm` in bytes. The size must be greater than 0. If omitted the system uses 64MB.
  --squash: oneof<nothing, bool> # Squash the resulting images layers into a single layer. *(Experimental release only.)*
  --labels: string # Arbitrary key/value labels to set on the image, as a JSON map of string pairs.
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are: `bridge`, `host`, `none`, and `container:<name|id>`. Any other value is taken as a custom network's name to which this container should connect to.
  --content-type: string@content-type-completer # default: application/x-tar
  --x-registry-config: string # This is a base64-encoded JSON object with auth configurations for multiple registries that a build may refer to. The key is a registry URL, and the value is an auth configuration object, [as described in the authentication section](#section/Authentication). For example: ``` { "docker.example.com": { "username": "janedoe", "password": "hunter2" }, "https://index.docker.io/v1/": { "username": "mobydock", "password": "conta1n3rize14" } } ``` Only the registry domain name (and port if not the default 443) are required. However, for legacy reasons, the Docker Hub registry must be specified with both a `https://` prefix and a `/v1/` suffix even though Docker will prefer to use the v2 registry API.
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/build"
    query: [{name: dockerfile, var: dockerfile}, {name: t, var: t}, {name: extrahosts, var: extrahosts}, {name: remote, var: remote}, {name: q, var: q}, {name: nocache, var: nocache}, {name: cachefrom, var: cachefrom}, {name: pull, var: pull}, {name: rm, var: rm}, {name: forcerm, var: forcerm}, {name: memory, var: memory}, {name: memswap, var: memswap}, {name: cpushares, var: cpushares}, {name: cpusetcpus, var: cpusetcpus}, {name: cpuperiod, var: cpuperiod}, {name: cpuquota, var: cpuquota}, {name: buildargs, var: buildargs}, {name: shmsize, var: shmsize}, {name: squash, var: squash}, {name: labels, var: labels}, {name: networkmode, var: networkmode}]
    header: [{name: Content-type, var: content_type}, {name: X-Registry-Config, var: x_registry_config}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dockerfile: $dockerfile, t: $t, extrahosts: $extrahosts, remote: $remote, q: $q, nocache: $nocache, cachefrom: $cachefrom, pull: $pull, rm: $rm, forcerm: $forcerm, memory: $memory, memswap: $memswap, cpushares: $cpushares, cpusetcpus: $cpusetcpus, cpuperiod: $cpuperiod, cpuquota: $cpuquota, buildargs: $buildargs, shmsize: $shmsize, squash: $squash, labels: $labels, networkmode: $networkmode, content_type: $content_type, x_registry_config: $x_registry_config, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete builder cache
#
# POST /build/prune
# Returns: record<SpaceReclaimed: int>
# operationId: BuildPrune
export def "build-prune" [
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
    path: "/build/prune"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new image from a container
#
# POST /commit
# Returns: record<Id: string>
# operationId: ImageCommit
export def "image-commit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --container: string # The ID or name of the container to commit
  --repo: string # Repository name for the created image
  --tag: string # Tag name for the create image
  --comment: string # Commit message
  --author: string # Author of the image (e.g., `John Hannibal Smith <hannibal@a-team.com>`)
  --pause: oneof<nothing, bool> # Whether to pause the container before committing (default: true)
  --changes: string # `Dockerfile` instructions to apply while committing
  --args-escaped: oneof<nothing, bool> # Command is already escaped (Windows only)
  --attach-stderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --attach-stdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --attach-stdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --cmd: any # Command to run specified as a string or an array of strings.
  --domainname: string # The domain name to use for the container.
  --entrypoint: any # The entry point for the container as a string or an array of strings. If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).
  --body-env: list<string> # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value. (spec name: Env)
  --exposed-ports: record # An object mapping ports to an empty object in the form: `{"/<tcp|udp>": {}}`
  --healthcheck: record # A test to perform to check that the container is healthy. — shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list<string>, Timeout?: int}
  --hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.
  --image: string # The name of the image to use when creating the container
  --labels: record # User-defined key/value metadata.
  --mac-address: string # MAC address of the container.
  --network-disabled: oneof<nothing, bool> # Disable networking for the container.
  --on-build: list<string> # `ONBUILD` metadata that were defined in the image's `Dockerfile`.
  --open-stdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --shell: list<string> # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.
  --stdin-once: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --stop-signal: string # Signal to stop a container as a string or unsigned integer. (default: SIGTERM)
  --stop-timeout: int # Timeout to stop a container in seconds. (default: 10)
  --tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed. (default: false)
  --user: string # The user that commands are run as inside the container.
  --volumes: record # An object mapping mount point paths inside the container to empty objects. — shape: {additionalProperties?: "{}"}
  --working-dir: string # The working directory for commands to run in.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/commit"
    query: [{name: container, var: container}, {name: repo, var: repo}, {name: tag, var: tag}, {name: comment, var: comment}, {name: author, var: author}, {name: pause, var: pause}, {name: changes, var: changes}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArgsEscaped, var: args_escaped}, {name: AttachStderr, var: attach_stderr}, {name: AttachStdin, var: attach_stdin}, {name: AttachStdout, var: attach_stdout}, {name: Cmd, var: cmd}, {name: Domainname, var: domainname}, {name: Entrypoint, var: entrypoint}, {name: Env, var: body_env}, {name: ExposedPorts, var: exposed_ports}, {name: Healthcheck, var: healthcheck}, {name: Hostname, var: hostname}, {name: Image, var: image}, {name: Labels, var: labels}, {name: MacAddress, var: mac_address}, {name: NetworkDisabled, var: network_disabled}, {name: OnBuild, var: on_build}, {name: OpenStdin, var: open_stdin}, {name: Shell, var: shell}, {name: StdinOnce, var: stdin_once}, {name: StopSignal, var: stop_signal}, {name: StopTimeout, var: stop_timeout}, {name: Tty, var: tty}, {name: User, var: user}, {name: Volumes, var: volumes}, {name: WorkingDir, var: working_dir}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    container: $container, repo: $repo, tag: $tag, comment: $comment, author: $author, pause: $pause, changes: $changes, args_escaped: $args_escaped, attach_stderr: $attach_stderr, attach_stdin: $attach_stdin, attach_stdout: $attach_stdout, cmd: $cmd, domainname: $domainname, entrypoint: $entrypoint, body_env: $body_env, exposed_ports: $exposed_ports, healthcheck: $healthcheck, hostname: $hostname, image: $image, labels: $labels, mac_address: $mac_address, network_disabled: $network_disabled, on_build: $on_build, open_stdin: $open_stdin, shell: $shell, stdin_once: $stdin_once, stop_signal: $stop_signal, stop_timeout: $stop_timeout, tty: $tty, user: $user, volumes: $volumes, working_dir: $working_dir
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List configs
#
# GET /configs
# Returns: table<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: ConfigList
export def "config-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the configs list. Available filters: - `id=` - `label= or label==value` - `name=` - `names=`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/configs"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a config
#
# POST /configs/create
# Returns: record<ID: string>
# operationId: ConfigCreate
export def "config-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) config data.
  --labels: record # User-defined key/value metadata.
  --name: string # User-defined name of the config.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/configs/create"
    body: {content_type: "application/json", kind: json, fields: [{name: Data, var: data}, {name: Labels, var: labels}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a config
#
# DELETE /configs/{id}
# operationId: ConfigDelete
export def "config-delete" [
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
    path: "/configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a config
#
# GET /configs/{id}
# Returns: record<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: ConfigInspect
export def "config-inspect" [
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
    path: "/configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Config
#
# POST /configs/{id}/update
# operationId: ConfigUpdate
export def "config-update" [
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
  --version: int # The version number of the config object being updated. This is required to avoid conflicting writes. (required, format: int64)
  --data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) config data.
  --labels: record # User-defined key/value metadata.
  --name: string # User-defined name of the config.
]: any -> any {
  $in | http-request {
    method: post
    path: "/configs/{id}/update"
    path_params: [{name: id, var: id}]
    query: [{name: version, var: version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Data, var: data}, {name: Labels, var: labels}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, version: $version, data: $data, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a container
#
# POST /containers/create
# Returns: record<Id: string, Warnings: list<string>>
# operationId: ContainerCreate
export def "container-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Assign the specified name to the container. Must match `/?[a-zA-Z0-9_-]+`.
  --args-escaped: oneof<nothing, bool> # Command is already escaped (Windows only)
  --attach-stderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --attach-stdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --attach-stdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --cmd: any # Command to run specified as a string or an array of strings.
  --domainname: string # The domain name to use for the container.
  --entrypoint: any # The entry point for the container as a string or an array of strings. If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).
  --body-env: list<string> # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value. (spec name: Env)
  --exposed-ports: record # An object mapping ports to an empty object in the form: `{"/<tcp|udp>": {}}`
  --healthcheck: record # A test to perform to check that the container is healthy. — shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list<string>, Timeout?: int}
  --hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.
  --image: string # The name of the image to use when creating the container
  --labels: record # User-defined key/value metadata.
  --mac-address: string # MAC address of the container.
  --network-disabled: oneof<nothing, bool> # Disable networking for the container.
  --on-build: list<string> # `ONBUILD` metadata that were defined in the image's `Dockerfile`.
  --open-stdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --shell: list<string> # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.
  --stdin-once: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --stop-signal: string # Signal to stop a container as a string or unsigned integer. (default: SIGTERM)
  --stop-timeout: int # Timeout to stop a container in seconds. (default: 10)
  --tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed. (default: false)
  --user: string # The user that commands are run as inside the container.
  --volumes: record # An object mapping mount point paths inside the container to empty objects. — shape: {additionalProperties?: "{}"}
  --working-dir: string # The working directory for commands to run in.
  --host-config: record # Container configuration that depends on the host we are running on — shape: {BlkioDeviceReadBps?: list, BlkioDeviceReadIOps?: list, BlkioDeviceWriteBps?: list, BlkioDeviceWriteIOps?: list, BlkioWeight?: int, BlkioWeightDevice?: list, CgroupParent?: string, CpuCount?: int, CpuPercent?: int, CpuPeriod?: int, CpuQuota?: int, CpuRealtimePeriod?: int, CpuRealtimeRuntime?: int, CpuShares?: int, CpusetCpus?: string, CpusetMems?: string, DeviceCgroupRules?: list<string>, Devices?: list, DiskQuota?: int, IOMaximumBandwidth?: int, IOMaximumIOps?: int, KernelMemory?: int, ... (43 more fields)}
  --networking-config: record # This container's networking configuration. — shape: {EndpointsConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/create"
    query: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: ArgsEscaped, var: args_escaped}, {name: AttachStderr, var: attach_stderr}, {name: AttachStdin, var: attach_stdin}, {name: AttachStdout, var: attach_stdout}, {name: Cmd, var: cmd}, {name: Domainname, var: domainname}, {name: Entrypoint, var: entrypoint}, {name: Env, var: body_env}, {name: ExposedPorts, var: exposed_ports}, {name: Healthcheck, var: healthcheck}, {name: Hostname, var: hostname}, {name: Image, var: image}, {name: Labels, var: labels}, {name: MacAddress, var: mac_address}, {name: NetworkDisabled, var: network_disabled}, {name: OnBuild, var: on_build}, {name: OpenStdin, var: open_stdin}, {name: Shell, var: shell}, {name: StdinOnce, var: stdin_once}, {name: StopSignal, var: stop_signal}, {name: StopTimeout, var: stop_timeout}, {name: Tty, var: tty}, {name: User, var: user}, {name: Volumes, var: volumes}, {name: WorkingDir, var: working_dir}, {name: HostConfig, var: host_config}, {name: NetworkingConfig, var: networking_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, args_escaped: $args_escaped, attach_stderr: $attach_stderr, attach_stdin: $attach_stdin, attach_stdout: $attach_stdout, cmd: $cmd, domainname: $domainname, entrypoint: $entrypoint, body_env: $body_env, exposed_ports: $exposed_ports, healthcheck: $healthcheck, hostname: $hostname, image: $image, labels: $labels, mac_address: $mac_address, network_disabled: $network_disabled, on_build: $on_build, open_stdin: $open_stdin, shell: $shell, stdin_once: $stdin_once, stop_signal: $stop_signal, stop_timeout: $stop_timeout, tty: $tty, user: $user, volumes: $volumes, working_dir: $working_dir, host_config: $host_config, networking_config: $networking_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List containers
#
# GET /containers/json
# Returns: table<Command: string, Created: int, HostConfig: record<NetworkMode: string>, Id: string, Image: string, ImageID: string, Labels: record, Mounts: list<record>, Names: list<string>, NetworkSettings: record<Networks: record>, Ports: list<record>, SizeRootFs: int, SizeRw: int, State: string, Status: string>
# operationId: ContainerList
export def "container-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Return all containers. By default, only running containers are shown (default: false)
  --limit: int # Return this number of most recently created containers, including non-running ones.
  --size: oneof<nothing, bool> # Return the size of container as fields `SizeRw` and `SizeRootFs`. (default: false)
  --filters: string # Filters to process on the container list, encoded as JSON (a `map[string][]string`). For example, `{"status": ["paused"]}` will only return paused containers. Available filters: - `ancestor`=(`<image-name>[:]`, ``, or `<image@digest>`) - `before`=(`` or ``) - `expose`=(`[/]`|`<startport-endport>/[]`) - `exited=` containers with exit code of `` - `health`=(`starting`|`healthy`|`unhealthy`|`none`) - `id=` a container's ID - `isolation=`(`default`|`process`|`hyperv`) (Windows daemon only) - `is-task=`(`true`|`false`) - `label=key` or `label="key=value"` of a container label - `name=` a container's name - `network`=(`` or ``) - `publish`=(`[/]`|`<startport-endport>/[]`) - `since`=(`` or ``) - `status=`(`created`|`restarting`|`running`|`removing`|`paused`|`exited`|`dead`) - `volume`=(`` or ``)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/containers/json"
    query: [{name: all, var: all}, {name: limit, var: limit}, {name: size, var: size}, {name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    all: $all, limit: $limit, size: $size, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete stopped containers
#
# POST /containers/prune
# Returns: record<ContainersDeleted: list<string>, SpaceReclaimed: int>
# operationId: ContainerPrune
export def "container-prune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters: - `until=` Prune containers created before this timestamp. The `` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=`, `label==`, `label!=`, or `label!==`) Prune containers with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/containers/prune"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a container
#
# DELETE /containers/{id}
# operationId: ContainerDelete
export def "container-delete" [
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
  --v: oneof<nothing, bool> # Remove the volumes associated with the container. (default: false)
  --force: oneof<nothing, bool> # If the container is running, kill it before removing it. (default: false)
  --link: oneof<nothing, bool> # Remove the specified link associated with the container. (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/containers/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: v, var: v}, {name: force, var: force}, {name: link, var: link}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, v: $v, force: $force, link: $link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an archive of a filesystem resource in a container
#
# GET /containers/{id}/archive
# operationId: ContainerArchive
export def "container-archive" [
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
  --path: string # Resource in the container’s filesystem to archive. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/containers/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: path, var: path, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information about files in a container
#
# HEAD /containers/{id}/archive
# Returns: record
# operationId: ContainerArchiveInfo
export def "container-archive-info" [
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
  --path: string # Resource in the container’s filesystem to archive. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/containers/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: path, var: path, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract an archive of files or folders to a directory in a container
#
# PUT /containers/{id}/archive
# operationId: PutContainerArchive
export def "put-container-archive" [
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
  --path: string # Path to a directory in the container to extract the archive’s contents into. (required)
  --no-overwrite-dir-non-dir: string # If “1”, “true”, or “True” then it will be an error if unpacking the given content would cause an existing directory to be replaced with a non-directory and vice versa.
  --body: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/containers/{id}/archive"
    path_params: [{name: id, var: id}]
    query: [{name: path, var: path, required: true}, {name: noOverwriteDirNonDir, var: no_overwrite_dir_non_dir}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, path: $path, no_overwrite_dir_non_dir: $no_overwrite_dir_non_dir, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach to a container
#
# POST /containers/{id}/attach
# operationId: ContainerAttach
export def "container-attach" [
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
  --detach-keys: string # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-` where `` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --logs: oneof<nothing, bool> # Replay previous logs from the container. This is useful for attaching to a container that has started and you want to output everything since the container started. If `stream` is also enabled, once all the previous output has been returned, it will seamlessly transition into streaming current output. (default: false)
  --stream: oneof<nothing, bool> # Stream attached streams from the time the request was made onwards (default: false)
  --stdin: oneof<nothing, bool> # Attach to `stdin` (default: false)
  --stdout: oneof<nothing, bool> # Attach to `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Attach to `stderr` (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/attach"
    path_params: [{name: id, var: id}]
    query: [{name: detachKeys, var: detach_keys}, {name: logs, var: logs}, {name: stream, var: stream}, {name: stdin, var: stdin}, {name: stdout, var: stdout}, {name: stderr, var: stderr}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, detach_keys: $detach_keys, logs: $logs, stream: $stream, stdin: $stdin, stdout: $stdout, stderr: $stderr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attach to a container via a websocket
#
# GET /containers/{id}/attach/ws
# operationId: ContainerAttachWebsocket
export def "container-attach-websocket" [
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
  --detach-keys: string # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-` where `` is one of: `a-z`, `@`, `^`, `[`, `,`, or `_`.
  --logs: oneof<nothing, bool> # Return logs (default: false)
  --stream: oneof<nothing, bool> # Return stream (default: false)
  --stdin: oneof<nothing, bool> # Attach to `stdin` (default: false)
  --stdout: oneof<nothing, bool> # Attach to `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Attach to `stderr` (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/containers/{id}/attach/ws"
    path_params: [{name: id, var: id}]
    query: [{name: detachKeys, var: detach_keys}, {name: logs, var: logs}, {name: stream, var: stream}, {name: stdin, var: stdin}, {name: stdout, var: stdout}, {name: stderr, var: stderr}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, detach_keys: $detach_keys, logs: $logs, stream: $stream, stdin: $stdin, stdout: $stdout, stderr: $stderr
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get changes on a container’s filesystem
#
# GET /containers/{id}/changes
# Returns: table<Kind: int, Path: string>
# operationId: ContainerChanges
export def "container-changes" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{id}/changes"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an exec instance
#
# POST /containers/{id}/exec
# Returns: record<Id: string>
# operationId: ContainerExec
export def "container-exec" [
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
  --attach-stderr: oneof<nothing, bool> # Attach to `stderr` of the exec command.
  --attach-stdin: oneof<nothing, bool> # Attach to `stdin` of the exec command.
  --attach-stdout: oneof<nothing, bool> # Attach to `stdout` of the exec command.
  --cmd: list<string> # Command to run, as a string or array of strings.
  --detach-keys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-` where `` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --body-env: list<string> # A list of environment variables in the form `["VAR=value", ...]`. (spec name: Env)
  --privileged: oneof<nothing, bool> # Runs the exec process with extended privileges. (default: false)
  --tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
  --user: string # The user, and optionally, group to run the exec process inside the container. Format is one of: `user`, `user:group`, `uid`, or `uid:gid`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/{id}/exec"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: AttachStderr, var: attach_stderr}, {name: AttachStdin, var: attach_stdin}, {name: AttachStdout, var: attach_stdout}, {name: Cmd, var: cmd}, {name: DetachKeys, var: detach_keys}, {name: Env, var: body_env}, {name: Privileged, var: privileged}, {name: Tty, var: tty}, {name: User, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, attach_stderr: $attach_stderr, attach_stdin: $attach_stdin, attach_stdout: $attach_stdout, cmd: $cmd, detach_keys: $detach_keys, body_env: $body_env, privileged: $privileged, tty: $tty, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export a container
#
# GET /containers/{id}/export
# operationId: ContainerExport
export def "container-export" [
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
    path: "/containers/{id}/export"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a container
#
# GET /containers/{id}/json
# Returns: record<AppArmorProfile: string, Args: list<string>, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, Driver: string, ExecIDs: string, GraphDriver: record<Data: record, Name: string>, HostConfig: record<BlkioDeviceReadBps: list<record>, BlkioDeviceReadIOps: list<record>, BlkioDeviceWriteBps: list<record>, BlkioDeviceWriteIOps: list<record>, BlkioWeight: int, BlkioWeightDevice: list<record>, CgroupParent: string, CpuCount: int, CpuPercent: int, CpuPeriod: int, CpuQuota: int, CpuRealtimePeriod: int, CpuRealtimeRuntime: int, CpuShares: int, CpusetCpus: string, CpusetMems: string, DeviceCgroupRules: list<string>, Devices: list<record>, DiskQuota: int, IOMaximumBandwidth: int, IOMaximumIOps: int, KernelMemory: int, Memory: int, MemoryReservation: int, MemorySwap: int, MemorySwappiness: int, NanoCPUs: int, OomKillDisable: bool, PidsLimit: int, Ulimits: list<record>, AutoRemove: bool, Binds: list<string>, CapAdd: list<string>, CapDrop: list<string>, Cgroup: string, ConsoleSize: list<int>, ContainerIDFile: string, Dns: list<string>, DnsOptions: list<string>, DnsSearch: list<string>, ExtraHosts: list<string>, GroupAdd: list<string>, IpcMode: string, Isolation: string, Links: list<string>, LogConfig: record<Config: record, Type: string>, Mounts: list<record>, NetworkMode: string, OomScoreAdj: int, PidMode: string, PortBindings: record, Privileged: bool, PublishAllPorts: bool, ReadonlyRootfs: bool, RestartPolicy: record<MaximumRetryCount: int, Name: string>, Runtime: string, SecurityOpt: list<string>, ShmSize: int, StorageOpt: record, Sysctls: record, Tmpfs: record, UTSMode: string, UsernsMode: string, VolumeDriver: string, VolumesFrom: list<string>>, HostnamePath: string, HostsPath: string, Id: string, Image: string, LogPath: string, MountLabel: string, Mounts: table<Destination: string, Driver: string, Mode: string, Name: string, Propagation: string, RW: bool, Source: string, Type: string>, Name: string, NetworkSettings: record<Bridge: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, HairpinMode: bool, IPAddress: string, IPPrefixLen: int, IPv6Gateway: string, LinkLocalIPv6Address: string, LinkLocalIPv6PrefixLen: int, MacAddress: string, Networks: record, Ports: record, SandboxID: string, SandboxKey: string, SecondaryIPAddresses: list<record>, SecondaryIPv6Addresses: list<record>>, Node: record, Path: string, ProcessLabel: string, ResolvConfPath: string, RestartCount: int, SizeRootFs: int, SizeRw: int, State: record<Dead: bool, Error: string, ExitCode: int, FinishedAt: string, OOMKilled: bool, Paused: bool, Pid: int, Restarting: bool, Running: bool, StartedAt: string, Status: string>>
# operationId: ContainerInspect
export def "container-inspect" [
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
  --size: oneof<nothing, bool> # Return the size of container as fields `SizeRw` and `SizeRootFs` (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{id}/json"
    path_params: [{name: id, var: id}]
    query: [{name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Kill a container
#
# POST /containers/{id}/kill
# operationId: ContainerKill
export def "container-kill" [
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
  --signal: string # Signal to send to the container as an integer or string (e.g. `SIGINT`) (default: SIGKILL)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/kill"
    path_params: [{name: id, var: id}]
    query: [{name: signal, var: signal}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, signal: $signal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get container logs
#
# GET /containers/{id}/logs
# Returns: string
# operationId: ContainerLogs
export def "container-logs" [
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
  --follow: oneof<nothing, bool> # Return the logs as a stream. This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach). (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> any {
  http-request {
    method: get
    path: "/containers/{id}/logs"
    path_params: [{name: id, var: id}]
    query: [{name: follow, var: follow}, {name: stdout, var: stdout}, {name: stderr, var: stderr}, {name: since, var: since}, {name: timestamps, var: timestamps}, {name: tail, var: tail}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, follow: $follow, stdout: $stdout, stderr: $stderr, since: $since, timestamps: $timestamps, tail: $tail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Pause a container
#
# POST /containers/{id}/pause
# operationId: ContainerPause
export def "container-pause" [
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
    method: post
    path: "/containers/{id}/pause"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename a container
#
# POST /containers/{id}/rename
# operationId: ContainerRename
export def "container-rename" [
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
  --name: string # New name for the container (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/rename"
    path_params: [{name: id, var: id}]
    query: [{name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resize a container TTY
#
# POST /containers/{id}/resize
# operationId: ContainerResize
export def "container-resize" [
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
  --h: int # Height of the tty session in characters
  --w: int # Width of the tty session in characters
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/resize"
    path_params: [{name: id, var: id}]
    query: [{name: h, var: h}, {name: w, var: w}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, h: $h, w: $w
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restart a container
#
# POST /containers/{id}/restart
# operationId: ContainerRestart
export def "container-restart" [
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
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/restart"
    path_params: [{name: id, var: id}]
    query: [{name: t, var: t}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, t: $t
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start a container
#
# POST /containers/{id}/start
# operationId: ContainerStart
export def "container-start" [
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
  --detach-keys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-` where `` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/start"
    path_params: [{name: id, var: id}]
    query: [{name: detachKeys, var: detach_keys}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    id: $id, detach_keys: $detach_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get container stats based on resource usage
#
# GET /containers/{id}/stats
# Returns: record
# operationId: ContainerStats
export def "container-stats" [
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
  --stream: oneof<nothing, bool> # Stream the output. If false, the stats will be output once and then it will disconnect. (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{id}/stats"
    path_params: [{name: id, var: id}]
    query: [{name: stream, var: stream}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, stream: $stream
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a container
#
# POST /containers/{id}/stop
# operationId: ContainerStop
export def "container-stop" [
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
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  http-request {
    method: post
    path: "/containers/{id}/stop"
    path_params: [{name: id, var: id}]
    query: [{name: t, var: t}]
    accept: ["application/json"]
    ok: [204, 304]
    auth: bearer
  } {
    id: $id, t: $t
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List processes running inside a container
#
# GET /containers/{id}/top
# Returns: record<Processes: list<list<string>>, Titles: list<string>>
# operationId: ContainerTop
export def "container-top" [
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
  --ps-args: string # The arguments to pass to `ps`. For example, `aux` (default: -ef)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/containers/{id}/top"
    path_params: [{name: id, var: id}]
    query: [{name: ps_args, var: ps_args}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ps_args: $ps_args
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Unpause a container
#
# POST /containers/{id}/unpause
# operationId: ContainerUnpause
export def "container-unpause" [
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
    method: post
    path: "/containers/{id}/unpause"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a container
#
# POST /containers/{id}/update
# Returns: record<Warnings: list<string>>
# operationId: ContainerUpdate
export def "container-update" [
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
  --blkio-device-read-bps: list # Limit read rate (bytes per second) from a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --blkio-device-read-i-ops: list # Limit read rate (IO per second) from a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --blkio-device-write-bps: list # Limit write rate (bytes per second) to a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --blkio-device-write-i-ops: list # Limit write rate (IO per second) to a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --blkio-weight: int # Block IO weight (relative weight).
  --blkio-weight-device: list # Block IO weight (relative device weight) in the form `[{"Path": "device_path", "Weight": weight}]`. — item shape: {Path?: string, Weight?: int}
  --cgroup-parent: string # Path to `cgroups` under which the container's `cgroup` is created. If the path is not absolute, the path is considered to be relative to the `cgroups` path of the init process. Cgroups are created if they do not already exist.
  --cpu-count: int # The number of usable CPUs (Windows only). On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last. (format: int64)
  --cpu-percent: int # The usable percentage of the available CPUs (Windows only). On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last. (format: int64)
  --cpu-period: int # The length of a CPU period in microseconds. (format: int64)
  --cpu-quota: int # Microseconds of CPU time that the container can get in a CPU period. (format: int64)
  --cpu-realtime-period: int # The length of a CPU real-time period in microseconds. Set to 0 to allocate no time allocated to real-time tasks. (format: int64)
  --cpu-realtime-runtime: int # The length of a CPU real-time runtime in microseconds. Set to 0 to allocate no time allocated to real-time tasks. (format: int64)
  --cpu-shares: int # An integer value representing this container's relative CPU weight versus other containers.
  --cpuset-cpus: string # CPUs in which to allow execution (e.g., `0-3`, `0,1`) (e.g. 0-3)
  --cpuset-mems: string # Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective on NUMA systems.
  --device-cgroup-rules: list<string> # a list of cgroup rules to apply to the container
  --devices: list # A list of devices to add to the container. — item shape: {CgroupPermissions?: string, PathInContainer?: string, PathOnHost?: string}
  --disk-quota: int # Disk limit (in bytes). (format: int64)
  --io-maximum-bandwidth: int # Maximum IO in bytes per second for the container system drive (Windows only) (format: int64)
  --io-maximum-i-ops: int # Maximum IOps for the container system drive (Windows only) (format: int64)
  --kernel-memory: int # Kernel memory limit in bytes. (format: int64)
  --memory: int # Memory limit in bytes. (default: 0)
  --memory-reservation: int # Memory soft limit in bytes. (format: int64)
  --memory-swap: int # Total memory limit (memory + swap). Set as `-1` to enable unlimited swap. (format: int64)
  --memory-swappiness: int # Tune a container's memory swappiness behavior. Accepts an integer between 0 and 100. (format: int64)
  --nano-cp-us: int # CPU quota in units of 10-9 CPUs. (format: int64)
  --oom-kill-disable: oneof<nothing, bool> # Disable OOM Killer for the container.
  --pids-limit: int # Tune a container's pids limit. Set -1 for unlimited. (format: int64)
  --ulimits: list # A list of resource limits to set in the container. For example: `{"Name": "nofile", "Soft": 1024, "Hard": 2048}`" — item shape: {Hard?: int, Name?: string, Soft?: int}
  --restart-policy: record # The behavior to apply when the container exits. The default is not to restart. An ever increasing delay (double the previous delay, starting at 100ms) is added before each restart to prevent flooding the server. — shape: {MaximumRetryCount?: int, Name?: ""|"always"|"unless-stopped"|"on-failure"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/containers/{id}/update"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: BlkioDeviceReadBps, var: blkio_device_read_bps}, {name: BlkioDeviceReadIOps, var: blkio_device_read_i_ops}, {name: BlkioDeviceWriteBps, var: blkio_device_write_bps}, {name: BlkioDeviceWriteIOps, var: blkio_device_write_i_ops}, {name: BlkioWeight, var: blkio_weight}, {name: BlkioWeightDevice, var: blkio_weight_device}, {name: CgroupParent, var: cgroup_parent}, {name: CpuCount, var: cpu_count}, {name: CpuPercent, var: cpu_percent}, {name: CpuPeriod, var: cpu_period}, {name: CpuQuota, var: cpu_quota}, {name: CpuRealtimePeriod, var: cpu_realtime_period}, {name: CpuRealtimeRuntime, var: cpu_realtime_runtime}, {name: CpuShares, var: cpu_shares}, {name: CpusetCpus, var: cpuset_cpus}, {name: CpusetMems, var: cpuset_mems}, {name: DeviceCgroupRules, var: device_cgroup_rules}, {name: Devices, var: devices}, {name: DiskQuota, var: disk_quota}, {name: IOMaximumBandwidth, var: io_maximum_bandwidth}, {name: IOMaximumIOps, var: io_maximum_i_ops}, {name: KernelMemory, var: kernel_memory}, {name: Memory, var: memory}, {name: MemoryReservation, var: memory_reservation}, {name: MemorySwap, var: memory_swap}, {name: MemorySwappiness, var: memory_swappiness}, {name: NanoCPUs, var: nano_cp_us}, {name: OomKillDisable, var: oom_kill_disable}, {name: PidsLimit, var: pids_limit}, {name: Ulimits, var: ulimits}, {name: RestartPolicy, var: restart_policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, blkio_device_read_bps: $blkio_device_read_bps, blkio_device_read_i_ops: $blkio_device_read_i_ops, blkio_device_write_bps: $blkio_device_write_bps, blkio_device_write_i_ops: $blkio_device_write_i_ops, blkio_weight: $blkio_weight, blkio_weight_device: $blkio_weight_device, cgroup_parent: $cgroup_parent, cpu_count: $cpu_count, cpu_percent: $cpu_percent, cpu_period: $cpu_period, cpu_quota: $cpu_quota, cpu_realtime_period: $cpu_realtime_period, cpu_realtime_runtime: $cpu_realtime_runtime, cpu_shares: $cpu_shares, cpuset_cpus: $cpuset_cpus, cpuset_mems: $cpuset_mems, device_cgroup_rules: $device_cgroup_rules, devices: $devices, disk_quota: $disk_quota, io_maximum_bandwidth: $io_maximum_bandwidth, io_maximum_i_ops: $io_maximum_i_ops, kernel_memory: $kernel_memory, memory: $memory, memory_reservation: $memory_reservation, memory_swap: $memory_swap, memory_swappiness: $memory_swappiness, nano_cp_us: $nano_cp_us, oom_kill_disable: $oom_kill_disable, pids_limit: $pids_limit, ulimits: $ulimits, restart_policy: $restart_policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wait for a container
#
# POST /containers/{id}/wait
# Returns: record<StatusCode: int>
# operationId: ContainerWait
export def "container-wait" [
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
  --condition: string # Wait until a container state reaches the given condition, either 'not-running' (default), 'next-exit', or 'removed'. (default: not-running)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/containers/{id}/wait"
    path_params: [{name: id, var: id}]
    query: [{name: condition, var: condition}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, condition: $condition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get image information from the registry
#
# GET /distribution/{name}/json
# Returns: record<Descriptor: record<Digest: string, MediaType: string, Size: int, URLs: list<string>>, Platforms: table<Architecture: string, Features: list, OS: string, OSFeatures: list, OSVersion: string, Variant: string>>
# operationId: DistributionInspect
export def "distribution-inspect" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/distribution/{name}/json"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monitor events
#
# GET /events
# Returns: record<Action: string, Actor: record<Attributes: record, ID: string>, Type: string, time: int, timeNano: int>
# operationId: SystemEvents
export def "system-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Show events created since this timestamp then stream new events.
  --until: string # Show events created until this timestamp then stop streaming.
  --filters: string # A JSON encoded value of filters (a `map[string][]string`) to process on the event list. Available filters: - `config=` config name or ID - `container=` container name or ID - `daemon=` daemon name or ID - `event=` event type - `image=` image name or ID - `label=` image or container label - `network=` network name or ID - `node=` node ID - `plugin`= plugin name or ID - `scope`＝ local or swarm - `secret=` secret name or ID - `service=` service name or ID - `type=` object to filter by, one of `container`, `image`, `volume`, `network`, `daemon`, `plugin`, `node`, `service`, `secret` or `config` - `volume=` volume name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: since, var: since}, {name: until, var: until}, {name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since, until: $until, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect an exec instance
#
# GET /exec/{id}/json
# Returns: record<ContainerID: string, ExitCode: int, ID: string, OpenStderr: bool, OpenStdin: bool, OpenStdout: bool, Pid: int, ProcessConfig: record<arguments: list<string>, entrypoint: string, privileged: bool, tty: bool, user: string>, Running: bool>
# operationId: ExecInspect
export def "exec-inspect" [
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
    path: "/exec/{id}/json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resize an exec instance
#
# POST /exec/{id}/resize
# operationId: ExecResize
export def "exec-resize" [
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
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
]: nothing -> any {
  http-request {
    method: post
    path: "/exec/{id}/resize"
    path_params: [{name: id, var: id}]
    query: [{name: h, var: h}, {name: w, var: w}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, h: $h, w: $w
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start an exec instance
#
# POST /exec/{id}/start
# operationId: ExecStart
export def "exec-start" [
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
  --detach: oneof<nothing, bool> # Detach from the command.
  --tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
]: any -> any {
  $in | http-request {
    method: post
    path: "/exec/{id}/start"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Detach, var: detach}, {name: Tty, var: tty}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, detach: $detach, tty: $tty
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an image
#
# POST /images/create
# operationId: ImageCreate
export def "image-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-image: string # Name of the image to pull. The name may include a tag or digest. This parameter may only be used when pulling an image. The pull is cancelled if the HTTP connection is closed.
  --from-src: string # Source to import. The value may be a URL from which the image can be retrieved or `-` to read the image from the request body. This parameter may only be used when importing an image.
  --repo: string # Repository name given to an image when it is imported. The repo may include a tag. This parameter may only be used when importing an image.
  --tag: string # Tag or digest. If empty when pulling an image, this causes all tags for the given image to be pulled.
  --x-registry-auth: string # A base64-encoded auth configuration. [See the authentication section for details.](#section/Authentication)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/images/create"
    query: [{name: fromImage, var: from_image}, {name: fromSrc, var: from_src}, {name: repo, var: repo}, {name: tag, var: tag}]
    header: [{name: X-Registry-Auth, var: x_registry_auth}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    from_image: $from_image, from_src: $from_src, repo: $repo, tag: $tag, x_registry_auth: $x_registry_auth, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export several images
#
# GET /images/get
# Returns: binary
# operationId: ImageGetAll
export def "image-get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --names: list<string> # Image names to filter by
]: nothing -> any {
  http-request {
    method: get
    path: "/images/get"
    query: [{name: names, var: names, style: csv}]
    accept: ["application/x-tar"]
    ok: [200]
    auth: bearer
  } {
    names: $names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Images
#
# GET /images/json
# Returns: table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list<string>, RepoTags: list<string>, SharedSize: int, Size: int, VirtualSize: int>
# operationId: ImageList
export def "image-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Show all images. Only images from a final layer (no children) are shown by default. (default: false)
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list. Available filters: - `before`=(`<image-name>[:]`, `` or `<image@digest>`) - `dangling=true` - `label=key` or `label="key=value"` of an image label - `reference`=(`<image-name>[:]`) - `since`=(`<image-name>[:]`, `` or `<image@digest>`)
  --digests: oneof<nothing, bool> # Show digest information as a `RepoDigests` field on each image. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/json"
    query: [{name: all, var: all}, {name: filters, var: filters}, {name: digests, var: digests}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    all: $all, filters: $filters, digests: $digests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import images
#
# POST /images/load
# operationId: ImageLoad
export def "image-load" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quiet: oneof<nothing, bool> # Suppress progress details during load. (default: false)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/images/load"
    query: [{name: quiet, var: quiet}]
    body: {content_type: "application/x-tar", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    quiet: $quiet, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete unused images
#
# POST /images/prune
# Returns: record<ImagesDeleted: table<Deleted: string, Untagged: string>, SpaceReclaimed: int>
# operationId: ImagePrune
export def "image-prune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters: - `dangling=` When set to `true` (or `1`), prune only unused *and* untagged images. When set to `false` (or `0`), all unused images are pruned. - `until=` Prune images created before this timestamp. The `` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=`, `label==`, `label!=`, or `label!==`) Prune images with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/images/prune"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search images
#
# GET /images/search
# Returns: table<description: string, is_automated: bool, is_official: bool, name: string, star_count: int>
# operationId: ImageSearch
export def "image-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --term: string # Term to search (required)
  --limit: int # Maximum number of results to return
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list. Available filters: - `is-automated=(true|false)` - `is-official=(true|false)` - `stars=` Matches images that has at least 'number' stars.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/search"
    query: [{name: term, var: term, required: true}, {name: limit, var: limit}, {name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    term: $term, limit: $limit, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an image
#
# DELETE /images/{name}
# Returns: table<Deleted: string, Untagged: string>
# operationId: ImageDelete
export def "image-delete" [
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
  --force: oneof<nothing, bool> # Remove the image even if it is being used by stopped containers or has other tags (default: false)
  --noprune: oneof<nothing, bool> # Do not delete untagged parent images (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: delete
    path: "/images/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: force, var: force}, {name: noprune, var: noprune}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, force: $force, noprune: $noprune
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export an image
#
# GET /images/{name}/get
# Returns: binary
# operationId: ImageGet
export def "image-get" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/images/{name}/get"
    path_params: [{name: name, var: name}]
    accept: ["application/x-tar"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the history of an image
#
# GET /images/{name}/history
# Returns: table<Comment: string, Created: int, CreatedBy: string, Id: string, Size: int, Tags: list<string>>
# operationId: ImageHistory
export def "image-history" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{name}/history"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect an image
#
# GET /images/{name}/json
# Returns: record<Architecture: string, Author: string, Comment: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, DockerVersion: string, GraphDriver: record<Data: record, Name: string>, Id: string, Metadata: record<LastTagTime: string>, Os: string, OsVersion: string, Parent: string, RepoDigests: list<string>, RepoTags: list<string>, RootFS: record<BaseLayer: string, Layers: list<string>, Type: string>, Size: int, VirtualSize: int>
# operationId: ImageInspect
export def "image-inspect" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{name}/json"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Push an image
#
# POST /images/{name}/push
# operationId: ImagePush
export def "image-push" [
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
  --tag: string # The tag to associate with the image on the registry.
  --x-registry-auth: string # A base64-encoded auth configuration. [See the authentication section for details.](#section/Authentication) (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/images/{name}/push"
    path_params: [{name: name, var: name}]
    query: [{name: tag, var: tag}]
    header: [{name: X-Registry-Auth, var: x_registry_auth, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, tag: $tag, x_registry_auth: $x_registry_auth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tag an image
#
# POST /images/{name}/tag
# operationId: ImageTag
export def "image-tag" [
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
  --repo: string # The repository to tag in. For example, `someuser/someimage`.
  --tag: string # The name of the new tag.
]: nothing -> any {
  http-request {
    method: post
    path: "/images/{name}/tag"
    path_params: [{name: name, var: name}]
    query: [{name: repo, var: repo}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, repo: $repo, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get system information
#
# GET /info
# Returns: record<Architecture: string, BridgeNfIp6tables: bool, BridgeNfIptables: bool, CPUSet: bool, CPUShares: bool, CgroupDriver: string, ClusterAdvertise: string, ClusterStore: string, ContainerdCommit: record<Expected: string, ID: string>, Containers: int, ContainersPaused: int, ContainersRunning: int, ContainersStopped: int, CpuCfsPeriod: bool, CpuCfsQuota: bool, Debug: bool, DefaultRuntime: string, DockerRootDir: string, Driver: string, DriverStatus: list<list<string>>, ExperimentalBuild: bool, GenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, HttpProxy: string, HttpsProxy: string, ID: string, IPv4Forwarding: bool, Images: int, IndexServerAddress: string, InitBinary: string, InitCommit: record<Expected: string, ID: string>, Isolation: string, KernelMemory: bool, KernelVersion: string, Labels: list<string>, LiveRestoreEnabled: bool, LoggingDriver: string, MemTotal: int, MemoryLimit: bool, NCPU: int, NEventsListener: int, NFd: int, NGoroutines: int, Name: string, NoProxy: string, OSType: string, OomKillDisable: bool, OperatingSystem: string, Plugins: record<Authorization: list<string>, Log: list<string>, Network: list<string>, Volume: list<string>>, RegistryConfig: record<AllowNondistributableArtifactsCIDRs: list<string>, AllowNondistributableArtifactsHostnames: list<string>, IndexConfigs: record, InsecureRegistryCIDRs: list<string>, Mirrors: list<string>>, RuncCommit: record<Expected: string, ID: string>, Runtimes: record, SecurityOptions: list<string>, ServerVersion: string, SwapLimit: bool, Swarm: record<Cluster: record<CreatedAt: string, ID: string, RootRotationInProgress: bool, Spec: record, TLSInfo: record, UpdatedAt: string, Version: record>, ControlAvailable: bool, Error: string, LocalNodeState: string, Managers: int, NodeAddr: string, NodeID: string, Nodes: int, RemoteManagers: list<record>>, SystemStatus: list<list<string>>, SystemTime: string>
# operationId: SystemInfo
export def "system-info" [
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
    path: "/info"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List networks
#
# GET /networks
# Returns: table<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list, Driver: string, Options: list>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string>
# operationId: NetworkList
export def "network-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the networks list. Available filters: - `driver=<driver-name>` Matches a network's driver. - `id=<network-id>` Matches all or part of a network ID. - `label=` or `label==` of a network label. - `name=<network-name>` Matches all or part of a network name. - `scope=["swarm"|"global"|"local"]` Filters networks by scope (`swarm`, `global`, or `local`). - `type=["custom"|"builtin"]` Filters networks by type. The `custom` keyword returns all user-defined networks.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/networks"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a network
#
# POST /networks/create
# Returns: record<Id: string, Warning: string>
# operationId: NetworkCreate
export def "network-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachable: oneof<nothing, bool> # Globally scoped network is manually attachable by regular containers from workers in swarm mode.
  --check-duplicate: oneof<nothing, bool> # Check for networks with duplicate names. Since Network is primarily keyed based on a random ID and not on the name, and network name is strictly a user-friendly alias to the network which is uniquely identified using ID, there is no guaranteed way to check for duplicates. CheckDuplicate is there to provide a best effort checking of any networks which has the same name but it is not guaranteed to catch all name collisions.
  --driver: string # Name of the network driver plugin to use. (default: bridge)
  --enable-i-pv6: oneof<nothing, bool> # Enable IPv6 on the network.
  --ipam: record # shape: {Config?: list, Driver?: string, Options?: list}
  --ingress: oneof<nothing, bool> # Ingress network is the network which provides the routing-mesh in swarm mode.
  --internal: oneof<nothing, bool> # Restrict external access to the network.
  --labels: record # User-defined key/value metadata.
  name: string # The network's name.
  --options: record # Network specific options to be used by the drivers.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/networks/create"
    body: {content_type: "application/json", kind: json, fields: [{name: Attachable, var: attachable}, {name: CheckDuplicate, var: check_duplicate}, {name: Driver, var: driver}, {name: EnableIPv6, var: enable_i_pv6}, {name: IPAM, var: ipam}, {name: Ingress, var: ingress}, {name: Internal, var: internal}, {name: Labels, var: labels}, {name: Name, var: name}, {name: Options, var: options}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    attachable: $attachable, check_duplicate: $check_duplicate, driver: $driver, enable_i_pv6: $enable_i_pv6, ipam: $ipam, ingress: $ingress, internal: $internal, labels: $labels, name: $name, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete unused networks
#
# POST /networks/prune
# Returns: record<NetworksDeleted: list<string>>
# operationId: NetworkPrune
export def "network-prune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters: - `until=` Prune networks created before this timestamp. The `` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=`, `label==`, `label!=`, or `label!==`) Prune networks with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/networks/prune"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a network
#
# DELETE /networks/{id}
# operationId: NetworkDelete
export def "network-delete" [
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

# Inspect a network
#
# GET /networks/{id}
# Returns: record<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list<record>, Driver: string, Options: list<record>>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string>
# operationId: NetworkInspect
export def "network-inspect" [
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
  --verbose: oneof<nothing, bool> # Detailed inspect output for troubleshooting (default: false)
  --scope: string # Filter the network by scope (swarm, global, or local)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/networks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: verbose, var: verbose}, {name: scope, var: scope}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, verbose: $verbose, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect a container to a network
#
# POST /networks/{id}/connect
# operationId: NetworkConnect
export def "network-connect" [
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
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/networks/{id}/connect"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnect a container from a network
#
# POST /networks/{id}/disconnect
# operationId: NetworkDisconnect
export def "network-disconnect" [
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
  --container: string # The ID or name of the container to disconnect from the network.
  --force: oneof<nothing, bool> # Force the container to disconnect from the network.
]: any -> any {
  $in | http-request {
    method: post
    path: "/networks/{id}/disconnect"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Container, var: container}, {name: Force, var: force}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, container: $container, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List nodes
#
# GET /nodes
# Returns: table<CreatedAt: string, Description: record<Engine: record, Hostname: string, Platform: record, Resources: record, TLSInfo: record>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: NodeList
export def "node-list" [
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
  --filters: string # Filters to process on the nodes list, encoded as JSON (a `map[string][]string`). Available filters: - `id=` - `label=` - `membership=`(`accepted`|`pending`)` - `name=` - `role=`(`manager`|`worker`)`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/nodes"
    query: [{name: filters, var: filters}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a node
#
# DELETE /nodes/{id}
# operationId: NodeDelete
export def "node-delete" [
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
  --force: oneof<nothing, bool> # Force remove a node from the swarm (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/nodes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a node
#
# GET /nodes/{id}
# Returns: record<CreatedAt: string, Description: record<Engine: record<EngineVersion: string, Labels: record, Plugins: list>, Hostname: string, Platform: record<Architecture: string, OS: string>, Resources: record<GenericResources: list, MemoryBytes: int, NanoCPUs: int>, TLSInfo: record<CertIssuerPublicKey: string, CertIssuerSubject: string, TrustRoot: string>>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: NodeInspect
export def "node-inspect" [
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
    path: "/nodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a node
#
# POST /nodes/{id}/update
# operationId: NodeUpdate
export def "node-update" [
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
  --version: int # The version number of the node object being updated. This is required to avoid conflicting writes. (required, format: int64)
  --availability: string@availability-completer # Availability of the node. (e.g. active)
  --labels: record # User-defined key/value metadata.
  --name: string # Name for the node. (e.g. my-node)
  --role: string@role-completer # Role of the node. (e.g. manager)
]: any -> any {
  $in | http-request {
    method: post
    path: "/nodes/{id}/update"
    path_params: [{name: id, var: id}]
    query: [{name: version, var: version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Availability, var: availability}, {name: Labels, var: labels}, {name: Name, var: name}, {name: Role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, version: $version, availability: $availability, labels: $labels, name: $name, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List plugins
#
# GET /plugins
# Returns: table<Config: record<Args: record, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list, Env: list, Interface: record, IpcHost: bool, Linux: record, Mounts: list, Network: record, PidHost: bool, PropagatedMount: string, User: record, WorkDir: string, rootfs: record>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list, Devices: list, Env: list, Mounts: list>>
# operationId: PluginList
export def "plugin-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the plugin list. Available filters: - `capability=` - `enable=|`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/plugins"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a plugin
#
# POST /plugins/create
# operationId: PluginCreate
export def "plugin-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the plugin. The `:latest` tag is optional, and is the default if omitted. (required)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/plugins/create"
    query: [{name: name, var: name, required: true}]
    body: {content_type: "application/x-tar", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get plugin privileges
#
# GET /plugins/privileges
# Returns: table<Description: string, Name: string, Value: list<string>>
# operationId: GetPluginPrivileges
export def "get-plugin-privileges" [
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
  --remote: string # The name of the plugin. The `:latest` tag is optional, and is the default if omitted. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/plugins/privileges"
    query: [{name: remote, var: remote, required: true}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    remote: $remote
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Install a plugin
#
# POST /plugins/pull
# operationId: PluginPull
export def "plugin-pull" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote: string # Remote reference for plugin to install. The `:latest` tag is optional, and is used as the default if omitted. (required)
  --name: string # Local name for the pulled plugin. The `:latest` tag is optional, and is used as the default if omitted.
  --x-registry-auth: string # A base64-encoded auth configuration to use when pulling a plugin from a registry. [See the authentication section for details.](#section/Authentication)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/plugins/pull"
    query: [{name: remote, var: remote, required: true}, {name: name, var: name}]
    header: [{name: X-Registry-Auth, var: x_registry_auth}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    remote: $remote, name: $name, x_registry_auth: $x_registry_auth, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a plugin
#
# DELETE /plugins/{name}
# Returns: record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>>
# operationId: PluginDelete
export def "plugin-delete" [
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
  --accept: string@accept-completer # Response content type
  --force: oneof<nothing, bool> # Disable the plugin before removing. This may result in issues if the plugin is in use by a container. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/plugins/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: force, var: force}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Disable a plugin
#
# POST /plugins/{name}/disable
# operationId: PluginDisable
export def "plugin-disable" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/plugins/{name}/disable"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a plugin
#
# POST /plugins/{name}/enable
# operationId: PluginEnable
export def "plugin-enable" [
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
  --timeout: int # Set the HTTP client timeout (in seconds) (default: 0)
]: nothing -> any {
  http-request {
    method: post
    path: "/plugins/{name}/enable"
    path_params: [{name: name, var: name}]
    query: [{name: timeout, var: timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a plugin
#
# GET /plugins/{name}/json
# Returns: record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>>
# operationId: PluginInspect
export def "plugin-inspect" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/plugins/{name}/json"
    path_params: [{name: name, var: name}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Push a plugin
#
# POST /plugins/{name}/push
# operationId: PluginPush
export def "plugin-push" [
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
]: nothing -> any {
  http-request {
    method: post
    path: "/plugins/{name}/push"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure a plugin
#
# POST /plugins/{name}/set
# operationId: PluginSet
export def "plugin-set" [
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
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/plugins/{name}/set"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrade a plugin
#
# POST /plugins/{name}/upgrade
# operationId: PluginUpgrade
export def "plugin-upgrade" [
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
  --remote: string # Remote reference to upgrade to. The `:latest` tag is optional, and is used as the default if omitted. (required)
  --x-registry-auth: string # A base64-encoded auth configuration to use when pulling a plugin from a registry. [See the authentication section for details.](#section/Authentication)
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/plugins/{name}/upgrade"
    path_params: [{name: name, var: name}]
    query: [{name: remote, var: remote, required: true}]
    header: [{name: X-Registry-Auth, var: x_registry_auth}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, remote: $remote, x_registry_auth: $x_registry_auth, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List secrets
#
# GET /secrets
# Returns: table<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: SecretList
export def "secret-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the secrets list. Available filters: - `id=` - `label= or label==value` - `name=` - `names=`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/secrets"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a secret
#
# POST /secrets/create
# Returns: record<ID: string>
# operationId: SecretCreate
export def "secret-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) data to store as secret. This field is only used to _create_ a secret, and is not returned by other endpoints. (e.g. )
  --driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --name: string # User-defined name of the secret.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/secrets/create"
    body: {content_type: "application/json", kind: json, fields: [{name: Data, var: data}, {name: Driver, var: driver}, {name: Labels, var: labels}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    data: $data, driver: $driver, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a secret
#
# DELETE /secrets/{id}
# operationId: SecretDelete
export def "secret-delete" [
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
    path: "/secrets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a secret
#
# GET /secrets/{id}
# Returns: record<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record<Name: string, Options: record>, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: SecretInspect
export def "secret-inspect" [
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
    path: "/secrets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Secret
#
# POST /secrets/{id}/update
# operationId: SecretUpdate
export def "secret-update" [
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
  --version: int # The version number of the secret object being updated. This is required to avoid conflicting writes. (required, format: int64)
  --data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) data to store as secret. This field is only used to _create_ a secret, and is not returned by other endpoints. (e.g. )
  --driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --name: string # User-defined name of the secret.
]: any -> any {
  $in | http-request {
    method: post
    path: "/secrets/{id}/update"
    path_params: [{name: id, var: id}]
    query: [{name: version, var: version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Data, var: data}, {name: Driver, var: driver}, {name: Labels, var: labels}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, version: $version, data: $data, driver: $driver, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List services
#
# GET /services
# Returns: table<CreatedAt: string, Endpoint: record<Ports: list, Spec: record, VirtualIPs: list>, ID: string, Spec: record<EndpointSpec: record, Labels: record, Mode: record, Name: string, Networks: list, RollbackConfig: record, TaskTemplate: record, UpdateConfig: record>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: ServiceList
export def "service-list" [
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the services list. Available filters: - `id=` - `label=` - `mode=["replicated"|"global"]` - `name=`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/services"
    query: [{name: filters, var: filters}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a service
#
# POST /services/create
# Returns: record<ID: string, Warning: string>
# operationId: ServiceCreate
export def "service-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-registry-auth: string # A base64-encoded auth configuration for pulling from private registries. [See the authentication section for details.](#section/Authentication)
  --endpoint-spec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
  --labels: record # User-defined key/value metadata.
  --mode: record # Scheduling mode for the service. — shape: {Global?: record, Replicated?: record}
  --name: string # Name of the service.
  --networks: list # Array of network names or IDs to attach the service to. — item shape: {Aliases?: list<string>, Target?: string}
  --rollback-config: record # Specification for the rollback strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
  --task-template: record # User modifiable task configuration. — shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
  --update-config: record # Specification for the update strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/services/create"
    header: [{name: X-Registry-Auth, var: x_registry_auth}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointSpec, var: endpoint_spec}, {name: Labels, var: labels}, {name: Mode, var: mode}, {name: Name, var: name}, {name: Networks, var: networks}, {name: RollbackConfig, var: rollback_config}, {name: TaskTemplate, var: task_template}, {name: UpdateConfig, var: update_config}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_registry_auth: $x_registry_auth, endpoint_spec: $endpoint_spec, labels: $labels, mode: $mode, name: $name, networks: $networks, rollback_config: $rollback_config, task_template: $task_template, update_config: $update_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service
#
# DELETE /services/{id}
# operationId: ServiceDelete
export def "service-delete" [
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
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a service
#
# GET /services/{id}
# Returns: record<CreatedAt: string, Endpoint: record<Ports: list<record>, Spec: record<Mode: string, Ports: list>, VirtualIPs: list<record>>, ID: string, Spec: record<EndpointSpec: record<Mode: string, Ports: list>, Labels: record, Mode: record<Global: record, Replicated: record>, Name: string, Networks: list<record>, RollbackConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>, TaskTemplate: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, UpdateConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: ServiceInspect
export def "service-inspect" [
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
  --insert-defaults: oneof<nothing, bool> # Fill empty fields with default values. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/services/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: insertDefaults, var: insert_defaults}]
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    id: $id, insert_defaults: $insert_defaults
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get service logs
#
# GET /services/{id}/logs
# Returns: string
# operationId: ServiceLogs
export def "service-logs" [
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
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Show service context and extra details provided to logs. (default: false)
  --follow: oneof<nothing, bool> # Return the logs as a stream. This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach). (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> any {
  http-request {
    method: get
    path: "/services/{id}/logs"
    path_params: [{name: id, var: id}]
    query: [{name: details, var: details}, {name: follow, var: follow}, {name: stdout, var: stdout}, {name: stderr, var: stderr}, {name: since, var: since}, {name: timestamps, var: timestamps}, {name: tail, var: tail}]
    accept: ["application/json", "application/vnd.docker.raw-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, details: $details, follow: $follow, stdout: $stdout, stderr: $stderr, since: $since, timestamps: $timestamps, tail: $tail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a service
#
# POST /services/{id}/update
# Returns: record<Warnings: list<string>>
# operationId: ServiceUpdate
export def "service-update" [
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
  --version: int # The version number of the service object being updated. This is required to avoid conflicting writes. (required)
  --registry-auth-from: string # If the X-Registry-Auth header is not specified, this parameter indicates where to find registry authorization credentials. The valid values are `spec` and `previous-spec`. (default: spec)
  --rollback: string # Set to this parameter to `previous` to cause a server-side rollback to the previous service spec. The supplied spec will be ignored in this case.
  --x-registry-auth: string # A base64-encoded auth configuration for pulling from private registries. [See the authentication section for details.](#section/Authentication)
  --endpoint-spec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
  --labels: record # User-defined key/value metadata.
  --mode: record # Scheduling mode for the service. — shape: {Global?: record, Replicated?: record}
  --name: string # Name of the service.
  --networks: list # Array of network names or IDs to attach the service to. — item shape: {Aliases?: list<string>, Target?: string}
  --rollback-config: record # Specification for the rollback strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
  --task-template: record # User modifiable task configuration. — shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
  --update-config: record # Specification for the update strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/services/{id}/update"
    path_params: [{name: id, var: id}]
    query: [{name: version, var: version, required: true}, {name: registryAuthFrom, var: registry_auth_from}, {name: rollback, var: rollback}]
    header: [{name: X-Registry-Auth, var: x_registry_auth}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointSpec, var: endpoint_spec}, {name: Labels, var: labels}, {name: Mode, var: mode}, {name: Name, var: name}, {name: Networks, var: networks}, {name: RollbackConfig, var: rollback_config}, {name: TaskTemplate, var: task_template}, {name: UpdateConfig, var: update_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, version: $version, registry_auth_from: $registry_auth_from, rollback: $rollback, x_registry_auth: $x_registry_auth, endpoint_spec: $endpoint_spec, labels: $labels, mode: $mode, name: $name, networks: $networks, rollback_config: $rollback_config, task_template: $task_template, update_config: $update_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initialize interactive session
#
# POST /session
# operationId: Session
export def "session" [
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
    path: "/session"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect swarm
#
# GET /swarm
# Returns: record<CreatedAt: string, ID: string, RootRotationInProgress: bool, Spec: record<CAConfig: record<ExternalCAs: list, ForceRotate: int, NodeCertExpiry: int, SigningCACert: string, SigningCAKey: string>, Dispatcher: record<HeartbeatPeriod: int>, EncryptionConfig: record<AutoLockManagers: bool>, Labels: record, Name: string, Orchestration: record<TaskHistoryRetentionLimit: int>, Raft: record<ElectionTick: int, HeartbeatTick: int, KeepOldSnapshots: int, LogEntriesForSlowFollowers: int, SnapshotInterval: int>, TaskDefaults: record<LogDriver: record>>, TLSInfo: record<CertIssuerPublicKey: string, CertIssuerSubject: string, TrustRoot: string>, UpdatedAt: string, Version: record<Index: int>, JoinTokens: record<Manager: string, Worker: string>>
# operationId: SwarmInspect
export def "swarm-inspect" [
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
    path: "/swarm"
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Initialize a new swarm
#
# POST /swarm/init
# Returns: string
# operationId: SwarmInit
export def "swarm-init" [
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
  --advertise-addr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --data-path-addr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example, `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used. The `DataPathAddr` specifies the address that global scope network drivers will publish towards other nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  --force-new-cluster: oneof<nothing, bool> # Force creation of a new swarm.
  --listen-addr: string # Listen address used for inter-manager communication, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP). This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the default swarm listening port is used.
  --spec: record # User modifiable swarm configuration. — shape: {CAConfig?: record, Dispatcher?: record, EncryptionConfig?: record, Labels?: record, Name?: string, Orchestration?: record, Raft?: record, TaskDefaults?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/swarm/init"
    body: {content_type: "application/json", kind: json, fields: [{name: AdvertiseAddr, var: advertise_addr}, {name: DataPathAddr, var: data_path_addr}, {name: ForceNewCluster, var: force_new_cluster}, {name: ListenAddr, var: listen_addr}, {name: Spec, var: spec}]}
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    advertise_addr: $advertise_addr, data_path_addr: $data_path_addr, force_new_cluster: $force_new_cluster, listen_addr: $listen_addr, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Join an existing swarm
#
# POST /swarm/join
# operationId: SwarmJoin
export def "swarm-join" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertise-addr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --data-path-addr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example, `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used. The `DataPathAddr` specifies the address that global scope network drivers will publish towards other nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  --join-token: string # Secret token for joining this swarm.
  --listen-addr: string # Listen address used for inter-manager communication if the node gets promoted to manager, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP).
  --remote-addrs: string # Addresses of manager nodes already participating in the swarm.
]: any -> any {
  $in | http-request {
    method: post
    path: "/swarm/join"
    body: {content_type: "application/json", kind: json, fields: [{name: AdvertiseAddr, var: advertise_addr}, {name: DataPathAddr, var: data_path_addr}, {name: JoinToken, var: join_token}, {name: ListenAddr, var: listen_addr}, {name: RemoteAddrs, var: remote_addrs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    advertise_addr: $advertise_addr, data_path_addr: $data_path_addr, join_token: $join_token, listen_addr: $listen_addr, remote_addrs: $remote_addrs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leave a swarm
#
# POST /swarm/leave
# operationId: SwarmLeave
export def "swarm-leave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force leave swarm, even if this is the last manager or that it will break the cluster. (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/swarm/leave"
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlock a locked manager
#
# POST /swarm/unlock
# operationId: SwarmUnlock
export def "swarm-unlock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unlock-key: string # The swarm's unlock key.
]: any -> any {
  $in | http-request {
    method: post
    path: "/swarm/unlock"
    body: {content_type: "application/json", kind: json, fields: [{name: UnlockKey, var: unlock_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    unlock_key: $unlock_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the unlock key
#
# GET /swarm/unlockkey
# Returns: record<UnlockKey: string>
# operationId: SwarmUnlockkey
export def "swarm-unlockkey" [
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
    path: "/swarm/unlockkey"
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a swarm
#
# POST /swarm/update
# operationId: SwarmUpdate
export def "swarm-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the swarm object being updated. This is required to avoid conflicting writes. (required, format: int64)
  --rotate-worker-token: oneof<nothing, bool> # Rotate the worker join token. (default: false)
  --rotate-manager-token: oneof<nothing, bool> # Rotate the manager join token. (default: false)
  --rotate-manager-unlock-key: oneof<nothing, bool> # Rotate the manager unlock key. (default: false)
  --ca-config: record # CA configuration. (nullable) — shape: {ExternalCAs?: list, ForceRotate?: int, NodeCertExpiry?: int, SigningCACert?: string, SigningCAKey?: string}
  --dispatcher: record # Dispatcher configuration. (nullable) — shape: {HeartbeatPeriod?: int}
  --encryption-config: record # Parameters related to encryption-at-rest. — shape: {AutoLockManagers?: bool}
  --labels: record # User-defined key/value metadata. (e.g. {com.example.corp.department: engineering, com.example.corp.type: production})
  --name: string # Name of the swarm. (e.g. default)
  --orchestration: record # Orchestration configuration. (nullable) — shape: {TaskHistoryRetentionLimit?: int}
  --raft: record # Raft configuration. — shape: {ElectionTick?: int, HeartbeatTick?: int, KeepOldSnapshots?: int, LogEntriesForSlowFollowers?: int, SnapshotInterval?: int}
  --task-defaults: record # Defaults for creating tasks in this cluster. — shape: {LogDriver?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/swarm/update"
    query: [{name: version, var: version, required: true}, {name: rotateWorkerToken, var: rotate_worker_token}, {name: rotateManagerToken, var: rotate_manager_token}, {name: rotateManagerUnlockKey, var: rotate_manager_unlock_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: CAConfig, var: ca_config}, {name: Dispatcher, var: dispatcher}, {name: EncryptionConfig, var: encryption_config}, {name: Labels, var: labels}, {name: Name, var: name}, {name: Orchestration, var: orchestration}, {name: Raft, var: raft}, {name: TaskDefaults, var: task_defaults}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version: $version, rotate_worker_token: $rotate_worker_token, rotate_manager_token: $rotate_manager_token, rotate_manager_unlock_key: $rotate_manager_unlock_key, ca_config: $ca_config, dispatcher: $dispatcher, encryption_config: $encryption_config, labels: $labels, name: $name, orchestration: $orchestration, raft: $raft, task_defaults: $task_defaults
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get data usage information
#
# GET /system/df
# Returns: record<Containers: list<list<record>>, Images: table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list, RepoTags: list, SharedSize: int, Size: int, VirtualSize: int>, LayersSize: int, Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>>
# operationId: SystemDataUsage
export def "system-data-usage" [
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
    path: "/system/df"
    accept: ["application/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List tasks
#
# GET /tasks
# Returns: table<AssignedGenericResources: list<record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, Status: record<ContainerStatus: record, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: TaskList
export def "task-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the tasks list. Available filters: - `desired-state=(running | shutdown | accepted)` - `id=` - `label=key` or `label="key=value"` - `name=` - `node=` - `service=`
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tasks"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a task
#
# GET /tasks/{id}
# Returns: record<AssignedGenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record<Args: list, Command: list, Configs: list, DNSConfig: record, Dir: string, Env: list, Groups: list, HealthCheck: record, Hostname: string, Hosts: list, Image: string, Labels: record, Mounts: list, OpenStdin: bool, Privileges: record, ReadOnly: bool, Secrets: list, StopGracePeriod: int, StopSignal: string, TTY: bool, User: string>, ForceUpdate: int, LogDriver: record<Name: string, Options: record>, Networks: list<record>, Placement: record<Constraints: list, Platforms: list, Preferences: list>, PluginSpec: record<Disabled: bool, Name: string, PluginPrivilege: list, Remote: string>, Resources: record<Limits: record, Reservation: record>, RestartPolicy: record<Condition: string, Delay: int, MaxAttempts: int, Window: int>, Runtime: string>, Status: record<ContainerStatus: record<ContainerID: string, ExitCode: int, PID: int>, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>>
# operationId: TaskInspect
export def "task-inspect" [
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
    path: "/tasks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task logs
#
# GET /tasks/{id}/logs
# Returns: string
# operationId: TaskLogs
export def "task-logs" [
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
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Show task context and extra details provided to logs. (default: false)
  --follow: oneof<nothing, bool> # Return the logs as a stream. This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach). (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> any {
  http-request {
    method: get
    path: "/tasks/{id}/logs"
    path_params: [{name: id, var: id}]
    query: [{name: details, var: details}, {name: follow, var: follow}, {name: stdout, var: stdout}, {name: stderr, var: stderr}, {name: since, var: since}, {name: timestamps, var: timestamps}, {name: tail, var: tail}]
    accept: ["application/json", "application/vnd.docker.raw-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, details: $details, follow: $follow, stdout: $stdout, stderr: $stderr, since: $since, timestamps: $timestamps, tail: $tail
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get version
#
# GET /version
# Returns: record<ApiVersion: string, Arch: string, BuildTime: string, Experimental: bool, GitCommit: string, GoVersion: string, KernelVersion: string, MinAPIVersion: string, Os: string, Version: string>
# operationId: SystemVersion
export def "system-version" [
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
    path: "/version"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List volumes
#
# GET /volumes
# Returns: record<Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>, Warnings: list<string>>
# operationId: VolumeList
export def "volume-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the volumes list. Available filters: - `dangling=` When set to `true` (or `1`), returns all volumes that are not in use by a container. When set to `false` (or `0`), only volumes that are in use by one or more containers are returned. - `driver=<volume-driver-name>` Matches volumes based on their driver. - `label=` or `label=:` Matches volumes based on the presence of a `label` alone or a `label` and a value. - `name=<volume-name>` Matches all or part of a volume name. (format: json)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a volume
#
# POST /volumes/create
# Returns: record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>>
# operationId: VolumeCreate
export def "volume-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver: string # Name of the volume driver to use. (default: local)
  --driver-opts: record # A mapping of driver options and values. These options are passed directly to the driver and are driver specific.
  --labels: record # User-defined key/value metadata.
  --name: string # The new volume's name. If not specified, Docker generates a name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/volumes/create"
    body: {content_type: "application/json", kind: json, fields: [{name: Driver, var: driver}, {name: DriverOpts, var: driver_opts}, {name: Labels, var: labels}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    driver: $driver, driver_opts: $driver_opts, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete unused volumes
#
# POST /volumes/prune
# Returns: record<SpaceReclaimed: int, VolumesDeleted: list<string>>
# operationId: VolumePrune
export def "volume-prune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters: - `label` (`label=`, `label==`, `label!=`, or `label!==`) Prune volumes with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/volumes/prune"
    query: [{name: filters, var: filters}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a volume
#
# DELETE /volumes/{name}
# operationId: VolumeDelete
export def "volume-delete" [
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
  --force: oneof<nothing, bool> # Force the removal of the volume (default: false)
]: nothing -> any {
  http-request {
    method: delete
    path: "/volumes/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inspect a volume
#
# GET /volumes/{name}
# Returns: record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>>
# operationId: VolumeInspect
export def "volume-inspect" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/volumes/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
