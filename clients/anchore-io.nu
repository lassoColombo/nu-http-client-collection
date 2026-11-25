# Auto-generated client for Anchore Engine API Server v0.1.20
# Source: https://api.apis.guru/v2/specs/anchore.io/0.1.20/openapi.json
# Auth: --token flag or $env.ANCHORE_ENGINE_API_SERVER_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "ANCHORE_ENGINE_API_SERVER_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru" "http://anchore.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["deleting" "disabled" "enabled"] }
def state-completer-1 [] { ["disabled" "enabled"] }
def credential-type-completer [] { ["password"] }
def type-completer [] { ["password"] }
def transition-completer [] { ["archive" "delete"] }
def image-status-completer [] { ["active" "all" "deleting"] }
def analysis-status-completer [] { ["analysis_failed" "analyzed" "analyzing" "not_analyzed"] }
def severity-completer [] { ["Critical" "High" "Low" "Medium" "Negligible" "Unknown"] }
def notification-type-completer [] { ["analysis_update" "policy_eval" "tag_update" "vuln_update"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    ping: "string"
    get-users-account: "record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>"
    list-accounts: "table<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>"
    create-account: "record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>"
    get-account: "record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>"
    update-account-state: "record<state: string>"
    list-users: "table<created_at: string, last_updated: string, source: string, type: string, username: string>"
    create-user: "record<created_at: string, last_updated: string, source: string, type: string, username: string>"
    get-account-user: "record<created_at: string, last_updated: string, source: string, type: string, username: string>"
    list-user-credentials: "table<created_at: string, type: string, value: string>"
    create-user-credential: "record<created_at: string, last_updated: string, source: string, type: string, username: string>"
    list-archives: "record<images: record<last_updated: string, total_data_bytes: int, total_image_count: int, total_tag_count: int>, rules: record<count: int, last_updated: string>>"
    list-analysis-archive: "table<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: list<record>, last_updated: string, parentDigest: string, status: string>"
    archive-image-analysis: "table<detail: string, digest: string, status: string>"
    get-archived-analysis: "record<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: table<detected_at: string, pullstring: string, registry: string, repository: string, tag: string>, last_updated: string, parentDigest: string, status: string>"
    list-analysis-archive-rules: "table<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>"
    create-analysis-archive-rule: "record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>"
    get-analysis-archive-rule: "record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>"
    list-event-types: "table<category: string, description: string, subcategories: list<record>>"
    delete-events: "list<string>"
    list-events: "record<item_count: int, next_page: bool, page: int, results: table<created_at: string, event: record, generated_uuid: string>>"
    get-event: "record<created_at: string, event: record<category: string, details: record, level: string, message: string, resource: record<id: string, type: string, user_id: string>, source: record<base_url: string, hostid: string, request_id: string, servicename: string>, timestamp: string, type: string>, generated_uuid: string>"
    delete-images-async: "table<detail: string, digest: string, status: string>"
    list-images: "table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>"
    add-image: "table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>"
    delete-image-by-image-id: "record<detail: string, digest: string, status: string>"
    get-image-by-image-id: "table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>"
    get-image-policy-check-by-image-id: "list<record>"
    list-image-content-by-imageid: "list<string>"
    get-image-content-by-type-image-id-files: "record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string>"
    get-image-content-by-type-image-id-javapackage: "record<content: table<cpes: list, implementation-version: string, location: string, maven-version: string, origin: string, package: string, specification-version: string, type: string>, content_type: string, imageDigest: string>"
    get-image-content-by-type-image-id: "record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string>"
    get-image-vulnerability-types-by-image-id: "list<string>"
    get-image-vulnerabilities-by-type-image-id: "record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string>"
    delete-image: "record<detail: string, digest: string, status: string>"
    get-image: "table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>"
    list-file-content-search-results: "table<matches: list<record>, path: string>"
    list-retrieved-files: "table<b64_content: string, path: string>"
    list-secret-search-results: "table<matches: list<record>, path: string>"
    get-image-policy-check: "list<record>"
    list-image-content: "list<string>"
    get-image-content-by-type-files: "record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string>"
    get-image-content-by-type-javapackage: "record<content: table<cpes: list, implementation-version: string, location: string, maven-version: string, origin: string, package: string, specification-version: string, type: string>, content_type: string, imageDigest: string>"
    get-image-content-by-type-malware: "record<content: table<enabled: bool, findings: list, metadata: record, scanner: string>, content_type: string, imageDigest: string>"
    get-image-content-by-type: "record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string>"
    list-image-metadata: "list<string>"
    get-image-metadata-by-type: "record<imageDigest: string, metadata: any, metadata_type: string>"
    get-image-sbom-native: "binary"
    get-image-vulnerability-types: "list<string>"
    get-image-vulnerabilities-by-type: "record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string>"
    import-image-archive: "table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>"
    list-operations: "table<created_at: string, expires_at: string, status: string, uuid: string>"
    create-operation: "record<created_at: string, expires_at: string, status: string, uuid: string>"
    invalidate-operation: "record<created_at: string, expires_at: string, status: string, uuid: string>"
    get-operation: "record<created_at: string, expires_at: string, status: string, uuid: string>"
    list-import-dockerfiles: "list<string>"
    import-image-dockerfile: "record<created_at: string, digest: string>"
    list-import-image-configs: "list<string>"
    import-image-config: "record<created_at: string, digest: string>"
    list-import-image-manifests: "list<string>"
    import-image-manifest: "record<created_at: string, digest: string>"
    list-import-packages: "list<string>"
    import-image-packages: "record<created_at: string, digest: string>"
    list-import-parent-manifests: "list<string>"
    import-image-parent-manifest: "record<created_at: string, digest: string>"
    get-oauth-token: "record<token: string>"
    list-policies: "table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>"
    add-policy: "record<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list<record>, comment: string, id: string, mappings: list<record>, name: string, policies: list<record>, version: string, whitelisted_images: list<record>, whitelists: list<record>>, userId: string>"
    get-policy: "table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>"
    update-policy: "table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>"
    query-images-by-package: "record<next_page: string, page: string, returned_count: int, images: table<image: record, packages: list>>"
    query-images-by-vulnerability: "record<next_page: string, page: string, returned_count: int, images: table<affected_packages: list, image: record>>"
    query-vulnerabilities: "record<next_page: string, page: string, returned_count: int, vulnerabilities: table<affected_packages: list, description: string, id: string, link: string, namespace: string, nvd_data: list, references: list, severity: string, vendor_data: list>>"
    list-registries: "table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>"
    create-registry: "table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>"
    get-registry: "table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>"
    update-registry: "table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>"
    add-repository: "table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>"
    get-status: "record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>"
    list-subscriptions: "table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>"
    add-subscription: "table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>"
    get-subscription: "table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>"
    update-subscription: "table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>"
    list-imagetags: "table<analysis_status: string, analyzed_at: int, created_at: int, fulltag: string, imageDigest: string, imageId: string, image_status: string, parentDigest: string, tag_detected_at: int>"
    get-service-detail: "record<service_states: table<base_url: string, hostid: string, service_detail: record, servicename: string, status: bool, status_message: string, version: string>>"
    describe-error-codes: "table<description: string, name: string>"
    get-system-feeds: "table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string>"
    post-system-feeds: "table<feed: string, groups: list<record>, status: string, total_time_seconds: float>"
    toggle-feed-enabled: "record<created_at: string, groups: table<created_at: string, last_sync: string, name: string, record_count: int>, last_full_sync: string, name: string, updated_at: string>"
    toggle-group-enabled: "table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string>"
    describe-policy: "table<description: string, name: string, state: string, superceded_by: string, triggers: list<record>>"
    list-services: "table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>"
    get-services-by-name: "table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>"
    get-services-by-name-and-host: "table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>"
    get-user: "record<created_at: string, last_updated: string, source: string, type: string, username: string>"
    get-credentials: "table<created_at: string, type: string, value: string>"
    add-credential: "record<created_at: string, last_updated: string, source: string, type: string, username: string>"
    version-check: "record<api: record<version: string>, db: record<schema_version: string>, service: record<version: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["ping" "get-users-account" "list-accounts" "create-account" "delete-account" "get-account" "update-account-state" "list-users" "create-user" "delete-user" "get-account-user" "delete-user-credential" "list-user-credentials" "create-user-credential" "list-archives" "list-analysis-archive" "archive-image-analysis" "delete-archived-analysis" "get-archived-analysis" "list-analysis-archive-rules" "create-analysis-archive-rule" "delete-analysis-archive-rule" "get-analysis-archive-rule" "list-event-types" "delete-events" "list-events" "delete-event" "get-event" "health-check" "delete-images-async" "list-images" "add-image" "delete-image-by-image-id" "get-image-by-image-id" "get-image-policy-check-by-image-id" "list-image-content-by-imageid" "get-image-content-by-type-image-id-files" "get-image-content-by-type-image-id-javapackage" "get-image-content-by-type-image-id" "get-image-vulnerability-types-by-image-id" "get-image-vulnerabilities-by-type-image-id" "delete-image" "get-image" "list-file-content-search-results" "list-retrieved-files" "list-secret-search-results" "get-image-policy-check" "list-image-content" "get-image-content-by-type-files" "get-image-content-by-type-javapackage" "get-image-content-by-type-malware" "get-image-content-by-type" "list-image-metadata" "get-image-metadata-by-type" "get-image-sbom-native" "get-image-vulnerability-types" "get-image-vulnerabilities-by-type" "import-image-archive" "list-operations" "create-operation" "invalidate-operation" "get-operation" "list-import-dockerfiles" "import-image-dockerfile" "list-import-image-configs" "import-image-config" "list-import-image-manifests" "import-image-manifest" "list-import-packages" "import-image-packages" "list-import-parent-manifests" "import-image-parent-manifest" "get-oauth-token" "list-policies" "add-policy" "delete-policy" "get-policy" "update-policy" "query-images-by-package" "query-images-by-vulnerability" "query-vulnerabilities" "list-registries" "create-registry" "delete-registry" "get-registry" "update-registry" "add-repository" "get-status" "list-subscriptions" "add-subscription" "delete-subscription" "get-subscription" "update-subscription" "list-imagetags" "get-service-detail" "describe-error-codes" "get-system-feeds" "post-system-feeds" "delete-feed" "toggle-feed-enabled" "delete-feed-group" "toggle-group-enabled" "describe-policy" "list-services" "get-services-by-name" "delete-service" "get-services-by-name-and-host" "test-webhook" "get-user" "get-credentials" "add-credential" "version-check" "commands"] | sort) } | get name | first)
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

# Simple status check
#
# GET /
# Returns: string
# operationId: ping
export def "ping" [
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
    path: "/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the account for the authenticated user
#
# GET /account
# Returns: record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>
# operationId: get_users_account
export def "get-users-account" [
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
    path: "/account"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user summaries. Only available to the system admin user.
#
# GET /accounts
# Returns: table<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>
# operationId: list_accounts
export def "list-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Filter accounts by state
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user. Only avaialble to admin user.
#
# POST /accounts
# Returns: record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>
# operationId: create_account
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # An optional email to associate with the account for contact purposes
  name: string # The account name to use. This will identify the account and must be globally unique in the system.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the specified account, only allowed if the account is in the disabled state. All users will be deleted along with the account and all resources will be garbage collected
#
# DELETE /accounts/{accountname}
# operationId: delete_account
export def "delete-account" [
  accountname: string
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
    path: "/accounts/{accountname}"
    path_params: [{name: accountname, var: accountname}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    accountname: $accountname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get info about an user. Only available to admin user. Uses the main user Id, not a username.
#
# GET /accounts/{accountname}
# Returns: record<created_at: string, email: string, last_updated: string, name: string, state: string, type: string>
# operationId: get_account
export def "get-account" [
  accountname: string
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
    path: "/accounts/{accountname}"
    path_params: [{name: accountname, var: accountname}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the state of an account to either enabled or disabled. For deletion use the DELETE route
#
# PUT /accounts/{accountname}/state
# Returns: record<state: string>
# operationId: update_account_state
export def "update-account-state" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The status of the account
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{accountname}/state"
    path_params: [{name: accountname, var: accountname}]
    body: {content_type: "application/json", kind: json, fields: [{name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List accounts for the user
#
# GET /accounts/{accountname}/users
# Returns: table<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: list_users
export def "list-users" [
  accountname: string
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
    path: "/accounts/{accountname}/users"
    path_params: [{name: accountname, var: accountname}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user
#
# POST /accounts/{accountname}/users
# Returns: record<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: create_user
export def "create-user" [
  accountname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The initial password for the user, must be at least 6 characters, up to 128
  username: string # The username to create
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountname}/users"
    path_params: [{name: accountname, var: accountname}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific user credential by username of the credential. Cannot be the credential used to authenticate the request.
#
# DELETE /accounts/{accountname}/users/{username}
# operationId: delete_user
export def "delete-user" [
  accountname: string
  username: string
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
    path: "/accounts/{accountname}/users/{username}"
    path_params: [{name: accountname, var: accountname}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    accountname: $accountname, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific user in the specified account
#
# GET /accounts/{accountname}/users/{username}
# Returns: record<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: get_account_user
export def "get-account-user" [
  accountname: string
  username: string
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
    path: "/accounts/{accountname}/users/{username}"
    path_params: [{name: accountname, var: accountname}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a credential by type
#
# DELETE /accounts/{accountname}/users/{username}/credentials
# operationId: delete_user_credential
export def "delete-user-credential" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --credential-type: string@credential-type-completer # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/accounts/{accountname}/users/{username}/credentials"
    path_params: [{name: accountname, var: accountname}, {name: username, var: username}]
    query: [{name: credential_type, var: credential_type, required: true, default: password}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    accountname: $accountname, username: $username, credential_type: $credential_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current credential summary
#
# GET /accounts/{accountname}/users/{username}/credentials
# Returns: table<created_at: string, type: string, value: string>
# operationId: list_user_credentials
export def "list-user-credentials" [
  accountname: string
  username: string
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
    path: "/accounts/{accountname}/users/{username}/credentials"
    path_params: [{name: accountname, var: accountname}, {name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add/replace credential
#
# POST /accounts/{accountname}/users/{username}/credentials
# Returns: record<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: create_user_credential
export def "create-user-credential" [
  accountname: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The timestamp of creation of the credential
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{accountname}/users/{username}/credentials"
    path_params: [{name: accountname, var: accountname}, {name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accountname: $accountname, username: $username, created_at: $created_at, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /archives
#
# Returns: record<images: record<last_updated: string, total_data_bytes: int, total_image_count: int, total_tag_count: int>, rules: record<count: int, last_updated: string>>
# operationId: list_archives
export def "list-archives" [
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
    path: "/archives"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /archives/images
#
# Returns: table<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: list<record>, last_updated: string, parentDigest: string, status: string>
# operationId: list_analysis_archive
export def "list-analysis-archive" [
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
    path: "/archives/images"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /archives/images
#
# Returns: table<detail: string, digest: string, status: string>
# operationId: archive_image_analysis
export def "archive-image-analysis" [
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
    method: post
    path: "/archives/images"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs a synchronous archive deletion
#
# DELETE /archives/images/{imageDigest}
# operationId: delete_archived_analysis
export def "delete-archived-analysis" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
]: nothing -> any {
  http-request {
    method: delete
    path: "/archives/images/{imageDigest}"
    path_params: [{name: imageDigest, var: image_digest}]
    query: [{name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the archive metadata record identifying the image and tags for the analysis in the archive.
#
# GET /archives/images/{imageDigest}
# Returns: record<analyzed_at: string, annotations: record, archive_size_bytes: int, created_at: string, imageDigest: string, image_detail: table<detected_at: string, pullstring: string, registry: string, repository: string, tag: string>, last_updated: string, parentDigest: string, status: string>
# operationId: get_archived_analysis
export def "get-archived-analysis" [
  image_digest: string
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
    path: "/archives/images/{imageDigest}"
    path_params: [{name: imageDigest, var: image_digest}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /archives/rules
#
# Returns: table<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>
# operationId: list_analysis_archive_rules
export def "list-analysis-archive-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --system-global: oneof<nothing, bool> # If true include system global rules (owned by admin) even for non-admin users. Defaults to true if not set. Can be set to false to exclude globals
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/archives/rules"
    query: [{name: system_global, var: system_global}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    system_global: $system_global
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /archives/rules
#
# Returns: record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>
# operationId: create_analysis_archive_rule
export def "create-analysis-archive-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --analysis-age-days: int # Matches if the analysis is strictly older than this number of days
  --created-at: string # format: date-time
  --exclude: record # Which Images to exclude from auto-archiving logic — shape: {expiration_days?: int, selector?: record}
  --last-updated: string # format: date-time
  --max-images-per-account: int # This is the maximum number of image analyses an account can have. Can only be set on system_global rules
  --rule-id: string # Unique identifier for archive rule
  --selector: record # A set of selection criteria to match an image by a tagged pullstring based on its components, with regex support in each field — shape: {registry?: string, repository?: string, tag?: string}
  --system-global: oneof<nothing, bool> # True if the rule applies to all accounts in the system. This is only available to admin users to update/modify, but all users with permission to list rules can see them
  --tag-versions-newer: int # Number of images mapped to the tag that are newer
  transition: string@transition-completer # The type of transition to make. If "archive", then archive an image from the working set and remove it from the working set. If "delete", then match against archived images and delete from the archive if match.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/archives/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: analysis_age_days, var: analysis_age_days}, {name: created_at, var: created_at}, {name: exclude, var: exclude}, {name: last_updated, var: last_updated}, {name: max_images_per_account, var: max_images_per_account}, {name: rule_id, var: rule_id}, {name: selector, var: selector}, {name: system_global, var: system_global}, {name: tag_versions_newer, var: tag_versions_newer}, {name: transition, var: transition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    analysis_age_days: $analysis_age_days, created_at: $created_at, exclude: $exclude, last_updated: $last_updated, max_images_per_account: $max_images_per_account, rule_id: $rule_id, selector: $selector, system_global: $system_global, tag_versions_newer: $tag_versions_newer, transition: $transition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /archives/rules/{ruleId}
#
# operationId: delete_analysis_archive_rule
export def "delete-analysis-archive-rule" [
  rule_id: string
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
    path: "/archives/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /archives/rules/{ruleId}
#
# Returns: record<analysis_age_days: int, created_at: string, exclude: record<expiration_days: int, selector: record<registry: string, repository: string, tag: string>>, last_updated: string, max_images_per_account: int, rule_id: string, selector: record<registry: string, repository: string, tag: string>, system_global: bool, tag_versions_newer: int, transition: string>
# operationId: get_analysis_archive_rule
export def "get-analysis-archive-rule" [
  rule_id: string
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
    path: "/archives/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Event Types
#
# GET /event_types
# Returns: table<category: string, description: string, subcategories: list<record>>
# operationId: list_event_types
export def "list-event-types" [
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
    path: "/event_types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Events
#
# DELETE /events
# Returns: list<string>
# operationId: delete_events
export def "delete-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Delete events that occurred before the timestamp
  --since: string # Delete events that occurred after the timestamp
  --level: string # Delete events that match the level - INFO or ERROR
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: delete
    path: "/events"
    query: [{name: before, var: before}, {name: since, var: since}, {name: level, var: level}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    before: $before, since: $since, level: $level, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Events
#
# GET /events
# Returns: record<item_count: int, next_page: bool, page: int, results: table<created_at: string, event: record, generated_uuid: string>>
# operationId: list_events
export def "list-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-servicename: string # Filter events by the originating service
  --source-hostid: string # Filter events by the originating host ID
  --event-type: string # Filter events by a prefix match on the event type (e.g. "user.image.")
  --resource-type: string # Filter events by the type of resource - tag, imageDigest, repository etc
  --resource-id: string # Filter events by the id of the resource
  --level: string # Filter events by the level - INFO or ERROR
  --since: string # Return events that occurred after the timestamp
  --before: string # Return events that occurred before the timestamp
  --page: int # Pagination controls - return the nth page of results. Defaults to first page if left empty (default: 1)
  --limit: int # Number of events in the result set. Defaults to 100 if left empty (default: 100)
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: source_servicename, var: source_servicename}, {name: source_hostid, var: source_hostid}, {name: event_type, var: event_type}, {name: resource_type, var: resource_type}, {name: resource_id, var: resource_id}, {name: level, var: level}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: limit, var: limit}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_servicename: $source_servicename, source_hostid: $source_hostid, event_type: $event_type, resource_type: $resource_type, resource_id: $resource_id, level: $level, since: $since, before: $before, page: $page, limit: $limit, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Event
#
# DELETE /events/{eventId}
# operationId: delete_event
export def "delete-event" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  http-request {
    method: delete
    path: "/events/{eventId}"
    path_params: [{name: eventId, var: event_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Event
#
# GET /events/{eventId}
# Returns: record<created_at: string, event: record<category: string, details: record, level: string, message: string, resource: record<id: string, type: string, user_id: string>, source: record<base_url: string, hostid: string, request_id: string, servicename: string>, timestamp: string, type: string>, generated_uuid: string>
# operationId: get_event
export def "get-event" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{eventId}"
    path_params: [{name: eventId, var: event_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Health check, returns 200 and no body if service is running
#
# GET /health
# operationId: health_check
export def "health-check" [
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
    path: "/health"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk mark images for deletion
#
# DELETE /images
# Returns: table<detail: string, digest: string, status: string>
# operationId: delete_images_async
export def "delete-images-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-digests: list<string> # required
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: delete
    path: "/images"
    query: [{name: imageDigests, var: image_digests, style: csv, required: true}, {name: force, var: force}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digests: $image_digests, force: $force, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all visible images
#
# GET /images
# Returns: table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>
# operationId: list_images
export def "list-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --history: oneof<nothing, bool> # Include image history in the response
  --fulltag: string # Full docker-pull string to filter results by (e.g. docker.io/library/nginx:latest, or myhost.com:5000/testimages:v1.1.1)
  --image-status: string@image-status-completer # Filter by image_status value on the record. Default if omitted is 'active'. (default: active)
  --analysis-status: string@analysis-status-completer # Filter by analysis_status value on the record.
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images"
    query: [{name: history, var: history}, {name: fulltag, var: fulltag}, {name: image_status, var: image_status}, {name: analysis_status, var: analysis_status}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    history: $history, fulltag: $fulltag, image_status: $image_status, analysis_status: $analysis_status, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a new image for analysis by the engine
#
# POST /images
# Returns: table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>
# operationId: add_image
export def "add-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Override any existing entry in the system
  --autosubscribe: oneof<nothing, bool> # Instruct engine to automatically begin watching the added tag for updates from registry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --annotations: record # Annotations to be associated with the added image in key/value form
  --created-at: string # Optional override of the image creation time, only honored when both tag and digest are also supplied e.g. 2018-10-17T18:14:00Z. Deprecated in favor of the 'source' field (format: date-time)
  --digest: string # A digest string for an image, maybe a pull string or just a digest. e.g. nginx@sha256:123 or sha256:abc123. If a pull string, it must have same regisry/repo as the tag field. Deprecated in favor of the 'source' field
  --dockerfile: string # Base64 encoded content of the dockerfile for the image, if available. Deprecated in favor of the 'source' field.
  --image-type: string # Optional. The type of image this is adding, defaults to "docker". This can be ommitted until multiple image types are supported.
  --source: record # A set of analysis source types. Only one may be set in any given request. — shape: {archive?: record, digest?: record, import?: record, tag?: record}
  --tag: string # Full pullable tag reference for image. e.g. docker.io/nginx:latest. Deprecated in favor of the 'source' field
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/images"
    query: [{name: force, var: force}, {name: autosubscribe, var: autosubscribe}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: annotations, var: annotations}, {name: created_at, var: created_at}, {name: digest, var: digest}, {name: dockerfile, var: dockerfile}, {name: image_type, var: image_type}, {name: source, var: source}, {name: tag, var: tag}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    force: $force, autosubscribe: $autosubscribe, x_anchore_account: $x_anchore_account, annotations: $annotations, created_at: $created_at, digest: $digest, dockerfile: $dockerfile, image_type: $image_type, source: $source, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete image by docker imageId
#
# DELETE /images/by_id/{imageId}
# Returns: record<detail: string, digest: string, status: string>
# operationId: delete_image_by_imageId
export def "delete-image-by-image-id" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/images/by_id/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    query: [{name: force, var: force}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, force: $force, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lookup image by docker imageId
#
# GET /images/by_id/{imageId}
# Returns: table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>
# operationId: get_image_by_imageId
export def "get-image-by-image-id" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}"
    path_params: [{name: imageId, var: image_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check policy evaluation status for image
#
# GET /images/by_id/{imageId}/check
# Returns: list<record>
# operationId: get_image_policy_check_by_imageId
export def "get-image-policy-check-by-image-id" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string
  --tag: string # required
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/check"
    path_params: [{name: imageId, var: image_id}]
    query: [{name: policyId, var: policy_id}, {name: tag, var: tag, required: true}, {name: detail, var: detail}, {name: history, var: history}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, policy_id: $policy_id, tag: $tag, detail: $detail, history: $history, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List image content types
#
# GET /images/by_id/{imageId}/content
# Returns: list<string>
# operationId: list_image_content_by_imageid
export def "list-image-content-by-imageid" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/content"
    path_params: [{name: imageId, var: image_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type files
#
# GET /images/by_id/{imageId}/content/files
# Returns: record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_imageId_files
export def "get-image-content-by-type-image-id-files" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/content/files"
    path_params: [{name: imageId, var: image_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type java
#
# GET /images/by_id/{imageId}/content/java
# Returns: record<content: table<cpes: list, implementation-version: string, location: string, maven-version: string, origin: string, package: string, specification-version: string, type: string>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_imageId_javapackage
export def "get-image-content-by-type-image-id-javapackage" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/content/java"
    path_params: [{name: imageId, var: image_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type
#
# GET /images/by_id/{imageId}/content/{ctype}
# Returns: record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_imageId
export def "get-image-content-by-type-image-id" [
  image_id: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/content/{ctype}"
    path_params: [{name: imageId, var: image_id}, {name: ctype, var: ctype}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, ctype: $ctype, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get vulnerability types
#
# GET /images/by_id/{imageId}/vuln
# Returns: list<string>
# operationId: get_image_vulnerability_types_by_imageId
export def "get-image-vulnerability-types-by-image-id" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/vuln"
    path_params: [{name: imageId, var: image_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get vulnerabilities by type
#
# GET /images/by_id/{imageId}/vuln/{vtype}
# Returns: record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string>
# operationId: get_image_vulnerabilities_by_type_imageId
export def "get-image-vulnerabilities-by-type-image-id" [
  image_id: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/by_id/{imageId}/vuln/{vtype}"
    path_params: [{name: imageId, var: image_id}, {name: vtype, var: vtype}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_id: $image_id, vtype: $vtype, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an image analysis
#
# DELETE /images/{imageDigest}
# Returns: record<detail: string, digest: string, status: string>
# operationId: delete_image
export def "delete-image" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/images/{imageDigest}"
    path_params: [{name: imageDigest, var: image_digest}]
    query: [{name: force, var: force}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, force: $force, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get image metadata
#
# GET /images/{imageDigest}
# Returns: table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>
# operationId: get_image
export def "get-image" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/file_content_search
# Returns: table<matches: list<record>, path: string>
# operationId: list_file_content_search_results
export def "list-file-content-search-results" [
  image_digest: string
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
    path: "/images/{imageDigest}/artifacts/file_content_search"
    path_params: [{name: imageDigest, var: image_digest}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/retrieved_files
# Returns: table<b64_content: string, path: string>
# operationId: list_retrieved_files
export def "list-retrieved-files" [
  image_digest: string
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
    path: "/images/{imageDigest}/artifacts/retrieved_files"
    path_params: [{name: imageDigest, var: image_digest}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of analyzer artifacts of the specified type
#
# GET /images/{imageDigest}/artifacts/secret_search
# Returns: table<matches: list<record>, path: string>
# operationId: list_secret_search_results
export def "list-secret-search-results" [
  image_digest: string
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
    path: "/images/{imageDigest}/artifacts/secret_search"
    path_params: [{name: imageDigest, var: image_digest}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check policy evaluation status for image
#
# GET /images/{imageDigest}/check
# Returns: list<record>
# operationId: get_image_policy_check
export def "get-image-policy-check" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-id: string
  --tag: string # required
  --detail: oneof<nothing, bool>
  --history: oneof<nothing, bool>
  --interactive: oneof<nothing, bool>
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/check"
    path_params: [{name: imageDigest, var: image_digest}]
    query: [{name: policyId, var: policy_id}, {name: tag, var: tag, required: true}, {name: detail, var: detail}, {name: history, var: history}, {name: interactive, var: interactive}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, policy_id: $policy_id, tag: $tag, detail: $detail, history: $history, interactive: $interactive, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List image content types
#
# GET /images/{imageDigest}/content
# Returns: list<string>
# operationId: list_image_content
export def "list-image-content" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/content"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type files
#
# GET /images/{imageDigest}/content/files
# Returns: record<content: table<filename: string, gid: int, linkdest: string, mode: string, sha256: string, size: int, type: string, uid: int>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_files
export def "get-image-content-by-type-files" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/content/files"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type java
#
# GET /images/{imageDigest}/content/java
# Returns: record<content: table<cpes: list, implementation-version: string, location: string, maven-version: string, origin: string, package: string, specification-version: string, type: string>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_javapackage
export def "get-image-content-by-type-javapackage" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/content/java"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type malware
#
# GET /images/{imageDigest}/content/malware
# Returns: record<content: table<enabled: bool, findings: list, metadata: record, scanner: string>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type_malware
export def "get-image-content-by-type-malware" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/content/malware"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of an image by type
#
# GET /images/{imageDigest}/content/{ctype}
# Returns: record<content: table<cpes: list, license: string, licenses: list, location: string, origin: string, package: string, size: string, type: string, version: string>, content_type: string, imageDigest: string>
# operationId: get_image_content_by_type
export def "get-image-content-by-type" [
  image_digest: string
  ctype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/content/{ctype}"
    path_params: [{name: imageDigest, var: image_digest}, {name: ctype, var: ctype}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, ctype: $ctype, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List image metadata types
#
# GET /images/{imageDigest}/metadata
# Returns: list<string>
# operationId: list_image_metadata
export def "list-image-metadata" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/metadata"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the metadata of an image by type
#
# GET /images/{imageDigest}/metadata/{mtype}
# Returns: record<imageDigest: string, metadata: any, metadata_type: string>
# operationId: get_image_metadata_by_type
export def "get-image-metadata-by-type" [
  image_digest: string
  mtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/metadata/{mtype}"
    path_params: [{name: imageDigest, var: image_digest}, {name: mtype, var: mtype}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, mtype: $mtype, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get image sbom in the native Anchore format
#
# GET /images/{imageDigest}/sboms/native
# Returns: binary
# operationId: get_image_sbom_native
export def "get-image-sbom-native" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  http-request {
    method: get
    path: "/images/{imageDigest}/sboms/native"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/gzip"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get vulnerability types
#
# GET /images/{imageDigest}/vuln
# Returns: list<string>
# operationId: get_image_vulnerability_types
export def "get-image-vulnerability-types" [
  image_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/vuln"
    path_params: [{name: imageDigest, var: image_digest}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get vulnerabilities by type
#
# GET /images/{imageDigest}/vuln/{vtype}
# Returns: record<imageDigest: string, vulnerabilities: table<feed: string, feed_group: string, fix: string, nvd_data: list, package: string, package_cpe: string, package_name: string, package_path: string, package_type: string, package_version: string, severity: string, url: string, vendor_data: list, vuln: string, will_not_fix: bool>, vulnerability_type: string>
# operationId: get_image_vulnerabilities_by_type
export def "get-image-vulnerabilities-by-type" [
  image_digest: string
  vtype: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-refresh: oneof<nothing, bool>
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data. When set to true, it will filter out all vulnerabilities where `will_not_fix` is False. If false all vulnerabilities are returned regardless of `will_not_fix`
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/images/{imageDigest}/vuln/{vtype}"
    path_params: [{name: imageDigest, var: image_digest}, {name: vtype, var: vtype}]
    query: [{name: force_refresh, var: force_refresh}, {name: vendor_only, var: vendor_only}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_digest: $image_digest, vtype: $vtype, force_refresh: $force_refresh, vendor_only: $vendor_only, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import an anchore image tar.gz archive file. This is a deprecated API replaced by the "/imports/images" route
#
# POST /import/images
# Returns: table<analysis_status: string, annotations: record, created_at: string, imageDigest: string, image_content: record, image_detail: list<record>, image_status: string, last_updated: string, record_version: string, userId: string>
# operationId: import_image_archive
export def "import-image-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  archive_file: string # anchore image tar archive. (format: binary)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/import/images"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: archive_file, var: archive_file}], files: [archive_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    archive_file: $archive_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists in-progress imports
#
# GET /imports/images
# Returns: table<created_at: string, expires_at: string, status: string, uuid: string>
# operationId: list_operations
export def "list-operations" [
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
    path: "/imports/images"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images
# Returns: record<created_at: string, expires_at: string, status: string, uuid: string>
# operationId: create_operation
export def "create-operation" [
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
    path: "/imports/images"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidate operation ID so it can be garbage collected
#
# DELETE /imports/images/{operation_id}
# Returns: record<created_at: string, expires_at: string, status: string, uuid: string>
# operationId: invalidate_operation
export def "invalidate-operation" [
  operation_id: string
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
    path: "/imports/images/{operation_id}"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detail on a single import
#
# GET /imports/images/{operation_id}
# Returns: record<created_at: string, expires_at: string, status: string, uuid: string>
# operationId: get_operation
export def "get-operation" [
  operation_id: string
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
    path: "/imports/images/{operation_id}"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded dockerfiles
#
# GET /imports/images/{operation_id}/dockerfile
# Returns: list<string>
# operationId: list_import_dockerfiles
export def "list-import-dockerfiles" [
  operation_id: string
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
    path: "/imports/images/{operation_id}/dockerfile"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/dockerfile
# Returns: record<created_at: string, digest: string>
# operationId: import_image_dockerfile
export def "import-image-dockerfile" [
  operation_id: string
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
    method: post
    path: "/imports/images/{operation_id}/dockerfile"
    path_params: [{name: operation_id, var: operation_id}]
    body: {content_type: "text/plain; utf-8", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded image configs
#
# GET /imports/images/{operation_id}/image_config
# Returns: list<string>
# operationId: list_import_image_configs
export def "list-import-image-configs" [
  operation_id: string
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
    path: "/imports/images/{operation_id}/image_config"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a docker or OCI image config to associate with the image
#
# POST /imports/images/{operation_id}/image_config
# Returns: record<created_at: string, digest: string>
# operationId: import_image_config
export def "import-image-config" [
  operation_id: string
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
    method: post
    path: "/imports/images/{operation_id}/image_config"
    path_params: [{name: operation_id, var: operation_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded image manifests
#
# GET /imports/images/{operation_id}/manifest
# Returns: list<string>
# operationId: list_import_image_manifests
export def "list-import-image-manifests" [
  operation_id: string
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
    path: "/imports/images/{operation_id}/manifest"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a docker or OCI distribution manifest to associate with the image
#
# POST /imports/images/{operation_id}/manifest
# Returns: record<created_at: string, digest: string>
# operationId: import_image_manifest
export def "import-image-manifest" [
  operation_id: string
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
    method: post
    path: "/imports/images/{operation_id}/manifest"
    path_params: [{name: operation_id, var: operation_id}]
    body: {content_type: "application/vnd.docker.distribution.manifest.v1+json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded package manifests
#
# GET /imports/images/{operation_id}/packages
# Returns: list<string>
# operationId: list_import_packages
export def "list-import-packages" [
  operation_id: string
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
    path: "/imports/images/{operation_id}/packages"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Begin the import of an image analyzed by Syft into the system
#
# POST /imports/images/{operation_id}/packages
# Returns: record<created_at: string, digest: string>
# operationId: import_image_packages
export def "import-image-packages" [
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifact-relationships: list # item shape: {child: string, metadata?: record, parent: string, type: string}
  artifacts: list # item shape: {cpes: list<string>, foundBy?: string, id?: string, language: string, licenses: list<string>, locations: list, metadata?: record, metadataType: string, name: string, purl?: string, type: string, version: string}
  --descriptor: record # shape: {name: string, version: string}
  distro: record # shape: {idLike: string, name: string, version: string}
  --schema: record # shape: {url: string, version: string}
  source: record # shape: {target: any, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/imports/images/{operation_id}/packages"
    path_params: [{name: operation_id, var: operation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: artifactRelationships, var: artifact_relationships}, {name: artifacts, var: artifacts}, {name: descriptor, var: descriptor}, {name: distro, var: distro}, {name: schema, var: schema}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id, artifact_relationships: $artifact_relationships, artifacts: $artifacts, descriptor: $descriptor, distro: $distro, schema: $schema, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List uploaded parent manifests (manifest lists for a tag)
#
# GET /imports/images/{operation_id}/parent_manifest
# Returns: list<string>
# operationId: list_import_parent_manifests
export def "list-import-parent-manifests" [
  operation_id: string
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
    path: "/imports/images/{operation_id}/parent_manifest"
    path_params: [{name: operation_id, var: operation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a docker or OCI distribution manifest list to associate with the image
#
# POST /imports/images/{operation_id}/parent_manifest
# Returns: record<created_at: string, digest: string>
# operationId: import_image_parent_manifest
export def "import-image-parent-manifest" [
  operation_id: string
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
    method: post
    path: "/imports/images/{operation_id}/parent_manifest"
    path_params: [{name: operation_id, var: operation_id}]
    body: {content_type: "application/vnd.docker.distribution.manifest.list.v2+json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    operation_id: $operation_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a jwt token for subsequent operations, this request is authenticated with normal HTTP auth
#
# POST /oauth/token
# Returns: record<token: string>
# operationId: get_oauth_token
export def "get-oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The type of client used for the OAuth token (default: anonymous)
  --grant-type: string # OAuth Grant type for token (default: password)
  --password: string # Password for corresponding user
  --username: string # User to assign OAuth token to
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: client_id, var: client_id}, {name: grant_type, var: grant_type}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, grant_type: $grant_type, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List policies
#
# GET /policies
# Returns: table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>
# operationId: list_policies
export def "list-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/policies"
    query: [{name: detail, var: detail}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    detail: $detail, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new policy
#
# POST /policies
# Returns: record<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list<record>, comment: string, id: string, mappings: list<record>, name: string, policies: list<record>, version: string, whitelisted_images: list<record>, whitelists: list<record>>, userId: string>
# operationId: add_policy
export def "add-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --blacklisted-images: list # List of mapping rules that define which images should always result in a STOP/FAIL policy result regardless of policy content or presence in whitelisted_images — item shape: {id?: string, image: record, name: string, registry: string, repository: string}
  --comment: string # Description of the bundle, human readable
  id: string # Id of the bundle
  mappings: list # Mapping rules for defining which policy and whitelist(s) to apply to an image based on a match of the image tag or id. Evaluated in order. — item shape: {id?: string, image: record, name: string, policy_id?: string, policy_ids?: list<string>, registry: string, repository: string, whitelist_ids?: list<string>}
  --name: string # Human readable name for the bundle
  policies: list # Policies which define the go/stop/warn status of an image using rule matches on image properties — item shape: {comment?: string, id: string, name?: string, rules?: list, version: string}
  version: string # Version id for this bundle format
  --whitelisted-images: list # List of mapping rules that define which images should always be passed (unless also on the blacklist), regardless of policy result. — item shape: {id?: string, image: record, name: string, registry: string, repository: string}
  --whitelists: list # Whitelists which define which policy matches to disregard explicitly in the final policy decision — item shape: {comment?: string, id: string, items?: list, name?: string, version: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/policies"
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: blacklisted_images, var: blacklisted_images}, {name: comment, var: comment}, {name: id, var: id}, {name: mappings, var: mappings}, {name: name, var: name}, {name: policies, var: policies}, {name: version, var: version}, {name: whitelisted_images, var: whitelisted_images}, {name: whitelists, var: whitelists}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_anchore_account: $x_anchore_account, blacklisted_images: $blacklisted_images, comment: $comment, id: $id, mappings: $mappings, name: $name, policies: $policies, version: $version, whitelisted_images: $whitelisted_images, whitelists: $whitelists
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete policy
#
# DELETE /policies/{policyId}
# operationId: delete_policy
export def "delete-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  http-request {
    method: delete
    path: "/policies/{policyId}"
    path_params: [{name: policyId, var: policy_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_id: $policy_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific policy
#
# GET /policies/{policyId}
# Returns: table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>
# operationId: get_policy
export def "get-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detail: oneof<nothing, bool> # Include policy bundle detail in the form of the full bundle content for each entry
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/policies/{policyId}"
    path_params: [{name: policyId, var: policy_id}]
    query: [{name: detail, var: detail}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_id: $policy_id, detail: $detail, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update policy
#
# PUT /policies/{policyId}
# Returns: table<active: bool, created_at: string, last_updated: string, policyId: string, policy_source: string, policybundle: record<blacklisted_images: list, comment: string, id: string, mappings: list, name: string, policies: list, version: string, whitelisted_images: list, whitelists: list>, userId: string>
# operationId: update_policy
export def "update-policy" [
  policy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Mark policy as active
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --body-active: oneof<nothing, bool> # True if the bundle is currently defined to be used automatically (spec name: active)
  --created-at: string # format: date-time
  --last-updated: string # format: date-time
  --body-policy-id: string # The bundle's identifier (spec name: policyId)
  --policy-source: string # Source location of where the policy bundle originated
  --policybundle: record # A bundle containing a set of policies, whitelists, and rules for mapping them to specific images — shape: {blacklisted_images?: list, comment?: string, id: string, mappings: list, name?: string, policies: list, version: string, whitelisted_images?: list, whitelists?: list}
  --user-id: string # UserId of the user that owns the bundle
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/policies/{policyId}"
    path_params: [{name: policyId, var: policy_id}]
    query: [{name: active, var: active}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: body_active}, {name: created_at, var: created_at}, {name: last_updated, var: last_updated}, {name: policyId, var: body_policy_id}, {name: policy_source, var: policy_source}, {name: policybundle, var: policybundle}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    policy_id: $policy_id, active: $active, x_anchore_account: $x_anchore_account, body_active: $body_active, created_at: $created_at, last_updated: $last_updated, body_policy_id: $body_policy_id, policy_source: $policy_source, policybundle: $policybundle, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of images containing given package
#
# GET /query/images/by_package
# Returns: record<next_page: string, page: string, returned_count: int, images: table<image: record, packages: list>>
# operationId: query_images_by_package
export def "query-images-by-package" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of package to search for (e.g. sed) (required)
  --package-type: string # Type of package to filter on (e.g. dpkg)
  --version: string # Version of named package to filter on (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/images/by_package"
    query: [{name: name, var: name, required: true}, {name: package_type, var: package_type}, {name: version, var: version}, {name: page, var: page}, {name: limit, var: limit}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, package_type: $package_type, version: $version, page: $page, limit: $limit, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List images vulnerable to the specific vulnerability ID.
#
# GET /query/images/by_vulnerability
# Returns: record<next_page: string, page: string, returned_count: int, images: table<affected_packages: list, image: record>>
# operationId: query_images_by_vulnerability
export def "query-images-by-vulnerability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vulnerability-id: string # The ID of the vulnerability to search for within all images stored in anchore-engine (e.g. CVE-1999-0001) (required)
  --namespace: string # Filter results to images within the given vulnerability namespace (e.g. debian:8, ubuntu:14.04)
  --affected-package: string # Filter results to images with vulnable packages with the given package name (e.g. libssl)
  --severity: string@severity-completer # Filter results to vulnerable package/vulnerability with the given severity
  --vendor-only: oneof<nothing, bool> # Filter results to include only vulnerabilities that are not marked as invalid by upstream OS vendor data (default: true)
  --page: int # The page of results to fetch. Pages start at 1
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/images/by_vulnerability"
    query: [{name: vulnerability_id, var: vulnerability_id, required: true}, {name: namespace, var: namespace}, {name: affected_package, var: affected_package}, {name: severity, var: severity}, {name: vendor_only, var: vendor_only}, {name: page, var: page}, {name: limit, var: limit}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    vulnerability_id: $vulnerability_id, namespace: $namespace, affected_package: $affected_package, severity: $severity, vendor_only: $vendor_only, page: $page, limit: $limit, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Listing information about given vulnerability
#
# GET /query/vulnerabilities
# Returns: record<next_page: string, page: string, returned_count: int, vulnerabilities: table<affected_packages: list, description: string, id: string, link: string, namespace: string, nvd_data: list, references: list, severity: string, vendor_data: list>>
# operationId: query_vulnerabilities
export def "query-vulnerabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # The ID of the vulnerability (e.g. CVE-1999-0001) (required)
  --affected-package: string # Filter results by specified package name (e.g. sed)
  --affected-package-version: string # Filter results by specified package version (e.g. 4.4-1)
  --page: string # The page of results to fetch. Pages start at 1 (default: 1)
  --limit: int # Limit the number of records for the requested page. If omitted or set to 0, return all results in a single page
  --namespace: list<string> # Namespace(s) to filter vulnerability records by
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/query/vulnerabilities"
    query: [{name: id, var: id, style: csv, required: true}, {name: affected_package, var: affected_package}, {name: affected_package_version, var: affected_package_version}, {name: page, var: page}, {name: limit, var: limit}, {name: namespace, var: namespace, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, affected_package: $affected_package, affected_package_version: $affected_package_version, page: $page, limit: $limit, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List configured registries
#
# GET /registries
# Returns: table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>
# operationId: list_registries
export def "list-registries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/registries"
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new registry
#
# POST /registries
# Returns: table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>
# operationId: create_registry
export def "create-registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry add time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository)
  --registry-name: string # human readable name associated with registry record
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --registry-user: string # Username portion of credential to use for this registry
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/registries"
    query: [{name: validate, var: validate}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: registry, var: registry}, {name: registry_name, var: registry_name}, {name: registry_pass, var: registry_pass}, {name: registry_type, var: registry_type}, {name: registry_user, var: registry_user}, {name: registry_verify, var: registry_verify}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    validate: $validate, x_anchore_account: $x_anchore_account, registry: $registry, registry_name: $registry_name, registry_pass: $registry_pass, registry_type: $registry_type, registry_user: $registry_user, registry_verify: $registry_verify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a registry configuration
#
# DELETE /registries/{registry}
# operationId: delete_registry
export def "delete-registry" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  http-request {
    method: delete
    path: "/registries/{registry}"
    path_params: [{name: registry, var: registry}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registry: $registry, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific registry configuration
#
# GET /registries/{registry}
# Returns: table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>
# operationId: get_registry
export def "get-registry" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/registries/{registry}"
    path_params: [{name: registry, var: registry}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registry: $registry, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update/replace a registry configuration
#
# PUT /registries/{registry}
# Returns: table<created_at: string, last_upated: string, registry: string, registry_name: string, registry_type: string, registry_user: string, registry_verify: bool, userId: string>
# operationId: update_registry
export def "update-registry" [
  registry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --validate: oneof<nothing, bool> # flag to determine whether or not to validate registry/credential at registry update time
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --body-registry: string # hostname:port string for accessing the registry, as would be used in a docker pull operation. May include some or all of a repository and wildcards (e.g. docker.io/library/* or gcr.io/myproject/myrepository) (spec name: registry)
  --registry-name: string # human readable name associated with registry record
  --registry-pass: string # Password portion of credential to use for this registry
  --registry-type: string # Type of registry
  --registry-user: string # Username portion of credential to use for this registry
  --registry-verify: oneof<nothing, bool> # Use TLS/SSL verification for the registry URL
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/registries/{registry}"
    path_params: [{name: registry, var: registry}]
    query: [{name: validate, var: validate}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: registry, var: body_registry}, {name: registry_name, var: registry_name}, {name: registry_pass, var: registry_pass}, {name: registry_type, var: registry_type}, {name: registry_user, var: registry_user}, {name: registry_verify, var: registry_verify}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registry: $registry, validate: $validate, x_anchore_account: $x_anchore_account, body_registry: $body_registry, registry_name: $registry_name, registry_pass: $registry_pass, registry_type: $registry_type, registry_user: $registry_user, registry_verify: $registry_verify
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add repository to watch
#
# POST /repositories
# Returns: table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>
# operationId: add_repository
export def "add-repository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository: string # full repository to add e.g. docker.io/library/alpine (required)
  --autosubscribe: oneof<nothing, bool> # flag to enable/disable auto tag_update activation when new images from a repo are added
  --dryrun: oneof<nothing, bool> # flag to return tags in the repository without actually watching the repository, default is false
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/repositories"
    query: [{name: repository, var: repository, required: true}, {name: autosubscribe, var: autosubscribe}, {name: dryrun, var: dryrun}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    repository: $repository, autosubscribe: $autosubscribe, dryrun: $dryrun, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Service status
#
# GET /status
# Returns: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>
# operationId: get_status
export def "get-status" [
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
    path: "/status"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all subscriptions
#
# GET /subscriptions
# Returns: table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>
# operationId: list_subscriptions
export def "list-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-key: string # filter only subscriptions matching key
  --subscription-type: string # filter only subscriptions matching type
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions"
    query: [{name: subscription_key, var: subscription_key}, {name: subscription_type, var: subscription_type}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_key: $subscription_key, subscription_type: $subscription_type, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a subscription of a specific type
#
# POST /subscriptions
# Returns: table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>
# operationId: add_subscription
export def "add-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --subscription-key: string
  --subscription-type: string
  --subscription-value: string # nullable
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions"
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: subscription_key, var: subscription_key}, {name: subscription_type, var: subscription_type}, {name: subscription_value, var: subscription_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_anchore_account: $x_anchore_account, subscription_key: $subscription_key, subscription_type: $subscription_type, subscription_value: $subscription_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete subscriptions of a specific type
#
# DELETE /subscriptions/{subscriptionId}
# operationId: delete_subscription
export def "delete-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific subscription set
#
# GET /subscriptions/{subscriptionId}
# Returns: table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>
# operationId: get_subscription
export def "get-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing and specific subscription
#
# PUT /subscriptions/{subscriptionId}
# Returns: table<active: bool, subscription_id: string, subscription_key: string, subscription_type: string, subscription_value: string, userId: string>
# operationId: update_subscription
export def "update-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
  --active: oneof<nothing, bool> # Toggle the subscription processing on or off
  --subscription-value: string # The new subscription value, e.g. the new tag to be subscribed to (nullable)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}"
    path_params: [{name: subscriptionId, var: subscription_id}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: subscription_value, var: subscription_value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, x_anchore_account: $x_anchore_account, active: $active, subscription_value: $subscription_value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all visible image digests and tags
#
# GET /summaries/imagetags
# Returns: table<analysis_status: string, analyzed_at: int, created_at: int, fulltag: string, imageDigest: string, imageId: string, image_status: string, parentDigest: string, tag_detected_at: int>
# operationId: list_imagetags
export def "list-imagetags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-status: list<string> # Filter images in one or more states such as active, deleting. Defaults to active images only if unspecified (default: [active])
  --x-anchore-account: string # An account name to change the resource scope of the request to that account, if permissions allow (admin only)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/summaries/imagetags"
    query: [{name: image_status, var: image_status, style: csv}]
    header: [{name: x-anchore-account, var: x_anchore_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    image_status: $image_status, x_anchore_account: $x_anchore_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# System status
#
# GET /system
# Returns: record<service_states: table<base_url: string, hostid: string, service_detail: record, servicename: string, status: bool, status_message: string, version: string>>
# operationId: get_service_detail
export def "get-service-detail" [
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
    path: "/system"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe anchore engine error codes.
#
# GET /system/error_codes
# Returns: table<description: string, name: string>
# operationId: describe_error_codes
export def "describe-error-codes" [
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
    path: "/system/error_codes"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list feeds operations and information
#
# GET /system/feeds
# Returns: table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string>
# operationId: get_system_feeds
export def "get-system-feeds" [
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
    path: "/system/feeds"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# trigger feeds operations
#
# POST /system/feeds
# Returns: table<feed: string, groups: list<record>, status: string, total_time_seconds: float>
# operationId: post_system_feeds
export def "post-system-feeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flush: oneof<nothing, bool> # instruct system to flush existing data feeds records from anchore-engine
  --sync: oneof<nothing, bool> # instruct system to re-sync data feeds
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/system/feeds"
    query: [{name: flush, var: flush}, {name: sync, var: sync}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flush: $flush, sync: $sync
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the groups and data for the feed and disable the feed itself
#
# DELETE /system/feeds/{feed}
# operationId: delete_feed
export def "delete-feed" [
  feed: string
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
    path: "/system/feeds/{feed}"
    path_params: [{name: feed, var: feed}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed: $feed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable the feed so that it does not sync on subsequent sync operations
#
# PUT /system/feeds/{feed}
# Returns: record<created_at: string, groups: table<created_at: string, last_sync: string, name: string, record_count: int>, last_full_sync: string, name: string, updated_at: string>
# operationId: toggle_feed_enabled
export def "toggle-feed-enabled" [
  feed: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/system/feeds/{feed}"
    path_params: [{name: feed, var: feed}]
    query: [{name: enabled, var: enabled, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed: $feed, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the group data and disable the group itself
#
# DELETE /system/feeds/{feed}/{group}
# operationId: delete_feed_group
export def "delete-feed-group" [
  feed: string
  group: string
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
    path: "/system/feeds/{feed}/{group}"
    path_params: [{name: feed, var: feed}, {name: group, var: group}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed: $feed, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a specific group within a feed to not sync
#
# PUT /system/feeds/{feed}/{group}
# Returns: table<created_at: string, groups: list<record>, last_full_sync: string, name: string, updated_at: string>
# operationId: toggle_group_enabled
export def "toggle-group-enabled" [
  feed: string
  group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: put
    path: "/system/feeds/{feed}/{group}"
    path_params: [{name: feed, var: feed}, {name: group, var: group}]
    query: [{name: enabled, var: enabled, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    feed: $feed, group: $group, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describe the policy language spec implemented by this service.
#
# GET /system/policy_spec
# Returns: table<description: string, name: string, state: string, superceded_by: string, triggers: list<record>>
# operationId: describe_policy
export def "describe-policy" [
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
    path: "/system/policy_spec"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List system services
#
# GET /system/services
# Returns: table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>
# operationId: list_services
export def "list-services" [
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
    path: "/system/services"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a service configuration and state
#
# GET /system/services/{servicename}
# Returns: table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>
# operationId: get_services_by_name
export def "get-services-by-name" [
  servicename: string
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
    path: "/system/services/{servicename}"
    path_params: [{name: servicename, var: servicename}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    servicename: $servicename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the service config
#
# DELETE /system/services/{servicename}/{hostid}
# operationId: delete_service
export def "delete-service" [
  servicename: string
  hostid: string
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
    path: "/system/services/{servicename}/{hostid}"
    path_params: [{name: servicename, var: servicename}, {name: hostid, var: hostid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    servicename: $servicename, hostid: $hostid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service config for a specific host
#
# GET /system/services/{servicename}/{hostid}
# Returns: table<base_url: string, hostid: string, service_detail: record<available: bool, busy: bool, db_version: string, detail: record, message: string, up: bool, version: string>, servicename: string, status: bool, status_message: string, version: string>
# operationId: get_services_by_name_and_host
export def "get-services-by-name-and-host" [
  servicename: string
  hostid: string
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
    path: "/system/services/{servicename}/{hostid}"
    path_params: [{name: servicename, var: servicename}, {name: hostid, var: hostid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    servicename: $servicename, hostid: $hostid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the capabilities to test a webhook delivery for the given notification type
#
# POST /system/webhooks/{webhook_type}/test
# operationId: test_webhook
export def "test-webhook" [
  webhook_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-type: string@notification-type-completer # What kind of Notification to send (default: tag_update)
]: nothing -> any {
  http-request {
    method: post
    path: "/system/webhooks/{webhook_type}/test"
    path_params: [{name: webhook_type, var: webhook_type}]
    query: [{name: notification_type, var: notification_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_type: $webhook_type, notification_type: $notification_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List authenticated user info
#
# GET /user
# Returns: record<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: get_user
export def "get-user" [
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
    path: "/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current credential summary
#
# GET /user/credentials
# Returns: table<created_at: string, type: string, value: string>
# operationId: get_credentials
export def "get-credentials" [
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
    path: "/user/credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# add/replace credential
#
# POST /user/credentials
# Returns: record<created_at: string, last_updated: string, source: string, type: string, username: string>
# operationId: add_credential
export def "add-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # The timestamp of creation of the credential
  type: string@type-completer # The type of credential
  value: string # The credential value (e.g. the password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: created_at, var: created_at}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    created_at: $created_at, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the version object for the service, including db schema version info
#
# GET /version
# Returns: record<api: record<version: string>, db: record<schema_version: string>, service: record<version: string>>
# operationId: version_check
export def "version-check" [
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
