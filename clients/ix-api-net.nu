# Auto-generated client for IX-API v2.1.0
# Source: https://api.apis.guru/v2/specs/ix-api.net/2.1.0/openapi.json
# Auth: --token flag or $env.IX_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api/v2"
  token_env_var: "IX_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/api/v2"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def type-completer [] { ["allow" "deny"] }
def type-completer-1 [] { ["route_server"] }
def bgp-session-type-completer [] { ["active" "passive"] }
def session-mode-completer [] { ["collector" "public"] }
def type-completer-2 [] { ["cloud_vc" "exchange_lan" "mp2mp_vc" "p2mp_vc" "p2p_vc"] }
def role-completer [] { ["leaf" "root"] }
def type-completer-3 [] { ["cloud_vc" "mp2mp_vc" "p2mp_vc" "p2p_vc"] }
def downgrade-allowed-completer [] { ["true" "true"] }
def upgrade-allowed-completer [] { ["false" "true"] }
def delivery-method-completer [] { ["dedicated" "shared"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accounts-list: "table<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: list<record>>"
    accounts-create: "record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    accounts-destroy: "record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    accounts-read: "record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    accounts-partial-update: "record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    accounts-update: "record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    auth-token-refresh: "record<access_token: string, refresh_token: string>"
    auth-token-create: "record<access_token: string, refresh_token: string>"
    connections-list: "table<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>, vlan_types: list<string>>"
    connections-read: "record<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>, vlan_types: list<string>>"
    contacts-list: "table<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    contacts-create: "record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    contacts-destroy: "record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    contacts-read: "record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    contacts-partial-update: "record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    contacts-update: "record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>"
    devices-list: "table<capabilities: list<record>, facility: string, id: string, name: string, pop: string>"
    devices-read: "record<capabilities: table<availability: int, max_lag: int, media_type: string, speed: int>, facility: string, id: string, name: string, pop: string>"
    facilities-list: "table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string>"
    facilities-read: "table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string>"
    api-health-read: "record<checks: record, description: string, links: record, notes: list<string>, output: string, releaseId: string, serviceId: string, status: string, version: string>"
    api-implementation-read: "record<schema_version: string, service_version: string, supported_network_feature_config_types: list<string>, supported_network_feature_types: list<string>, supported_network_service_config_types: list<string>, supported_network_service_types: list<string>, supported_operations: list<string>>"
    ips-list: "table<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>"
    ips-create: "record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>"
    ips-read: "record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>"
    ips-partial-update: "record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>"
    ips-update: "record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>"
    macs-list: "table<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>"
    macs-create: "record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>"
    macs-destroy: "record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>"
    macs-read: "record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>"
    member-joining-rules-list: "list<any>"
    metro-area-networks-list: "table<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string>"
    metro-area-networks-read: "record<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string>"
    metro-areas-list: "table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string>"
    metro-areas-read: "table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string>"
    network-feature-configs-list: "list<any>"
    network-features-list: "list<any>"
    network-service-configs-list: "list<any>"
    network-service-config-cancellation-policy-read: "record<charged_until: string, decommission_at: string>"
    network-services-list: "list<any>"
    network-service-cancellation-policy-read: "record<charged_until: string, decommission_at: string>"
    network-service-change-request-destroy: "record<capacity: int, product_offering: string>"
    network-service-change-request-read: "record<capacity: int, product_offering: string>"
    network-service-change-request-create: "record<capacity: int, product_offering: string>"
    pops-list: "table<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string>"
    pops-read: "record<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string>"
    ports-list: "table<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>>"
    ports-read: "record<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>"
    product-offerings-list: "list<any>"
    role-assignments-list: "table<contact: string, id: string, role: string>"
    role-assignments-create: "record<contact: string, id: string, role: string>"
    role-assignments-destroy: "record<contact: string, id: string, role: string>"
    role-assignments-read: "record<contact: string, id: string, role: string>"
    roles-list: "table<id: string, name: string, required_fields: list<string>>"
    roles-read: "record<id: string, name: string, required_fields: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accounts-list" "accounts-create" "accounts-destroy" "accounts-read" "accounts-partial-update" "accounts-update" "auth-token-refresh" "auth-token-create" "connections-list" "connections-read" "contacts-list" "contacts-create" "contacts-destroy" "contacts-read" "contacts-partial-update" "contacts-update" "devices-list" "devices-read" "facilities-list" "facilities-read" "api-health-read" "api-implementation-read" "ips-list" "ips-create" "ips-read" "ips-partial-update" "ips-update" "macs-list" "macs-create" "macs-destroy" "macs-read" "member-joining-rules-list" "member-joining-rules-create" "member-joining-rules-destroy" "member-joining-rules-read" "member-joining-rules-partial-update" "member-joining-rules-update" "metro-area-networks-list" "metro-area-networks-read" "metro-areas-list" "metro-areas-read" "network-feature-configs-list" "network-feature-configs-create" "network-feature-configs-destroy" "network-feature-configs-read" "network-feature-configs-partial-update" "network-feature-configs-update" "network-features-list" "network-features-read" "network-service-configs-list" "network-service-configs-create" "network-service-configs-destroy" "network-service-configs-read" "network-service-configs-partial-update" "network-service-configs-update" "network-service-config-cancellation-policy-read" "network-services-list" "network-services-create" "network-services-destroy" "network-services-read" "network-services-partial-update" "network-services-update" "network-service-cancellation-policy-read" "network-service-change-request-destroy" "network-service-change-request-read" "network-service-change-request-create" "pops-list" "pops-read" "ports-list" "ports-read" "product-offerings-list" "product-offerings-read" "role-assignments-list" "role-assignments-create" "role-assignments-destroy" "role-assignments-read" "roles-list" "roles-read" "commands"] | sort) } | get name | first)
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

# Retrieve a list of `Account`s. This includes all accounts the currently authorized account is managing and the current account itself.
#
# GET /accounts
# Returns: table<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: list<record>>
# operationId: accounts_list
export def "accounts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --billable: int # Filter by billable
  --external-ref: string # Filter by external_ref
  --name: string # Filter by name
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: managing_account, var: managing_account}, {name: billable, var: billable}, {name: external_ref, var: external_ref}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, managing_account: $managing_account, billable: $billable, external_ref: $external_ref, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new account.
#
# POST /accounts
# Returns: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: accounts_create
export def "accounts-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {country: string, locality: string, post_office_box_number?: string, postal_code: string, region?: string, street_address: string}
  --billing-information: record # Optional information required for issuing invoices. Only accounts with `billing_information` present can be used as a `billing_account`. — shape: {address: record, name: string, vat_number?: string}
  --discoverable: oneof<nothing, bool> # The account will be included for all members of the ix in the list of accounts. Only `id`, `name` and `present_in_metro_area_networks` are provided to other members. (default: false)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --legal-name: string # Legal name of the organisation. Only required when it's different from the account name. (nullable, e.g. Moon Network Services LLS.)
  --managing-account: string # The `id` of a managing account. Can be used for creating a customer hierachy. (nullable, e.g. IX:Account:231)
  --metro-area-network-presence: list<string> # Informal list of `MetroAreaNetwork` ids, indicating the presence to other accounts. The list is maintained by the account and can be empty. (default: [], e.g. [14021, 12939])
  name: string # Name of the account, how it gets represented in e.g. a "customers list". (e.g. Moonpeer Inc.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: billing_information, var: billing_information}, {name: discoverable, var: discoverable}, {name: external_ref, var: external_ref}, {name: legal_name, var: legal_name}, {name: managing_account, var: managing_account}, {name: metro_area_network_presence, var: metro_area_network_presence}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    address: $address, billing_information: $billing_information, discoverable: $discoverable, external_ref: $external_ref, legal_name: $legal_name, managing_account: $managing_account, metro_area_network_presence: $metro_area_network_presence, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accounts can be deleted, when all services and configs are decommissioned or the account is not longer referenced e.g. as a `managing_account` or `billing_account`. Deleting an account will cascade to `contacts` and `role-assignments`. The request will immediately fail, if the above preconditions are not met.
#
# DELETE /accounts/{id}
# Returns: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: accounts_destroy
export def "accounts-destroy" [
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
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single account.
#
# GET /accounts/{id}
# Returns: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: accounts_read
export def "accounts-read" [
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
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update parts of an account.
#
# PATCH /accounts/{id}
# Returns: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: accounts_partial_update
export def "accounts-partial-update" [
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
  --address: record # shape: {country: string, locality: string, post_office_box_number?: string, postal_code: string, region?: string, street_address: string}
  --billing-information: record # Optional information required for issuing invoices. Only accounts with `billing_information` present can be used as a `billing_account`. — shape: {address: record, name: string, vat_number?: string}
  --discoverable: oneof<nothing, bool> # The account will be included for all members of the ix in the list of accounts. Only `id`, `name` and `present_in_metro_area_networks` are provided to other members. (default: false)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --legal-name: string # Legal name of the organisation. Only required when it's different from the account name. (nullable, e.g. Moon Network Services LLS.)
  --managing-account: string # The `id` of a managing account. Can be used for creating a customer hierachy. (nullable, e.g. IX:Account:231)
  --metro-area-network-presence: list<string> # Informal list of `MetroAreaNetwork` ids, indicating the presence to other accounts. The list is maintained by the account and can be empty. (e.g. [14021, 12939])
  --name: string # Name of the account, how it gets represented in e.g. a "customers list". (e.g. Moonpeer Inc.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: address, var: address}, {name: billing_information, var: billing_information}, {name: discoverable, var: discoverable}, {name: external_ref, var: external_ref}, {name: legal_name, var: legal_name}, {name: managing_account, var: managing_account}, {name: metro_area_network_presence, var: metro_area_network_presence}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, address: $address, billing_information: $billing_information, discoverable: $discoverable, external_ref: $external_ref, legal_name: $legal_name, managing_account: $managing_account, metro_area_network_presence: $metro_area_network_presence, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the entire account.
#
# PUT /accounts/{id}
# Returns: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: accounts_update
export def "accounts-update" [
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
  address: record # shape: {country: string, locality: string, post_office_box_number?: string, postal_code: string, region?: string, street_address: string}
  --billing-information: record # Optional information required for issuing invoices. Only accounts with `billing_information` present can be used as a `billing_account`. — shape: {address: record, name: string, vat_number?: string}
  --discoverable: oneof<nothing, bool> # The account will be included for all members of the ix in the list of accounts. Only `id`, `name` and `present_in_metro_area_networks` are provided to other members. (default: false)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --legal-name: string # Legal name of the organisation. Only required when it's different from the account name. (nullable, e.g. Moon Network Services LLS.)
  --managing-account: string # The `id` of a managing account. Can be used for creating a customer hierachy. (nullable, e.g. IX:Account:231)
  metro_area_network_presence: list<string> # Informal list of `MetroAreaNetwork` ids, indicating the presence to other accounts. The list is maintained by the account and can be empty. (e.g. [14021, 12939])
  name: string # Name of the account, how it gets represented in e.g. a "customers list". (e.g. Moonpeer Inc.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: billing_information, var: billing_information}, {name: discoverable, var: discoverable}, {name: external_ref, var: external_ref}, {name: legal_name, var: legal_name}, {name: managing_account, var: managing_account}, {name: metro_area_network_presence, var: metro_area_network_presence}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, address: $address, billing_information: $billing_information, discoverable: $discoverable, external_ref: $external_ref, legal_name: $legal_name, managing_account: $managing_account, metro_area_network_presence: $metro_area_network_presence, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reauthenticate the API user, issue a new `access_token` and `refresh_token` pair by providing the `refresh_token` in the request body.
#
# POST /auth/refresh
# Returns: record<access_token: string, refresh_token: string>
# operationId: auth_token_refresh
export def "auth-token-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/refresh"
    body: {content_type: "application/json", kind: json, fields: [{name: refresh_token, var: refresh_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate an API user identified by `api_key` and `api_secret`.
#
# POST /auth/token
# Returns: record<access_token: string, refresh_token: string>
# operationId: auth_token_create
export def "auth-token-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  api_secret: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/token"
    body: {content_type: "application/json", kind: json, fields: [{name: api_key, var: api_key}, {name: api_secret, var: api_secret}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    api_key: $api_key, api_secret: $api_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all `connection`s.
#
# GET /connections
# Returns: table<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>, vlan_types: list<string>>
# operationId: connections_list
export def "connections-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --mode: string # Filter by mode
  --mode-is-not: string # Filter by mode__is_not
  --name: string # Filter by name
  --metro-area-network: string # Filter by metro_area_network
  --pop: string # Filter by pop
  --facility: string # Filter by facility
  --external-ref: string # Filter by external_ref
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/connections"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: mode, var: mode}, {name: mode__is_not, var: mode_is_not}, {name: name, var: name}, {name: metro_area_network, var: metro_area_network}, {name: pop, var: pop}, {name: facility, var: facility}, {name: external_ref, var: external_ref}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, mode: $mode, mode_is_not: $mode_is_not, name: $name, metro_area_network: $metro_area_network, pop: $pop, facility: $facility, external_ref: $external_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read a `connection`.
#
# GET /connections/{id}
# Returns: record<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>, vlan_types: list<string>>
# operationId: connections_read
export def "connections-read" [
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
    path: "/connections/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available contacts managed by the authorized account.
#
# GET /contacts
# Returns: table<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_list
export def "contacts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/contacts"
    query: [{name: id, var: id, style: csv}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contact.
#
# POST /contacts
# Returns: record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_create
export def "contacts-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --email: string # The email of the legal company entity. (nullable, e.g. info@moon-peer.net)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --name: string # A name of a person or an organisation (nullable, e.g. Some A. Name)
  --telephone: string # The telephone number in E.164 Phone Number Formatting (nullable, e.g. +442071838750)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: consuming_account, var: consuming_account}, {name: email, var: email}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: name, var: name}, {name: telephone, var: telephone}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    consuming_account: $consuming_account, email: $email, external_ref: $external_ref, managing_account: $managing_account, name: $name, telephone: $telephone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a contact. Please note, that a contact can only be removed if it is not longer in use in a network service or config through a role assignment.
#
# DELETE /contacts/{id}
# Returns: record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_destroy
export def "contacts-destroy" [
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
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a contact by it's id
#
# GET /contacts/{id}
# Returns: record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_read
export def "contacts-read" [
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
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update parts of a contact
#
# PATCH /contacts/{id}
# Returns: record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_partial_update
export def "contacts-partial-update" [
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
  --consuming-account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --email: string # The email of the legal company entity. (nullable, e.g. info@moon-peer.net)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --name: string # A name of a person or an organisation (nullable, e.g. Some A. Name)
  --telephone: string # The telephone number in E.164 Phone Number Formatting (nullable, e.g. +442071838750)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: consuming_account, var: consuming_account}, {name: email, var: email}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: name, var: name}, {name: telephone, var: telephone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, consuming_account: $consuming_account, email: $email, external_ref: $external_ref, managing_account: $managing_account, name: $name, telephone: $telephone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a contact
#
# PUT /contacts/{id}
# Returns: record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string>
# operationId: contacts_update
export def "contacts-update" [
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
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --email: string # The email of the legal company entity. (nullable, e.g. info@moon-peer.net)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --name: string # A name of a person or an organisation (nullable, e.g. Some A. Name)
  --telephone: string # The telephone number in E.164 Phone Number Formatting (nullable, e.g. +442071838750)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/contacts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: consuming_account, var: consuming_account}, {name: email, var: email}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: name, var: name}, {name: telephone, var: telephone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, consuming_account: $consuming_account, email: $email, external_ref: $external_ref, managing_account: $managing_account, name: $name, telephone: $telephone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available devices
#
# GET /devices
# Returns: table<capabilities: list<record>, facility: string, id: string, name: string, pop: string>
# operationId: devices_list
export def "devices-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
  --facility: string # Filter by facility
  --pop: string # Filter by pop
  --metro-area-network: string # Filter by metro_area_network
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices"
    query: [{name: id, var: id, style: csv}, {name: name, var: name}, {name: capability_media_type, var: capability_media_type}, {name: capability_speed, var: capability_speed}, {name: capability_speed__lt, var: capability_speed_lt}, {name: capability_speed__lte, var: capability_speed_lte}, {name: capability_speed__gt, var: capability_speed_gt}, {name: capability_speed__gte, var: capability_speed_gte}, {name: facility, var: facility}, {name: pop, var: pop}, {name: metro_area_network, var: metro_area_network}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, capability_media_type: $capability_media_type, capability_speed: $capability_speed, capability_speed_lt: $capability_speed_lt, capability_speed_lte: $capability_speed_lte, capability_speed_gt: $capability_speed_gt, capability_speed_gte: $capability_speed_gte, facility: $facility, pop: $pop, metro_area_network: $metro_area_network
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific device identified by id
#
# GET /devices/{id}
# Returns: record<capabilities: table<availability: int, max_lag: int, media_type: string, speed: int>, facility: string, id: string, name: string, pop: string>
# operationId: devices_read
export def "devices-read" [
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
    path: "/devices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a (filtered) list of `facilities`.
#
# GET /facilities
# Returns: table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string>
# operationId: facilities_list
export def "facilities-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
  --organisation-name: string # Filter by organisation_name
  --metro-area: string # Filter by metro_area
  --metro-area-network: string # Filter by metro_area_network
  --address-country: string # Filter by address_country
  --address-locality: string # Filter by address_locality
  --postal-code: string # Filter by postal_code
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/facilities"
    query: [{name: id, var: id, style: csv}, {name: capability_media_type, var: capability_media_type}, {name: capability_speed, var: capability_speed}, {name: capability_speed__lt, var: capability_speed_lt}, {name: capability_speed__lte, var: capability_speed_lte}, {name: capability_speed__gt, var: capability_speed_gt}, {name: capability_speed__gte, var: capability_speed_gte}, {name: organisation_name, var: organisation_name}, {name: metro_area, var: metro_area}, {name: metro_area_network, var: metro_area_network}, {name: address_country, var: address_country}, {name: address_locality, var: address_locality}, {name: postal_code, var: postal_code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, capability_media_type: $capability_media_type, capability_speed: $capability_speed, capability_speed_lt: $capability_speed_lt, capability_speed_lte: $capability_speed_lte, capability_speed_gt: $capability_speed_gt, capability_speed_gte: $capability_speed_gte, organisation_name: $organisation_name, metro_area: $metro_area, metro_area_network: $metro_area_network, address_country: $address_country, address_locality: $address_locality, postal_code: $postal_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a facility by id
#
# GET /facilities/{id}
# Returns: table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string>
# operationId: facilities_read
export def "facilities-read" [
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
    path: "/facilities/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the IX-API service health status.
#
# GET /health
# Returns: record<checks: record, description: string, links: record, notes: list<string>, output: string, releaseId: string, serviceId: string, status: string, version: string>
# operationId: api_health_read
export def "api-health-read" [
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
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the API implementation details.
#
# GET /implementation
# Returns: record<schema_version: string, service_version: string, supported_network_feature_config_types: list<string>, supported_network_feature_types: list<string>, supported_network_service_config_types: list<string>, supported_network_service_types: list<string>, supported_operations: list<string>>
# operationId: api_implementation_read
export def "api-implementation-read" [
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
    path: "/implementation"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all ip addresses (and prefixes).
#
# GET /ips
# Returns: table<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>
# operationId: ips_list
export def "ips-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --network-service: string # Filter by network_service
  --network-service-config: string # Filter by network_service_config
  --network-feature: string # Filter by network_feature
  --network-feature-config: string # Filter by network_feature_config
  --version: int # Filter by version
  --fqdn: string # Filter by fqdn
  --prefix-length: int # Filter by prefix_length
  --valid-not-before: string # Filter by valid_not_before
  --valid-not-after: string # Filter by valid_not_after
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ips"
    query: [{name: id, var: id, style: csv}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: network_service, var: network_service}, {name: network_service_config, var: network_service_config}, {name: network_feature, var: network_feature}, {name: network_feature_config, var: network_feature_config}, {name: version, var: version}, {name: fqdn, var: fqdn}, {name: prefix_length, var: prefix_length}, {name: valid_not_before, var: valid_not_before}, {name: valid_not_after, var: valid_not_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref, network_service: $network_service, network_service_config: $network_service_config, network_feature: $network_feature, network_feature_config: $network_feature_config, version: $version, fqdn: $fqdn, prefix_length: $prefix_length, valid_not_before: $valid_not_before, valid_not_after: $valid_not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an ip host address or network prefix.
#
# POST /ips
# Returns: record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>
# operationId: ips_create
export def "ips-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IPv4 or IPv6 Address in the following format: - IPv4: [dot-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation) - IPv6: hexadecimal colon separated notation (e.g. 23.142.52.0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --fqdn: string # nullable
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  prefix_length: int # The CIDR ip prefix length (format: int32, e.g. 23)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
  version: int # The version of the internet protocol. (e.g. 4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: fqdn, var: fqdn}, {name: managing_account, var: managing_account}, {name: prefix_length, var: prefix_length}, {name: valid_not_after, var: valid_not_after}, {name: valid_not_before, var: valid_not_before}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    address: $address, consuming_account: $consuming_account, external_ref: $external_ref, fqdn: $fqdn, managing_account: $managing_account, prefix_length: $prefix_length, valid_not_after: $valid_not_after, valid_not_before: $valid_not_before, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single ip addresses by it's id.
#
# GET /ips/{id}
# Returns: record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>
# operationId: ips_read
export def "ips-read" [
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
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update parts of an ip address. As with the `PUT` opertaion, IP addresses, where you don't have update rights, will yield a `resource access denied` error when attempting an update. If the ip address was allocated for you, you might not be able to change anything but the `fqdn`.
#
# PATCH /ips/{id}
# Returns: record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>
# operationId: ips_partial_update
export def "ips-partial-update" [
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
  --address: string # IPv4 or IPv6 Address in the following format: - IPv4: [dot-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation) - IPv6: hexadecimal colon separated notation (e.g. 23.142.52.0)
  --consuming-account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --fqdn: string # nullable
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --prefix-length: int # The CIDR ip prefix length (format: int32, e.g. 23)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
  --version: int # The version of the internet protocol. (e.g. 4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: address, var: address}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: fqdn, var: fqdn}, {name: managing_account, var: managing_account}, {name: prefix_length, var: prefix_length}, {name: valid_not_after, var: valid_not_after}, {name: valid_not_before, var: valid_not_before}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, address: $address, consuming_account: $consuming_account, external_ref: $external_ref, fqdn: $fqdn, managing_account: $managing_account, prefix_length: $prefix_length, valid_not_after: $valid_not_after, valid_not_before: $valid_not_before, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an ip address object. You can only update IP addresses within your current scope. Not all addresses you can read you can update. If the ip address was allocated for you, you might not be able to change anything but the `fqdn`.
#
# PUT /ips/{id}
# Returns: record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int>
# operationId: ips_update
export def "ips-update" [
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
  address: string # IPv4 or IPv6 Address in the following format: - IPv4: [dot-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation) - IPv6: hexadecimal colon separated notation (e.g. 23.142.52.0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --fqdn: string # nullable
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  prefix_length: int # The CIDR ip prefix length (format: int32, e.g. 23)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
  version: int # The version of the internet protocol. (e.g. 4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ips/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: fqdn, var: fqdn}, {name: managing_account, var: managing_account}, {name: prefix_length, var: prefix_length}, {name: valid_not_after, var: valid_not_after}, {name: valid_not_before, var: valid_not_before}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, address: $address, consuming_account: $consuming_account, external_ref: $external_ref, fqdn: $fqdn, managing_account: $managing_account, prefix_length: $prefix_length, valid_not_after: $valid_not_after, valid_not_before: $valid_not_before, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all mac addresses managed by the authorized customer.
#
# GET /macs
# Returns: table<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>
# operationId: macs_list
export def "macs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --network-service-config: string # Filter by network_service_config
  --address: string # Filter by address
  --assigned-at: string # Filter by assigned_at
  --valid-not-before: string # Filter by valid_not_before
  --valid-not-after: string # Filter by valid_not_after
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/macs"
    query: [{name: id, var: id, style: csv}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: network_service_config, var: network_service_config}, {name: address, var: address}, {name: assigned_at, var: assigned_at}, {name: valid_not_before, var: valid_not_before}, {name: valid_not_after, var: valid_not_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref, network_service_config: $network_service_config, address: $address, assigned_at: $assigned_at, valid_not_before: $valid_not_before, valid_not_after: $valid_not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a mac address.
#
# POST /macs
# Returns: record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>
# operationId: macs_create
export def "macs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Unicast MAC address, formatted hexadecimal values with colons. (e.g. 42:23:bc:8e:b8:b0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/macs"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: valid_not_after, var: valid_not_after}, {name: valid_not_before, var: valid_not_before}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    address: $address, consuming_account: $consuming_account, external_ref: $external_ref, managing_account: $managing_account, valid_not_after: $valid_not_after, valid_not_before: $valid_not_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a mac address.
#
# DELETE /macs/{id}
# Returns: record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>
# operationId: macs_destroy
export def "macs-destroy" [
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
    path: "/macs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single mac address by it's id.
#
# GET /macs/{id}
# Returns: record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string>
# operationId: macs_read
export def "macs-read" [
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
    path: "/macs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of joining rules
#
# GET /member-joining-rules
# Returns: list<any>
# operationId: member_joining_rules_list
export def "member-joining-rules-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --network-service: string # Filter by network_service
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/member-joining-rules"
    query: [{name: id, var: id, style: csv}, {name: network_service, var: network_service}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, network_service: $network_service
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a member joining rule
#
# POST /member-joining-rules
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_create
export def "member-joining-rules-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capacity-max: int # An optional rate limit which has precedence over the capacity set in the network service config. (nullable)
  --capacity-min: int # Require an optional minimum capacity to join the network service. (nullable)
  consuming_account: string # The `id` of the account to which access to the network service should be granted or denied. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  network_service: string
  type: string@type-completer # e.g. allow
]: any -> any {
  $in | http-request {
    method: post
    path: "/member-joining-rules"
    body: {content_type: "application/json", kind: json, fields: [{name: capacity_max, var: capacity_max}, {name: capacity_min, var: capacity_min}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: network_service, var: network_service}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    capacity_max: $capacity_max, capacity_min: $capacity_min, consuming_account: $consuming_account, external_ref: $external_ref, managing_account: $managing_account, network_service: $network_service, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a joining rule
#
# DELETE /member-joining-rules/{id}
# Discriminator (response): type = allow, deny
# operationId: member_joining_rules_destroy
export def "member-joining-rules-destroy" [
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
    path: "/member-joining-rules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single rule
#
# GET /member-joining-rules/{id}
# Discriminator (response): type = allow, deny
# operationId: member_joining_rules_read
export def "member-joining-rules-read" [
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
    path: "/member-joining-rules/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update a joining rule
#
# PATCH /member-joining-rules/{id}
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_partial_update
export def "member-joining-rules-partial-update" [
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
  --capacity-max: int # An optional rate limit which has precedence over the capacity set in the network service config. (nullable)
  --capacity-min: int # Require an optional minimum capacity to join the network service. (nullable)
  --consuming-account: string # The `id` of the account to which access to the network service should be granted or denied. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  type: string@type-completer # e.g. allow
]: any -> any {
  $in | http-request {
    method: patch
    path: "/member-joining-rules/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: capacity_max, var: capacity_max}, {name: capacity_min, var: capacity_min}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, capacity_max: $capacity_max, capacity_min: $capacity_min, consuming_account: $consuming_account, external_ref: $external_ref, managing_account: $managing_account, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a joining rule
#
# PUT /member-joining-rules/{id}
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_update
export def "member-joining-rules-update" [
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
  --capacity-max: int # An optional rate limit which has precedence over the capacity set in the network service config. (nullable)
  --capacity-min: int # Require an optional minimum capacity to join the network service. (nullable)
  consuming_account: string # The `id` of the account to which access to the network service should be granted or denied. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  type: string@type-completer # e.g. allow
]: any -> any {
  $in | http-request {
    method: put
    path: "/member-joining-rules/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: capacity_max, var: capacity_max}, {name: capacity_min, var: capacity_min}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: managing_account, var: managing_account}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, capacity_max: $capacity_max, capacity_min: $capacity_min, consuming_account: $consuming_account, external_ref: $external_ref, managing_account: $managing_account, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all MetroAreaNetworks
#
# GET /metro-area-networks
# Returns: table<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string>
# operationId: metro_area_networks_list
export def "metro-area-networks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --metro-area: string # Filter by metro_area
  --service-provider: string # Filter by service_provider
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metro-area-networks"
    query: [{name: id, var: id, style: csv}, {name: name, var: name}, {name: metro_area, var: metro_area}, {name: service_provider, var: service_provider}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, metro_area: $metro_area, service_provider: $service_provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a MetroAreaNetwork
#
# GET /metro-area-networks/{id}
# Returns: record<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string>
# operationId: metro_area_networks_read
export def "metro-area-networks-read" [
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
    path: "/metro-area-networks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all MetroAreas
#
# GET /metro-areas
# Returns: table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string>
# operationId: metro_areas_list
export def "metro-areas-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metro-areas"
    query: [{name: id, var: id, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single MetroArea
#
# GET /metro-areas/{id}
# Returns: table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string>
# operationId: metro_areas_read
export def "metro-areas-read" [
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
    path: "/metro-areas/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all network feature configs.
#
# GET /network-feature-configs
# Returns: list<any>
# operationId: network_feature_configs_list
export def "network-feature-configs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer-1 # Filter by type
  --service-config: string # Filter by service_config
  --network-feature: string # Filter by network_feature
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/network-feature-configs"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: type, var: type}, {name: service_config, var: service_config}, {name: network_feature, var: network_feature}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref, type: $type, service_config: $service_config, network_feature: $network_feature
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a configuration for a `NetworkFeature` defined in the `NetworkFeature`s collection.
#
# POST /network-feature-configs
# Discriminator (request): type = route_server
# operationId: network_feature_configs_create
export def "network-feature-configs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --as-set-v4: string # AS-SET of the customer for IPv4 prefix filtering. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet` address family. If multiple address families are supported, it is optional if the `as_set_v6` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  --as-set-v6: string # AS-SET of the customer for IPv6. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet6` address family. If multiple address families are supported, it is optional if the `as_set_v4` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  asn: int # The ASN of the peer. (format: int64, e.g. 4200000023)
  bgp_session_type: string@bgp-session-type-completer # The session type describes which of the both parties will open the connection. If set to passive, the customer router needs to open the connection. If its set to active, the route server will open the connection. The standard behavior on most exchanges is passive. (e.g. passive)
  billing_account: string # An account requires billing_information to be used as a `billing_account`.
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --insert-ixp-asn: oneof<nothing, bool> # Insert the ASN of the exchange into the AS path. This function is only used in special cases. In 99% of all cases, it should be false. (default: true)
  ip: string # The BGP session will be established from this IP address. Only IPs assigned to the corresponding network service config can be used.
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --max-prefix-v4: int # Announcing more than `max_prefix` IPv4 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  --max-prefix-v6: int # Announcing more than `max_prefix` IPv6 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  network_feature: string
  network_service_config: string
  --password: string # The cleartext BGP session password (default: "", e.g. bgp-session-test-23)
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  role_assignments: list<string> # A set of `RoleAssignment`s. See the documentation on the specific `required_contact_roles`, `nfc_required_contact_roles` or `nsc_required_contact_roles` on what `RoleAssignment`s to provide. (e.g. [c-impl:123, c-noc:331])
  session_mode: string@session-mode-completer # Set the session mode with the routeserver. (e.g. public)
  type: string@type-completer-1 # e.g. route_server
]: any -> any {
  $in | http-request {
    method: post
    path: "/network-feature-configs"
    body: {content_type: "application/json", kind: json, fields: [{name: as_set_v4, var: as_set_v4}, {name: as_set_v6, var: as_set_v6}, {name: asn, var: asn}, {name: bgp_session_type, var: bgp_session_type}, {name: billing_account, var: billing_account}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: insert_ixp_asn, var: insert_ixp_asn}, {name: ip, var: ip}, {name: managing_account, var: managing_account}, {name: max_prefix_v4, var: max_prefix_v4}, {name: max_prefix_v6, var: max_prefix_v6}, {name: network_feature, var: network_feature}, {name: network_service_config, var: network_service_config}, {name: password, var: password}, {name: purchase_order, var: purchase_order}, {name: role_assignments, var: role_assignments}, {name: session_mode, var: session_mode}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    as_set_v4: $as_set_v4, as_set_v6: $as_set_v6, asn: $asn, bgp_session_type: $bgp_session_type, billing_account: $billing_account, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, insert_ixp_asn: $insert_ixp_asn, ip: $ip, managing_account: $managing_account, max_prefix_v4: $max_prefix_v4, max_prefix_v6: $max_prefix_v6, network_feature: $network_feature, network_service_config: $network_service_config, password: $password, purchase_order: $purchase_order, role_assignments: $role_assignments, session_mode: $session_mode, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a network feature config. The network feature config will be marked as `decommission_requested`. Decommissioning a network feature config will not cascade to related services or service configs.
#
# DELETE /network-feature-configs/{id}
# Discriminator (response): type = route_server
# operationId: network_feature_configs_destroy
export def "network-feature-configs-destroy" [
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
    path: "/network-feature-configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single network feature config.
#
# GET /network-feature-configs/{id}
# Discriminator (response): type = route_server
# operationId: network_feature_configs_read
export def "network-feature-configs-read" [
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
    path: "/network-feature-configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update parts of a network feature configuration
#
# PATCH /network-feature-configs/{id}
# Discriminator (request): type = route_server
# operationId: network_feature_configs_partial_update
export def "network-feature-configs-partial-update" [
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
  --as-set-v4: string # AS-SET of the customer for IPv4 prefix filtering. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet` address family. If multiple address families are supported, it is optional if the `as_set_v6` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  --as-set-v6: string # AS-SET of the customer for IPv6. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet6` address family. If multiple address families are supported, it is optional if the `as_set_v4` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  --asn: int # The ASN of the peer. (format: int64, e.g. 4200000023)
  --bgp-session-type: string@bgp-session-type-completer # The session type describes which of the both parties will open the connection. If set to passive, the customer router needs to open the connection. If its set to active, the route server will open the connection. The standard behavior on most exchanges is passive. (e.g. passive)
  --consuming-account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --insert-ixp-asn: oneof<nothing, bool> # Insert the ASN of the exchange into the AS path. This function is only used in special cases. In 99% of all cases, it should be false. (default: true)
  --ip: string # The BGP session will be established from this IP address. Only IPs assigned to the corresponding network service config can be used.
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --max-prefix-v4: int # Announcing more than `max_prefix` IPv4 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  --max-prefix-v6: int # Announcing more than `max_prefix` IPv6 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  --password: string # The cleartext BGP session password (default: "", e.g. bgp-session-test-23)
  --session-mode: string@session-mode-completer # Set the session mode with the routeserver. (e.g. public)
  type: string@type-completer-1 # e.g. route_server
]: any -> any {
  $in | http-request {
    method: patch
    path: "/network-feature-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: as_set_v4, var: as_set_v4}, {name: as_set_v6, var: as_set_v6}, {name: asn, var: asn}, {name: bgp_session_type, var: bgp_session_type}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: insert_ixp_asn, var: insert_ixp_asn}, {name: ip, var: ip}, {name: managing_account, var: managing_account}, {name: max_prefix_v4, var: max_prefix_v4}, {name: max_prefix_v6, var: max_prefix_v6}, {name: password, var: password}, {name: session_mode, var: session_mode}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, as_set_v4: $as_set_v4, as_set_v6: $as_set_v6, asn: $asn, bgp_session_type: $bgp_session_type, consuming_account: $consuming_account, external_ref: $external_ref, insert_ixp_asn: $insert_ixp_asn, ip: $ip, managing_account: $managing_account, max_prefix_v4: $max_prefix_v4, max_prefix_v6: $max_prefix_v6, password: $password, session_mode: $session_mode, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a network feature configuration
#
# PUT /network-feature-configs/{id}
# Discriminator (request): type = route_server
# operationId: network_feature_configs_update
export def "network-feature-configs-update" [
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
  --as-set-v4: string # AS-SET of the customer for IPv4 prefix filtering. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet` address family. If multiple address families are supported, it is optional if the `as_set_v6` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  --as-set-v6: string # AS-SET of the customer for IPv6. This is used to generate filters on the router servers. Only valid referenced prefixes within the AS-SET are allowed inbound to the route server. All other routes are filtered. This field is *required* if the route server network feature only supports the `af_inet6` address family. If multiple address families are supported, it is optional if the `as_set_v4` is provided. Important: The format has to be: "AS-SET@IRR". IRR is the database where the AS-SET is registred. Typically used IRR's are RADB, RIPE, NTTCOM, APNIC, ALTDB, LEVEL3, ARIN, AFRINIC, LACNIC (nullable, e.g. MOON-AS@RIPE)
  asn: int # The ASN of the peer. (format: int64, e.g. 4200000023)
  bgp_session_type: string@bgp-session-type-completer # The session type describes which of the both parties will open the connection. If set to passive, the customer router needs to open the connection. If its set to active, the route server will open the connection. The standard behavior on most exchanges is passive. (e.g. passive)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --insert-ixp-asn: oneof<nothing, bool> # Insert the ASN of the exchange into the AS path. This function is only used in special cases. In 99% of all cases, it should be false. (default: true)
  ip: string # The BGP session will be established from this IP address. Only IPs assigned to the corresponding network service config can be used.
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --max-prefix-v4: int # Announcing more than `max_prefix` IPv4 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  --max-prefix-v6: int # Announcing more than `max_prefix` IPv6 prefixes the bgp session will be droped. (nullable, e.g. 5000)
  --password: string # The cleartext BGP session password (default: "", e.g. bgp-session-test-23)
  session_mode: string@session-mode-completer # Set the session mode with the routeserver. (e.g. public)
  type: string@type-completer-1 # e.g. route_server
]: any -> any {
  $in | http-request {
    method: put
    path: "/network-feature-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: as_set_v4, var: as_set_v4}, {name: as_set_v6, var: as_set_v6}, {name: asn, var: asn}, {name: bgp_session_type, var: bgp_session_type}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: insert_ixp_asn, var: insert_ixp_asn}, {name: ip, var: ip}, {name: managing_account, var: managing_account}, {name: max_prefix_v4, var: max_prefix_v4}, {name: max_prefix_v6, var: max_prefix_v6}, {name: password, var: password}, {name: session_mode, var: session_mode}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, as_set_v4: $as_set_v4, as_set_v6: $as_set_v6, asn: $asn, bgp_session_type: $bgp_session_type, consuming_account: $consuming_account, external_ref: $external_ref, insert_ixp_asn: $insert_ixp_asn, ip: $ip, managing_account: $managing_account, max_prefix_v4: $max_prefix_v4, max_prefix_v6: $max_prefix_v6, password: $password, session_mode: $session_mode, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available network features.
#
# GET /network-features
# Returns: list<any>
# operationId: network_features_list
export def "network-features-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --type: string@type-completer-1 # Filter by type
  --required: string # Filter by required
  --network-service: string # Filter by network_service
  --name: string # Filter by name
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/network-features"
    query: [{name: id, var: id, style: csv}, {name: type, var: type}, {name: required, var: required}, {name: network_service, var: network_service}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, required: $required, network_service: $network_service, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single network feature by it's id.
#
# GET /network-features/{id}
# Discriminator (response): type = route_server
# operationId: network_features_read
export def "network-features-read" [
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
    path: "/network-features/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all `network-service-config`s.
#
# GET /network-service-configs
# Returns: list<any>
# operationId: network_service_configs_list
export def "network-service-configs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer-2 # Filter by type
  --inner-vlan: int # Filter by inner_vlan
  --outer-vlan: int # Filter by outer_vlan
  --capacity: int # Filter by capacity
  --network-service: string # Filter by network_service
  --connection: string # Filter by connection
  --product-offering: string # Filter by product_offering
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/network-service-configs"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: type, var: type}, {name: inner_vlan, var: inner_vlan}, {name: outer_vlan, var: outer_vlan}, {name: capacity, var: capacity}, {name: network_service, var: network_service}, {name: connection, var: connection}, {name: product_offering, var: product_offering}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref, type: $type, inner_vlan: $inner_vlan, outer_vlan: $outer_vlan, capacity: $capacity, network_service: $network_service, connection: $connection, product_offering: $product_offering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a `network-service-config`.
#
# POST /network-service-configs
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_create
export def "network-service-configs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asns: list<int>
  billing_account: string # An account requires billing_information to be used as a `billing_account`.
  --capacity: int # The capacity of the service in Mbps. If set to Null, the maximum capacity will be used, i.e. the virtual circuit is not rate-limited. An exchange may choose to constrain the available capacity range of a `ProductOffering`. That means, the service can consume up to the total bandwidth of the `Connection`. Typically the service is charged based on the capacity. (nullable)
  connection: string # The id of the connection to use for this `NetworkServiceConfig`.
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --listed: oneof<nothing, bool> # The customer wants to be featured on the member list
  --macs: list<string> # A list of mac-address IDs.
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  network_service: string # The id of the `NetworkService` to configure.
  --product-offering: string # The product offering must match the type `exchange_lan` and must refer to the related network service through the `exchange_lan_network_service` property.
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  role_assignments: list<string> # A set of `RoleAssignment`s. See the documentation on the specific `required_contact_roles`, `nfc_required_contact_roles` or `nsc_required_contact_roles` on what `RoleAssignment`s to provide. (e.g. [c-impl:123, c-noc:331])
  type: string@type-completer-2 # e.g. exchange_lan
  vlan_config: any # The vlan configuration defines how the service is made available on the connection.
  --role: string@role-completer # A `leaf` can only reach roots and is isolated from other leafs. A `root` can reach any other point in the virtual circuit including other roots. (default: leaf)
  --cloud-vlan: int # If the `provider_vlans` property of the `ProductOffering` is `multi`, a numeric value refers to a specific vlan on the service provider side. Otherwise, if set to `null`, it refers to all unmatched vlan ids on the service provider side. (All vlan ids from the service provider side are presented as tags within any vlans specified in `vlan_config`.) If the `provider_vlans` property of the `ProductOffering` is `single`, the `cloud_vlan` MUST be `null` or MUST NOT be provided. (nullable, format: int32)
  --handover: int # The handover enumerates the connection and is required for checking diversity constraints. It must be within `1 <= x <= network_service.diversity`. (e.g. 1)
]: any -> any {
  $in | http-request {
    method: post
    path: "/network-service-configs"
    body: {content_type: "application/json", kind: json, fields: [{name: asns, var: asns}, {name: billing_account, var: billing_account}, {name: capacity, var: capacity}, {name: connection, var: connection}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: listed, var: listed}, {name: macs, var: macs}, {name: managing_account, var: managing_account}, {name: network_service, var: network_service}, {name: product_offering, var: product_offering}, {name: purchase_order, var: purchase_order}, {name: role_assignments, var: role_assignments}, {name: type, var: type}, {name: vlan_config, var: vlan_config}, {name: role, var: role}, {name: cloud_vlan, var: cloud_vlan}, {name: handover, var: handover}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    asns: $asns, billing_account: $billing_account, capacity: $capacity, connection: $connection, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, listed: $listed, macs: $macs, managing_account: $managing_account, network_service: $network_service, product_offering: $product_offering, purchase_order: $purchase_order, role_assignments: $role_assignments, type: $type, vlan_config: $vlan_config, role: $role, cloud_vlan: $cloud_vlan, handover: $handover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request decommissioning the network service configuration. The network service config will assume the state `decommission_requested`. This will cascade to related resources like `network-feature-configs`.
#
# DELETE /network-service-configs/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_destroy
export def "network-service-configs-destroy" [
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
  --decommission-at: string # An optional date for scheduling the cancellation and service decommissioning. (format: date)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/network-service-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: decommission_at, var: decommission_at}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, decommission_at: $decommission_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a `network-service-config`
#
# GET /network-service-configs/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_read
export def "network-service-configs-read" [
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
    path: "/network-service-configs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update parts of an exisiting `network-service-config`.
#
# PATCH /network-service-configs/{id}
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_partial_update
export def "network-service-configs-partial-update" [
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
  --asns: list<int>
  --billing-account: string # An account requires billing_information to be used as a `billing_account`.
  --capacity: int # The capacity of the service in Mbps. If set to Null, the maximum capacity will be used, i.e. the virtual circuit is not rate-limited. An exchange may choose to constrain the available capacity range of a `ProductOffering`. That means, the service can consume up to the total bandwidth of the `Connection`. Typically the service is charged based on the capacity. (nullable)
  --connection: string # The id of the connection to use for this `NetworkServiceConfig`.
  --consuming-account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --listed: oneof<nothing, bool> # The customer wants to be featured on the member list
  --macs: list<string> # A list of mac-address IDs.
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  --role-assignments: list<string> # A set of `RoleAssignment`s. See the documentation on the specific `required_contact_roles`, `nfc_required_contact_roles` or `nsc_required_contact_roles` on what `RoleAssignment`s to provide. (e.g. [c-impl:123, c-noc:331])
  type: string@type-completer-2 # e.g. exchange_lan
  --vlan-config: any # The vlan configuration defines how the service is made available on the connection.
  --network-service: string # The id of the `NetworkService` to configure.
  --role: string@role-completer # A `leaf` can only reach roots and is isolated from other leafs. A `root` can reach any other point in the virtual circuit including other roots. (default: leaf)
  --cloud-vlan: int # If the `provider_vlans` property of the `ProductOffering` is `multi`, a numeric value refers to a specific vlan on the service provider side. Otherwise, if set to `null`, it refers to all unmatched vlan ids on the service provider side. (All vlan ids from the service provider side are presented as tags within any vlans specified in `vlan_config`.) If the `provider_vlans` property of the `ProductOffering` is `single`, the `cloud_vlan` MUST be `null` or MUST NOT be provided. (nullable, format: int32)
  --handover: int # The handover enumerates the connection and is required for checking diversity constraints. It must be within `1 <= x <= network_service.diversity`. (e.g. 1)
]: any -> any {
  $in | http-request {
    method: patch
    path: "/network-service-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: asns, var: asns}, {name: billing_account, var: billing_account}, {name: capacity, var: capacity}, {name: connection, var: connection}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: listed, var: listed}, {name: macs, var: macs}, {name: managing_account, var: managing_account}, {name: purchase_order, var: purchase_order}, {name: role_assignments, var: role_assignments}, {name: type, var: type}, {name: vlan_config, var: vlan_config}, {name: network_service, var: network_service}, {name: role, var: role}, {name: cloud_vlan, var: cloud_vlan}, {name: handover, var: handover}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, asns: $asns, billing_account: $billing_account, capacity: $capacity, connection: $connection, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, listed: $listed, macs: $macs, managing_account: $managing_account, purchase_order: $purchase_order, role_assignments: $role_assignments, type: $type, vlan_config: $vlan_config, network_service: $network_service, role: $role, cloud_vlan: $cloud_vlan, handover: $handover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an exisiting `network-service-config`
#
# PUT /network-service-configs/{id}
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_update
export def "network-service-configs-update" [
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
  --asns: list<int>
  billing_account: string # An account requires billing_information to be used as a `billing_account`.
  --capacity: int # The capacity of the service in Mbps. If set to Null, the maximum capacity will be used, i.e. the virtual circuit is not rate-limited. An exchange may choose to constrain the available capacity range of a `ProductOffering`. That means, the service can consume up to the total bandwidth of the `Connection`. Typically the service is charged based on the capacity. (nullable)
  connection: string # The id of the connection to use for this `NetworkServiceConfig`.
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --listed: oneof<nothing, bool> # The customer wants to be featured on the member list
  --macs: list<string> # A list of mac-address IDs.
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  role_assignments: list<string> # A set of `RoleAssignment`s. See the documentation on the specific `required_contact_roles`, `nfc_required_contact_roles` or `nsc_required_contact_roles` on what `RoleAssignment`s to provide. (e.g. [c-impl:123, c-noc:331])
  type: string@type-completer-2 # e.g. exchange_lan
  vlan_config: any # The vlan configuration defines how the service is made available on the connection.
  --network-service: string # The id of the `NetworkService` to configure.
  --role: string@role-completer # A `leaf` can only reach roots and is isolated from other leafs. A `root` can reach any other point in the virtual circuit including other roots. (default: leaf)
  --cloud-vlan: int # If the `provider_vlans` property of the `ProductOffering` is `multi`, a numeric value refers to a specific vlan on the service provider side. Otherwise, if set to `null`, it refers to all unmatched vlan ids on the service provider side. (All vlan ids from the service provider side are presented as tags within any vlans specified in `vlan_config`.) If the `provider_vlans` property of the `ProductOffering` is `single`, the `cloud_vlan` MUST be `null` or MUST NOT be provided. (nullable, format: int32)
  --handover: int # The handover enumerates the connection and is required for checking diversity constraints. It must be within `1 <= x <= network_service.diversity`. (e.g. 1)
]: any -> any {
  $in | http-request {
    method: put
    path: "/network-service-configs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: asns, var: asns}, {name: billing_account, var: billing_account}, {name: capacity, var: capacity}, {name: connection, var: connection}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: listed, var: listed}, {name: macs, var: macs}, {name: managing_account, var: managing_account}, {name: purchase_order, var: purchase_order}, {name: role_assignments, var: role_assignments}, {name: type, var: type}, {name: vlan_config, var: vlan_config}, {name: network_service, var: network_service}, {name: role, var: role}, {name: cloud_vlan, var: cloud_vlan}, {name: handover, var: handover}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, asns: $asns, billing_account: $billing_account, capacity: $capacity, connection: $connection, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, listed: $listed, macs: $macs, managing_account: $managing_account, purchase_order: $purchase_order, role_assignments: $role_assignments, type: $type, vlan_config: $vlan_config, network_service: $network_service, role: $role, cloud_vlan: $cloud_vlan, handover: $handover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The cancellation-policy can be queried to answer the questions: If I cancel my subscription, *when will it be technically decommissioned*? If I cancel my subscription, *until what date will I be charged*? When the query parameter `decommision_at` is not provided it will provide the first possible cancellation date and charge period if cancelled at above date. The granularity of the date field is a day, the start and end of which are to be interpreted by the IXP (some may use UTC, some may use their local time zone).
#
# GET /network-service-configs/{id}/cancellation-policy
# Returns: record<charged_until: string, decommission_at: string>
# operationId: network_service_config_cancellation_policy_read
export def "network-service-config-cancellation-policy-read" [
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
  --decommission-at: string # By providing a date in the format `YYYY-MM-DD` you can query the policy what would happen if you request a decommissioning on this date.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/network-service-configs/{id}/cancellation-policy"
    path_params: [{name: id, var: id}]
    query: [{name: decommission_at, var: decommission_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, decommission_at: $decommission_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List available `NetworkService`s.
#
# GET /network-services
# Returns: list<any>
# operationId: network_services_list
export def "network-services-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer-2 # Filter by type
  --pop: string # Filter by pop
  --product-offering: string # Filter by product_offering
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/network-services"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: managing_account, var: managing_account}, {name: consuming_account, var: consuming_account}, {name: external_ref, var: external_ref}, {name: type, var: type}, {name: pop, var: pop}, {name: product_offering, var: product_offering}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, managing_account: $managing_account, consuming_account: $consuming_account, external_ref: $external_ref, type: $type, pop: $pop, product_offering: $product_offering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new network service
#
# POST /network-services
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_create
export def "network-services-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_account: string # An account requires billing_information to be used as a `billing_account`.
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --joining-member-account: string # The account of the B-side member joining the virtual circuit. (e.g. 231829)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  product_offering: string
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  type: string@type-completer-3 # e.g. p2p_vc
  --name: string # Name of the point to multi-point virtual circuit.
  --public: oneof<nothing, bool> # A public p2mp network service can be joined by everyone on the exchange unless denied by a member-joining-rule. Public network services are visible to other members of the IXP, however only `name`, `type`, `product_offering`, `consuming_account` and `managing_account` are made available. Other required fields are redacted. (default: false)
  --capacity: int # The capacity of the service in Mbps. When null, the maximum capacity will be used. (nullable)
  --cloud-key: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/network-services"
    body: {content_type: "application/json", kind: json, fields: [{name: billing_account, var: billing_account}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: joining_member_account, var: joining_member_account}, {name: managing_account, var: managing_account}, {name: product_offering, var: product_offering}, {name: purchase_order, var: purchase_order}, {name: type, var: type}, {name: name, var: name}, {name: public, var: public}, {name: capacity, var: capacity}, {name: cloud_key, var: cloud_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    billing_account: $billing_account, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, joining_member_account: $joining_member_account, managing_account: $managing_account, product_offering: $product_offering, purchase_order: $purchase_order, type: $type, name: $name, public: $public, capacity: $capacity, cloud_key: $cloud_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request decomissioning of the network service. The network service will enter the state of `decommission_requested`. The request will cascade to related network service and feature configs. An *optional request body* can be provided to request a specific service termination date. If no date is given in the request body, it is assumed to be the earliest possible date. Possible values for `decommission_at` can be queried through the `network_service_cancellation_policy_read` operation. The response will contain the dates on which the changes will be effected.
#
# DELETE /network-services/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_destroy
export def "network-services-destroy" [
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
  --decommission-at: string # An optional date for scheduling the cancellation and service decommissioning. (format: date)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/network-services/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: decommission_at, var: decommission_at}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, decommission_at: $decommission_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific `network-service` by id.
#
# GET /network-services/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_read
export def "network-services-read" [
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
    path: "/network-services/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Partially update a network service
#
# PATCH /network-services/{id}
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_partial_update
export def "network-services-partial-update" [
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
  --billing-account: string # An account requires billing_information to be used as a `billing_account`.
  --consuming-account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --joining-member-account: string # The account of the B-side member joining the virtual circuit. (e.g. 231829)
  --managing-account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --product-offering: string
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  type: string@type-completer-3 # e.g. p2p_vc
  --name: string # Name of the point to multi-point virtual circuit.
  --public: oneof<nothing, bool> # A public p2mp network service can be joined by everyone on the exchange unless denied by a member-joining-rule. Public network services are visible to other members of the IXP, however only `name`, `type`, `product_offering`, `consuming_account` and `managing_account` are made available. Other required fields are redacted. (default: false)
  --capacity: int # The capacity of the service in Mbps. When null, the maximum capacity will be used. (nullable)
  --cloud-key: string
]: any -> any {
  $in | http-request {
    method: patch
    path: "/network-services/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/merge-patch+json", kind: json, fields: [{name: billing_account, var: billing_account}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: joining_member_account, var: joining_member_account}, {name: managing_account, var: managing_account}, {name: product_offering, var: product_offering}, {name: purchase_order, var: purchase_order}, {name: type, var: type}, {name: name, var: name}, {name: public, var: public}, {name: capacity, var: capacity}, {name: cloud_key, var: cloud_key}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, billing_account: $billing_account, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, joining_member_account: $joining_member_account, managing_account: $managing_account, product_offering: $product_offering, purchase_order: $purchase_order, type: $type, name: $name, public: $public, capacity: $capacity, cloud_key: $cloud_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a network service
#
# PUT /network-services/{id}
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_update
export def "network-services-update" [
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
  billing_account: string # An account requires billing_information to be used as a `billing_account`.
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --contract-ref: string # A reference to a contract. If no specific contract is used, a default MAY be chosen by the implementer. (nullable, e.g. contract:31824)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --joining-member-account: string # The account of the B-side member joining the virtual circuit. (e.g. 231829)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  product_offering: string
  --purchase-order: string # Purchase Order ID which will be displayed on the invoice. (default: "", e.g. Project: DC Moon)
  type: string@type-completer-3 # e.g. p2p_vc
  --name: string # Name of the point to multi-point virtual circuit.
  --public: oneof<nothing, bool> # A public p2mp network service can be joined by everyone on the exchange unless denied by a member-joining-rule. Public network services are visible to other members of the IXP, however only `name`, `type`, `product_offering`, `consuming_account` and `managing_account` are made available. Other required fields are redacted. (default: false)
  --capacity: int # The capacity of the service in Mbps. When null, the maximum capacity will be used. (nullable)
  --cloud-key: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/network-services/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_account, var: billing_account}, {name: consuming_account, var: consuming_account}, {name: contract_ref, var: contract_ref}, {name: external_ref, var: external_ref}, {name: joining_member_account, var: joining_member_account}, {name: managing_account, var: managing_account}, {name: product_offering, var: product_offering}, {name: purchase_order, var: purchase_order}, {name: type, var: type}, {name: name, var: name}, {name: public, var: public}, {name: capacity, var: capacity}, {name: cloud_key, var: cloud_key}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, billing_account: $billing_account, consuming_account: $consuming_account, contract_ref: $contract_ref, external_ref: $external_ref, joining_member_account: $joining_member_account, managing_account: $managing_account, product_offering: $product_offering, purchase_order: $purchase_order, type: $type, name: $name, public: $public, capacity: $capacity, cloud_key: $cloud_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The cancellation-policy can be queried to answer the questions: If I cancel my service, *when will it be technically decommissioned*? If I cancel my service, *until what date will I be charged*? When the query parameter `decommision_at` is not provided it will provide the first possible cancellation date and charge period if cancelled at above date. The granularity of the date field is a day, the start and end of which are to be interpreted by the IXP (some may use UTC, some may use their local time zone).
#
# GET /network-services/{id}/cancellation-policy
# Returns: record<charged_until: string, decommission_at: string>
# operationId: network_service_cancellation_policy_read
export def "network-service-cancellation-policy-read" [
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
  --decommission-at: string # By providing a date in the format `YYYY-MM-DD` you can query the policy what would happen if you request a decommissioning on this date.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/network-services/{id}/cancellation-policy"
    path_params: [{name: id, var: id}]
    query: [{name: decommission_at, var: decommission_at}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, decommission_at: $decommission_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retract or reject a change to the network service.
#
# DELETE /network-services/{id}/change-request
# Returns: record<capacity: int, product_offering: string>
# operationId: network_service_change_request_destroy
export def "network-service-change-request-destroy" [
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
    path: "/network-services/{id}/change-request"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the change request.
#
# GET /network-services/{id}/change-request
# Returns: record<capacity: int, product_offering: string>
# operationId: network_service_change_request_read
export def "network-service-change-request-read" [
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
    path: "/network-services/{id}/change-request"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a change to the network service. A participant in a network service of type `p2p_vc` can issue a change request, expressing a desired change in the capacity. The change is accepted when all sides have configured the network service configs with the new bandwidth. These changes can sometimes require a change of the product offering. The product offering may only differ in regards to bandwidth. The network service will change it's state from `production` into `production_change_pending`. Only one change request may be issued at a time.
#
# POST /network-services/{id}/change-request
# Returns: record<capacity: int, product_offering: string>
# operationId: network-service-change-request_create
export def "network-service-change-request-create" [
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
  --capacity: int # The desired capacity of the service in Mbps. Must be within the range of `bandwidth_min` and `bandwidth_max` of the `ProductOffering`. When `null` the maximum capacity wil be used. (nullable)
  product_offering: string # Migrate to a diffrent product offering. Please note, that the offering only may differ in bandwidth.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/network-services/{id}/change-request"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: capacity, var: capacity}, {name: product_offering, var: product_offering}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, capacity: $capacity, product_offering: $product_offering
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all PoPs
#
# GET /pops
# Returns: table<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string>
# operationId: pops_list
export def "pops-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --facility: string # Filter by facility
  --metro-area-network: string # Filter by metro_area_network
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/pops"
    query: [{name: id, var: id, style: csv}, {name: facility, var: facility}, {name: metro_area_network, var: metro_area_network}, {name: capability_media_type, var: capability_media_type}, {name: capability_speed, var: capability_speed}, {name: capability_speed__lt, var: capability_speed_lt}, {name: capability_speed__lte, var: capability_speed_lte}, {name: capability_speed__gt, var: capability_speed_gt}, {name: capability_speed__gte, var: capability_speed_gte}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, facility: $facility, metro_area_network: $metro_area_network, capability_media_type: $capability_media_type, capability_speed: $capability_speed, capability_speed_lt: $capability_speed_lt, capability_speed_lte: $capability_speed_lte, capability_speed_gt: $capability_speed_gt, capability_speed_gte: $capability_speed_gte
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single point of presence
#
# GET /pops/{id}
# Returns: record<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string>
# operationId: pops_read
export def "pops-read" [
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
    path: "/pops/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all ports.
#
# GET /ports
# Returns: table<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>>
# operationId: ports_list
export def "ports-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --media-type: string # Filter by media_type
  --pop: string # Filter by pop
  --name: string # Filter by name
  --external-ref: string # Filter by external_ref
  --device: string # Filter by device
  --speed: string # Filter by speed
  --connection: string # Filter by connection
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ports"
    query: [{name: id, var: id, style: csv}, {name: state, var: state}, {name: state__is_not, var: state_is_not}, {name: media_type, var: media_type}, {name: pop, var: pop}, {name: name, var: name}, {name: external_ref, var: external_ref}, {name: device, var: device}, {name: speed, var: speed}, {name: connection, var: connection}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, state: $state, state_is_not: $state_is_not, media_type: $media_type, pop: $pop, name: $name, external_ref: $external_ref, device: $device, speed: $speed, connection: $connection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a port.
#
# GET /ports/{id}
# Returns: record<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>>
# operationId: ports_read
export def "ports-read" [
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
    path: "/ports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all (filtered) products-offerings available on the platform
#
# GET /product-offerings
# Returns: list<any>
# operationId: product_offerings_list
export def "product-offerings-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --type: string@type-completer-2 # Filter by type
  --name: string # Filter by name
  --handover-metro-area: string # Filter by handover_metro_area
  --handover-metro-area-network: string # Filter by handover_metro_area_network
  --service-metro-area: string # Filter by service_metro_area
  --service-metro-area-network: string # Filter by service_metro_area_network
  --service-provider: string # Filter by service_provider
  --downgrade-allowed: string@downgrade-allowed-completer # Filter by downgrade_allowed
  --upgrade-allowed: string@upgrade-allowed-completer # Filter by upgrade_allowed
  --bandwidth: int # Find product offerings where bandwidth is within the range of `bandwidth_min` and `bandwidth_max`.
  --physical-port-speed: int # Filter by physical_port_speed
  --service-provider-region: string # Filter by service_provider_region
  --service-provider-pop: string # Filter by service_provider_pop
  --delivery-method: string@delivery-method-completer # Filter by delivery_method
  --cloud-key: string # For product offerings of type `cloud_vc`, if the `service_provider_workflow` is `provider_first` the `cloud_key` will be used for filtering the relevant offerings.
  --fields: string # Returned objects only have properties which are present in the list of fields. The required `type` property is *implicitly* included. The results are *deduplicated*. (e.g. handover_metro_area,service_provider)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/product-offerings"
    query: [{name: id, var: id, style: csv}, {name: type, var: type}, {name: name, var: name}, {name: handover_metro_area, var: handover_metro_area}, {name: handover_metro_area_network, var: handover_metro_area_network}, {name: service_metro_area, var: service_metro_area}, {name: service_metro_area_network, var: service_metro_area_network}, {name: service_provider, var: service_provider}, {name: downgrade_allowed, var: downgrade_allowed}, {name: upgrade_allowed, var: upgrade_allowed}, {name: bandwidth, var: bandwidth}, {name: physical_port_speed, var: physical_port_speed}, {name: service_provider_region, var: service_provider_region}, {name: service_provider_pop, var: service_provider_pop}, {name: delivery_method, var: delivery_method}, {name: cloud_key, var: cloud_key}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, name: $name, handover_metro_area: $handover_metro_area, handover_metro_area_network: $handover_metro_area_network, service_metro_area: $service_metro_area, service_metro_area_network: $service_metro_area_network, service_provider: $service_provider, downgrade_allowed: $downgrade_allowed, upgrade_allowed: $upgrade_allowed, bandwidth: $bandwidth, physical_port_speed: $physical_port_speed, service_provider_region: $service_provider_region, service_provider_pop: $service_provider_pop, delivery_method: $delivery_method, cloud_key: $cloud_key, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single products-offering by id.
#
# GET /product-offerings/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: product_offerings_read
export def "product-offerings-read" [
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
    path: "/product-offerings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all role assignments for a contact.
#
# GET /role-assignments
# Returns: table<contact: string, id: string, role: string>
# operationId: role_assignments_list
export def "role-assignments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --contact: string # Filter by contact
  --role: string # Filter by role
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/role-assignments"
    query: [{name: id, var: id, style: csv}, {name: contact, var: contact}, {name: role, var: role}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, contact: $contact, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a `Role` to a `Contact`. The contact needs to have all fields filled, which the role requires. If this is not the case a `400` `UnableToFulfill` will be returned.
#
# POST /role-assignments
# Returns: record<contact: string, id: string, role: string>
# operationId: role_assignments_create
export def "role-assignments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contact: string # The `id` of a contact the role is assigned to. (e.g. contact:42b)
  role: string # The `id` of a role the contact is assigned to. (e.g. role:23)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/role-assignments"
    body: {content_type: "application/json", kind: json, fields: [{name: contact, var: contact}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    contact: $contact, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a role assignment from a contact. If the contact is still in use with a given role required, this will yield an `UnableToFulfill` error.
#
# DELETE /role-assignments/{assignment_id}
# Returns: record<contact: string, id: string, role: string>
# operationId: role_assignments_destroy
export def "role-assignments-destroy" [
  assignment_id: string
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
    path: "/role-assignments/{assignment_id}"
    path_params: [{name: assignment_id, var: assignment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment_id: $assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a role assignment for a contact.
#
# GET /role-assignments/{assignment_id}
# Returns: record<contact: string, id: string, role: string>
# operationId: role_assignments_read
export def "role-assignments-read" [
  assignment_id: string
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
    path: "/role-assignments/{assignment_id}"
    path_params: [{name: assignment_id, var: assignment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    assignment_id: $assignment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all roles available.
#
# GET /roles
# Returns: table<id: string, name: string, required_fields: list<string>>
# operationId: roles_list
export def "roles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --contact: string # Filter by contact
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/roles"
    query: [{name: id, var: id, style: csv}, {name: name, var: name}, {name: contact, var: contact}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name, contact: $contact
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single `Role`.
#
# GET /roles/{id}
# Returns: record<id: string, name: string, required_fields: list<string>>
# operationId: roles_read
export def "roles-read" [
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
  --qp-id: list<string> # Filter by id (e.g. id1,id2,id3) (spec name: id)
  --name: string # Filter by name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/roles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: id, var: qp_id, style: csv}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_id: $qp_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
