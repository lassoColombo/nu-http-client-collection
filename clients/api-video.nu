# Auto-generated client for api.video v1
# Source: https://api.apis.guru/v2/specs/api.video/1/openapi.json
# Auth: --token flag or $env.API_VIDEO_TOKEN

const CLIENT = {
  base_url: "https://ws.api.video"
  token_env_var: "API_VIDEO_TOKEN"
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

def base-url-completer [] { ["https://ws.api.video"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def sort-order-completer [] { ["asc" "desc"] }
def sort-by-completer [] { ["createdAt" "updatedAt"] }
def sort-by-completer-1 [] { ["createdAt" "ttl"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-account: "record<environment: string, features: list<string>, quota: record<quotaRemaining: float, quotaTotal: float, quotaUsed: float>>"
    get-analytics-live-streams-live-stream-id: "record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    get-analytics-sessions-session-id-events: "record<data: table<at: int, emittedAt: string, from: int, to: int, type: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    get-analytics-videos-video-id: "record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-auth-api-key: "record<access_token: string, expires_in: int, refresh_token: string, token_type: string>"
    post-auth-refresh: "record<access_token: string, expires_in: int, refresh_token: string, token_type: string>"
    get-live-streams: "record<data: table<assets: record, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-live-streams: "record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>"
    get-live-streams-live-stream-id: "record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>"
    patch-live-streams-live-stream-id: "record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>"
    delete-live-streams-live-stream-id-thumbnail: "record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>"
    post-live-streams-live-stream-id-thumbnail: "record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>"
    get-players: "record<data: table<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-players: "record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>"
    get-players-player-id: "record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>"
    patch-players-player-id: "record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>"
    delete-players-player-id-logo: "record"
    post-players-player-id-logo: "record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>"
    post-upload: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    get-upload-tokens: "record<data: table<createdAt: string, expiresAt: string, token: string, ttl: int>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-upload-tokens: "record<createdAt: string, expiresAt: string, token: string, ttl: int>"
    get-upload-tokens-upload-token: "record<createdAt: string, expiresAt: string, token: string, ttl: int>"
    list-videos: "record<data: table<assets: record, description: string, metadata: list, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record, tags: list, title: string, updatedAt: string, videoId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-video: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    get-video: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    patch-video: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    get-videos-video-id-captions: "record<data: table<default: bool, src: string, srclang: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    get-videos-video-id-captions-language: "record<default: bool, src: string, srclang: string, uri: string>"
    patch-videos-video-id-captions-language: "record<default: bool, src: string, srclang: string, uri: string>"
    post-videos-video-id-captions-language: "record<default: bool, src: string, srclang: string, uri: string>"
    get-videos-video-id-chapters: "record<data: table<language: string, src: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    get-videos-video-id-chapters-language: "record<language: string, src: string, uri: string>"
    post-videos-video-id-chapters-language: "record<language: string, src: string, uri: string>"
    post-videos-video-id-source: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    get-video-status: "record<encoding: record<metadata: record<aspectRatio: string, audioCodec: string, bitrate: float, duration: int, framerate: int, height: int, samplerate: int, videoCodec: string, width: int>, playable: bool, qualities: list<record>>, ingest: record<filesize: int, receivedBytes: list<record>, status: string>>"
    patch-videos-video-id-thumbnail: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    post-videos-video-id-thumbnail: "record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>"
    list-webhooks: "record<data: table<createdAt: string, events: list, url: string, webhookId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>"
    post-webhooks: "record<createdAt: string, events: list<string>, url: string, webhookId: string>"
    get-webhook: "record<createdAt: string, events: list<string>, url: string, webhookId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-account" "get-analytics-live-streams-live-stream-id" "get-analytics-sessions-session-id-events" "get-analytics-videos-video-id" "post-auth-api-key" "post-auth-refresh" "get-live-streams" "post-live-streams" "delete-live-streams-live-stream-id" "get-live-streams-live-stream-id" "patch-live-streams-live-stream-id" "delete-live-streams-live-stream-id-thumbnail" "post-live-streams-live-stream-id-thumbnail" "get-players" "post-players" "delete-players-player-id" "get-players-player-id" "patch-players-player-id" "delete-players-player-id-logo" "post-players-player-id-logo" "post-upload" "get-upload-tokens" "post-upload-tokens" "delete-upload-tokens-upload-token" "get-upload-tokens-upload-token" "list-videos" "post-video" "delete-video" "get-video" "patch-video" "get-videos-video-id-captions" "delete-videos-video-id-captions-language" "get-videos-video-id-captions-language" "patch-videos-video-id-captions-language" "post-videos-video-id-captions-language" "get-videos-video-id-chapters" "delete-videos-video-id-chapters-language" "get-videos-video-id-chapters-language" "post-videos-video-id-chapters-language" "post-videos-video-id-source" "get-video-status" "patch-videos-video-id-thumbnail" "post-videos-video-id-thumbnail" "list-webhooks" "post-webhooks" "delete-webhook" "get-webhook" "commands"] | sort) } | get name | first)
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

# Show account
#
# GET /account
# DEPRECATED
# Returns: record<environment: string, features: list<string>, quota: record<quotaRemaining: float, quotaTotal: float, quotaUsed: float>>
# operationId: GET_account
@deprecated
export def "get-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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

# List live stream player sessions
#
# GET /analytics/live-streams/{liveStreamId}
# Returns: record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_analytics-live-streams-liveStreamId
export def "get-analytics-live-streams-live-stream-id" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Period must have one of the following formats: - For a day : "2018-01-01", - For a week: "2018-W01", - For a month: "2018-01" - For a year: "2018" For a range period: - Date range: "2018-01-01/2018-01-15" (format: period, e.g. 2019-01-01)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analytics/live-streams/{liveStreamId}"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    query: [{name: period, var: period}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    live_stream_id: $live_stream_id, period: $period, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List player session events
#
# GET /analytics/sessions/{sessionId}/events
# Returns: record<data: table<at: int, emittedAt: string, from: int, to: int, type: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_analytics-sessions-sessionId-events
export def "get-analytics-sessions-session-id-events" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analytics/sessions/{sessionId}/events"
    path_params: [{name: sessionId, var: session_id}]
    query: [{name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    session_id: $session_id, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video player sessions
#
# GET /analytics/videos/{videoId}
# Returns: record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_analytics-videos-videoId
export def "get-analytics-videos-video-id" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Period must have one of the following formats: - For a day : 2018-01-01, - For a week: 2018-W01, - For a month: 2018-01 - For a year: 2018 For a range period: - Date range: 2018-01-01/2018-01-15 (format: period)
  --metadata: list<string> # Metadata and [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) filter. Send an array of key value pairs you want to filter sessios with. (e.g. [{"key": "Author", "value": "John Doe"}, {"key": "Format", "value": "Tutorial"}])
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analytics/videos/{videoId}"
    path_params: [{name: videoId, var: video_id}]
    query: [{name: period, var: period}, {name: metadata, var: metadata, style: multi}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, period: $period, metadata: $metadata, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate
#
# POST /auth/api-key
# Returns: record<access_token: string, expires_in: int, refresh_token: string, token_type: string>
# operationId: POST_auth-api-key
export def "post-auth-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # Your account API key. You can use your sandbox API key, or you can use your production API key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/api-key"
    body: {content_type: "application/json", kind: json, fields: [{name: apiKey, var: api_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh token
#
# POST /auth/refresh
# Returns: record<access_token: string, expires_in: int, refresh_token: string, token_type: string>
# operationId: POST_auth-refresh
export def "post-auth-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string # The refresh token is either the first refresh token you received when you authenticated with the auth/api-key endpoint, or it's the refresh token from the last time you used the auth/refresh endpoint. Place this in the body of your request to obtain a new access token (which is valid for an hour) and a new refresh token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/refresh"
    body: {content_type: "application/json", kind: json, fields: [{name: refreshToken, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all live streams
#
# GET /live-streams
# Returns: record<data: table<assets: record, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_live-streams
export def "get-live-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream-key: string # The unique stream key that allows you to stream videos. (e.g. 30087931-229e-42cf-b5f9-e91bcc1f7332)
  --name: string # You can filter live streams by their name or a part of their name. (e.g. My Video)
  --sort-by: string # Allowed: createdAt, publishedAt, name. createdAt - the time a livestream was created using the specified streamKey. publishedAt - the time a livestream was published using the specified streamKey. name - the name of the livestream. If you choose one of the time based options, the time is presented in ISO-8601 format. (e.g. createdAt)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending for date and time means that earlier values precede later ones. Descending means that later values preced earlier ones. For title, it is 0-9 and A-Z ascending and Z-A, 9-0 descending. (e.g. desc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/live-streams"
    query: [{name: streamKey, var: stream_key}, {name: name, var: name}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    stream_key: $stream_key, name: $name, sort_by: $sort_by, sort_order: $sort_order, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create live stream
#
# POST /live-streams
# Returns: record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>
# operationId: POST_live-streams
export def "post-live-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Add a name for your live stream here. (e.g. My Live Stream Video)
  --player-id: string # The unique identifier for the player. (e.g. pl4f4ferf5erfr5zed4fsdd)
  --public: oneof<nothing, bool> # BETA FEATURE Please limit all public = false ("private") livestreams to 3,000 users. Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view.
  --record: oneof<nothing, bool> # Whether you are recording or not. True for record, false for not record. (default: false, e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/live-streams"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: playerId, var: player_id}, {name: public, var: public}, {name: record, var: record}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, player_id: $player_id, public: $public, record: $record
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a live stream
#
# DELETE /live-streams/{liveStreamId}
# operationId: DELETE_live-streams-liveStreamId
export def "delete-live-streams-live-stream-id" [
  live_stream_id: string
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
    path: "/live-streams/{liveStreamId}"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    live_stream_id: $live_stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show live stream
#
# GET /live-streams/{liveStreamId}
# Returns: record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>
# operationId: GET_live-streams-liveStreamId
export def "get-live-streams-live-stream-id" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/live-streams/{liveStreamId}"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    live_stream_id: $live_stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a live stream
#
# PATCH /live-streams/{liveStreamId}
# Returns: record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>
# operationId: PATCH_live-streams-liveStreamId
export def "patch-live-streams-live-stream-id" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name you want to use for your live stream. (e.g. My Live Stream Video)
  --player-id: string # The unique ID for the player associated with a live stream that you want to update. (e.g. pl45KFKdlddgk654dspkze)
  --public: oneof<nothing, bool> # BETA FEATURE Please limit all public = false ("private") livestreams to 3,000 users. Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view.
  --record: oneof<nothing, bool> # Use this to indicate whether you want the recording on or off. On is true, off is false. (e.g. true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/live-streams/{liveStreamId}"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: playerId, var: player_id}, {name: public, var: public}, {name: record, var: record}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    live_stream_id: $live_stream_id, name: $name, player_id: $player_id, public: $public, record: $record
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a thumbnail
#
# DELETE /live-streams/{liveStreamId}/thumbnail
# Returns: record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>
# operationId: DELETE_live-streams-liveStreamId-thumbnail
export def "delete-live-streams-live-stream-id-thumbnail" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/live-streams/{liveStreamId}/thumbnail"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    live_stream_id: $live_stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a thumbnail
#
# POST /live-streams/{liveStreamId}/thumbnail
# Returns: record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>
# operationId: POST_live-streams-liveStreamId-thumbnail
export def "post-live-streams-live-stream-id-thumbnail" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The image to be added as a thumbnail. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/live-streams/{liveStreamId}/thumbnail"
    path_params: [{name: liveStreamId, var: live_stream_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    live_stream_id: $live_stream_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all players
#
# GET /players
# Returns: record<data: table<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_players
export def "get-players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # createdAt is the time the player was created. updatedAt is the time the player was last updated. The time is presented in ISO-8601 format. (e.g. createdAt)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending for date and time means that earlier values precede later ones. Descending means that later values preced earlier ones. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/players"
    query: [{name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, sort_order: $sort_order, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a player
#
# POST /players
# Returns: record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>
# operationId: POST_players
export def "post-players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background-bottom: string # RGBA color: bottom 50% of background. Default: rgba(0, 0, 0, .7)
  --background-text: string # RGBA color for title text. Default: rgba(255, 255, 255, 1)
  --background-top: string # RGBA color: top 50% of background. Default: rgba(0, 0, 0, .7)
  --enable-api: oneof<nothing, bool> # enable/disable player SDK access. Default: true (default: true)
  --enable-controls: oneof<nothing, bool> # enable/disable player controls. Default: true (default: true)
  --force-autoplay: oneof<nothing, bool> # enable/disable player autoplay. Default: false (default: false)
  --force-loop: oneof<nothing, bool> # enable/disable looping. Default: false (default: false)
  --hide-title: oneof<nothing, bool> # enable/disable title. Default: false (default: false)
  --link: string # RGBA color for all controls. Default: rgba(255, 255, 255, 1)
  --link-hover: string # RGBA color for all controls when hovered. Default: rgba(255, 255, 255, 1)
  --text: string # RGBA color for timer text. Default: rgba(255, 255, 255, 1)
  --track-background: string # RGBA color playback bar: background. Default: rgba(255, 255, 255, .2)
  --track-played: string # RGBA color playback bar: played content. Default: rgba(88, 131, 255, .95)
  --track-unplayed: string # RGBA color playback bar: downloaded but unplayed (buffered) content. Default: rgba(255, 255, 255, .35)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/players"
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundBottom, var: background_bottom}, {name: backgroundText, var: background_text}, {name: backgroundTop, var: background_top}, {name: enableApi, var: enable_api}, {name: enableControls, var: enable_controls}, {name: forceAutoplay, var: force_autoplay}, {name: forceLoop, var: force_loop}, {name: hideTitle, var: hide_title}, {name: link, var: link}, {name: linkHover, var: link_hover}, {name: text, var: text}, {name: trackBackground, var: track_background}, {name: trackPlayed, var: track_played}, {name: trackUnplayed, var: track_unplayed}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    background_bottom: $background_bottom, background_text: $background_text, background_top: $background_top, enable_api: $enable_api, enable_controls: $enable_controls, force_autoplay: $force_autoplay, force_loop: $force_loop, hide_title: $hide_title, link: $link, link_hover: $link_hover, text: $text, track_background: $track_background, track_played: $track_played, track_unplayed: $track_unplayed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a player
#
# DELETE /players/{playerId}
# operationId: DELETE_players-playerId
export def "delete-players-player-id" [
  player_id: string
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
    path: "/players/{playerId}"
    path_params: [{name: playerId, var: player_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a player
#
# GET /players/{playerId}
# Returns: record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>
# operationId: GET_players-playerId
export def "get-players-player-id" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/players/{playerId}"
    path_params: [{name: playerId, var: player_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a player
#
# PATCH /players/{playerId}
# Returns: record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>
# operationId: PATCH_players-playerId
export def "patch-players-player-id" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background-bottom: string # RGBA color: bottom 50% of background. Default: rgba(0, 0, 0, .7)
  --background-text: string # RGBA color for title text. Default: rgba(255, 255, 255, 1)
  --background-top: string # RGBA color: top 50% of background. Default: rgba(0, 0, 0, .7)
  --enable-api: oneof<nothing, bool> # enable/disable player SDK access. Default: true (default: true)
  --enable-controls: oneof<nothing, bool> # enable/disable player controls. Default: true (default: true)
  --force-autoplay: oneof<nothing, bool> # enable/disable player autoplay. Default: false (default: false)
  --force-loop: oneof<nothing, bool> # enable/disable looping. Default: false (default: false)
  --hide-title: oneof<nothing, bool> # enable/disable title. Default: false (default: false)
  --link: string # RGBA color for all controls. Default: rgba(255, 255, 255, 1)
  --link-hover: string # RGBA color for all controls when hovered. Default: rgba(255, 255, 255, 1)
  --text: string # RGBA color for timer text. Default: rgba(255, 255, 255, 1)
  --track-background: string # RGBA color playback bar: background. Default: rgba(255, 255, 255, .2)
  --track-played: string # RGBA color playback bar: played content. Default: rgba(88, 131, 255, .95)
  --track-unplayed: string # RGBA color playback bar: downloaded but unplayed (buffered) content. Default: rgba(255, 255, 255, .35)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/players/{playerId}"
    path_params: [{name: playerId, var: player_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundBottom, var: background_bottom}, {name: backgroundText, var: background_text}, {name: backgroundTop, var: background_top}, {name: enableApi, var: enable_api}, {name: enableControls, var: enable_controls}, {name: forceAutoplay, var: force_autoplay}, {name: forceLoop, var: force_loop}, {name: hideTitle, var: hide_title}, {name: link, var: link}, {name: linkHover, var: link_hover}, {name: text, var: text}, {name: trackBackground, var: track_background}, {name: trackPlayed, var: track_played}, {name: trackUnplayed, var: track_unplayed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    player_id: $player_id, background_bottom: $background_bottom, background_text: $background_text, background_top: $background_top, enable_api: $enable_api, enable_controls: $enable_controls, force_autoplay: $force_autoplay, force_loop: $force_loop, hide_title: $hide_title, link: $link, link_hover: $link_hover, text: $text, track_background: $track_background, track_played: $track_played, track_unplayed: $track_unplayed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete logo
#
# DELETE /players/{playerId}/logo
# Returns: record
# operationId: DELETE_players-playerId-logo
export def "delete-players-player-id-logo" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/players/{playerId}/logo"
    path_params: [{name: playerId, var: player_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    player_id: $player_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a logo
#
# POST /players/{playerId}/logo
# Returns: record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>
# operationId: POST_players-playerId-logo
export def "post-players-player-id-logo" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The name of the file you want to use for your logo. (format: binary, e.g. mylogo.jpg)
  link: string # The path to the file you want to upload and use as a logo. (format: string, e.g. path/to/my/logo/mylogo.jpg)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/players/{playerId}/logo"
    path_params: [{name: playerId, var: player_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: link, var: link}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    player_id: $player_id, file: $file, link: $link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload with an upload token
#
# POST /upload
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: POST_upload
export def "post-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The unique identifier for the token you want to use to upload a video. (required, e.g. to1tcmSFHeYY5KzyhOqVKMKb) (spec name: token)
  --content-range: string # Content-Range represents the range of bytes that will be returned as a result of the request. Byte ranges are inclusive, meaning that bytes 0-999 represents the first 1000 bytes in a file or object. (e.g. Content-Range: bytes 200-100/5000)
  file: string # The path to the video you want to upload. (format: binary, e.g. path/to/video/video.mp4)
  --video-id: string # The video id returned by the first call to this endpoint in a large video upload scenario.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/upload"
    query: [{name: token, var: qp_token, required: true}]
    header: [{name: Content-Range, var: content_range}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: videoId, var: video_id}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    qp_token: $qp_token, content_range: $content_range, file: $file, video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all active upload tokens.
#
# GET /upload-tokens
# Returns: record<data: table<createdAt: string, expiresAt: string, token: string, ttl: int>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_upload-tokens
export def "get-upload-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer-1 # Allowed: createdAt, ttl. You can use these to sort by when a token was created, or how much longer the token will be active (ttl - time to live). Date and time is presented in ISO-8601 format. (e.g. ttl)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending is 0-9 or A-Z. Descending is 9-0 or Z-A. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/upload-tokens"
    query: [{name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, sort_order: $sort_order, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate an upload token
#
# POST /upload-tokens
# Returns: record<createdAt: string, expiresAt: string, token: string, ttl: int>
# operationId: POST_upload-tokens
export def "post-upload-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # Time in seconds that the token will be active. A value of 0 means that the token has no exipration date. The default is to have no expiration. (default: 0)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/upload-tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an upload token
#
# DELETE /upload-tokens/{uploadToken}
# operationId: DELETE_upload-tokens-uploadToken
export def "delete-upload-tokens-upload-token" [
  upload_token: string
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
    path: "/upload-tokens/{uploadToken}"
    path_params: [{name: uploadToken, var: upload_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    upload_token: $upload_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show upload token
#
# GET /upload-tokens/{uploadToken}
# Returns: record<createdAt: string, expiresAt: string, token: string, ttl: int>
# operationId: GET_upload-tokens-uploadToken
export def "get-upload-tokens-upload-token" [
  upload_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/upload-tokens/{uploadToken}"
    path_params: [{name: uploadToken, var: upload_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    upload_token: $upload_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all videos
#
# GET /videos
# Returns: record<data: table<assets: record, description: string, metadata: list, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record, tags: list, title: string, updatedAt: string, videoId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: LIST-videos
export def "list-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of a specific video you want to find. The search will match exactly to what term you provide and return any videos that contain the same term as part of their titles. (e.g. My Video.mp4)
  --tags: list<string> # A tag is a category you create and apply to videos. You can search for videos with particular tags by listing one or more here. Only videos that have all the tags you list will be returned. (e.g. "tags": ["captions", "dialogue"])
  --metadata: list<string> # Videos can be tagged with metadata tags in key:value pairs. You can search for videos with specific key value pairs using this parameter. [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) allows you to define a key that allows any value pair. (e.g. [{"key":"Author", "value":"John Doe"}, {"key":"Format", "value":"Tutorial"}])
  --description: string # If you described a video with a term or sentence, you can add it here to return videos containing this string. (e.g. New Zealand)
  --live-stream-id: string # If you know the ID for a live stream, you can retrieve the stream by adding the ID for it here. (e.g. li400mYKSgQ6xs7taUeSaEKr)
  --sort-by: string # Allowed: publishedAt, title. You can search by the time videos were published at, or by title. (e.g. publishedAt)
  --sort-order: string # Allowed: asc, desc. asc is ascending and sorts from A to Z. desc is descending and sorts from Z to A. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/videos"
    query: [{name: title, var: title}, {name: tags, var: tags, style: multi}, {name: metadata, var: metadata, style: multi}, {name: description, var: description}, {name: liveStreamId, var: live_stream_id}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, tags: $tags, metadata: $metadata, description: $description, live_stream_id: $live_stream_id, sort_by: $sort_by, sort_order: $sort_order, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a video
#
# POST /videos
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: POST-video
export def "post-video" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A brief description of your video. (e.g. A video about string theory.)
  --metadata: list # A list of key value pairs that you use to provide metadata for your video. These pairs can be made dynamic, allowing you to segment your audience. Read more on [dynamic metadata](https://api.video/blog/endpoints/dynamic-metadata). (e.g. [{"key": "Author", "value": "John Doe"}]) — item shape: {key?: string, value?: string}
  --mp4-support: oneof<nothing, bool> # Enables mp4 version in addition to streamed version. (default: true, e.g. true)
  --panoramic: oneof<nothing, bool> # Indicates if your video is a 360/immersive video. (default: false, e.g. false)
  --player-id: string # The unique identification number for your video player. (e.g. pl45KFKdlddgk654dspkze)
  --public: oneof<nothing, bool> # Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view. Default is true. Tutorials on [private videos](https://api.video/blog/endpoints/private-videos). (default: true, e.g. true)
  --published-at: string # The API uses ISO-8601 format for time, and includes 3 places for milliseconds. (format: date-time, e.g. 2020-07-14T23:36:18.598Z)
  --source: string # If you add a video already on the web, this is where you enter the url for the video. (e.g. https://www.myvideo.url.com/video.mp4)
  --tags: list<string> # A list of tags you want to use to describe your video. (e.g. ["maths", "string theory", "video"])
  title: string # The title of your new video. (e.g. Maths video)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: metadata, var: metadata}, {name: mp4Support, var: mp4_support}, {name: panoramic, var: panoramic}, {name: playerId, var: player_id}, {name: public, var: public}, {name: publishedAt, var: published_at}, {name: source, var: source}, {name: tags, var: tags}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: bearer
  } {
    description: $description, metadata: $metadata, mp4_support: $mp4_support, panoramic: $panoramic, player_id: $player_id, public: $public, published_at: $published_at, source: $source, tags: $tags, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a video
#
# DELETE /videos/{videoId}
# operationId: DELETE-video
export def "delete-video" [
  video_id: string
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
    path: "/videos/{videoId}"
    path_params: [{name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a video
#
# GET /videos/{videoId}
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: GET-video
export def "get-video" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/videos/{videoId}"
    path_params: [{name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a video
#
# PATCH /videos/{videoId}
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: PATCH-video
export def "patch-video" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A brief description of the video. (e.g. A film about good books.)
  --metadata: list # A list (array) of dictionaries where each dictionary contains a key value pair that describes the video. As with tags, you must send the complete list of metadata you want as whatever you send here will overwrite the existing metadata for the video. [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) allows you to define a key that allows any value pair. — item shape: {key?: string, value?: string}
  --mp4-support: oneof<nothing, bool> # Whether the player supports the mp4 format. (e.g. true)
  --panoramic: oneof<nothing, bool> # Whether the video is a 360 degree or immersive video. (e.g. false)
  --player-id: string # The unique ID for the player you want to associate with your video. (e.g. pl4k0jvEUuaTdRAEjQ4Jfrgz)
  --public: oneof<nothing, bool> # Whether the video is publicly available or not. False means it is set to private. Default is true. Tutorials on [private videos](https://api.video/blog/endpoints/private-videos). (e.g. true)
  --tags: list<string> # A list of terms or words you want to tag the video with. Make sure the list includes all the tags you want as whatever you send in this list will overwrite the existing list for the video. (e.g. ["maths", "string theory", "video"])
  --title: string # The title you want to use for your video.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{videoId}"
    path_params: [{name: videoId, var: video_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: metadata, var: metadata}, {name: mp4Support, var: mp4_support}, {name: panoramic, var: panoramic}, {name: playerId, var: player_id}, {name: public, var: public}, {name: tags, var: tags}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, description: $description, metadata: $metadata, mp4_support: $mp4_support, panoramic: $panoramic, player_id: $player_id, public: $public, tags: $tags, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video captions
#
# GET /videos/{videoId}/captions
# Returns: record<data: table<default: bool, src: string, srclang: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_videos-videoId-captions
export def "get-videos-video-id-captions" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{videoId}/captions"
    path_params: [{name: videoId, var: video_id}]
    query: [{name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a caption
#
# DELETE /videos/{videoId}/captions/{language}
# operationId: DELETE_videos-videoId-captions-language
export def "delete-videos-video-id-captions-language" [
  video_id: string
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
    method: delete
    path: "/videos/{videoId}/captions/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a caption
#
# GET /videos/{videoId}/captions/{language}
# Returns: record<default: bool, src: string, srclang: string, uri: string>
# operationId: GET_videos-videoId-captions-language
export def "get-videos-video-id-captions-language" [
  video_id: string
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
    path: "/videos/{videoId}/captions/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update caption
#
# PATCH /videos/{videoId}/captions/{language}
# Returns: record<default: bool, src: string, srclang: string, uri: string>
# operationId: PATCH_videos-videoId-captions-language
export def "patch-videos-video-id-captions-language" [
  video_id: string
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
  --default: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{videoId}/captions/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, language: $language, default: $default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a caption
#
# POST /videos/{videoId}/captions/{language}
# Returns: record<default: bool, src: string, srclang: string, uri: string>
# operationId: POST_videos-videoId-captions-language
export def "post-videos-video-id-captions-language" [
  video_id: string
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
  file: string # The video text track (VTT) you want to upload. (format: binary, e.g. https://cdn.api.video/vod/vi3N6cDinStg3oBbN79GklWS/captions/en.vtt)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{videoId}/captions/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, language: $language, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List video chapters
#
# GET /videos/{videoId}/chapters
# Returns: record<data: table<language: string, src: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: GET_videos-videoId-chapters
export def "get-videos-video-id-chapters" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/videos/{videoId}/chapters"
    path_params: [{name: videoId, var: video_id}]
    query: [{name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a chapter
#
# DELETE /videos/{videoId}/chapters/{language}
# operationId: DELETE_videos-videoId-chapters-language
export def "delete-videos-video-id-chapters-language" [
  video_id: string
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
    method: delete
    path: "/videos/{videoId}/chapters/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    video_id: $video_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show a chapter
#
# GET /videos/{videoId}/chapters/{language}
# Returns: record<language: string, src: string, uri: string>
# operationId: GET_videos-videoId-chapters-language
export def "get-videos-video-id-chapters-language" [
  video_id: string
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
    path: "/videos/{videoId}/chapters/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a chapter
#
# POST /videos/{videoId}/chapters/{language}
# Returns: record<language: string, src: string, uri: string>
# operationId: POST_videos-videoId-chapters-language
export def "post-videos-video-id-chapters-language" [
  video_id: string
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
  file: string # The VTT file describing the chapters you want to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{videoId}/chapters/{language}"
    path_params: [{name: videoId, var: video_id}, {name: language, var: language}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, language: $language, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a video
#
# POST /videos/{videoId}/source
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: POST_videos-videoId-source
export def "post-videos-video-id-source" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range represents the range of bytes that will be returned as a result of the request. Byte ranges are inclusive, meaning that bytes 0-999 represents the first 1000 bytes in a file or object. (e.g. Content-Range: bytes 200-100/5000)
  file: string # The path to the video you would like to upload. The path must be local. If you want to use a video from an online source, you must use the "/videos" endpoint and add the "source" parameter when you create a new video. (format: binary, e.g. @/path/to/video.mp4)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{videoId}/source"
    path_params: [{name: videoId, var: video_id}]
    header: [{name: Content-Range, var: content_range}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    video_id: $video_id, content_range: $content_range, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show video status
#
# GET /videos/{videoId}/status
# Returns: record<encoding: record<metadata: record<aspectRatio: string, audioCodec: string, bitrate: float, duration: int, framerate: int, height: int, samplerate: int, videoCodec: string, width: int>, playable: bool, qualities: list<record>>, ingest: record<filesize: int, receivedBytes: list<record>, status: string>>
# operationId: GET-video-status
export def "get-video-status" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/videos/{videoId}/status"
    path_params: [{name: videoId, var: video_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pick a thumbnail
#
# PATCH /videos/{videoId}/thumbnail
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: PATCH_videos-videoId-thumbnail
export def "patch-videos-video-id-thumbnail" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  timecode: string # Frame in video to be used as a placeholder before the video plays. Example: '"00:01:00.000" for 1 minute into the video.' Valid Patterns: "hh:mm:ss.ms" "hh:mm:ss:frameNumber" "124" (integer value is reported as seconds) If selection is out of range, "00:00:00.00" will be chosen.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/videos/{videoId}/thumbnail"
    path_params: [{name: videoId, var: video_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: timecode, var: timecode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, timecode: $timecode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a thumbnail
#
# POST /videos/{videoId}/thumbnail
# Returns: record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string>
# operationId: POST_videos-videoId-thumbnail
export def "post-videos-video-id-thumbnail" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The image to be added as a thumbnail. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/videos/{videoId}/thumbnail"
    path_params: [{name: videoId, var: video_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    video_id: $video_id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all webhooks
#
# GET /webhooks
# Returns: record<data: table<createdAt: string, events: list, url: string, webhookId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>>
# operationId: LIST-webhooks
export def "list-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: string # The webhook event that you wish to filter on. (e.g. video.encoding.quality.completed)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: events, var: events}, {name: currentPage, var: current_page}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    events: $events, current_page: $current_page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Webhook
#
# POST /webhooks
# Returns: record<createdAt: string, events: list<string>, url: string, webhookId: string>
# operationId: POST-webhooks
export def "post-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  events: list<string> # A list of the webhooks that you are subscribing to. There are Currently four webhook options: * ```video.encoding.quality.completed``` When a new video is uploaded into your account, it will be encoded into several different HLS sizes/bitrates. When each version is encoded, your webhook will get a notification. It will look like ```{ \"type\": \"video.encoding.quality.completed\", \"emittedAt\": \"2021-01-29T16:46:25.217+01:00\", \"videoId\": \"viXXXXXXXX\", \"encoding\": \"hls\", \"quality\": \"720p\"} ```. This request says that the 720p HLS encoding was completed. * ```live-stream.broadcast.started``` When a livestream begins broadcasting, the broadcasting parameter changes from false to true, and this webhook fires. * ```live-stream.broadcast.ended``` This event fores when the livestream has finished broadcasting, and the broadcasting parameter flips from false to true. * ```video.source.recorded``` This event is similar to ```video.encoding.quality.completed```, but tells you if a livestream has been recorded as a VOD. (e.g. video.encoding.quality.completed)
  url: string # The the url to which HTTP notifications are sent. It could be any http or https URL. (e.g. https://example.com/webhooks)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    events: $events, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Webhook
#
# DELETE /webhooks/{webhookId}
# operationId: DELETE-webhook
export def "delete-webhook" [
  webhook_id: string
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
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show Webhook details
#
# GET /webhooks/{webhookId}
# Returns: record<createdAt: string, events: list<string>, url: string, webhookId: string>
# operationId: GET-Webhook
export def "get-webhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/webhooks/{webhookId}"
    path_params: [{name: webhookId, var: webhook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
