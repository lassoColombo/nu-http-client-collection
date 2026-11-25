# Auto-generated client for MotaWord API v1.0
# Source: https://api.apis.guru/v2/specs/motaword.com/1.0/openapi.json
# Auth: --token flag or $env.MOTAWORD_API_TOKEN

const CLIENT = {
  base_url: "https://api.motaword.com"
  token_env_var: "MOTAWORD_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://api.motaword.com" "https://sandbox.motaword.com" "http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["active"] }
def type-filter-completer [] { ["ALL" "DESIGNS" "GLOSSARIES" "IMAGES" "LOCALIZATION" "PDFS" "PRESENTATIONS" "SPREADSHEETS" "STYLE_GUIDES" "SUBTITLES" "TEXT_DOCUMENTS" "WEB"] }
def order-by-completer [] { ["created_at" "id" "name" "updated_at"] }
def order-type-completer [] { ["asc" "desc"] }
def device-completer [] { ["Amazon" "Android" "Chrome" "Edge" "Firefox" "MacOS" "Safari" "Windows" "WindowsPhone" "iOS"] }
def type-completer-1 [] { ["OneSignal"] }
def order-by-completer-1 [] { ["delivery" "id" "price" "status"] }
def action-type-completer [] { ["completed" "proofread" "translated"] }
def payment-method-completer [] { ["app" "client" "corporate" "corporate_card" "credit"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def type-completer-2 [] { ["EMAIL" "INCOMING_EMAIL" "NOTE" "TASK"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def period-completer [] { ["monthly" "weekly"] }
def user-type-completer [] { ["all" "vendor"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-endpoints: "record"
    download-async: "binary"
    get-blog-posts: "record<articles: table<announcement_type: string, author: string, content: string, created_at: string, excerpt: string, id: int, language: string, links: record, slug: string, title: string, topic: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    delete-cache: "record<status: string>"
    get-commissions: "record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-commissions-by-filter: "record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-continuous-projects: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record, target_languages: list, type: string, word_count: int>>"
    create-continuous-project: "record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>"
    delete-continuous-project: "record<status: string>"
    get-continuous-project: "record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>"
    update-continuous-project: "record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>"
    get-analytics-token: "record<jwt: string>"
    collect-analytics: "record<status: string>"
    post-continuous-projects-id-complete: "record<status: string>"
    get-quote-for-documents: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    complete-continuous-document: "record<status: string>"
    get-quote-for-document: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    get-quote-for-languages: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    complete-language: "record<status: string>"
    get-quote-for-language: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    delete-subscription: "record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>"
    get-subscription: "record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>"
    create-subscription: "record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>"
    update-subscription: "record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>"
    update-subscription-payment-method: "record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>"
    get-continuous-project-documents: "record<documents: table<billed_word_count: int, id: string, links: record, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    add-document: "record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>"
    post-continuous-project-document-progress: "record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>"
    post-continuous-project-file-strings: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-continuous-project-document: "record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>"
    update-document: "record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>"
    get-continuous-project-document-progress: "record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>"
    get-continuous-project-file-strings: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-continuous-project-invoices: "record<invoices: table<amount: float, base_amount: float, base_currency: string, billing: record, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record, status: string>>"
    get-continuous-project-progress: "record<costs: record<mt: record<amount: float, currency: string>, post_edit: record<amount: float, currency: string>, saved: record<amount: float, currency: string>, total: record<amount: float, currency: string>>, progress: record<languages: record, links: record<self: record, project: record>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>, word_counts: record<mt: int, post_edit: int, total: int>>"
    get-continuous-project-strings: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    clear-translation-cache: "record<status: string>"
    get-translation-cache: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: record>"
    recache-translations: "record<status: string>"
    get-active-widgets: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, widgets: table<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>>"
    create-active-widget: "record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>"
    delete-active-widget: "record<status: string>"
    get-active-widget: "record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>"
    update-active-widget: "record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>"
    reset-active-widget-token: "record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>"
    get-corporate: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>"
    get-available-corporate-permissions: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>"
    get-corporate-user-groups: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>"
    save-corporate-user-group: "record<corporate_id: int, id: int, name: string, permissions: list<string>>"
    get-corporate-users: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    save-corporate-user: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    get-corporates-list: "table<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>"
    get-corporate-by-id: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>"
    get-available-corporate-permissions-by-id: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>"
    get-corporate-user-groups-by-id: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>"
    save-corporate-user-group-by-id: "record<corporate_id: int, id: int, name: string, permissions: list<string>>"
    get-corporate-users-by-id: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    delete-account: "record<status: string>"
    get-documents: "record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-all-document-subjects: "table<name: string>"
    get-document: "record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>"
    get-document-progress: "record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>"
    regenerate-preview: "record<link: record<href: string>, source: string>"
    get-similar-documents: "record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    use-as-draft: "record<status: string>"
    use-as-regular: "record<status: string>"
    downgrade-proofreader: "record<status: string>"
    get-earnings: "record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float>"
    get-formats: "record"
    freeze-account: "record<status: string>"
    download-global-glossary: "string"
    update-global-glossary: "record<status: string>"
    get-integrations-token: "record<token: string>"
    get-invitation-vendors: "record<vendors: table<matchedNeeds: list, userId: int>>"
    get-languages: "table<code: string, name: string>"
    log-location: "record<status: string>"
    make-proofreader: "record<status: string>"
    get-me: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    update-me: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    get-delivery-prediction: "record<result: table<language: string, late: bool, probability: float>>"
    subscribe-notification: "record<status: string>"
    unsubscribe-notification: "record<status: string>"
    post-message: "record<status: string>"
    get-client-profile-for-pam: "record<account_creation_date: string, client_project_count: float, corporate: string, corporate_id: float, corporate_user_count: float, frequent_file_extension: string, frequent_language_pairs: list<string>, full_name: string, growth: bool, is_complex: bool, last_12_months_spending: float, last_project: float, last_project_time: string, last_proofreaders: table<full_name: string, id: float, language: string, vendor_link: string>, notes: list<string>, nps: record<average: record<completed_surveys_count: float, score: float>, last: record<completion_date: string, score: float>>, user_rank_in_project_count: float, user_rank_in_spending: float>"
    get-project-completion-report-for-pam: "record<admin_user_id: float, completion_report_data: table<invited_vendors: list, target_language: string>, id: float, quote_id: float>"
    update-password: "record<status: string>"
    get-payment-info: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>"
    update-payment-info: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>"
    reset-corporate-payment-code: "record<bin: string, id: int, is_default: bool, payment_code: string>"
    toggle-corporate-auto-charge: "record<status: string>"
    get-credit-card: "record<bin: string, id: int, is_default: bool, payment_code: string>"
    delete-credit-card: "record<status: string>"
    reset-card-payment-code: "record<bin: string, id: int, is_default: bool, payment_code: string>"
    get-permissions: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>"
    upload-profile-picture: "record<status: string>"
    get-projects: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    create-project: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    get-quote-id-from-internal-id: "record<internal-id: int, public-id: int>"
    get-vendor-projects: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    delete-project: "record<status: string>"
    get-project: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    update-project: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    assign-cm: "record<status: string>"
    trigger-callback: "record<data: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list<record>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record, documents: record, glossaries: record, payment: record, quote-pdf: record, styleguides: record>, pairs: list<record>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>, result: string, type: string, url: string>"
    cancel-project: "record<status: string>"
    deliver-project: "record<status: string>"
    download: "binary"
    download-language: "binary"
    send-quote-email: "record<status: string>"
    get-invoice: "record<amount: float, base_amount: float, base_currency: string, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record<self: record<href: string>, corporate: record<href: string>, html: record<href: string>, json: record<href: string>, pdf: record<href: string>, project: record<href: string>, view: record<href: string>>, status: string>"
    download-html-invoice: "string"
    download-pdf-invoice: "binary"
    launch-project: "record<status: string>"
    package: "binary"
    track-package: "record<status: string>"
    package-language: "record<status: string, key: string>"
    get-progress: "record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>"
    recreate-project: "record<status: string>"
    submit-project-reports: "record<status: string>"
    get-sales-activities: "record<activities: table<body: string, created_at: int, created_by: string, type: string>>"
    insert-sales-activity: "record<status: string>"
    delete-project-webhook: "record<status: string>"
    get-project-webhooks: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    post-project-webhook: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    update-project-webhook: "record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>"
    get-activities: "record<activities: table<activity_at: int, id: int, links: record, source_text: string, target_text: string, translator: int, type: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-activity: "record<activity_at: int, id: int, links: record<self: record<href: string>, comments: record<href: string>, project: record<href: string>>, source_text: string, target_text: string, translator: int, type: string>"
    submit-comment: "record<comment: string, commented_at: int, id: int, links: record<self: record<href: string>, activity: record<href: string>, project: record<href: string>>>"
    get-activity-comments: "record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-comments: "record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    get-project-documents: "record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    create-project-document: "record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    delete-project-document: "record<status: string>"
    get-project-document: "record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int>"
    update-project-document: "record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int>"
    download-project-document: "string"
    get-document-translations: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    download-translated-document-for-language: "binary"
    get-document-translations-for-language: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-glossaries: "record<glossaries: table<id: int, links: record, name: string, uploaded_at: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    create-glossary: "record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>"
    delete-glossary: "record<status: string>"
    get-glossary: "record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>"
    update-glossary: "record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>"
    download-glossary: "string"
    get-project-strings: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    package-project-translation-memory: "record<duration: int, key: string, message: record, status: string>"
    package-project-translation-memory-status: "record<duration: int, key: string, message: record, status: string>"
    package-project-translation-memory-for-language: "record<duration: int, key: string, message: record, status: string>"
    package-project-translation-memory-for-language-status: "record<duration: int, key: string, message: record, status: string>"
    get-project-strings-for-language: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-style-guides: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>>"
    create-style-guide: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>>"
    delete-style-guide: "record<status: string>"
    get-style-guide: "record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>"
    update-style-guide: "record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>"
    download-style-guide: "string"
    get-project-translations: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-project-translations-for-language: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>"
    get-project-vendors: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    get-filter-contents: "record<budget_codes: list<string>, categories: list<string>, clients: table<id: int, name: string>, documents: table<id: int, name: string>, projects: table<id: int, name: string>, severities: list<string>, source_languages: list<string>, subjects: list<string>, target_languages: list<string>, vendors: table<id: int, name: string>>"
    get-language-pairs-report: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<language_pair: record, spending: float, word_count: int>>"
    get-projects-report: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    generate-qa-report: "record<report: table<category: string, comment: string, docId: string, editorLink: string, end: int, inSource: bool, isCurrent: bool, module: string, projectId: record, severity: string, source: string, sourceLanguage: record, start: int, state: string, targetLanguage: record, translation: string, uniqueKey: string, vendor: record>>"
    get-users-report: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<currency: string, spending: float, user: record, word_count: int>>"
    send-email-confirmation: "record<status: string>"
    get-responsivity: "record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>>"
    search-everywhere: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, result: record<documents: list<record>, projects: list<record>, strings: list<record>>>"
    reindex-documents: "record<duration: int, key: string, message: record, status: string>"
    check-documents-reindex: "record<duration: int, key: string, message: record, status: string>"
    get-stats: "record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>>"
    get-commission-stats: "record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>>"
    get-commission-stats-by-filter: "record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>>"
    get-popular-pairs: "record<pairs: table<source_language: string, target_language: string>>"
    get-project-stats: "record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>>"
    get-string-stats: "record<language_counts: table<project_string_count: int, source_language: string, tm_string_count: int>, total_project_strings_count: int, total_tm_strings_count: int>"
    get-strings: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, strings: table<content: string, language: string, last_changed: string, translations: list>>"
    post-strings: "record<cost: record<amount: float, currency: string>, strings: table<content: string, language: string, last_changed: string, translations: list>>"
    update-translation-memory-unit: "record<status: string>"
    package-user-translation-memory: "record<duration: int, key: string, message: record, status: string>"
    package-user-translation-memory-for-language-status: "record<duration: int, key: string, message: record, status: string>"
    download-global-style-guide: "string"
    update-global-style-guide: "record<status: string>"
    get-questions: "table<answers: list<record>, question: record<enabled: bool, format: string, id: int, question: string, text: string>, question_answers: list<record>>"
    submit-answers: "record<status: string>"
    get-swagger-yaml: "string"
    get-access-token: "record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string, user_id: int>"
    unfreeze-account: "record<status: string>"
    get-user-groups: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>"
    get-users: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    create-user: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    get-available-vendors: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    get-filtered-vendors: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>"
    send-password-reminder: "record<status: string>"
    get-all-vendor-tags: "table<color: string, name: string>"
    get-user: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    update-user: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>"
    approve-vendor-application: "record<status: string>"
    delete-user-account: "record<status: string>"
    get-user-documents: "record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>"
    downgrade-user-proofreader: "record<status: string>"
    get-user-earnings: "record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float>"
    freeze-user-account: "record<status: string>"
    make-user-proofreader: "record<status: string>"
    subscribe-user-notification: "record<status: string>"
    unsubscribe-user-notification: "record<status: string>"
    get-user-payment-info: "record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>"
    update-user-payment-info: "record<status: string>"
    get-user-permissions: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>"
    upload-user-profile-picture: "record<status: string>"
    get-vendor-projects-by-user-id: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>"
    reject-vendor-application: "record<status: string>"
    send-user-email-confirmation: "record<status: string>"
    get-user-responsivity: "record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>>"
    get-user-stats: "record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>>"
    get-user-popular-pairs: "record<pairs: table<source_language: string, target_language: string>>"
    get-user-project-stats: "record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>>"
    suspend-user: "record<status: string>"
    unfreeze-user-account: "record<status: string>"
    get-this-user-groups: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>"
    update-user-group: "record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-endpoints" "download-async" "get-blog-posts" "delete-cache" "get-commissions" "get-commissions-by-filter" "get-continuous-projects" "create-continuous-project" "delete-continuous-project" "get-continuous-project" "update-continuous-project" "get-analytics-token" "collect-analytics" "post-continuous-projects-id-complete" "get-quote-for-documents" "complete-continuous-document" "get-quote-for-document" "get-quote-for-languages" "complete-language" "get-quote-for-language" "delete-subscription" "get-subscription" "create-subscription" "update-subscription" "update-subscription-payment-method" "translate" "get-continuous-project-documents" "add-document" "post-continuous-project-document-progress" "post-continuous-project-file-strings" "get-continuous-project-document" "update-document" "get-continuous-project-document-progress" "get-continuous-project-file-strings" "get-continuous-project-invoices" "get-continuous-project-progress" "get-continuous-project-strings" "clear-translation-cache" "get-translation-cache" "recache-translations" "get-active-widgets" "create-active-widget" "delete-active-widget" "get-active-widget" "update-active-widget" "reset-active-widget-token" "get-corporate" "get-available-corporate-permissions" "get-corporate-user-groups" "save-corporate-user-group" "get-corporate-users" "save-corporate-user" "get-corporates-list" "get-corporate-by-id" "get-available-corporate-permissions-by-id" "get-corporate-user-groups-by-id" "save-corporate-user-group-by-id" "get-corporate-users-by-id" "delete-account" "get-documents" "get-all-document-subjects" "get-document" "get-document-progress" "regenerate-preview" "get-similar-documents" "use-as-draft" "use-as-regular" "downgrade-proofreader" "get-earnings" "get-formats" "freeze-account" "download-global-glossary" "update-global-glossary" "get-integrations-token" "get-invitation-vendors" "get-languages" "log-location" "make-proofreader" "get-me" "update-me" "get-delivery-prediction" "subscribe-notification" "unsubscribe-notification" "post-message" "get-client-profile-for-pam" "get-project-completion-report-for-pam" "update-password" "get-payment-info" "update-payment-info" "reset-corporate-payment-code" "toggle-corporate-auto-charge" "get-credit-card" "delete-credit-card" "reset-card-payment-code" "get-permissions" "upload-profile-picture" "get-projects" "create-project" "get-quote-id-from-internal-id" "get-vendor-projects" "delete-project" "get-project" "update-project" "assign-cm" "trigger-callback" "cancel-project" "deliver-project" "download" "download-language" "send-quote-email" "get-invoice" "download-html-invoice" "download-pdf-invoice" "launch-project" "package" "track-package" "package-language" "get-progress" "recreate-project" "submit-project-reports" "get-sales-activities" "insert-sales-activity" "delete-project-webhook" "get-project-webhooks" "post-project-webhook" "update-project-webhook" "get-activities" "get-activity" "submit-comment" "get-activity-comments" "get-comments" "get-project-documents" "create-project-document" "delete-project-document" "get-project-document" "update-project-document" "download-project-document" "get-document-translations" "download-translated-document-for-language" "get-document-translations-for-language" "get-glossaries" "create-glossary" "delete-glossary" "get-glossary" "update-glossary" "download-glossary" "get-project-strings" "package-project-translation-memory" "package-project-translation-memory-status" "package-project-translation-memory-for-language" "package-project-translation-memory-for-language-status" "get-project-strings-for-language" "get-style-guides" "create-style-guide" "delete-style-guide" "get-style-guide" "update-style-guide" "download-style-guide" "get-project-translations" "get-project-translations-for-language" "get-project-vendors" "get-filter-contents" "get-language-pairs-report" "get-projects-report" "generate-qa-report" "get-users-report" "send-email-confirmation" "get-responsivity" "search-everywhere" "reindex-documents" "check-documents-reindex" "get-stats" "get-commission-stats" "get-commission-stats-by-filter" "get-popular-pairs" "get-project-stats" "get-string-stats" "get-strings" "post-strings" "update-translation-memory-unit" "package-user-translation-memory" "package-user-translation-memory-for-language-status" "download-global-style-guide" "update-global-style-guide" "get-questions" "submit-answers" "get-swagger-yaml" "get-access-token" "unfreeze-account" "get-user-groups" "get-users" "create-user" "get-available-vendors" "get-filtered-vendors" "send-password-reminder" "get-all-vendor-tags" "get-user" "update-user" "approve-vendor-application" "delete-user-account" "get-user-documents" "downgrade-user-proofreader" "get-user-earnings" "freeze-user-account" "make-user-proofreader" "subscribe-user-notification" "unsubscribe-user-notification" "get-user-payment-info" "update-user-payment-info" "get-user-permissions" "upload-user-profile-picture" "get-vendor-projects-by-user-id" "reject-vendor-application" "send-user-email-confirmation" "get-user-responsivity" "get-user-stats" "get-user-popular-pairs" "get-user-project-stats" "suspend-user" "unfreeze-user-account" "get-this-user-groups" "update-user-group" "commands"] | sort) } | get name | first)
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

# Available endpoints
#
# GET /
# Returns: record
# operationId: getEndpoints
export def "get-endpoints" [
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
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download result of an async operation
#
# GET /async/download
# Returns: binary
# operationId: downloadAsync
export def "download-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/async/download"
    query: [{name: async_request_key, var: async_request_key, required: true}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    async_request_key: $async_request_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get blog posts - ordered by created desc by default
#
# GET /blogs
# Returns: record<articles: table<announcement_type: string, author: string, content: string, created_at: string, excerpt: string, id: int, language: string, links: record, slug: string, title: string, topic: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getBlogPosts
export def "get-blog-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Article language, default `en`. When no blog article is available and `fallback=true` is specified, it falls back to `en`.
  --fallback: oneof<nothing, bool> # When `true`, and no article is found in the locale, it falls back to `locale=en`.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 1
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/blogs"
    query: [{name: locale, var: locale}, {name: fallback, var: fallback}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    locale: $locale, fallback: $fallback, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear cache by key
#
# DELETE /cache/{key}
# Returns: record<status: string>
# operationId: deleteCache
export def "delete-cache" [
  key: string
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
    path: "/cache/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a commission list of current client.
#
# GET /commissions
# Returns: record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getCommissions
export def "get-commissions" [
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
    path: "/commissions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a commission list of current client.
#
# POST /commissions
# Returns: record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getCommissionsByFilter
export def "get-commissions-by-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/commissions"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_code, var: budget_code}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: source_languages, var: source_languages}, {name: target_languages, var: target_languages}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View continuous projects
#
# GET /continuous_projects
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record, target_languages: list, type: string, word_count: int>>
# operationId: getContinuousProjects
export def "get-continuous-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of continuous project. (nullable, default: active)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/continuous_projects"
    query: [{name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a continuous project
#
# POST /continuous_projects
# Returns: record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>
# operationId: createContinuousProject
export def "create-continuous-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --analytics-enabled: oneof<nothing, bool> # Should we collect analytics data from Active for this continuous project?
  --auto-start-postedit: oneof<nothing, bool> # Immediately start post-editing project for translation requests that are applied MT.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --id: int # format: int64
  --is-enabled: oneof<nothing, bool>
  --last-activity-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --links: record # shape: {self?: record, editors?: record}
  --mt-enabled: oneof<nothing, bool> # Immediately apply MT on translation requests if they are missing from TM.
  --mt-engine: string # One of "MOTAWORD", "GOOGLE", "AMAZON", "MS". Default is "MOTAWORD".
  --name: string
  --postedit-enabled: oneof<nothing, bool> # Get an instant quote for translation requests that are applied MT.
  --source-language: string
  --status: string # One of "a => ACTIVE", "i => INACTIVE", "d => DELETED", "c => SCHEDULED CANCELLATION", "p => SCHEDULED CHANGE"
  --subscription: record # shape: {downgrade?: list<string>, payment_method?: int, period_end?: string, plan_id?: string, plan_name?: string, price?: string, products?: list, schedule_name?: string, schedule_start?: string, subscription_id?: string, upgrade?: list<string>, withTrial?: any}
  --target-languages: list<string>
  --type: string # Continuous project type. We currently have only 2 types, NULL and "active".
  --word-count: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects"
    body: {content_type: "application/json", kind: json, fields: [{name: analytics_enabled, var: analytics_enabled}, {name: auto_start_postedit, var: auto_start_postedit}, {name: created_at, var: created_at}, {name: id, var: id}, {name: is_enabled, var: is_enabled}, {name: last_activity_at, var: last_activity_at}, {name: links, var: links}, {name: mt_enabled, var: mt_enabled}, {name: mt_engine, var: mt_engine}, {name: name, var: name}, {name: postedit_enabled, var: postedit_enabled}, {name: source_language, var: source_language}, {name: status, var: status}, {name: subscription, var: subscription}, {name: target_languages, var: target_languages}, {name: type, var: type}, {name: word_count, var: word_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    analytics_enabled: $analytics_enabled, auto_start_postedit: $auto_start_postedit, created_at: $created_at, id: $id, is_enabled: $is_enabled, last_activity_at: $last_activity_at, links: $links, mt_enabled: $mt_enabled, mt_engine: $mt_engine, name: $name, postedit_enabled: $postedit_enabled, source_language: $source_language, status: $status, subscription: $subscription, target_languages: $target_languages, type: $type, word_count: $word_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a continuous project
#
# DELETE /continuous_projects/{id}
# Returns: record<status: string>
# operationId: deleteContinuousProject
export def "delete-continuous-project" [
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
    path: "/continuous_projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a continuous project
#
# GET /continuous_projects/{id}
# Returns: record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>
# operationId: getContinuousProject
export def "get-continuous-project" [
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
    path: "/continuous_projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a continuous project
#
# POST /continuous_projects/{id}
# Returns: record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int>
# operationId: updateContinuousProject
export def "update-continuous-project" [
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
  --analytics-enabled: oneof<nothing, bool>
  --auto-start-postedit: oneof<nothing, bool>
  --is-enabled: oneof<nothing, bool>
  --languages: list # item shape: {code?: string, is_enabled?: bool}
  --mt-enabled: oneof<nothing, bool>
  --name: string
  --postedit-enabled: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: analytics_enabled, var: analytics_enabled}, {name: auto_start_postedit, var: auto_start_postedit}, {name: is_enabled, var: is_enabled}, {name: languages, var: languages}, {name: mt_enabled, var: mt_enabled}, {name: name, var: name}, {name: postedit_enabled, var: postedit_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, analytics_enabled: $analytics_enabled, auto_start_postedit: $auto_start_postedit, is_enabled: $is_enabled, languages: $languages, mt_enabled: $mt_enabled, name: $name, postedit_enabled: $postedit_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get JWT token to be used in analytics dashboards
#
# GET /continuous_projects/{id}/analytics-token
# Returns: record<jwt: string>
# operationId: getAnalyticsToken
export def "get-analytics-token" [
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
    path: "/continuous_projects/{id}/analytics-token"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save/collect analytics data from Active widget
#
# POST /continuous_projects/{id}/collect-analytics
# Returns: record<status: string>
# operationId: collectAnalytics
export def "collect-analytics" [
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
  --anonymous-id: string
  --properties: record
  --session-id: string
  --type: string
  --user-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}/collect-analytics"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: anonymousId, var: anonymous_id}, {name: properties, var: properties}, {name: sessionId, var: session_id}, {name: type, var: type}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, anonymous_id: $anonymous_id, properties: $properties, session_id: $session_id, type: $type, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete continuous project
#
# POST /continuous_projects/{id}/complete
# Returns: record<status: string>
# operationId: complete
export def "post-continuous-projects-id-complete" [
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
    path: "/continuous_projects/{id}/complete"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get quote for documents
#
# POST /continuous_projects/{id}/documents/quote
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getQuoteForDocuments
export def "get-quote-for-documents" [
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
  --files: list<int>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}/documents/quote"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: files, var: files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, files: $files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/complete
# Returns: record<status: string>
# operationId: completeContinuousDocument
export def "complete-continuous-document" [
  id: int
  document_id: int
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
    path: "/continuous_projects/{id}/documents/{documentId}/complete"
    path_params: [{name: id, var: id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a quote for a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/quote
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getQuoteForDocument
export def "get-quote-for-document" [
  id: int
  document_id: int
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
    path: "/continuous_projects/{id}/documents/{documentId}/quote"
    path_params: [{name: id, var: id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get quote for languages
#
# POST /continuous_projects/{id}/languages/quote
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getQuoteForLanguages
export def "get-quote-for-languages" [
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
  --languages: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}/languages/quote"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: languages, var: languages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, languages: $languages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete continuous project language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/complete
# Returns: record<status: string>
# operationId: completeLanguage
export def "complete-language" [
  id: int
  target_language: string
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
    path: "/continuous_projects/{id}/languages/{targetLanguage}/complete"
    path_params: [{name: id, var: id}, {name: targetLanguage, var: target_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_language: $target_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get quote for language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/quote
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getQuoteForLanguage
export def "get-quote-for-language" [
  id: int
  target_language: string
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
    path: "/continuous_projects/{id}/languages/{targetLanguage}/quote"
    path_params: [{name: id, var: id}, {name: targetLanguage, var: target_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_language: $target_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete subscription for continuous project
#
# DELETE /continuous_projects/{id}/subscription
# Returns: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>
# operationId: deleteSubscription
export def "delete-subscription" [
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
    path: "/continuous_projects/{id}/subscription"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subscription for continuous project
#
# GET /continuous_projects/{id}/subscription
# Returns: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>
# operationId: getSubscription
export def "get-subscription" [
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
    path: "/continuous_projects/{id}/subscription"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create subscription for continuous project
#
# POST /continuous_projects/{id}/subscription
# Returns: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>
# operationId: createSubscription
export def "create-subscription" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}/subscription"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: downgrade, var: downgrade}, {name: payment_method, var: payment_method}, {name: period_end, var: period_end}, {name: plan_id, var: plan_id}, {name: plan_name, var: plan_name}, {name: price, var: price}, {name: products, var: products}, {name: schedule_name, var: schedule_name}, {name: schedule_start, var: schedule_start}, {name: subscription_id, var: subscription_id}, {name: upgrade, var: upgrade}, {name: withTrial, var: with_trial}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, with_trial: $with_trial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update subscription for continuous project
#
# PUT /continuous_projects/{id}/subscription
# Returns: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>
# operationId: updateSubscription
export def "update-subscription" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/continuous_projects/{id}/subscription"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: downgrade, var: downgrade}, {name: payment_method, var: payment_method}, {name: period_end, var: period_end}, {name: plan_id, var: plan_id}, {name: plan_name, var: plan_name}, {name: price, var: price}, {name: products, var: products}, {name: schedule_name, var: schedule_name}, {name: schedule_start, var: schedule_start}, {name: subscription_id, var: subscription_id}, {name: upgrade, var: upgrade}, {name: withTrial, var: with_trial}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, with_trial: $with_trial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update subscription payment method for continuous project
#
# PUT /continuous_projects/{id}/subscription/payment
# Returns: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>
# operationId: updateSubscriptionPaymentMethod
export def "update-subscription-payment-method" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/continuous_projects/{id}/subscription/payment"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: downgrade, var: downgrade}, {name: payment_method, var: payment_method}, {name: period_end, var: period_end}, {name: plan_id, var: plan_id}, {name: plan_name, var: plan_name}, {name: price, var: price}, {name: products, var: products}, {name: schedule_name, var: schedule_name}, {name: schedule_start, var: schedule_start}, {name: subscription_id, var: subscription_id}, {name: upgrade, var: upgrade}, {name: withTrial, var: with_trial}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, with_trial: $with_trial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instantly translate your content
#
# POST /continuous_projects/{id}/translate/{targetLanguage}
# operationId: translate
export def "translate" [
  id: int
  target_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list<string> # Simple list of strings to be translated. You can also choose to upload files instead of strings.
  --documents: list # You can add as many files as you want in documents parameter. — item shape: {data?: string, name?: string}
  --filters: record # shape: {skipMt?: list<string>, skipPostEdit?: list<string>}
  --meta: record # Free-form meta data to attach to your instant translation request. This can be used in statistics and analytical dashboards.
]: any -> any {
  $in | http-request {
    method: post
    path: "/continuous_projects/{id}/translate/{targetLanguage}"
    path_params: [{name: id, var: id}, {name: targetLanguage, var: target_language}]
    body: {content_type: "application/json", kind: json, fields: [{name: contents, var: contents}, {name: documents, var: documents}, {name: filters, var: filters}, {name: meta, var: meta}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, target_language: $target_language, contents: $contents, documents: $documents, filters: $filters, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View continuous documents
#
# GET /continuous_projects/{projectId}/documents
# Returns: record<documents: table<billed_word_count: int, id: string, links: record, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getContinuousProjectDocuments
export def "get-continuous-project-documents" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/continuous_projects/{projectId}/documents"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: filterByLanguage, var: filter_by_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, filter_by_language: $filter_by_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new document to your continuous project
#
# POST /continuous_projects/{projectId}/documents
# Returns: record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>
# operationId: addDocument
export def "add-document" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/documents"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document: $document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get continuous project document progress for multiple IDs
#
# POST /continuous_projects/{projectId}/documents/progress
# Returns: record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>
# operationId: postContinuousProjectDocumentProgress
export def "post-continuous-project-document-progress" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-name: string
  --filter-by-language: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/documents/progress"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: documentName, var: document_name}, {name: filterByLanguage, var: filter_by_language}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_name: $document_name, filter_by_language: $filter_by_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of strings and its translations in the project.
#
# POST /continuous_projects/{projectId}/documents/strings
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: postContinuousProjectFileStrings
export def "post-continuous-project-file-strings" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/documents/strings"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: documentName, var: document_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_name: $document_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}
# Returns: record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>
# operationId: getContinuousProjectDocument
export def "get-continuous-project-document" [
  project_id: int
  document_id: int
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
    path: "/continuous_projects/{projectId}/documents/{documentId}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the document
#
# POST /continuous_projects/{projectId}/documents/{documentId}
# Returns: record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>
# operationId: updateDocument
export def "update-document" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/documents/{documentId}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, document: $document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monitor progress of a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/progress
# Returns: record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>
# operationId: getContinuousProjectDocumentProgress
export def "get-continuous-project-document-progress" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/continuous_projects/{projectId}/documents/{documentId}/progress"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    query: [{name: filterByLanguage, var: filter_by_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, filter_by_language: $filter_by_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View strings their translations in a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/strings
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getContinuousProjectFileStrings
export def "get-continuous-project-file-strings" [
  project_id: int
  document_id: int
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
    path: "/continuous_projects/{projectId}/documents/{documentId}/strings"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invoices of a continuous project
#
# GET /continuous_projects/{projectId}/invoices
# Returns: record<invoices: table<amount: float, base_amount: float, base_currency: string, billing: record, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record, status: string>>
# operationId: getContinuousProjectInvoices
export def "get-continuous-project-invoices" [
  project_id: int
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
    path: "/continuous_projects/{projectId}/invoices"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monitor progress and status of a continous project
#
# GET /continuous_projects/{projectId}/progress
# Returns: record<costs: record<mt: record<amount: float, currency: string>, post_edit: record<amount: float, currency: string>, saved: record<amount: float, currency: string>, total: record<amount: float, currency: string>>, progress: record<languages: record, links: record<self: record, project: record>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>, word_counts: record<mt: int, post_edit: int, total: int>>
# operationId: getContinuousProjectProgress
export def "get-continuous-project-progress" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/continuous_projects/{projectId}/progress"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: filterByLanguage, var: filter_by_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, filter_by_language: $filter_by_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View strings and translations in continuous project
#
# GET /continuous_projects/{projectId}/strings
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getContinuousProjectStrings
export def "get-continuous-project-strings" [
  project_id: int
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
    path: "/continuous_projects/{projectId}/strings"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear translation cache
#
# DELETE /continuous_projects/{projectId}/strings/cached
# Returns: record<status: string>
# operationId: clearTranslationCache
export def "clear-translation-cache" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/continuous_projects/{projectId}/strings/cached"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: locale, var: locale}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, locale: $locale, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View cached strings translations in continuous project
#
# GET /continuous_projects/{projectId}/strings/cached
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: record>
# operationId: getTranslationCache
export def "get-translation-cache" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # Flatten cache results and ignore document keys (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/continuous_projects/{projectId}/strings/cached"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: flatten, var: flatten}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, flatten: $flatten
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recache translations
#
# POST /continuous_projects/{projectId}/strings/recache-tms
# Returns: record<status: string>
# operationId: recacheTranslations
export def "recache-translations" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/continuous_projects/{projectId}/strings/recache-tms"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: locale, var: locale}, {name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, locale: $locale, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View Active widgets
#
# GET /continuous_projects/{projectId}/widgets
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, widgets: table<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>>
# operationId: getActiveWidgets
export def "get-active-widgets" [
  project_id: int
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
    path: "/continuous_projects/{projectId}/widgets"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Active widget
#
# POST /continuous_projects/{projectId}/widgets
# Returns: record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>
# operationId: createActiveWidget
export def "create-active-widget" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website. (spec name: token)
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/widgets"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_hash_in_url, var: allow_hash_in_url}, {name: allow_query_in_url, var: allow_query_in_url}, {name: auto_detect_source_language, var: auto_detect_source_language}, {name: created_at, var: created_at}, {name: elements, var: elements}, {name: follow_user, var: follow_user}, {name: force_cache_refresh_interval, var: force_cache_refresh_interval}, {name: id, var: id}, {name: language_mappings, var: language_mappings}, {name: live, var: live}, {name: modify_links, var: modify_links}, {name: name, var: name}, {name: optimize_per_page, var: optimize_per_page}, {name: pages, var: pages}, {name: path_regex, var: path_regex}, {name: position, var: position}, {name: query_name, var: query_name}, {name: reboot_on_url_change, var: reboot_on_url_change}, {name: restricted_domains, var: restricted_domains}, {name: sections, var: sections}, {name: test_mode, var: test_mode}, {name: theme, var: theme}, {name: token, var: body_token}, {name: url_change_mode, var: url_change_mode}, {name: url_mode, var: url_mode}, {name: use_cache, var: use_cache}, {name: use_dummy_translations, var: use_dummy_translations}, {name: variables, var: variables}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, body_token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $variables
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a single widget for this Active project
#
# DELETE /continuous_projects/{projectId}/widgets/{widgetId}
# Returns: record<status: string>
# operationId: deleteActiveWidget
export def "delete-active-widget" [
  project_id: int
  widget_id: int
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
    path: "/continuous_projects/{projectId}/widgets/{widgetId}"
    path_params: [{name: projectId, var: project_id}, {name: widgetId, var: widget_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, widget_id: $widget_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View an Active widget
#
# GET /continuous_projects/{projectId}/widgets/{widgetId}
# Returns: record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>
# operationId: getActiveWidget
export def "get-active-widget" [
  project_id: int
  widget_id: int
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
    path: "/continuous_projects/{projectId}/widgets/{widgetId}"
    path_params: [{name: projectId, var: project_id}, {name: widgetId, var: widget_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, widget_id: $widget_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Active widget settings.
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}
# Returns: record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>
# operationId: updateActiveWidget
export def "update-active-widget" [
  project_id: int
  widget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website. (spec name: token)
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/continuous_projects/{projectId}/widgets/{widgetId}"
    path_params: [{name: projectId, var: project_id}, {name: widgetId, var: widget_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_hash_in_url, var: allow_hash_in_url}, {name: allow_query_in_url, var: allow_query_in_url}, {name: auto_detect_source_language, var: auto_detect_source_language}, {name: created_at, var: created_at}, {name: elements, var: elements}, {name: follow_user, var: follow_user}, {name: force_cache_refresh_interval, var: force_cache_refresh_interval}, {name: id, var: id}, {name: language_mappings, var: language_mappings}, {name: live, var: live}, {name: modify_links, var: modify_links}, {name: name, var: name}, {name: optimize_per_page, var: optimize_per_page}, {name: pages, var: pages}, {name: path_regex, var: path_regex}, {name: position, var: position}, {name: query_name, var: query_name}, {name: reboot_on_url_change, var: reboot_on_url_change}, {name: restricted_domains, var: restricted_domains}, {name: sections, var: sections}, {name: test_mode, var: test_mode}, {name: theme, var: theme}, {name: token, var: body_token}, {name: url_change_mode, var: url_change_mode}, {name: url_mode, var: url_mode}, {name: use_cache, var: use_cache}, {name: use_dummy_translations, var: use_dummy_translations}, {name: variables, var: variables}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, widget_id: $widget_id, allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, body_token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $variables
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset Active widget token
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}/reset-token
# Returns: record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>
# operationId: resetActiveWidgetToken
export def "reset-active-widget-token" [
  project_id: int
  widget_id: int
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
    path: "/continuous_projects/{projectId}/widgets/{widgetId}/reset-token"
    path_params: [{name: projectId, var: project_id}, {name: widgetId, var: widget_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, widget_id: $widget_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your corporate account
#
# GET /corporate
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>
# operationId: getCorporate
export def "get-corporate" [
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
    path: "/corporate"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View available permissions
#
# GET /corporate/permissions
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>
# operationId: getAvailableCorporatePermissions
export def "get-available-corporate-permissions" [
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
    path: "/corporate/permissions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View user groups
#
# GET /corporate/user-groups
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>
# operationId: getCorporateUserGroups
export def "get-corporate-user-groups" [
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
    path: "/corporate/user-groups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a corporate user group
#
# POST /corporate/user-groups
# Returns: record<corporate_id: int, id: int, name: string, permissions: list<string>>
# operationId: saveCorporateUserGroup
export def "save-corporate-user-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporate-id: int # format: int64
  --id: int # format: int64
  --name: string
  --permissions: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/corporate/user-groups"
    body: {content_type: "application/json", kind: json, fields: [{name: corporate_id, var: corporate_id}, {name: id, var: id}, {name: name, var: name}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id, id: $id, name: $name, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View users
#
# GET /corporate/users
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getCorporateUsers
export def "get-corporate-users" [
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
    path: "/corporate/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a user
#
# POST /corporate/users
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
# operationId: saveCorporateUser
export def "save-corporate-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/corporate/users"
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: phone, var: phone}, {name: state, var: state}, {name: street, var: street}, {name: zip, var: zip}, {name: birthday, var: birthday}, {name: email, var: email}, {name: first_name, var: first_name}, {name: id, var: id}, {name: last_name, var: last_name}, {name: notifications, var: notifications}, {name: notify, var: notify}, {name: paypal_email, var: paypal_email}, {name: require_1099, var: require_1099}, {name: user_groups, var: user_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of corporate accounts
#
# GET /corporates/all
# Returns: table<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>
# operationId: getCorporatesList
export def "get-corporates-list" [
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
    path: "/corporates/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of this corporate account
#
# GET /corporates/{corporateId}
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string>
# operationId: getCorporateById
export def "get-corporate-by-id" [
  corporate_id: int
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
    path: "/corporates/{corporateId}"
    path_params: [{name: corporateId, var: corporate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of available permissions for this corporate account. They are used when assigning permissions to corporate users.
#
# GET /corporates/{corporateId}/permissions
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>
# operationId: getAvailableCorporatePermissionsById
export def "get-available-corporate-permissions-by-id" [
  corporate_id: int
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
    path: "/corporates/{corporateId}/permissions"
    path_params: [{name: corporateId, var: corporate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user groups for this corporate account
#
# GET /corporates/{corporateId}/user-groups
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>
# operationId: getCorporateUserGroupsById
export def "get-corporate-user-groups-by-id" [
  corporate_id: int
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
    path: "/corporates/{corporateId}/user-groups"
    path_params: [{name: corporateId, var: corporate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a corporate user group for this corporate account
#
# POST /corporates/{corporateId}/user-groups
# Returns: record<corporate_id: int, id: int, name: string, permissions: list<string>>
# operationId: saveCorporateUserGroupById
export def "save-corporate-user-group-by-id" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-corporate-id: int # format: int64 (spec name: corporate_id)
  --id: int # format: int64
  --name: string
  --permissions: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/corporates/{corporateId}/user-groups"
    path_params: [{name: corporateId, var: corporate_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: corporate_id, var: body_corporate_id}, {name: id, var: id}, {name: name, var: name}, {name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id, body_corporate_id: $body_corporate_id, id: $id, name: $name, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of users for this corporate account
#
# GET /corporates/{corporateId}/users
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getCorporateUsersById
export def "get-corporate-users-by-id" [
  corporate_id: int
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
    path: "/corporates/{corporateId}/users"
    path_params: [{name: corporateId, var: corporate_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporate_id: $corporate_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete your account
#
# DELETE /delete-account
# Returns: record<status: string>
# operationId: deleteAccount
export def "delete-account" [
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
    path: "/delete-account"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your documents
#
# GET /documents
# Returns: record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getDocuments
export def "get-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents"
    query: [{name: recent, var: recent}, {name: search, var: search}, {name: type_filter, var: type_filter}, {name: language_code, var: language_code}, {name: page, var: page}, {name: per_page, var: per_page}, {name: order_by, var: order_by}, {name: order_type, var: order_type}, {name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recent: $recent, search: $search, type_filter: $type_filter, language_code: $language_code, page: $page, per_page: $per_page, order_by: $order_by, order_type: $order_type, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of subjects of projects
#
# GET /documents/subjects
# Returns: table<name: string>
# operationId: getAllDocumentSubjects
export def "get-all-document-subjects" [
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
    path: "/documents/subjects"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a single document
#
# GET /documents/{documentId}
# Returns: record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int>
# operationId: getDocument
export def "get-document" [
  document_id: string
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
    path: "/documents/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a document translation progress
#
# GET /documents/{documentId}/progress
# Returns: record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>
# operationId: getDocumentProgress
export def "get-document-progress" [
  document_id: float
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
    path: "/documents/{documentId}/progress"
    path_params: [{name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerate preview and return preview URL for given file
#
# POST /documents/{documentId}/regenerate_preview
# Returns: record<link: record<href: string>, source: string>
# operationId: regeneratePreview
export def "regenerate-preview" [
  document_id: int
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
    path: "/documents/{documentId}/regenerate_preview"
    path_params: [{name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find documents similar to this document.
#
# GET /documents/{documentId}/similars
# Returns: record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getSimilarDocuments
export def "get-similar-documents" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Determines the number of similar documents to return. (format: int64, default: 1)
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents/{documentId}/similars"
    path_params: [{name: documentId, var: document_id}]
    query: [{name: per_page, var: per_page}, {name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, per_page: $per_page, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the translation of given source manual document as manual draft source for the given target document.
#
# POST /documents/{documentId}/use_as_draft
# Returns: record<status: string>
# operationId: useAsDraft
export def "use-as-draft" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-file-id: float
  --from-manual-translation-file-id: float
  --to-manual-translation-file-id: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents/{documentId}/use_as_draft"
    path_params: [{name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: fromFileId, var: from_file_id}, {name: fromManualTranslationFileId, var: from_manual_translation_file_id}, {name: toManualTranslationFileId, var: to_manual_translation_file_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, from_file_id: $from_file_id, from_manual_translation_file_id: $from_manual_translation_file_id, to_manual_translation_file_id: $to_manual_translation_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the translation of the given manual document as a regular file.
#
# POST /documents/{documentId}/use_as_regular
# Returns: record<status: string>
# operationId: useAsRegular
export def "use-as-regular" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-original-file-preview: oneof<nothing, bool>
  --allow-review-in-manual-editor: oneof<nothing, bool>
  --disable-invitations: oneof<nothing, bool>
  --from-manual-translation-file-id: float
  --hide-numbers: oneof<nothing, bool>
  --recreate: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents/{documentId}/use_as_regular"
    path_params: [{name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowOriginalFilePreview, var: allow_original_file_preview}, {name: allowReviewInManualEditor, var: allow_review_in_manual_editor}, {name: disableInvitations, var: disable_invitations}, {name: fromManualTranslationFileId, var: from_manual_translation_file_id}, {name: hideNumbers, var: hide_numbers}, {name: recreate, var: recreate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, allow_original_file_preview: $allow_original_file_preview, allow_review_in_manual_editor: $allow_review_in_manual_editor, disable_invitations: $disable_invitations, from_manual_translation_file_id: $from_manual_translation_file_id, hide_numbers: $hide_numbers, recreate: $recreate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /downgrade-proofreader
#
# Returns: record<status: string>
# operationId: downgradeProofreader
export def "downgrade-proofreader" [
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
    path: "/downgrade-proofreader"
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your vendor earnings
#
# GET /earnings
# Returns: record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float>
# operationId: getEarnings
export def "get-earnings" [
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
    path: "/earnings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported file formats
#
# GET /formats
# Returns: record
# operationId: getFormats
export def "get-formats" [
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
    path: "/formats"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Freeze account
#
# POST /freeze-account
# Returns: record<status: string>
# operationId: freezeAccount
export def "freeze-account" [
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
    path: "/freeze-account"
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download account glossary.
#
# GET /glossary
# Returns: string
# operationId: downloadGlobalGlossary
export def "download-global-glossary" [
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
    path: "/glossary"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update the account glossary
#
# POST /glossary
# Returns: record<status: string>
# operationId: updateGlobalGlossary
export def "update-global-glossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossary: string # Glossary file. Currently supported formats: .xlsx, .tbx (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/glossary"
    body: {content_type: "application/json", kind: json, fields: [{name: glossary, var: glossary}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    glossary: $glossary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a new access token for MotaWord's integrations service
#
# GET /integrations/token
# Returns: record<token: string>
# operationId: getIntegrationsToken
export def "get-integrations-token" [
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
    path: "/integrations/token"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get vendor list for compiled invitation needs
#
# POST /invitation/vendors
# Returns: record<vendors: table<matchedNeeds: list, userId: int>>
# operationId: getInvitationVendors
export def "get-invitation-vendors" [
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
    path: "/invitation/vendors"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of supported languages
#
# GET /languages
# Returns: table<code: string, name: string>
# operationId: getLanguages
export def "get-languages" [
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
    path: "/languages"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Log user's current location. This data is used in our Intelligent Project Manager for various data analysis, including project prioritization for vendors and account validation.
#
# POST /location
# Returns: record<status: string>
# operationId: logLocation
export def "log-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # Latitude of location (format: float)
  lon: float # Longitude of location (format: float)
  --timestamp: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/location"
    body: {content_type: "application/json", kind: json, fields: [{name: lat, var: lat}, {name: lon, var: lon}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lat: $lat, lon: $lon, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /make-proofreader
#
# Returns: record<status: string>
# operationId: makeProofreader
export def "make-proofreader" [
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
    path: "/make-proofreader"
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your account info
#
# GET /me
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your account info
#
# POST /me
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
# operationId: updateMe
export def "update-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/me"
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: phone, var: phone}, {name: state, var: state}, {name: street, var: street}, {name: zip, var: zip}, {name: birthday, var: birthday}, {name: email, var: email}, {name: first_name, var: first_name}, {name: id, var: id}, {name: last_name, var: last_name}, {name: notifications, var: notifications}, {name: notify, var: notify}, {name: paypal_email, var: paypal_email}, {name: require_1099, var: require_1099}, {name: user_groups, var: user_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a delivery prediction for a project
#
# POST /ml/delivery-prediction
# Returns: record<result: table<language: string, late: bool, probability: float>>
# operationId: getDeliveryPrediction
export def "get-delivery-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ml/delivery-prediction"
    body: {content_type: "application/json", kind: json, fields: [{name: projectId, var: project_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to push notifications
#
# POST /notifications/subscribe
# Returns: record<status: string>
# operationId: subscribeNotification
export def "subscribe-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications/subscribe"
    body: {content_type: "application/json", kind: json, fields: [{name: device, var: device}, {name: endpoint, var: endpoint}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device: $device, endpoint: $endpoint, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /notifications/unsubscribe
#
# Returns: record<status: string>
# operationId: unsubscribeNotification
export def "unsubscribe-notification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications/unsubscribe"
    body: {content_type: "application/json", kind: json, fields: [{name: device, var: device}, {name: endpoint, var: endpoint}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device: $device, endpoint: $endpoint, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends a message to chat
#
# POST /pam/chat
# Returns: record<status: string>
# operationId: postMessage
export def "post-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # the message to be sent
  --recipients: list<string> # name of the recipients in the channel
  --slots: list<string> # contexts for next message
  --thread-id: string # id of the thread
  --thread-key: string # the key for thread_id default is project
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pam/chat"
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: recipients, var: recipients}, {name: slots, var: slots}, {name: thread_id, var: thread_id}, {name: thread_key, var: thread_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message: $message, recipients: $recipients, slots: $slots, thread_id: $thread_id, thread_key: $thread_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Pam profile of a client for this client ID
#
# GET /pam/profiles/client/{clientId}
# Returns: record<account_creation_date: string, client_project_count: float, corporate: string, corporate_id: float, corporate_user_count: float, frequent_file_extension: string, frequent_language_pairs: list<string>, full_name: string, growth: bool, is_complex: bool, last_12_months_spending: float, last_project: float, last_project_time: string, last_proofreaders: table<full_name: string, id: float, language: string, vendor_link: string>, notes: list<string>, nps: record<average: record<completed_surveys_count: float, score: float>, last: record<completion_date: string, score: float>>, user_rank_in_project_count: float, user_rank_in_spending: float>
# operationId: getClientProfileForPam
export def "get-client-profile-for-pam" [
  client_id: int
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
    path: "/pam/profiles/client/{clientId}"
    path_params: [{name: clientId, var: client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get completion report data of a project
#
# GET /pam/projects/{projectId}/completion-report
# Returns: record<admin_user_id: float, completion_report_data: table<invited_vendors: list, target_language: string>, id: float, quote_id: float>
# operationId: getProjectCompletionReportForPam
export def "get-project-completion-report-for-pam" [
  project_id: int
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
    path: "/pam/projects/{projectId}/completion-report"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your account password
#
# POST /password
# Returns: record<status: string>
# operationId: updatePassword
export def "update-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # New Password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/password"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your payment and billing info
#
# GET /payment
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>
# operationId: getPaymentInfo
export def "get-payment-info" [
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
    path: "/payment"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update payment info
#
# POST /payment
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>
# operationId: updatePaymentInfo
export def "update-payment-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --bin: string
  --save-as-corporate-primary: oneof<nothing, bool>
  --share-with-corporate-users: oneof<nothing, bool>
  --stripe-token: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/payment"
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: phone, var: phone}, {name: state, var: state}, {name: street, var: street}, {name: zip, var: zip}, {name: bin, var: bin}, {name: save_as_corporate_primary, var: save_as_corporate_primary}, {name: share_with_corporate_users, var: share_with_corporate_users}, {name: stripeToken, var: stripe_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, bin: $bin, save_as_corporate_primary: $save_as_corporate_primary, share_with_corporate_users: $share_with_corporate_users, stripe_token: $stripe_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset payment code
#
# POST /payment/reset-corporate-payment-code
# Returns: record<bin: string, id: int, is_default: bool, payment_code: string>
# operationId: resetCorporatePaymentCode
export def "reset-corporate-payment-code" [
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
    path: "/payment/reset-corporate-payment-code"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Manage automatic charges on your credit card
#
# POST /payment/toggle-corporate-auto-charge
# Returns: record<status: string>
# operationId: toggleCorporateAutoCharge
export def "toggle-corporate-auto-charge" [
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
    path: "/payment/toggle-corporate-auto-charge"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View saved credit card
#
# GET /payment/{cardId}
# Returns: record<bin: string, id: int, is_default: bool, payment_code: string>
# operationId: getCreditCard
export def "get-credit-card" [
  card_id: int
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
    path: "/payment/{cardId}"
    path_params: [{name: cardId, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete credit card
#
# DELETE /payment/{cardId}/delete
# Returns: record<status: string>
# operationId: deleteCreditCard
export def "delete-credit-card" [
  card_id: int
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
    path: "/payment/{cardId}/delete"
    path_params: [{name: cardId, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset credit card payment code
#
# POST /payment/{cardId}/reset-payment-code
# Returns: record<bin: string, id: int, is_default: bool, payment_code: string>
# operationId: resetCardPaymentCode
export def "reset-card-payment-code" [
  card_id: int
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
    path: "/payment/{cardId}/reset-payment-code"
    path_params: [{name: cardId, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your permissions
#
# GET /permissions
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>
# operationId: getPermissions
export def "get-permissions" [
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
    path: "/permissions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload profile picture
#
# POST /profile-picture
# Returns: record<status: string>
# operationId: uploadProfilePicture
export def "upload-profile-picture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/profile-picture"
    body: {content_type: "application/json", kind: json, fields: [{name: profile_picture, var: profile_picture}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_picture: $profile_picture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your translation projects
#
# GET /projects
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getProjects
@deprecated --flag with-pending
@deprecated --flag with-started
@deprecated --flag with-completed
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
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --status: list<string> # Filter projects by status. Accepts multiple statuses. Possible values 'pending', 'started', 'completed'
  --with-pending: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-started: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-completed: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --order-by: string@order-by-completer-1 # default: id
  --order-type: string@order-type-completer
  --with: list<string> # Include detailed information. Possible values 'client', 'vendor'
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: "status[]", var: status, style: multi}, {name: with_pending, var: with_pending}, {name: with_started, var: with_started}, {name: with_completed, var: with_completed}, {name: order_by, var: order_by}, {name: order_type, var: order_type}, {name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, status: $status, with_pending: $with_pending, with_started: $with_started, with_completed: $with_completed, order_by: $order_by, order_type: $order_type, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project
#
# POST /projects
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: createProject
export def "create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list<string> # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value.
  --documents: string # Optional. You can add as many files as you want in documents[] parameter. Or you add your documents later in separate calls. (format: binary)
  --glossaries: string # Optional. Only one glossary is supported at the moment. (format: binary)
  --source-language: string
  --styleguides: string # Optional. You can add as many files as you want in styleguides[] parameter. Or you add your style guides later in separate calls. (format: binary)
  --target-languages: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: callback_url, var: callback_url}, {name: coupon_code, var: coupon_code}, {name: custom, var: custom}, {name: "documents[]", var: documents}, {name: "glossaries[]", var: glossaries}, {name: source_language, var: source_language}, {name: "styleguides[]", var: styleguides}, {name: "target_languages[]", var: target_languages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    callback_url: $callback_url, coupon_code: $coupon_code, custom: $custom, documents: $documents, glossaries: $glossaries, source_language: $source_language, styleguides: $styleguides, target_languages: $target_languages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Quote Id
#
# GET /projects/from-internal-id/{projectId}
# Returns: record<internal-id: int, public-id: int>
# operationId: getQuoteIdFromInternalId
export def "get-quote-id-from-internal-id" [
  project_id: int
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
    path: "/projects/from-internal-id/{projectId}"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List projects as a vendor
#
# GET /projects/vendor
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getVendorProjects
export def "get-vendor-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/vendor"
    query: [{name: joined, var: joined}, {name: completed, var: completed}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    joined: $joined, completed: $completed, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete your translation project
#
# DELETE /projects/{id}
# Returns: record<status: string>
# operationId: deleteProject
export def "delete-project" [
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
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a translation project
#
# GET /projects/{id}
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: getProject
export def "get-project" [
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
  --with: list<string> # Include detailed information. Possible values 'client', 'vendor', 'score'
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project info and settings
#
# PUT /projects/{id}
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: updateProject
export def "update-project" [
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
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list<string> # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value. If you previously provided one, it will be replaced.
  --source-language: string
  --target-languages: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: callback_url, var: callback_url}, {name: coupon_code, var: coupon_code}, {name: custom, var: custom}, {name: source_language, var: source_language}, {name: "target_languages[]", var: target_languages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, callback_url: $callback_url, coupon_code: $coupon_code, custom: $custom, source_language: $source_language, target_languages: $target_languages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a CM to the project
#
# POST /projects/{id}/assign-cm
# Returns: record<status: string>
# operationId: assignCM
export def "assign-cm" [
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
  --user-id: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/assign-cm"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a call to your callback URL related to this project.
#
# GET /projects/{id}/callback/{actionType}
# Returns: record<data: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list<record>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record, documents: record, glossaries: record, payment: record, quote-pdf: record, styleguides: record>, pairs: list<record>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>, result: string, type: string, url: string>
# operationId: triggerCallback
export def "trigger-callback" [
  id: int
  action_type: string@action-type-completer
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
    path: "/projects/{id}/callback/{actionType}"
    path_params: [{name: id, var: id}, {name: actionType, var: action_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, action_type: $action_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel your translation project
#
# POST /projects/{id}/cancel
# Returns: record<status: string>
# operationId: cancelProject
export def "cancel-project" [
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
  --reason: string # Cancellation reason
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/cancel"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deliver project
#
# POST /projects/{id}/deliver
# Returns: record<status: string>
# operationId: deliverProject
export def "deliver-project" [
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
    path: "/projects/{id}/deliver"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download your translated project
#
# GET /projects/{id}/download
# Returns: binary
# operationId: download
export def "download" [
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
    method: get
    path: "/projects/{id}/download"
    path_params: [{name: id, var: id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download your translated project language
#
# GET /projects/{id}/download/{language}
# Returns: binary
# operationId: downloadLanguage
export def "download-language" [
  id: int
  language: string
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
    path: "/projects/{id}/download/{language}"
    path_params: [{name: id, var: id}, {name: language, var: language}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a quote email
#
# POST /projects/{id}/email-quote
# Returns: record<status: string>
# operationId: sendQuoteEmail
export def "send-quote-email" [
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
    path: "/projects/{id}/email-quote"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View project invoice
#
# GET /projects/{id}/invoice
# Returns: record<amount: float, base_amount: float, base_currency: string, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record<self: record<href: string>, corporate: record<href: string>, html: record<href: string>, json: record<href: string>, pdf: record<href: string>, project: record<href: string>, view: record<href: string>>, status: string>
# operationId: getInvoice
export def "get-invoice" [
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
    path: "/projects/{id}/invoice"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download project invoice (HTML)
#
# GET /projects/{id}/invoice.html
# Returns: string
# operationId: downloadHtmlInvoice
export def "download-html-invoice" [
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
    method: get
    path: "/projects/{id}/invoice.html"
    path_params: [{name: id, var: id}]
    accept: ["text/html"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download project invoice (PDF)
#
# GET /projects/{id}/invoice.pdf
# Returns: binary
# operationId: downloadPdfInvoice
export def "download-pdf-invoice" [
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
    method: get
    path: "/projects/{id}/invoice.pdf"
    path_params: [{name: id, var: id}]
    accept: ["application/pdf"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launch your translation project
#
# POST /projects/{id}/launch
# Returns: record<status: string>
# operationId: launchProject
export def "launch-project" [
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
  --bin: string # Last 4 digits of the credit card you are using one-time. This parameter is only required when stripe_token is provided.
  --budget-code: string # Optional with corporate accounts. Not available for others.
  --card-id: int # Optional. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. (format: int64)
  --payment-code: string # Optional. `corporate` payment method requires this.s
  --payment-method: string@payment-method-completer # Optional. Determines which method to use for payment. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. `corporate` method follows corporate account policy automatically, either follows invoicing flow or automatically charges corporate's primary card.
  --stripe-token: string # This is required if you are using a one-time credit card. This is the token generted from frontend via Stripe SDK. If you are using a one-time card with `stripe_token`, you must also provide `bin`, last 4 digits of the card.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/launch"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bin, var: bin}, {name: budget_code, var: budget_code}, {name: card_id, var: card_id}, {name: payment_code, var: payment_code}, {name: payment_method, var: payment_method}, {name: stripe_token, var: stripe_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, bin: $bin, budget_code: $budget_code, card_id: $card_id, payment_code: $payment_code, payment_method: $payment_method, stripe_token: $stripe_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Package your translated project
#
# POST /projects/{id}/package
# Returns: binary
# operationId: package
export def "package" [
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
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> any {
  http-request {
    method: post
    path: "/projects/{id}/package"
    path_params: [{name: id, var: id}]
    query: [{name: async, var: async}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, async: $async
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Track translation packaging status
#
# GET /projects/{id}/package/check
# Returns: record<status: string>
# operationId: trackPackage
export def "track-package" [
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
  --key: string # This is the package tracking key provided in the response of a /package call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}/package/check"
    path_params: [{name: id, var: id}]
    query: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Package your translated project language
#
# POST /projects/{id}/package/{language}
# Returns: record<status: string, key: string>
# operationId: packageLanguage
export def "package-language" [
  id: int
  language: string
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
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{id}/package/{language}"
    path_params: [{name: id, var: id}, {name: language, var: language}]
    query: [{name: async, var: async}]
    accept: ["application/json", "application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language: $language, async: $async
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# View progress of a project
#
# GET /projects/{id}/progress
# Returns: record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>
# operationId: getProgress
export def "get-progress" [
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
  --qp-raw: oneof<nothing, bool> # This will return a more raw progress information for translation and proofreading. For instance, when completed, we will return 100% for both tasks by default, whereas their actual progress may be lower than 100%. (default: false) (spec name: raw)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}/progress"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recreate your translation project from scratch. This is a risky action, you will lose current translations.
#
# POST /projects/{id}/recreate
# Returns: record<status: string>
# operationId: recreateProject
export def "recreate-project" [
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
    path: "/projects/{id}/recreate"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit feedback report for a project
#
# POST /projects/{id}/reports
# Returns: record<status: string>
# operationId: submitProjectReports
export def "submit-project-reports" [
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
  --activity-type: string # Activity Type
  --message: string # Report Message
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/reports"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: activity_type, var: activity_type}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, activity_type: $activity_type, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sales activities for a project
#
# GET /projects/{id}/sales/activities
# Returns: record<activities: table<body: string, created_at: int, created_by: string, type: string>>
# operationId: getSalesActivities
export def "get-sales-activities" [
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
  --exclude-owner: string
  --type: string@type-completer-2
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{id}/sales/activities"
    path_params: [{name: id, var: id}]
    query: [{name: excludeOwner, var: exclude_owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, exclude_owner: $exclude_owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert sales activity for a project
#
# POST /projects/{id}/sales/activities
# Returns: record<status: string>
# operationId: insertSalesActivity
export def "insert-sales-activity" [
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
  --subject: string
  --timestamp: int # format: int64
  --type: string # Activity Type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/sales/activities"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: subject, var: subject}, {name: timestamp, var: timestamp}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, subject: $subject, timestamp: $timestamp, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete project webhooks
#
# DELETE /projects/{id}/webhooks
# Returns: record<status: string>
# operationId: deleteProjectWebhook
export def "delete-project-webhook" [
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
    path: "/projects/{id}/webhooks"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View project webhooks
#
# GET /projects/{id}/webhooks
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: getProjectWebhooks
export def "get-project-webhooks" [
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
    path: "/projects/{id}/webhooks"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project webhook
#
# POST /projects/{id}/webhooks
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: postProjectWebhook
export def "post-project-webhook" [
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
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{id}/webhooks"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: callback_url, var: callback_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, callback_url: $callback_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project webhook
#
# PUT /projects/{id}/webhooks
# Returns: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote-pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>
# operationId: updateProjectWebhook
export def "update-project-webhook" [
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
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{id}/webhooks"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: callback_url, var: callback_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, callback_url: $callback_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Monitor project activities
#
# GET /projects/{projectId}/activities
# Returns: record<activities: table<activity_at: int, id: int, links: record, source_text: string, target_text: string, translator: int, type: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getActivities
export def "get-activities" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/activities"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View an activity
#
# GET /projects/{projectId}/activities/{activityId}
# Returns: record<activity_at: int, id: int, links: record<self: record<href: string>, comments: record<href: string>, project: record<href: string>>, source_text: string, target_text: string, translator: int, type: string>
# operationId: getActivity
export def "get-activity" [
  project_id: int
  activity_id: int
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
    path: "/projects/{projectId}/activities/{activityId}"
    path_params: [{name: projectId, var: project_id}, {name: activityId, var: activity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit comment to an activity
#
# POST /projects/{projectId}/activities/{activityId}
# Returns: record<comment: string, commented_at: int, id: int, links: record<self: record<href: string>, activity: record<href: string>, project: record<href: string>>>
# operationId: submitComment
export def "submit-comment" [
  project_id: int
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  comment: string # Comment text.
  --commented-at: int # Unix epoch time (format: int64)
  --id: int # format: int64
  --links: record # shape: {self?: record, activity?: record, project?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/activities/{activityId}"
    path_params: [{name: projectId, var: project_id}, {name: activityId, var: activity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: commented_at, var: commented_at}, {name: id, var: id}, {name: links, var: links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, activity_id: $activity_id, comment: $comment, commented_at: $commented_at, id: $id, links: $links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View activity comments
#
# GET /projects/{projectId}/activities/{activityId}/comments
# Returns: record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getActivityComments
export def "get-activity-comments" [
  project_id: int
  activity_id: int
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
    path: "/projects/{projectId}/activities/{activityId}/comments"
    path_params: [{name: projectId, var: project_id}, {name: activityId, var: activity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, activity_id: $activity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View all project comments
#
# GET /projects/{projectId}/comments
# Returns: record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getComments
export def "get-comments" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/comments"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View project source documents
#
# GET /projects/{projectId}/documents
# Returns: record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getProjectDocuments
export def "get-project-documents" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/documents"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new document
#
# POST /projects/{projectId}/documents
# Returns: record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: createProjectDocument
export def "create-project-document" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # You can add as many files as you want in documents[] parameter.
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-links: list # When provided, we will download the files from these URLs, in addition to files provded in `documents` parameter and then save as source documents — item shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/documents"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "documents[]", var: documents}, {name: "schemes[]", var: schemes}, {name: "source-links[]", var: source_links}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, documents: $documents, schemes: $schemes, source_links: $source_links
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the document
#
# DELETE /projects/{projectId}/documents/{documentId}
# Returns: record<status: string>
# operationId: deleteProjectDocument
export def "delete-project-document" [
  project_id: int
  document_id: int
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
    path: "/projects/{projectId}/documents/{documentId}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a project source document
#
# GET /projects/{projectId}/documents/{documentId}
# Returns: record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int>
# operationId: getProjectDocument
export def "get-project-document" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/documents/{documentId}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    query: [{name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the document.
#
# POST /projects/{projectId}/documents/{documentId}
# Returns: record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int>
# operationId: updateProjectDocument
export def "update-project-document" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: string # Single file data. The name is plural to provide a consistent naming convention. (format: binary)
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-link: record # shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/documents/{documentId}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: documents, var: documents}, {name: schemes, var: schemes}, {name: source-link, var: source_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, documents: $documents, schemes: $schemes, source_link: $source_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a project source document
#
# GET /projects/{projectId}/documents/{documentId}/download
# Returns: string
# operationId: downloadProjectDocument
export def "download-project-document" [
  project_id: int
  document_id: int
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
    path: "/projects/{projectId}/documents/{documentId}/download"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View strings and translations of a document
#
# GET /projects/{projectId}/documents/{documentId}/translations
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getDocumentTranslations
export def "get-document-translations" [
  project_id: int
  document_id: int
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
    path: "/projects/{projectId}/documents/{documentId}/translations"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download translated document
#
# GET /projects/{projectId}/documents/{documentId}/translations/download/{language}
# Returns: binary
# operationId: downloadTranslatedDocumentForLanguage
export def "download-translated-document-for-language" [
  project_id: int
  document_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certified: oneof<nothing, bool> # Download certified translation (default: 0)
]: nothing -> any {
  http-request {
    method: get
    path: "/projects/{projectId}/documents/{documentId}/translations/download/{language}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}, {name: language, var: language}]
    query: [{name: certified, var: certified}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, language: $language, certified: $certified
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View strings and translations of a document for target language
#
# GET /projects/{projectId}/documents/{documentId}/translations/{language}
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getDocumentTranslationsForLanguage
export def "get-document-translations-for-language" [
  project_id: int
  document_id: int
  language: string
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
    path: "/projects/{projectId}/documents/{documentId}/translations/{language}"
    path_params: [{name: projectId, var: project_id}, {name: documentId, var: document_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, document_id: $document_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View glossaries
#
# GET /projects/{projectId}/glossaries
# Returns: record<glossaries: table<id: int, links: record, name: string, uploaded_at: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getGlossaries
export def "get-glossaries" [
  project_id: int
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
    path: "/projects/{projectId}/glossaries"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a glossary file
#
# POST /projects/{projectId}/glossaries
# Returns: record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>
# operationId: createGlossary
export def "create-glossary" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/glossaries"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: glossaries, var: glossaries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, glossaries: $glossaries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a glossary
#
# DELETE /projects/{projectId}/glossaries/{glossaryId}
# Returns: record<status: string>
# operationId: deleteGlossary
export def "delete-glossary" [
  project_id: int
  glossary_id: int
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
    path: "/projects/{projectId}/glossaries/{glossaryId}"
    path_params: [{name: projectId, var: project_id}, {name: glossaryId, var: glossary_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, glossary_id: $glossary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}
# Returns: record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>
# operationId: getGlossary
export def "get-glossary" [
  project_id: int
  glossary_id: int
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
    path: "/projects/{projectId}/glossaries/{glossaryId}"
    path_params: [{name: projectId, var: project_id}, {name: glossaryId, var: glossary_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, glossary_id: $glossary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a glossary
#
# PUT /projects/{projectId}/glossaries/{glossaryId}
# Returns: record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>
# operationId: updateGlossary
export def "update-glossary" [
  project_id: int
  glossary_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/glossaries/{glossaryId}"
    path_params: [{name: projectId, var: project_id}, {name: glossaryId, var: glossary_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: glossaries, var: glossaries}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, glossary_id: $glossary_id, glossaries: $glossaries
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}/download
# Returns: string
# operationId: downloadGlossary
export def "download-glossary" [
  project_id: int
  glossary_id: int
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
    path: "/projects/{projectId}/glossaries/{glossaryId}/download"
    path_params: [{name: projectId, var: project_id}, {name: glossaryId, var: glossary_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, glossary_id: $glossary_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View project strings and translations
#
# GET /projects/{projectId}/strings
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getProjectStrings
export def "get-project-strings" [
  project_id: int
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
    path: "/projects/{projectId}/strings"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download project translation memory
#
# POST /projects/{projectId}/strings/package
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageProjectTranslationMemory
export def "package-project-translation-memory" [
  project_id: int
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/strings/package"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: async, var: async}, {name: format, var: format}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, async: $async, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check translation memory packaging status
#
# GET /projects/{projectId}/strings/package/status
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageProjectTranslationMemoryStatus
export def "package-project-translation-memory-status" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/strings/package/status"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: async_request_key, var: async_request_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, async_request_key: $async_request_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download language-specific project translation memory
#
# POST /projects/{projectId}/strings/{languageCode}/package
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageProjectTranslationMemoryForLanguage
export def "package-project-translation-memory-for-language" [
  project_id: int
  language_code: string
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/strings/{languageCode}/package"
    path_params: [{name: projectId, var: project_id}, {name: languageCode, var: language_code}]
    query: [{name: async, var: async}, {name: format, var: format}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, language_code: $language_code, async: $async, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check language-specific translation memory packaging status
#
# GET /projects/{projectId}/strings/{languageCode}/package/status
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageProjectTranslationMemoryForLanguageStatus
export def "package-project-translation-memory-for-language-status" [
  project_id: int
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/strings/{languageCode}/package/status"
    path_params: [{name: projectId, var: project_id}, {name: languageCode, var: language_code}]
    query: [{name: async_request_key, var: async_request_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, language_code: $language_code, async_request_key: $async_request_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View strings and translations for target language
#
# GET /projects/{projectId}/strings/{language}
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getProjectStringsForLanguage
export def "get-project-strings-for-language" [
  project_id: int
  language: string
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
    path: "/projects/{projectId}/strings/{language}"
    path_params: [{name: projectId, var: project_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View style guides
#
# GET /projects/{projectId}/styleguides
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>>
# operationId: getStyleGuides
export def "get-style-guides" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/styleguides"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a new style guide
#
# POST /projects/{projectId}/styleguides
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>>
# operationId: createStyleGuide
export def "create-style-guide" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/styleguides"
    path_params: [{name: projectId, var: project_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: styleguides, var: styleguides}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, styleguides: $styleguides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a style guide
#
# DELETE /projects/{projectId}/styleguides/{styleGuideId}
# Returns: record<status: string>
# operationId: deleteStyleGuide
export def "delete-style-guide" [
  project_id: int
  style_guide_id: int
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
    path: "/projects/{projectId}/styleguides/{styleGuideId}"
    path_params: [{name: projectId, var: project_id}, {name: styleGuideId, var: style_guide_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, style_guide_id: $style_guide_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}
# Returns: record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>
# operationId: getStyleGuide
export def "get-style-guide" [
  project_id: int
  style_guide_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/styleguides/{styleGuideId}"
    path_params: [{name: projectId, var: project_id}, {name: styleGuideId, var: style_guide_id}]
    query: [{name: "with[]", var: with, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, style_guide_id: $style_guide_id, with: $with
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a style guide
#
# PUT /projects/{projectId}/styleguides/{styleGuideId}
# Returns: record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview-box: record<href: string>, preview-pdf: record<href: string>, preview-pdf-viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int>
# operationId: updateStyleGuide
export def "update-style-guide" [
  project_id: int
  style_guide_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/styleguides/{styleGuideId}"
    path_params: [{name: projectId, var: project_id}, {name: styleGuideId, var: style_guide_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: styleguides, var: styleguides}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, style_guide_id: $style_guide_id, styleguides: $styleguides
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}/download
# Returns: string
# operationId: downloadStyleGuide
export def "download-style-guide" [
  project_id: int
  style_guide_id: int
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
    path: "/projects/{projectId}/styleguides/{styleGuideId}/download"
    path_params: [{name: projectId, var: project_id}, {name: styleGuideId, var: style_guide_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, style_guide_id: $style_guide_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. Use /projects/{projectId}/strings instead.
#
# GET /projects/{projectId}/translations
# DEPRECATED
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getProjectTranslations
@deprecated
export def "get-project-translations" [
  project_id: int
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
    path: "/projects/{projectId}/translations"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated. use /projects/{projectId}/strings/{language} instead.
#
# GET /projects/{projectId}/translations/{language}
# DEPRECATED
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>>
# operationId: getProjectTranslationsForLanguage
@deprecated
export def "get-project-translations-for-language" [
  project_id: int
  language: string
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
    path: "/projects/{projectId}/translations/{language}"
    path_params: [{name: projectId, var: project_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of vendors.
#
# GET /projects/{projectId}/vendors
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getProjectVendors
export def "get-project-vendors" [
  project_id: int
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
    path: "/projects/{projectId}/vendors"
    path_params: [{name: projectId, var: project_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns available options for selected timeframe.
#
# POST /reports/filter
# Returns: record<budget_codes: list<string>, categories: list<string>, clients: table<id: int, name: string>, documents: table<id: int, name: string>, projects: table<id: int, name: string>, severities: list<string>, source_languages: list<string>, subjects: list<string>, target_languages: list<string>, vendors: table<id: int, name: string>>
# operationId: getFilterContents
export def "get-filter-contents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/filter"
    body: {content_type: "application/json", kind: json, fields: [{name: date_from, var: date_from}, {name: date_to, var: date_to}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_from: $date_from, date_to: $date_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Language pairs report
#
# POST /reports/language-pairs
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<language_pair: record, spending: float, word_count: int>>
# operationId: getLanguagePairsReport
export def "get-language-pairs-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/language-pairs"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_code, var: budget_code}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: source_languages, var: source_languages}, {name: target_languages, var: target_languages}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Projects report
#
# POST /reports/projects
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getProjectsReport
export def "get-projects-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/projects"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_code, var: budget_code}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: source_languages, var: source_languages}, {name: target_languages, var: target_languages}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate a QA report for given filter
#
# POST /reports/qa
# Returns: record<report: table<category: string, comment: string, docId: string, editorLink: string, end: int, inSource: bool, isCurrent: bool, module: string, projectId: record, severity: string, source: string, sourceLanguage: record, start: int, state: string, targetLanguage: record, translation: string, uniqueKey: string, vendor: record>>
# operationId: generateQAReport
export def "generate-qa-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-codes: list<string>
  --categories: list<string>
  --clients: list<float>
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --documents: list<float>
  --projects: list<float>
  --severities: list<string>
  --source-languages: list<string>
  --subjects: list<string>
  --target-languages: list<string>
  --vendors: list<float>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/qa"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_codes, var: budget_codes}, {name: categories, var: categories}, {name: clients, var: clients}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: documents, var: documents}, {name: projects, var: projects}, {name: severities, var: severities}, {name: source_languages, var: source_languages}, {name: subjects, var: subjects}, {name: target_languages, var: target_languages}, {name: vendors, var: vendors}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_codes: $budget_codes, categories: $categories, clients: $clients, date_from: $date_from, date_to: $date_to, documents: $documents, projects: $projects, severities: $severities, source_languages: $source_languages, subjects: $subjects, target_languages: $target_languages, vendors: $vendors
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Company users report
#
# POST /reports/users
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<currency: string, spending: float, user: record, word_count: int>>
# operationId: getUsersReport
export def "get-users-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reports/users"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_code, var: budget_code}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: source_languages, var: source_languages}, {name: target_languages, var: target_languages}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends email confirmation email for current user
#
# POST /resend-email-confirmation
# Returns: record<status: string>
# operationId: sendEmailConfirmation
export def "send-email-confirmation" [
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
    path: "/resend-email-confirmation"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your vendor responsiveness
#
# GET /responsivity
# Returns: record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>>
# operationId: getResponsivity
export def "get-responsivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Time period to calculate your responsiveness (default: monthly)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/responsivity"
    query: [{name: period, var: period}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search everything in your account
#
# GET /search
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, result: record<documents: list<record>, projects: list<record>, strings: list<record>>>
# operationId: searchEverywhere
export def "search-everywhere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query term (required)
  --include: list<string> # Search in these entities. Current oprions are projects, documents, strings. Can be multiple. When not provided, we'll search through all entities.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: query, var: query, required: true}, {name: "include[]", var: include, style: multi}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, include: $include, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reindex for search all of the client source and translation documents.
#
# POST /search/documents/reindex
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: reindexDocuments
export def "reindex-documents" [
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
    path: "/search/documents/reindex"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check reindex status of the client source and translation documents.
#
# GET /search/documents/reindex/status
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: checkDocumentsReindex
export def "check-documents-reindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/documents/reindex/status"
    query: [{name: async_request_key, var: async_request_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    async_request_key: $async_request_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your account statistics
#
# GET /stats
# Returns: record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>>
# operationId: getStats
export def "get-stats" [
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
    path: "/stats"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the total commissions stats.
#
# GET /stats/commissions
# Returns: record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>>
# operationId: getCommissionStats
export def "get-commission-stats" [
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
    path: "/stats/commissions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the total commissions stats by report filter.
#
# POST /stats/commissions
# Returns: record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>>
# operationId: getCommissionStatsByFilter
export def "get-commission-stats-by-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stats/commissions"
    body: {content_type: "application/json", kind: json, fields: [{name: budget_code, var: budget_code}, {name: date_from, var: date_from}, {name: date_to, var: date_to}, {name: source_languages, var: source_languages}, {name: target_languages, var: target_languages}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your popular language pairs
#
# GET /stats/popular-pairs
# Returns: record<pairs: table<source_language: string, target_language: string>>
# operationId: getPopularPairs
export def "get-popular-pairs" [
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
    path: "/stats/popular-pairs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your project statistics
#
# GET /stats/projects
# Returns: record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>>
# operationId: getProjectStats
export def "get-project-stats" [
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
    path: "/stats/projects"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your translation statistics
#
# GET /stats/strings
# Returns: record<language_counts: table<project_string_count: int, source_language: string, tm_string_count: int>, total_project_strings_count: int, total_tm_strings_count: int>
# operationId: getStringStats
export def "get-string-stats" [
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
    path: "/stats/strings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View account strings (translation memory)
#
# GET /strings
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, strings: table<content: string, language: string, last_changed: string, translations: list>>
# operationId: getStrings
export def "get-strings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string # Source Language Code
  --page: int # Requested page (format: int64, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/strings"
    query: [{name: source_language, var: source_language}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Translate Strings with MT
#
# POST /strings
# DEPRECATED
# Returns: record<cost: record<amount: float, currency: string>, strings: table<content: string, language: string, last_changed: string, translations: list>>
# operationId: postStrings
@deprecated
export def "post-strings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list<string>
  --source-language: string
  --target-languages: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/strings"
    body: {content_type: "application/json", kind: json, fields: [{name: contents, var: contents}, {name: source_language, var: source_language}, {name: target_languages, var: target_languages}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    contents: $contents, source_language: $source_language, target_languages: $target_languages
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update string translation
#
# PUT /strings
# Returns: record<status: string>
# operationId: updateTranslationMemoryUnit
export def "update-translation-memory-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string
  --source-text: string
  --target-language: string
  --target-text: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/strings"
    body: {content_type: "application/json", kind: json, fields: [{name: sourceLanguage, var: source_language}, {name: sourceText, var: source_text}, {name: targetLanguage, var: target_language}, {name: targetText, var: target_text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_language: $source_language, source_text: $source_text, target_language: $target_language, target_text: $target_text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download account translation memory
#
# POST /strings/{languageCode}/package
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageUserTranslationMemory
export def "package-user-translation-memory" [
  language_code: string
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --email: int # If you don't need us to email the TMX, set this to '0'. Default is 1. (format: int64, default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/strings/{languageCode}/package"
    path_params: [{name: languageCode, var: language_code}]
    query: [{name: async, var: async}, {name: email, var: email}]
    accept: ["application/json", "application/xml"]
    ok: [200]
    auth: bearer
  } {
    language_code: $language_code, async: $async, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check account translation memory packaging status
#
# GET /strings/{languageCode}/package/status
# Returns: record<duration: int, key: string, message: record, status: string>
# operationId: packageUserTranslationMemoryForLanguageStatus
export def "package-user-translation-memory-for-language-status" [
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/strings/{languageCode}/package/status"
    path_params: [{name: languageCode, var: language_code}]
    query: [{name: async_request_key, var: async_request_key, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    language_code: $language_code, async_request_key: $async_request_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download account style guide
#
# GET /styleguide
# Returns: string
# operationId: downloadGlobalStyleGuide
export def "download-global-style-guide" [
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
    path: "/styleguide"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update the account style guide
#
# POST /styleguide
# Returns: record<status: string>
# operationId: updateGlobalStyleGuide
export def "update-global-style-guide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguide: string # Style guide file. Currently supported formats: .pdf, .docx, .txt (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/styleguide"
    body: {content_type: "application/json", kind: json, fields: [{name: styleguide, var: styleguide}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    styleguide: $styleguide
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get survey questions in given scope and type
#
# GET /surveys/{scope}/{type}
# Returns: table<answers: list<record>, question: record<enabled: bool, format: string, id: int, question: string, text: string>, question_answers: list<record>>
# operationId: getQuestions
export def "get-questions" [
  scope: string
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
  --attach-answers-for-project: int # Project ID (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/surveys/{scope}/{type}"
    path_params: [{name: scope, var: scope}, {name: type, var: type}]
    query: [{name: attach_answers_for_project, var: attach_answers_for_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, type: $type, attach_answers_for_project: $attach_answers_for_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post survey answers for scope and type
#
# POST /surveys/{scope}/{type}
# Returns: record<status: string>
# operationId: submitAnswers
export def "submit-answers" [
  scope: string
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
  --answers: list # item shape: {answer?: string, project_id?: int, question_answer_id?: int, question_id?: int, user_id?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/surveys/{scope}/{type}"
    path_params: [{name: scope, var: scope}, {name: type, var: type}]
    body: {content_type: "application/json", kind: json, fields: [{name: answers, var: answers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    scope: $scope, type: $type, answers: $answers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OpenAPI YAML representation of our API
#
# GET /swagger
# Returns: string
# operationId: getSwaggerYaml
export def "get-swagger-yaml" [
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
    path: "/swagger"
    accept: ["text/yaml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an access token
#
# POST /token
# Returns: record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string, user_id: int>
# operationId: getAccessToken
export def "get-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string # OAuth2 grant type. Supports 'client_credentials', 'password', 'refresh_token' or 'user_id'.
  --password: string # MW Account password (to be used in password grant type)
  --refresh-token: string # Refresh token value for refresh token flow.
  scope: string # Authorization scope. Use 'privileged' for private endpoints.
  --user-id: int # Value for user_id grant type flow. (format: int64)
  --username: string # MW Account email (to be used in password grant type)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/token"
    body: {content_type: "application/json", kind: json, fields: [{name: grant_type, var: grant_type}, {name: password, var: password}, {name: refresh_token, var: refresh_token}, {name: scope, var: scope}, {name: user_id, var: user_id}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    grant_type: $grant_type, password: $password, refresh_token: $refresh_token, scope: $scope, user_id: $user_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Defreeze your account
#
# POST /unfreeze-account
# Returns: record<status: string>
# operationId: unfreezeAccount
export def "unfreeze-account" [
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
    path: "/unfreeze-account"
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View your user groups
#
# GET /user-groups
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>
# operationId: getUserGroups
export def "get-user-groups" [
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
    path: "/user-groups"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of platform users
#
# GET /users
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --user-type: string@user-type-completer # default: all
  --search: string
  --email: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: user_type, var: user_type}, {name: search, var: search}, {name: email, var: email}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, user_type: $user_type, search: $search, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new user
#
# POST /users
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
# operationId: createUser
@deprecated --flag can-work-manual-files
@deprecated --flag city
@deprecated --flag country
@deprecated --flag is-proofreader
@deprecated --flag language-pairs
@deprecated --flag native-language
@deprecated --flag nps
@deprecated --flag state
@deprecated --flag street
@deprecated --flag tms-user-name
@deprecated --flag zip-code
export def "create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Send a welcome email to the user (default: 1)
  --billing: record # shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string, name?: string}
  --birthday: string # format: date
  --can-work-manual-files: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --city: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --client: record # shape: {corporate?: record, nps?: float, subjects?: record}
  --corporate-id: int # format: int64
  --country: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --created-at: int # Unix epoch time (format: int64)
  --do-not-contact: oneof<nothing, bool>
  --email: string
  --first-name: string
  --has-pwd: oneof<nothing, bool>
  --id: int # format: int64
  --is-client: oneof<nothing, bool>
  --is-developer: oneof<nothing, bool>
  --is-proofreader: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --is-prospect: oneof<nothing, bool>
  --is-sales-person: oneof<nothing, bool>
  --is-vendor: oneof<nothing, bool>
  --language-pairs: list # \@deprecated. use `vendor` key (DEPRECATED) — item shape: {source_language?: string, target_language?: string}
  --last-name: string
  --last-seen-online-at: int # Unix epoch time (format: int64)
  --links: record # shape: {self?: record, login_as?: record, projects?: record, responsivity?: record, stats?: record}
  --locale: string # User Locale
  --mailing: record # shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string}
  --name: string
  --native-language: string # \@deprecated. Native language of user (DEPRECATED)
  --nps: float # \@deprecated. use /stats endpoint for the current nps value. (DEPRECATED, format: float)
  --phone-number: string
  --profile-picture-path: string
  --social-media: record # shape: {facebook_url?: string, linkedIn_url?: string, twitter_url?: string}
  --state: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --status: string
  --street: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --timezone: string
  --tms-user-name: string # \@deprecated. use `vendor` key (DEPRECATED)
  --user-groups: list # item shape: {corporate_id?: int, id?: int, name?: string, permissions?: list<string>}
  --vendor: record # shape: {can_work_manual_files?: bool, email_open_rate?: float, is_frozen?: bool, is_proofreader?: bool, language_pairs?: list, native_language?: string, pam_tqs?: float, paypal_email?: string, profile_survey?: record, require_1099?: bool, tags?: list<string>, tms_user_name?: string, vendor_type?: string}
  --zip-code: string # \@deprecated. use mailing or billing key. new key name is "zip". (DEPRECATED)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    query: [{name: notify, var: notify}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing, var: billing}, {name: birthday, var: birthday}, {name: can_work_manual_files, var: can_work_manual_files}, {name: city, var: city}, {name: client, var: client}, {name: corporate_id, var: corporate_id}, {name: country, var: country}, {name: created_at, var: created_at}, {name: do_not_contact, var: do_not_contact}, {name: email, var: email}, {name: first_name, var: first_name}, {name: has_pwd, var: has_pwd}, {name: id, var: id}, {name: is_client, var: is_client}, {name: is_developer, var: is_developer}, {name: is_proofreader, var: is_proofreader}, {name: is_prospect, var: is_prospect}, {name: is_sales_person, var: is_sales_person}, {name: is_vendor, var: is_vendor}, {name: language_pairs, var: language_pairs}, {name: last_name, var: last_name}, {name: last_seen_online_at, var: last_seen_online_at}, {name: links, var: links}, {name: locale, var: locale}, {name: mailing, var: mailing}, {name: name, var: name}, {name: native_language, var: native_language}, {name: nps, var: nps}, {name: phone_number, var: phone_number}, {name: profile_picture_path, var: profile_picture_path}, {name: social_media, var: social_media}, {name: state, var: state}, {name: status, var: status}, {name: street, var: street}, {name: timezone, var: timezone}, {name: tms_user_name, var: tms_user_name}, {name: user_groups, var: user_groups}, {name: vendor, var: vendor}, {name: zip_code, var: zip_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    notify: $notify, billing: $billing, birthday: $birthday, can_work_manual_files: $can_work_manual_files, city: $city, client: $client, corporate_id: $corporate_id, country: $country, created_at: $created_at, do_not_contact: $do_not_contact, email: $email, first_name: $first_name, has_pwd: $has_pwd, id: $id, is_client: $is_client, is_developer: $is_developer, is_proofreader: $is_proofreader, is_prospect: $is_prospect, is_sales_person: $is_sales_person, is_vendor: $is_vendor, language_pairs: $language_pairs, last_name: $last_name, last_seen_online_at: $last_seen_online_at, links: $links, locale: $locale, mailing: $mailing, name: $name, native_language: $native_language, nps: $nps, phone_number: $phone_number, profile_picture_path: $profile_picture_path, social_media: $social_media, state: $state, status: $status, street: $street, timezone: $timezone, tms_user_name: $tms_user_name, user_groups: $user_groups, vendor: $vendor, zip_code: $zip_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of vendors available for the criteria given
#
# POST /users/available-vendors
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getAvailableVendors
export def "get-available-vendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Include detailed information. Possible values 'user'. Requesting user info enrichment takes much longer.
  --corporate-id: float # Corporate account ID to filter for vendor authorization
  --manual-work-permission: oneof<nothing, bool> # Filter vendors for manual work permission (default: 0)
  --source-language: string # Source language code
  --target-languages: list<string> # List of target language codes.
  --types: list<string> # List of vendor types
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/available-vendors"
    query: [{name: "with[]", var: with, style: multi}]
    body: {content_type: "application/json", kind: json, fields: [{name: corporateId, var: corporate_id}, {name: manualWorkPermission, var: manual_work_permission}, {name: sourceLanguage, var: source_language}, {name: targetLanguages, var: target_languages}, {name: types, var: types}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    with: $with, corporate_id: $corporate_id, manual_work_permission: $manual_work_permission, source_language: $source_language, target_languages: $target_languages, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Filter vendors based on provided parameters
#
# POST /users/filter
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>>
# operationId: getFilteredVendors
export def "get-filtered-vendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number
  --per-page: int # The number of items per page
  --order-by: string # The field to order the results by
  --order: string # The order to sort the results by (ascending or descending)
  --clients: list<int>
  --communication-channel: list<string>
  --corporate-ids-for-auth: list<int>
  --corporates: list<int>
  --country: list<string>
  --created-at: string
  --current-services: list<string>
  --daily-proofreading-capacity: int
  --daily-translation-capacity: int
  --destination-languages: list<int>
  --dtp-software: list<string>
  --email-address: string
  --experience: list<string>
  --first-name: string
  --id: list<int>
  --is-certified-translator: oneof<nothing, bool>
  --is-sworn-translator: oneof<nothing, bool>
  --language-pairs: list
  --last-name: string
  --last-online: string
  --last-worked: string
  --memoq: int
  --memsource: int
  --min-tqs: float
  --omegat: int
  --project-count: int
  --proofreader-experience: int
  --provides-creative-writing-service: oneof<nothing, bool>
  --provides-postedit-service: oneof<nothing, bool>
  --quote-file-subjects: list<string>
  --reference: string
  --sdl-trados: int
  --search: string
  --skype-id: string
  --smartcat: int
  --smartling: int
  --source-languages: list<int>
  --specialization: list<string>
  --status: list<string>
  --subtitle-edit: int
  --subtitle-workshop: int
  --translator-association: string
  --transsuite-2000: int
  --user-working-timezone: list<string>
  --vendor-profile-lsp: string
  --vendor-tags: list<string>
  --vendor-type: list<string>
  --vendor-working-timezone: list<string>
  --word-count: int
  --wordbee: int
  --wordfast: int
  --work-type: string
  --work-with: string
  --working-as: list<string>
  --xbench: int
  --xtm: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/filter"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: order_by, var: order_by}, {name: order, var: order}]
    body: {content_type: "application/json", kind: json, fields: [{name: clients, var: clients}, {name: communication_channel, var: communication_channel}, {name: corporate_ids_for_auth, var: corporate_ids_for_auth}, {name: corporates, var: corporates}, {name: country, var: country}, {name: created_at, var: created_at}, {name: current_services, var: current_services}, {name: daily_proofreading_capacity, var: daily_proofreading_capacity}, {name: daily_translation_capacity, var: daily_translation_capacity}, {name: destination_languages, var: destination_languages}, {name: dtp_software, var: dtp_software}, {name: email_address, var: email_address}, {name: experience, var: experience}, {name: first_name, var: first_name}, {name: id, var: id}, {name: is_certified_translator, var: is_certified_translator}, {name: is_sworn_translator, var: is_sworn_translator}, {name: language_pairs, var: language_pairs}, {name: last_name, var: last_name}, {name: last_online, var: last_online}, {name: last_worked, var: last_worked}, {name: memoq, var: memoq}, {name: memsource, var: memsource}, {name: min_tqs, var: min_tqs}, {name: omegat, var: omegat}, {name: project_count, var: project_count}, {name: proofreader_experience, var: proofreader_experience}, {name: provides_creative_writing_service, var: provides_creative_writing_service}, {name: provides_postedit_service, var: provides_postedit_service}, {name: quote_file_subjects, var: quote_file_subjects}, {name: reference, var: reference}, {name: sdl_trados, var: sdl_trados}, {name: search, var: search}, {name: skype_id, var: skype_id}, {name: smartcat, var: smartcat}, {name: smartling, var: smartling}, {name: source_languages, var: source_languages}, {name: specialization, var: specialization}, {name: status, var: status}, {name: subtitle_edit, var: subtitle_edit}, {name: subtitle_workshop, var: subtitle_workshop}, {name: translator_association, var: translator_association}, {name: transsuite_2000, var: transsuite_2000}, {name: user_working_timezone, var: user_working_timezone}, {name: vendor_profile_lsp, var: vendor_profile_lsp}, {name: vendor_tags, var: vendor_tags}, {name: vendor_type, var: vendor_type}, {name: vendor_working_timezone, var: vendor_working_timezone}, {name: word_count, var: word_count}, {name: wordbee, var: wordbee}, {name: wordfast, var: wordfast}, {name: work_type, var: work_type}, {name: work_with, var: work_with}, {name: working_as, var: working_as}, {name: xbench, var: xbench}, {name: xtm, var: xtm}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, order_by: $order_by, order: $order, clients: $clients, communication_channel: $communication_channel, corporate_ids_for_auth: $corporate_ids_for_auth, corporates: $corporates, country: $country, created_at: $created_at, current_services: $current_services, daily_proofreading_capacity: $daily_proofreading_capacity, daily_translation_capacity: $daily_translation_capacity, destination_languages: $destination_languages, dtp_software: $dtp_software, email_address: $email_address, experience: $experience, first_name: $first_name, id: $id, is_certified_translator: $is_certified_translator, is_sworn_translator: $is_sworn_translator, language_pairs: $language_pairs, last_name: $last_name, last_online: $last_online, last_worked: $last_worked, memoq: $memoq, memsource: $memsource, min_tqs: $min_tqs, omegat: $omegat, project_count: $project_count, proofreader_experience: $proofreader_experience, provides_creative_writing_service: $provides_creative_writing_service, provides_postedit_service: $provides_postedit_service, quote_file_subjects: $quote_file_subjects, reference: $reference, sdl_trados: $sdl_trados, search: $search, skype_id: $skype_id, smartcat: $smartcat, smartling: $smartling, source_languages: $source_languages, specialization: $specialization, status: $status, subtitle_edit: $subtitle_edit, subtitle_workshop: $subtitle_workshop, translator_association: $translator_association, transsuite_2000: $transsuite_2000, user_working_timezone: $user_working_timezone, vendor_profile_lsp: $vendor_profile_lsp, vendor_tags: $vendor_tags, vendor_type: $vendor_type, vendor_working_timezone: $vendor_working_timezone, word_count: $word_count, wordbee: $wordbee, wordfast: $wordfast, work_type: $work_type, work_with: $work_with, working_as: $working_as, xbench: $xbench, xtm: $xtm
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends password reset email to the user's registered email address
#
# POST /users/send-password-reminder
# Returns: record<status: string>
# operationId: sendPasswordReminder
export def "send-password-reminder" [
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/send-password-reminder"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all vendor tags for vendors filter
#
# GET /users/tags
# Returns: table<color: string, name: string>
# operationId: getAllVendorTags
export def "get-all-vendor-tags" [
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
    path: "/users/tags"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user information, including client or vendor specific info.
#
# GET /{userId}
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
# operationId: getUser
export def "get-user" [
  user_id: int
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
    path: "/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}
#
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string>
# operationId: updateUser
export def "update-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: city, var: city}, {name: country, var: country}, {name: phone, var: phone}, {name: state, var: state}, {name: street, var: street}, {name: zip, var: zip}, {name: birthday, var: birthday}, {name: email, var: email}, {name: first_name, var: first_name}, {name: id, var: id}, {name: last_name, var: last_name}, {name: notifications, var: notifications}, {name: notify, var: notify}, {name: paypal_email, var: paypal_email}, {name: require_1099, var: require_1099}, {name: user_groups, var: user_groups}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/approve
#
# Returns: record<status: string>
# operationId: approveVendorApplication
export def "approve-vendor-application" [
  user_id: int
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
    path: "/{userId}/approve"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete requester account
#
# DELETE /{userId}/delete-account
# Returns: record<status: string>
# operationId: deleteUserAccount
export def "delete-user-account" [
  user_id: int
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
    path: "/{userId}/delete-account"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of your documents
#
# GET /{userId}/documents
# Returns: record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>>
# operationId: getUserDocuments
export def "get-user-documents" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{userId}/documents"
    path_params: [{name: userId, var: user_id}]
    query: [{name: recent, var: recent}, {name: search, var: search}, {name: type_filter, var: type_filter}, {name: language_code, var: language_code}, {name: page, var: page}, {name: per_page, var: per_page}, {name: order_by, var: order_by}, {name: order_type, var: order_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, recent: $recent, search: $search, type_filter: $type_filter, language_code: $language_code, page: $page, per_page: $per_page, order_by: $order_by, order_type: $order_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/downgrade-proofreader
#
# Returns: record<status: string>
# operationId: downgradeUserProofreader
export def "downgrade-user-proofreader" [
  user_id: int
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
    path: "/{userId}/downgrade-proofreader"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns your vendor earnings. Includes real-time earnings from ongoing projects, and fixed earnings from completed projects. Also includes total earnings and string edits.
#
# GET /{userId}/earnings
# Returns: record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float>
# operationId: getUserEarnings
export def "get-user-earnings" [
  user_id: int
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
    path: "/{userId}/earnings"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Freeze requester account for project notifications
#
# POST /{userId}/freeze-account
# Returns: record<status: string>
# operationId: freezeUserAccount
export def "freeze-user-account" [
  user_id: int
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
    path: "/{userId}/freeze-account"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/make-proofreader
#
# Returns: record<status: string>
# operationId: makeUserProofreader
export def "make-user-proofreader" [
  user_id: int
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
    path: "/{userId}/make-proofreader"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/notifications/subscribe
#
# Returns: record<status: string>
# operationId: subscribeUserNotification
export def "subscribe-user-notification" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/notifications/subscribe"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: device, var: device}, {name: endpoint, var: endpoint}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, device: $device, endpoint: $endpoint, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/notifications/unsubscribe
#
# Returns: record<status: string>
# operationId: unsubscribeUserNotification
export def "unsubscribe-user-notification" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/notifications/unsubscribe"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: device, var: device}, {name: endpoint, var: endpoint}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, device: $device, endpoint: $endpoint, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View user's payment and billing info
#
# GET /{userId}/payment
# Returns: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>>
# operationId: getUserPaymentInfo
export def "get-user-payment-info" [
  user_id: int
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
    path: "/{userId}/payment"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user payment info
#
# POST /{userId}/payment
# Returns: record<status: string>
# operationId: updateUserPaymentInfo
export def "update-user-payment-info" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing: record # shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string, name?: string}
  --card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --cards: list # item shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --corporate: record # shape: {allow_api_invoicing?: bool, allow_payment_code?: bool, auto_charge?: bool, billing?: record, card?: record, contact_email_address?: string, payment_code?: string}
  --shared-card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/payment"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing, var: billing}, {name: card, var: card}, {name: cards, var: cards}, {name: corporate, var: corporate}, {name: shared_card, var: shared_card}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, billing: $billing, card: $card, cards: $cards, corporate: $corporate, shared_card: $shared_card
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of permissions that this user is authorized for.
#
# GET /{userId}/permissions
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>>
# operationId: getUserPermissions
export def "get-user-permissions" [
  user_id: int
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
    path: "/{userId}/permissions"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/profile-picture
#
# Returns: record<status: string>
# operationId: uploadUserProfilePicture
export def "upload-user-profile-picture" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/profile-picture"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: profile_picture, var: profile_picture}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, profile_picture: $profile_picture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user/vendor projects
#
# GET /{userId}/projects/vendor
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>>
# operationId: getVendorProjectsByUserId
export def "get-vendor-projects-by-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{userId}/projects/vendor"
    path_params: [{name: userId, var: user_id}]
    query: [{name: joined, var: joined}, {name: completed, var: completed}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, joined: $joined, completed: $completed, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/reject
#
# Returns: record<status: string>
# operationId: rejectVendorApplication
export def "reject-vendor-application" [
  user_id: int
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
    path: "/{userId}/reject"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends email confirmation email for a user
#
# POST /{userId}/resend-email-confirmation
# Returns: record<status: string>
# operationId: sendUserEmailConfirmation
export def "send-user-email-confirmation" [
  user_id: int
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
    path: "/{userId}/resend-email-confirmation"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user's vendor responsivity stats
#
# GET /{userId}/responsivity
# Returns: record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>>
# operationId: getUserResponsivity
export def "get-user-responsivity" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Period for calcualtion. (default: monthly)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{userId}/responsivity"
    path_params: [{name: userId, var: user_id}]
    query: [{name: period, var: period}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, period: $period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user's client and vendor statistics. This used to be called "summary" (\@deprecated).
#
# GET /{userId}/stats
# Returns: record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>>
# operationId: getUserStats
export def "get-user-stats" [
  user_id: int
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
    path: "/{userId}/stats"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the language pairs that the user has ordered most.
#
# GET /{userId}/stats/popular-pairs
# Returns: record<pairs: table<source_language: string, target_language: string>>
# operationId: getUserPopularPairs
export def "get-user-popular-pairs" [
  user_id: int
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
    path: "/{userId}/stats/popular-pairs"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user's project statistics.
#
# GET /{userId}/stats/projects
# Returns: record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>>
# operationId: getUserProjectStats
export def "get-user-project-stats" [
  user_id: int
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
    path: "/{userId}/stats/projects"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/suspend
#
# Returns: record<status: string>
# operationId: suspendUser
export def "suspend-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Suspension reason for vendor
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/suspend"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfreeze requester account for project notifications
#
# POST /{userId}/unfreeze-account
# Returns: record<status: string>
# operationId: unfreezeUserAccount
export def "unfreeze-user-account" [
  user_id: int
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
    path: "/{userId}/unfreeze-account"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of user groups that this user belongs to.
#
# GET /{userId}/user-groups
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>
# operationId: getThisUserGroups
export def "get-this-user-groups" [
  user_id: int
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
    path: "/{userId}/user-groups"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /{userId}/user-groups
#
# Returns: record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>>
# operationId: updateUserGroup
export def "update-user-group" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website. (spec name: token)
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{userId}/user-groups"
    path_params: [{name: userId, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_hash_in_url, var: allow_hash_in_url}, {name: allow_query_in_url, var: allow_query_in_url}, {name: auto_detect_source_language, var: auto_detect_source_language}, {name: created_at, var: created_at}, {name: elements, var: elements}, {name: follow_user, var: follow_user}, {name: force_cache_refresh_interval, var: force_cache_refresh_interval}, {name: id, var: id}, {name: language_mappings, var: language_mappings}, {name: live, var: live}, {name: modify_links, var: modify_links}, {name: name, var: name}, {name: optimize_per_page, var: optimize_per_page}, {name: pages, var: pages}, {name: path_regex, var: path_regex}, {name: position, var: position}, {name: query_name, var: query_name}, {name: reboot_on_url_change, var: reboot_on_url_change}, {name: restricted_domains, var: restricted_domains}, {name: sections, var: sections}, {name: test_mode, var: test_mode}, {name: theme, var: theme}, {name: token, var: body_token}, {name: url_change_mode, var: url_change_mode}, {name: url_mode, var: url_mode}, {name: use_cache, var: use_cache}, {name: use_dummy_translations, var: use_dummy_translations}, {name: variables, var: variables}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, body_token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $variables
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
