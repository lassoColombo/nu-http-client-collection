# Auto-generated client for Google Classroom API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/classroom/v1/openapi.json
# Auth: --token flag or $env.GOOGLE_CLASSROOM_API_TOKEN

const CLIENT = {
  base_url: "https://classroom.googleapis.com"
  token_env_var: "GOOGLE_CLASSROOM_API_TOKEN"
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

def base-url-completer [] { ["https://classroom.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def course-state-completer [] { ["ACTIVE" "ARCHIVED" "COURSE_STATE_UNSPECIFIED" "DECLINED" "PROVISIONED" "SUSPENDED"] }
def assignee-mode-completer [] { ["ALL_STUDENTS" "ASSIGNEE_MODE_UNSPECIFIED" "INDIVIDUAL_STUDENTS"] }
def state-completer [] { ["ANNOUNCEMENT_STATE_UNSPECIFIED" "DELETED" "DRAFT" "PUBLISHED"] }
def state-completer-1 [] { ["COURSE_WORK_STATE_UNSPECIFIED" "DELETED" "DRAFT" "PUBLISHED"] }
def submission-modification-mode-completer [] { ["MODIFIABLE" "MODIFIABLE_UNTIL_TURNED_IN" "SUBMISSION_MODIFICATION_MODE_UNSPECIFIED"] }
def work-type-completer [] { ["ASSIGNMENT" "COURSE_WORK_TYPE_UNSPECIFIED" "MULTIPLE_CHOICE_QUESTION" "SHORT_ANSWER_QUESTION"] }
def late-completer [] { ["LATE_ONLY" "LATE_VALUES_UNSPECIFIED" "NOT_LATE_ONLY"] }
def course-work-type-completer [] { ["ASSIGNMENT" "COURSE_WORK_TYPE_UNSPECIFIED" "MULTIPLE_CHOICE_QUESTION" "SHORT_ANSWER_QUESTION"] }
def state-completer-2 [] { ["CREATED" "NEW" "RECLAIMED_BY_STUDENT" "RETURNED" "SUBMISSION_STATE_UNSPECIFIED" "TURNED_IN"] }
def state-completer-3 [] { ["COURSEWORK_MATERIAL_STATE_UNSPECIFIED" "DELETED" "DRAFT" "PUBLISHED"] }
def role-completer [] { ["COURSE_ROLE_UNSPECIFIED" "OWNER" "STUDENT" "TEACHER"] }
def state-completer-4 [] { ["COMPLETE" "GUARDIAN_INVITATION_STATE_UNSPECIFIED" "PENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    classroom-courses-list: "record<courses: table<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: list, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record, teacherGroupEmail: string, updateTime: string>, nextPageToken: string>"
    classroom-courses-create: "record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>"
    classroom-courses-aliases-list: "record<aliases: table<alias: string>, nextPageToken: string>"
    classroom-courses-aliases-create: "record<alias: string>"
    classroom-courses-aliases-delete: "record"
    classroom-courses-announcements-list: "record<announcements: table<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record, materials: list, scheduledTime: string, state: string, text: string, updateTime: string>, nextPageToken: string>"
    classroom-courses-announcements-create: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>"
    classroom-courses-announcements-delete: "record"
    classroom-courses-announcements-get: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>"
    classroom-courses-announcements-patch: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>"
    classroom-courses-announcements-modify-assignees: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>"
    classroom-courses-course-work-list: "record<courseWork: table<alternateLink: string, assigneeMode: string, assignment: record, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record, dueTime: record, gradeCategory: record, id: string, individualStudentsOptions: record, materials: list, maxPoints: float, multipleChoiceQuestion: record, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>, nextPageToken: string>"
    classroom-courses-course-work-create: "record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>"
    classroom-courses-course-work-student-submissions-list: "record<nextPageToken: string, studentSubmissions: table<alternateLink: string, assignedGrade: float, assignmentSubmission: record, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record, shortAnswerSubmission: record, state: string, submissionHistory: list, updateTime: string, userId: string>>"
    classroom-courses-course-work-student-submissions-get: "record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>"
    classroom-courses-course-work-student-submissions-patch: "record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>"
    classroom-courses-course-work-student-submissions-modify-attachments: "record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>"
    classroom-courses-course-work-student-submissions-reclaim: "record"
    classroom-courses-course-work-student-submissions-return: "record"
    classroom-courses-course-work-student-submissions-turn-in: "record"
    classroom-courses-course-work-delete: "record"
    classroom-courses-course-work-get: "record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>"
    classroom-courses-course-work-patch: "record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>"
    classroom-courses-course-work-modify-assignees: "record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>"
    classroom-courses-course-work-materials-list: "record<courseWorkMaterial: table<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record, materials: list, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>, nextPageToken: string>"
    classroom-courses-course-work-materials-create: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>"
    classroom-courses-course-work-materials-delete: "record"
    classroom-courses-course-work-materials-get: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>"
    classroom-courses-course-work-materials-patch: "record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>"
    classroom-courses-students-list: "record<nextPageToken: string, students: table<courseId: string, profile: record, studentWorkFolder: record, userId: string>>"
    classroom-courses-students-create: "record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, studentWorkFolder: record<alternateLink: string, id: string, title: string>, userId: string>"
    classroom-courses-students-delete: "record"
    classroom-courses-students-get: "record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, studentWorkFolder: record<alternateLink: string, id: string, title: string>, userId: string>"
    classroom-courses-teachers-list: "record<nextPageToken: string, teachers: table<courseId: string, profile: record, userId: string>>"
    classroom-courses-teachers-create: "record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, userId: string>"
    classroom-courses-teachers-delete: "record"
    classroom-courses-teachers-get: "record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, userId: string>"
    classroom-courses-topics-list: "record<nextPageToken: string, topic: table<courseId: string, name: string, topicId: string, updateTime: string>>"
    classroom-courses-topics-create: "record<courseId: string, name: string, topicId: string, updateTime: string>"
    classroom-courses-topics-delete: "record"
    classroom-courses-topics-get: "record<courseId: string, name: string, topicId: string, updateTime: string>"
    classroom-courses-topics-patch: "record<courseId: string, name: string, topicId: string, updateTime: string>"
    classroom-courses-delete: "record"
    classroom-courses-get: "record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>"
    classroom-courses-patch: "record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>"
    classroom-courses-update: "record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>"
    classroom-invitations-list: "record<invitations: table<courseId: string, id: string, role: string, userId: string>, nextPageToken: string>"
    classroom-invitations-create: "record<courseId: string, id: string, role: string, userId: string>"
    classroom-invitations-delete: "record"
    classroom-invitations-get: "record<courseId: string, id: string, role: string, userId: string>"
    classroom-invitations-accept: "record"
    classroom-registrations-create: "record<cloudPubsubTopic: record<topicName: string>, expiryTime: string, feed: record<courseRosterChangesInfo: record<courseId: string>, courseWorkChangesInfo: record<courseId: string>, feedType: string>, registrationId: string>"
    classroom-registrations-delete: "record"
    classroom-user-profiles-guardian-invitations-list: "record<guardianInvitations: table<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>, nextPageToken: string>"
    classroom-user-profiles-guardian-invitations-create: "record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>"
    classroom-user-profiles-guardian-invitations-get: "record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>"
    classroom-user-profiles-guardian-invitations-patch: "record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>"
    classroom-user-profiles-guardians-list: "record<guardians: table<guardianId: string, guardianProfile: record, invitedEmailAddress: string, studentId: string>, nextPageToken: string>"
    classroom-user-profiles-guardians-delete: "record"
    classroom-user-profiles-guardians-get: "record<guardianId: string, guardianProfile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, invitedEmailAddress: string, studentId: string>"
    classroom-user-profiles-get: "record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: table<permission: string>, photoUrl: string, verifiedTeacher: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["classroom-courses-list" "classroom-courses-create" "classroom-courses-aliases-list" "classroom-courses-aliases-create" "classroom-courses-aliases-delete" "classroom-courses-announcements-list" "classroom-courses-announcements-create" "classroom-courses-announcements-delete" "classroom-courses-announcements-get" "classroom-courses-announcements-patch" "classroom-courses-announcements-modify-assignees" "classroom-courses-course-work-list" "classroom-courses-course-work-create" "classroom-courses-course-work-student-submissions-list" "classroom-courses-course-work-student-submissions-get" "classroom-courses-course-work-student-submissions-patch" "classroom-courses-course-work-student-submissions-modify-attachments" "classroom-courses-course-work-student-submissions-reclaim" "classroom-courses-course-work-student-submissions-return" "classroom-courses-course-work-student-submissions-turn-in" "classroom-courses-course-work-delete" "classroom-courses-course-work-get" "classroom-courses-course-work-patch" "classroom-courses-course-work-modify-assignees" "classroom-courses-course-work-materials-list" "classroom-courses-course-work-materials-create" "classroom-courses-course-work-materials-delete" "classroom-courses-course-work-materials-get" "classroom-courses-course-work-materials-patch" "classroom-courses-students-list" "classroom-courses-students-create" "classroom-courses-students-delete" "classroom-courses-students-get" "classroom-courses-teachers-list" "classroom-courses-teachers-create" "classroom-courses-teachers-delete" "classroom-courses-teachers-get" "classroom-courses-topics-list" "classroom-courses-topics-create" "classroom-courses-topics-delete" "classroom-courses-topics-get" "classroom-courses-topics-patch" "classroom-courses-delete" "classroom-courses-get" "classroom-courses-patch" "classroom-courses-update" "classroom-invitations-list" "classroom-invitations-create" "classroom-invitations-delete" "classroom-invitations-get" "classroom-invitations-accept" "classroom-registrations-create" "classroom-registrations-delete" "classroom-user-profiles-guardian-invitations-list" "classroom-user-profiles-guardian-invitations-create" "classroom-user-profiles-guardian-invitations-get" "classroom-user-profiles-guardian-invitations-patch" "classroom-user-profiles-guardians-list" "classroom-user-profiles-guardians-delete" "classroom-user-profiles-guardians-get" "classroom-user-profiles-get" "commands"] | sort) } | get name | first)
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

# Returns a list of courses that the requesting user is permitted to view, restricted to those that match the request. Returned courses are ordered by creation time, with the most recently created coming first. This method returns the following error codes: * `PERMISSION_DENIED` for access errors. * `INVALID_ARGUMENT` if the query argument is malformed. * `NOT_FOUND` if any users specified in the query arguments do not exist.
#
# GET /v1/courses
# Returns: record<courses: table<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: list, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record, teacherGroupEmail: string, updateTime: string>, nextPageToken: string>
# operationId: classroom.courses.list
export def "classroom-courses-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --course-states: list<string> # Restricts returned courses to those in one of the specified states The default value is ACTIVE, ARCHIVED, PROVISIONED, DECLINED.
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
  --student-id: string # Restricts returned courses to those having a student with the specified identifier. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
  --teacher-id: string # Restricts returned courses to those having a teacher with the specified identifier. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: courseStates, var: course_states, style: multi}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: studentId, var: student_id}, {name: teacherId, var: teacher_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, course_states: $course_states, page_size: $page_size, page_token: $page_token, student_id: $student_id, teacher_id: $teacher_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a course. The user specified in `ownerId` is the owner of the created course and added as a teacher. A non-admin requesting user can only create a course with themselves as the owner. Domain admins can create courses owned by any user within their domain. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to create courses or for access errors. * `NOT_FOUND` if the primary teacher is not a valid user. * `FAILED_PRECONDITION` if the course owner's account is disabled or for the following request errors: * UserCannotOwnCourse * UserGroupsMembershipLimitReached * `ALREADY_EXISTS` if an alias was specified in the `id` and already exists.
#
# POST /v1/courses
# Returns: record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>
# operationId: classroom.courses.create
export def "classroom-courses-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-link: string # Absolute link to this course in the Classroom web UI. Read-only.
  --calendar-id: string # The Calendar ID for a calendar that all course members can see, to which Classroom adds events for course work and announcements in the course. Read-only.
  --course-group-email: string # The email address of a Google group containing all members of the course. This group does not accept email and can only be used for permissions. Read-only.
  --course-material-sets: list # Sets of materials that appear on the "about" page of this course. Read-only. — item shape: {materials?: list, title?: string}
  --course-state: string@course-state-completer # State of the course. If unspecified, the default state is `PROVISIONED`.
  --creation-time: string # Creation time of the course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
  --description: string # Optional description. For example, "We'll be learning about the structure of living creatures from a combination of textbooks, guest lectures, and lab work. Expect to be excited!" If set, this field must be a valid UTF-8 string and no longer than 30,000 characters.
  --description-heading: string # Optional heading for the description. For example, "Welcome to 10th Grade Biology." If set, this field must be a valid UTF-8 string and no longer than 3600 characters.
  --enrollment-code: string # Enrollment code to use when joining this course. Specifying this field in a course update mask results in an error. Read-only.
  --gradebook-settings: record # The gradebook settings for a course. See the [help center article](https://support.google.com/edu/classroom/answer/9184995) for details. — shape: {calculationType?: "CALCULATION_TYPE_UNSPECIFIED"|"TOTAL_POINTS"|"WEIGHTED_CATEGORIES", displaySetting?: "DISPLAY_SETTING_UNSPECIFIED"|"SHOW_OVERALL_GRADE"|"HIDE_OVERALL_GRADE"|"SHOW_TEACHERS_ONLY", gradeCategories?: list}
  --guardians-enabled: oneof<nothing, bool> # Whether or not guardian notifications are enabled for this course. Read-only.
  --id: string # Identifier for this course assigned by Classroom. When creating a course, you may optionally set this identifier to an alias string in the request to create a corresponding alias. The `id` is still assigned by Classroom and cannot be updated after the course is created. Specifying this field in a course update mask results in an error.
  --name: string # Name of the course. For example, "10th Grade Biology". The name is required. It must be between 1 and 750 characters and a valid UTF-8 string.
  --owner-id: string # The identifier of the owner of a course. When specified as a parameter of a create course request, this field is required. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user This must be set in a create request. Admins can also specify this field in a patch course request to transfer ownership. In other contexts, it is read-only.
  --room: string # Optional room location. For example, "301". If set, this field must be a valid UTF-8 string and no longer than 650 characters.
  --section: string # Section of the course. For example, "Period 2". If set, this field must be a valid UTF-8 string and no longer than 2800 characters.
  --teacher-folder: record # Representation of a Google Drive folder. — shape: {alternateLink?: string, id?: string, title?: string}
  --teacher-group-email: string # The email address of a Google group containing all teachers of the course. This group does not accept email and can only be used for permissions. Read-only.
  --update-time: string # Time of the most recent update to this course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: calendarId, var: calendar_id}, {name: courseGroupEmail, var: course_group_email}, {name: courseMaterialSets, var: course_material_sets}, {name: courseState, var: course_state}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: descriptionHeading, var: description_heading}, {name: enrollmentCode, var: enrollment_code}, {name: gradebookSettings, var: gradebook_settings}, {name: guardiansEnabled, var: guardians_enabled}, {name: id, var: id}, {name: name, var: name}, {name: ownerId, var: owner_id}, {name: room, var: room}, {name: section, var: section}, {name: teacherFolder, var: teacher_folder}, {name: teacherGroupEmail, var: teacher_group_email}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_link: $alternate_link, calendar_id: $calendar_id, course_group_email: $course_group_email, course_material_sets: $course_material_sets, course_state: $course_state, creation_time: $creation_time, description: $description, description_heading: $description_heading, enrollment_code: $enrollment_code, gradebook_settings: $gradebook_settings, guardians_enabled: $guardians_enabled, id: $id, name: $name, owner_id: $owner_id, room: $room, section: $section, teacher_folder: $teacher_folder, teacher_group_email: $teacher_group_email, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of aliases for a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the course or for access errors. * `NOT_FOUND` if the course does not exist.
#
# GET /v1/courses/{courseId}/aliases
# Returns: record<aliases: table<alias: string>, nextPageToken: string>
# operationId: classroom.courses.aliases.list
export def "classroom-courses-aliases-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/aliases"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an alias for a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to create the alias or for access errors. * `NOT_FOUND` if the course does not exist. * `ALREADY_EXISTS` if the alias already exists. * `FAILED_PRECONDITION` if the alias requested does not make sense for the requesting user or course (for example, if a user not in a domain attempts to access a domain-scoped alias).
#
# POST /v1/courses/{courseId}/aliases
# Returns: record<alias: string>
# operationId: classroom.courses.aliases.create
export def "classroom-courses-aliases-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alias: string # Alias string. The format of the string indicates the desired alias scoping. * `d:` indicates a domain-scoped alias. Example: `d:math_101` * `p:` indicates a project-scoped alias. Example: `p:abc123` This field has a maximum length of 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/aliases"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alias: $alias
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an alias of a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to remove the alias or for access errors. * `NOT_FOUND` if the alias does not exist. * `FAILED_PRECONDITION` if the alias requested does not make sense for the requesting user or course (for example, if a user not in a domain attempts to delete a domain-scoped alias).
#
# DELETE /v1/courses/{courseId}/aliases/{alias}
# Returns: record
# operationId: classroom.courses.aliases.delete
export def "classroom-courses-aliases-delete" [
  course_id: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/aliases/{alias}"
    path_params: [{name: courseId, var: course_id}, {name: alias, var: alias}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, alias: $alias, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of announcements that the requester is permitted to view. Course students may only view `PUBLISHED` announcements. Course teachers and domain administrators may view all announcements. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# GET /v1/courses/{courseId}/announcements
# Returns: record<announcements: table<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record, materials: list, scheduledTime: string, state: string, text: string, updateTime: string>, nextPageToken: string>
# operationId: classroom.courses.announcements.list
export def "classroom-courses-announcements-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --announcement-states: list<string> # Restriction on the `state` of announcements returned. If this argument is left unspecified, the default value is `PUBLISHED`.
  --order-by: string # Optional sort ordering for results. A comma-separated list of fields with an optional sort direction keyword. Supported field is `updateTime`. Supported direction keywords are `asc` and `desc`. If not specified, `updateTime desc` is the default behavior. Examples: `updateTime asc`, `updateTime`
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/announcements"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: announcementStates, var: announcement_states, style: multi}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, announcement_states: $announcement_states, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an announcement. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course, create announcements in the requested course, share a Drive attachment, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist. * `FAILED_PRECONDITION` for the following request error: * AttachmentNotVisible
#
# POST /v1/courses/{courseId}/announcements
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>
# operationId: classroom.courses.announcements.create
export def "classroom-courses-announcements-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-link: string # Absolute link to this announcement in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the announcement. If unspecified, the default value is `ALL_STUDENTS`.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this announcement was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the announcement. Read-only.
  --id: string # Classroom-assigned identifier of this announcement, unique per course. Read-only.
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. Announcements must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --scheduled-time: string # Optional timestamp when this announcement is scheduled to be published. (format: google-datetime)
  --state: string@state-completer # Status of this announcement. If unspecified, the default state is `DRAFT`.
  --text: string # Description of this announcement. The text must be a valid UTF-8 string containing no more than 30,000 characters.
  --update-time: string # Timestamp of the most recent change to this announcement. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/announcements"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: id, var: id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: text, var: text}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_link: $alternate_link, assignee_mode: $assignee_mode, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, id: $id, individual_students_options: $individual_students_options, materials: $materials, scheduled_time: $scheduled_time, state: $state, text: $text, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an announcement. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding announcement item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding announcement, if the requesting user is not permitted to delete the requested course or for access errors. * `FAILED_PRECONDITION` if the requested announcement has already been deleted. * `NOT_FOUND` if no course exists with the requested ID.
#
# DELETE /v1/courses/{courseId}/announcements/{id}
# Returns: record
# operationId: classroom.courses.announcements.delete
export def "classroom-courses-announcements-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/announcements/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an announcement. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or announcement, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or announcement does not exist.
#
# GET /v1/courses/{courseId}/announcements/{id}
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>
# operationId: classroom.courses.announcements.get
export def "classroom-courses-announcements-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/announcements/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields of an announcement. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding announcement or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `FAILED_PRECONDITION` if the requested announcement has already been deleted. * `NOT_FOUND` if the requested course or announcement does not exist
#
# PATCH /v1/courses/{courseId}/announcements/{id}
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>
# operationId: classroom.courses.announcements.patch
export def "classroom-courses-announcements-patch" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the announcement to update. This field is required to do an update. The update fails if invalid fields are specified. If a field supports empty values, it can be cleared by specifying it in the update mask and not in the Announcement object. If a field that does not support empty values is included in the update mask and not set in the Announcement object, an `INVALID_ARGUMENT` error is returned. The following fields may be specified by teachers: * `text` * `state` * `scheduled_time`
  --alternate-link: string # Absolute link to this announcement in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the announcement. If unspecified, the default value is `ALL_STUDENTS`.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this announcement was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the announcement. Read-only.
  --body-id: string # Classroom-assigned identifier of this announcement, unique per course. Read-only. (spec name: id)
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. Announcements must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --scheduled-time: string # Optional timestamp when this announcement is scheduled to be published. (format: google-datetime)
  --state: string@state-completer # Status of this announcement. If unspecified, the default state is `DRAFT`.
  --text: string # Description of this announcement. The text must be a valid UTF-8 string containing no more than 30,000 characters.
  --update-time: string # Timestamp of the most recent change to this announcement. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{courseId}/announcements/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: id, var: body_id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: text, var: text}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, alternate_link: $alternate_link, assignee_mode: $assignee_mode, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, body_id: $body_id, individual_students_options: $individual_students_options, materials: $materials, scheduled_time: $scheduled_time, state: $state, text: $text, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies assignee mode and options of an announcement. Only a teacher of the course that contains the announcement may call this method. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or course work does not exist.
#
# POST /v1/courses/{courseId}/announcements/{id}:modifyAssignees
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, text: string, updateTime: string>
# operationId: classroom.courses.announcements.modifyAssignees
export def "classroom-courses-announcements-modify-assignees" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --assignee-mode: string@assignee-mode-completer # Mode of the announcement describing whether it is accessible by all students or specified individual students.
  --modify-individual-students-options: record # Contains fields to add or remove students from a course work or announcement where the `assigneeMode` is set to `INDIVIDUAL_STUDENTS`. — shape: {addStudentIds?: list<string>, removeStudentIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/announcements/{id}:modifyAssignees"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: assigneeMode, var: assignee_mode}, {name: modifyIndividualStudentsOptions, var: modify_individual_students_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, assignee_mode: $assignee_mode, modify_individual_students_options: $modify_individual_students_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of course work that the requester is permitted to view. Course students may only view `PUBLISHED` course work. Course teachers and domain administrators may view all course work. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# GET /v1/courses/{courseId}/courseWork
# Returns: record<courseWork: table<alternateLink: string, assigneeMode: string, assignment: record, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record, dueTime: record, gradeCategory: record, id: string, individualStudentsOptions: record, materials: list, maxPoints: float, multipleChoiceQuestion: record, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>, nextPageToken: string>
# operationId: classroom.courses.courseWork.list
export def "classroom-courses-course-work-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --course-work-states: list<string> # Restriction on the work status to return. Only courseWork that matches is returned. If unspecified, items with a work status of `PUBLISHED` is returned.
  --order-by: string # Optional sort ordering for results. A comma-separated list of fields with an optional sort direction keyword. Supported fields are `updateTime` and `dueDate`. Supported direction keywords are `asc` and `desc`. If not specified, `updateTime desc` is the default behavior. Examples: `dueDate asc,updateTime desc`, `updateTime,dueDate desc`
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWork"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: courseWorkStates, var: course_work_states, style: multi}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, course_work_states: $course_work_states, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates course work. The resulting course work (and corresponding student submissions) are associated with the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to make the request. Classroom API requests to modify course work and student submissions must be made with an OAuth client ID from the associated Developer Console project. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course, create course work in the requested course, share a Drive attachment, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist. * `FAILED_PRECONDITION` for the following request error: * AttachmentNotVisible
#
# POST /v1/courses/{courseId}/courseWork
# Returns: record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>
# operationId: classroom.courses.courseWork.create
export def "classroom-courses-course-work-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-link: string # Absolute link to this course work in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the coursework. If unspecified, the default value is `ALL_STUDENTS`.
  --assignment: record # Additional details for assignments. — shape: {studentWorkFolder?: record}
  --associated-with-developer: oneof<nothing, bool> # Whether this course work item is associated with the Developer Console project making the request. See CreateCourseWork for more details. Read-only.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this course work was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the coursework. Read-only.
  --description: string # Optional description of this course work. If set, the description must be a valid UTF-8 string containing no more than 30,000 characters.
  --due-date: record # Represents a whole or partial calendar date, such as a birthday. The time of day and time zone are either specified elsewhere or are insignificant. The date is relative to the Gregorian Calendar. This can represent one of the following: * A full date, with non-zero year, month, and day values. * A month and day, with a zero year (for example, an anniversary). * A year on its own, with a zero month and a zero day. * A year and month, with a zero day (for example, a credit card expiration date). Related types: * google.type.TimeOfDay * google.type.DateTime * google.protobuf.Timestamp — shape: {day?: int, month?: int, year?: int}
  --due-time: record # Represents a time of day. The date and time zone are either not significant or are specified elsewhere. An API may choose to allow leap seconds. Related types are google.type.Date and `google.protobuf.Timestamp`. — shape: {hours?: int, minutes?: int, nanos?: int, seconds?: int}
  --grade-category: record # Details for a grade category in a course. Coursework may have zero or one grade category, and the category may be used in computing the overall grade. See the [help center article](https://support.google.com/edu/classroom/answer/9184995) for details. — shape: {defaultGradeDenominator?: int, id?: string, name?: string, weight?: int}
  --id: string # Classroom-assigned identifier of this course work, unique per course. Read-only.
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. CourseWork must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --max-points: float # Maximum grade for this course work. If zero or unspecified, this assignment is considered ungraded. This must be a non-negative integer value. (format: double)
  --multiple-choice-question: record # Additional details for multiple-choice questions. — shape: {choices?: list<string>}
  --scheduled-time: string # Optional timestamp when this course work is scheduled to be published. (format: google-datetime)
  --state: string@state-completer-1 # Status of this course work. If unspecified, the default state is `DRAFT`.
  --submission-modification-mode: string@submission-modification-mode-completer # Setting to determine when students are allowed to modify submissions. If unspecified, the default value is `MODIFIABLE_UNTIL_TURNED_IN`.
  --title: string # Title of this course work. The title must be a valid UTF-8 string containing between 1 and 3000 characters.
  --topic-id: string # Identifier for the topic that this coursework is associated with. Must match an existing topic in the course.
  --update-time: string # Timestamp of the most recent change to this course work. Read-only. (format: google-datetime)
  --work-type: string@work-type-completer # Type of this course work. The type is set when the course work is created and cannot be changed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: assignment, var: assignment}, {name: associatedWithDeveloper, var: associated_with_developer}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: description, var: description}, {name: dueDate, var: due_date}, {name: dueTime, var: due_time}, {name: gradeCategory, var: grade_category}, {name: id, var: id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: maxPoints, var: max_points}, {name: multipleChoiceQuestion, var: multiple_choice_question}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: submissionModificationMode, var: submission_modification_mode}, {name: title, var: title}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}, {name: workType, var: work_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_link: $alternate_link, assignee_mode: $assignee_mode, assignment: $assignment, associated_with_developer: $associated_with_developer, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, description: $description, due_date: $due_date, due_time: $due_time, grade_category: $grade_category, id: $id, individual_students_options: $individual_students_options, materials: $materials, max_points: $max_points, multiple_choice_question: $multiple_choice_question, scheduled_time: $scheduled_time, state: $state, submission_modification_mode: $submission_modification_mode, title: $title, topic_id: $topic_id, update_time: $update_time, work_type: $work_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of student submissions that the requester is permitted to view, factoring in the OAuth scopes of the request. `-` may be specified as the `course_work_id` to include student submissions for multiple course work items. Course students may only view their own work. Course teachers and domain administrators may view all student submissions. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# GET /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions
# Returns: record<nextPageToken: string, studentSubmissions: table<alternateLink: string, assignedGrade: float, assignmentSubmission: record, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record, shortAnswerSubmission: record, state: string, submissionHistory: list, updateTime: string, userId: string>>
# operationId: classroom.courses.courseWork.studentSubmissions.list
export def "classroom-courses-course-work-student-submissions-list" [
  course_id: string
  course_work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --late: string@late-completer # Requested lateness value. If specified, returned student submissions are restricted by the requested value. If unspecified, submissions are returned regardless of `late` value.
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
  --states: list<string> # Requested submission states. If specified, returned student submissions match one of the specified submission states.
  --user-id: string # Optional argument to restrict returned student work to those owned by the student with the specified identifier. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: late, var: late}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: states, var: states, style: multi}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, late: $late, page_size: $page_size, page_token: $page_token, states: $states, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a student submission. * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course, course work, or student submission or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# GET /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}
# Returns: record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>
# operationId: classroom.courses.courseWork.studentSubmissions.get
export def "classroom-courses-course-work-student-submissions-get" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields of a student submission. See google.classroom.v1.StudentSubmission for details of which fields may be updated and who may change them. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding course work, if the user is not permitted to make the requested modification to the student submission, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# PATCH /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}
# Returns: record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>
# operationId: classroom.courses.courseWork.studentSubmissions.patch
export def "classroom-courses-course-work-student-submissions-patch" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the student submission to update. This field is required to do an update. The update fails if invalid fields are specified. The following fields may be specified by teachers: * `draft_grade` * `assigned_grade`
  --alternate-link: string # Absolute link to the submission in the Classroom web UI. Read-only.
  --assigned-grade: float # Optional grade. If unset, no grade was set. This value must be non-negative. Decimal (that is, non-integer) values are allowed, but are rounded to two decimal places. This may be modified only by course teachers. (format: double)
  --assignment-submission: record # Student work for an assignment. — shape: {attachments?: list}
  --associated-with-developer: oneof<nothing, bool> # Whether this student submission is associated with the Developer Console project making the request. See CreateCourseWork for more details. Read-only.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --body-course-work-id: string # Identifier for the course work this corresponds to. Read-only. (spec name: courseWorkId)
  --course-work-type: string@course-work-type-completer # Type of course work this submission is for. Read-only.
  --creation-time: string # Creation time of this submission. This may be unset if the student has not accessed this item. Read-only. (format: google-datetime)
  --draft-grade: float # Optional pending grade. If unset, no grade was set. This value must be non-negative. Decimal (that is, non-integer) values are allowed, but are rounded to two decimal places. This is only visible to and modifiable by course teachers. (format: double)
  --body-id: string # Classroom-assigned Identifier for the student submission. This is unique among submissions for the relevant course work. Read-only. (spec name: id)
  --late: oneof<nothing, bool> # Whether this submission is late. Read-only.
  --multiple-choice-submission: record # Student work for a multiple-choice question. — shape: {answer?: string}
  --short-answer-submission: record # Student work for a short answer question. — shape: {answer?: string}
  --state: string@state-completer-2 # State of this submission. Read-only.
  --submission-history: list # The history of the submission (includes state and grade histories). Read-only. — item shape: {gradeHistory?: record, stateHistory?: record}
  --update-time: string # Last update time of this submission. This may be unset if the student has not accessed this item. Read-only. (format: google-datetime)
  --user-id: string # Identifier for the student that owns this submission. Read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assignedGrade, var: assigned_grade}, {name: assignmentSubmission, var: assignment_submission}, {name: associatedWithDeveloper, var: associated_with_developer}, {name: courseId, var: body_course_id}, {name: courseWorkId, var: body_course_work_id}, {name: courseWorkType, var: course_work_type}, {name: creationTime, var: creation_time}, {name: draftGrade, var: draft_grade}, {name: id, var: body_id}, {name: late, var: late}, {name: multipleChoiceSubmission, var: multiple_choice_submission}, {name: shortAnswerSubmission, var: short_answer_submission}, {name: state, var: state}, {name: submissionHistory, var: submission_history}, {name: updateTime, var: update_time}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, alternate_link: $alternate_link, assigned_grade: $assigned_grade, assignment_submission: $assignment_submission, associated_with_developer: $associated_with_developer, body_course_id: $body_course_id, body_course_work_id: $body_course_work_id, course_work_type: $course_work_type, creation_time: $creation_time, draft_grade: $draft_grade, body_id: $body_id, late: $late, multiple_choice_submission: $multiple_choice_submission, short_answer_submission: $short_answer_submission, state: $state, submission_history: $submission_history, update_time: $update_time, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies attachments of student submission. Attachments may only be added to student submissions belonging to course work objects with a `workType` of `ASSIGNMENT`. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, if the user is not permitted to modify attachments on the requested student submission, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# POST /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:modifyAttachments
# Returns: record<alternateLink: string, assignedGrade: float, assignmentSubmission: record<attachments: list<record>>, associatedWithDeveloper: bool, courseId: string, courseWorkId: string, courseWorkType: string, creationTime: string, draftGrade: float, id: string, late: bool, multipleChoiceSubmission: record<answer: string>, shortAnswerSubmission: record<answer: string>, state: string, submissionHistory: table<gradeHistory: record, stateHistory: record>, updateTime: string, userId: string>
# operationId: classroom.courses.courseWork.studentSubmissions.modifyAttachments
export def "classroom-courses-course-work-student-submissions-modify-attachments" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --add-attachments: list # Attachments to add. A student submission may not have more than 20 attachments. Form attachments are not supported. — item shape: {driveFile?: record, form?: record, link?: record, youTubeVideo?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:modifyAttachments"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addAttachments, var: add_attachments}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, add_attachments: $add_attachments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reclaims a student submission on behalf of the student that owns it. Reclaiming a student submission transfers ownership of attached Drive files to the student and updates the submission state. Only the student that owns the requested student submission may call this method, and only for a student submission that has been turned in. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, unsubmit the requested student submission, or for access errors. * `FAILED_PRECONDITION` if the student submission has not been turned in. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# POST /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:reclaim
# Returns: record
# operationId: classroom.courses.courseWork.studentSubmissions.reclaim
export def "classroom-courses-course-work-student-submissions-reclaim" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:reclaim"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a student submission. Returning a student submission transfers ownership of attached Drive files to the student and may also update the submission state. Unlike the Classroom application, returning a student submission does not set assignedGrade to the draftGrade value. Only a teacher of the course that contains the requested student submission may call this method. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, return the requested student submission, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# POST /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:return
# Returns: record
# operationId: classroom.courses.courseWork.studentSubmissions.return
export def "classroom-courses-course-work-student-submissions-return" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:return"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Turns in a student submission. Turning in a student submission transfers ownership of attached Drive files to the teacher and may also update the submission state. This may only be called by the student that owns the specified student submission. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, turn in the requested student submission, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# POST /v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:turnIn
# Returns: record
# operationId: classroom.courses.courseWork.studentSubmissions.turnIn
export def "classroom-courses-course-work-student-submissions-turn-in" [
  course_id: string
  course_work_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork/{courseWorkId}/studentSubmissions/{id}:turnIn"
    path_params: [{name: courseId, var: course_id}, {name: courseWorkId, var: course_work_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, course_work_id: $course_work_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a course work. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding course work, if the requesting user is not permitted to delete the requested course or for access errors. * `FAILED_PRECONDITION` if the requested course work has already been deleted. * `NOT_FOUND` if no course exists with the requested ID.
#
# DELETE /v1/courses/{courseId}/courseWork/{id}
# Returns: record
# operationId: classroom.courses.courseWork.delete
export def "classroom-courses-course-work-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/courseWork/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns course work. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or course work does not exist.
#
# GET /v1/courses/{courseId}/courseWork/{id}
# Returns: record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>
# operationId: classroom.courses.courseWork.get
export def "classroom-courses-course-work-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWork/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields of a course work. See google.classroom.v1.CourseWork for details of which fields may be updated and who may change them. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding course work, if the user is not permitted to make the requested modification to the student submission, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `FAILED_PRECONDITION` if the requested course work has already been deleted. * `NOT_FOUND` if the requested course, course work, or student submission does not exist.
#
# PATCH /v1/courses/{courseId}/courseWork/{id}
# Returns: record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>
# operationId: classroom.courses.courseWork.patch
export def "classroom-courses-course-work-patch" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the course work to update. This field is required to do an update. The update fails if invalid fields are specified. If a field supports empty values, it can be cleared by specifying it in the update mask and not in the CourseWork object. If a field that does not support empty values is included in the update mask and not set in the CourseWork object, an `INVALID_ARGUMENT` error is returned. The following fields may be specified by teachers: * `title` * `description` * `state` * `due_date` * `due_time` * `max_points` * `scheduled_time` * `submission_modification_mode` * `topic_id`
  --alternate-link: string # Absolute link to this course work in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the coursework. If unspecified, the default value is `ALL_STUDENTS`.
  --assignment: record # Additional details for assignments. — shape: {studentWorkFolder?: record}
  --associated-with-developer: oneof<nothing, bool> # Whether this course work item is associated with the Developer Console project making the request. See CreateCourseWork for more details. Read-only.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this course work was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the coursework. Read-only.
  --description: string # Optional description of this course work. If set, the description must be a valid UTF-8 string containing no more than 30,000 characters.
  --due-date: record # Represents a whole or partial calendar date, such as a birthday. The time of day and time zone are either specified elsewhere or are insignificant. The date is relative to the Gregorian Calendar. This can represent one of the following: * A full date, with non-zero year, month, and day values. * A month and day, with a zero year (for example, an anniversary). * A year on its own, with a zero month and a zero day. * A year and month, with a zero day (for example, a credit card expiration date). Related types: * google.type.TimeOfDay * google.type.DateTime * google.protobuf.Timestamp — shape: {day?: int, month?: int, year?: int}
  --due-time: record # Represents a time of day. The date and time zone are either not significant or are specified elsewhere. An API may choose to allow leap seconds. Related types are google.type.Date and `google.protobuf.Timestamp`. — shape: {hours?: int, minutes?: int, nanos?: int, seconds?: int}
  --grade-category: record # Details for a grade category in a course. Coursework may have zero or one grade category, and the category may be used in computing the overall grade. See the [help center article](https://support.google.com/edu/classroom/answer/9184995) for details. — shape: {defaultGradeDenominator?: int, id?: string, name?: string, weight?: int}
  --body-id: string # Classroom-assigned identifier of this course work, unique per course. Read-only. (spec name: id)
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. CourseWork must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --max-points: float # Maximum grade for this course work. If zero or unspecified, this assignment is considered ungraded. This must be a non-negative integer value. (format: double)
  --multiple-choice-question: record # Additional details for multiple-choice questions. — shape: {choices?: list<string>}
  --scheduled-time: string # Optional timestamp when this course work is scheduled to be published. (format: google-datetime)
  --state: string@state-completer-1 # Status of this course work. If unspecified, the default state is `DRAFT`.
  --submission-modification-mode: string@submission-modification-mode-completer # Setting to determine when students are allowed to modify submissions. If unspecified, the default value is `MODIFIABLE_UNTIL_TURNED_IN`.
  --title: string # Title of this course work. The title must be a valid UTF-8 string containing between 1 and 3000 characters.
  --topic-id: string # Identifier for the topic that this coursework is associated with. Must match an existing topic in the course.
  --update-time: string # Timestamp of the most recent change to this course work. Read-only. (format: google-datetime)
  --work-type: string@work-type-completer # Type of this course work. The type is set when the course work is created and cannot be changed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{courseId}/courseWork/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: assignment, var: assignment}, {name: associatedWithDeveloper, var: associated_with_developer}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: description, var: description}, {name: dueDate, var: due_date}, {name: dueTime, var: due_time}, {name: gradeCategory, var: grade_category}, {name: id, var: body_id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: maxPoints, var: max_points}, {name: multipleChoiceQuestion, var: multiple_choice_question}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: submissionModificationMode, var: submission_modification_mode}, {name: title, var: title}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}, {name: workType, var: work_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, alternate_link: $alternate_link, assignee_mode: $assignee_mode, assignment: $assignment, associated_with_developer: $associated_with_developer, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, description: $description, due_date: $due_date, due_time: $due_time, grade_category: $grade_category, body_id: $body_id, individual_students_options: $individual_students_options, materials: $materials, max_points: $max_points, multiple_choice_question: $multiple_choice_question, scheduled_time: $scheduled_time, state: $state, submission_modification_mode: $submission_modification_mode, title: $title, topic_id: $topic_id, update_time: $update_time, work_type: $work_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies assignee mode and options of a coursework. Only a teacher of the course that contains the coursework may call this method. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or course work does not exist.
#
# POST /v1/courses/{courseId}/courseWork/{id}:modifyAssignees
# Returns: record<alternateLink: string, assigneeMode: string, assignment: record<studentWorkFolder: record<alternateLink: string, id: string, title: string>>, associatedWithDeveloper: bool, courseId: string, creationTime: string, creatorUserId: string, description: string, dueDate: record<day: int, month: int, year: int>, dueTime: record<hours: int, minutes: int, nanos: int, seconds: int>, gradeCategory: record<defaultGradeDenominator: int, id: string, name: string, weight: int>, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, maxPoints: float, multipleChoiceQuestion: record<choices: list<string>>, scheduledTime: string, state: string, submissionModificationMode: string, title: string, topicId: string, updateTime: string, workType: string>
# operationId: classroom.courses.courseWork.modifyAssignees
export def "classroom-courses-course-work-modify-assignees" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --assignee-mode: string@assignee-mode-completer # Mode of the coursework describing whether it will be assigned to all students or specified individual students.
  --modify-individual-students-options: record # Contains fields to add or remove students from a course work or announcement where the `assigneeMode` is set to `INDIVIDUAL_STUDENTS`. — shape: {addStudentIds?: list<string>, removeStudentIds?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWork/{id}:modifyAssignees"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: assigneeMode, var: assignee_mode}, {name: modifyIndividualStudentsOptions, var: modify_individual_students_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, assignee_mode: $assignee_mode, modify_individual_students_options: $modify_individual_students_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of course work material that the requester is permitted to view. Course students may only view `PUBLISHED` course work material. Course teachers and domain administrators may view all course work material. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# GET /v1/courses/{courseId}/courseWorkMaterials
# Returns: record<courseWorkMaterial: table<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record, materials: list, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>, nextPageToken: string>
# operationId: classroom.courses.courseWorkMaterials.list
export def "classroom-courses-course-work-materials-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --course-work-material-states: list<string> # Restriction on the work status to return. Only course work material that matches is returned. If unspecified, items with a work status of `PUBLISHED` is returned.
  --material-drive-id: string # Optional filtering for course work material with at least one Drive material whose ID matches the provided string. If `material_link` is also specified, course work material must have materials matching both filters.
  --material-link: string # Optional filtering for course work material with at least one link material whose URL partially matches the provided string.
  --order-by: string # Optional sort ordering for results. A comma-separated list of fields with an optional sort direction keyword. Supported field is `updateTime`. Supported direction keywords are `asc` and `desc`. If not specified, `updateTime desc` is the default behavior. Examples: `updateTime asc`, `updateTime`
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWorkMaterials"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: courseWorkMaterialStates, var: course_work_material_states, style: multi}, {name: materialDriveId, var: material_drive_id}, {name: materialLink, var: material_link}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, course_work_material_states: $course_work_material_states, material_drive_id: $material_drive_id, material_link: $material_link, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a course work material. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course, create course work material in the requested course, share a Drive attachment, or for access errors. * `INVALID_ARGUMENT` if the request is malformed or if more than 20 * materials are provided. * `NOT_FOUND` if the requested course does not exist. * `FAILED_PRECONDITION` for the following request error: * AttachmentNotVisible
#
# POST /v1/courses/{courseId}/courseWorkMaterials
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>
# operationId: classroom.courses.courseWorkMaterials.create
export def "classroom-courses-course-work-materials-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-link: string # Absolute link to this course work material in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the course work material. If unspecified, the default value is `ALL_STUDENTS`.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this course work material was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the course work material. Read-only.
  --description: string # Optional description of this course work material. The text must be a valid UTF-8 string containing no more than 30,000 characters.
  --id: string # Classroom-assigned identifier of this course work material, unique per course. Read-only.
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. A course work material must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --scheduled-time: string # Optional timestamp when this course work material is scheduled to be published. (format: google-datetime)
  --state: string@state-completer-3 # Status of this course work material. If unspecified, the default state is `DRAFT`.
  --title: string # Title of this course work material. The title must be a valid UTF-8 string containing between 1 and 3000 characters.
  --topic-id: string # Identifier for the topic that this course work material is associated with. Must match an existing topic in the course.
  --update-time: string # Timestamp of the most recent change to this course work material. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/courseWorkMaterials"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: description, var: description}, {name: id, var: id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: title, var: title}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_link: $alternate_link, assignee_mode: $assignee_mode, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, description: $description, id: $id, individual_students_options: $individual_students_options, materials: $materials, scheduled_time: $scheduled_time, state: $state, title: $title, topic_id: $topic_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a course work material. This request must be made by the Developer Console project of the [OAuth client ID](https://support.google.com/cloud/answer/6158849) used to create the corresponding course work material item. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding course work material, if the requesting user is not permitted to delete the requested course or for access errors. * `FAILED_PRECONDITION` if the requested course work material has already been deleted. * `NOT_FOUND` if no course exists with the requested ID.
#
# DELETE /v1/courses/{courseId}/courseWorkMaterials/{id}
# Returns: record
# operationId: classroom.courses.courseWorkMaterials.delete
export def "classroom-courses-course-work-materials-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/courseWorkMaterials/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a course work material. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or course work material, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or course work material does not exist.
#
# GET /v1/courses/{courseId}/courseWorkMaterials/{id}
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>
# operationId: classroom.courses.courseWorkMaterials.get
export def "classroom-courses-course-work-materials-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/courseWorkMaterials/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields of a course work material. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `FAILED_PRECONDITION` if the requested course work material has already been deleted. * `NOT_FOUND` if the requested course or course work material does not exist
#
# PATCH /v1/courses/{courseId}/courseWorkMaterials/{id}
# Returns: record<alternateLink: string, assigneeMode: string, courseId: string, creationTime: string, creatorUserId: string, description: string, id: string, individualStudentsOptions: record<studentIds: list<string>>, materials: table<driveFile: record, form: record, link: record, youtubeVideo: record>, scheduledTime: string, state: string, title: string, topicId: string, updateTime: string>
# operationId: classroom.courses.courseWorkMaterials.patch
export def "classroom-courses-course-work-materials-patch" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the course work material to update. This field is required to do an update. The update fails if invalid fields are specified. If a field supports empty values, it can be cleared by specifying it in the update mask and not in the course work material object. If a field that does not support empty values is included in the update mask and not set in the course work material object, an `INVALID_ARGUMENT` error is returned. The following fields may be specified by teachers: * `title` * `description` * `state` * `scheduled_time` * `topic_id`
  --alternate-link: string # Absolute link to this course work material in the Classroom web UI. This is only populated if `state` is `PUBLISHED`. Read-only.
  --assignee-mode: string@assignee-mode-completer # Assignee mode of the course work material. If unspecified, the default value is `ALL_STUDENTS`.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --creation-time: string # Timestamp when this course work material was created. Read-only. (format: google-datetime)
  --creator-user-id: string # Identifier for the user that created the course work material. Read-only.
  --description: string # Optional description of this course work material. The text must be a valid UTF-8 string containing no more than 30,000 characters.
  --body-id: string # Classroom-assigned identifier of this course work material, unique per course. Read-only. (spec name: id)
  --individual-students-options: record # Assignee details about a coursework/announcement. This field is set if and only if `assigneeMode` is `INDIVIDUAL_STUDENTS`. — shape: {studentIds?: list<string>}
  --materials: list # Additional materials. A course work material must have no more than 20 material items. — item shape: {driveFile?: record, form?: record, link?: record, youtubeVideo?: record}
  --scheduled-time: string # Optional timestamp when this course work material is scheduled to be published. (format: google-datetime)
  --state: string@state-completer-3 # Status of this course work material. If unspecified, the default state is `DRAFT`.
  --title: string # Title of this course work material. The title must be a valid UTF-8 string containing between 1 and 3000 characters.
  --topic-id: string # Identifier for the topic that this course work material is associated with. Must match an existing topic in the course.
  --update-time: string # Timestamp of the most recent change to this course work material. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{courseId}/courseWorkMaterials/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: assigneeMode, var: assignee_mode}, {name: courseId, var: body_course_id}, {name: creationTime, var: creation_time}, {name: creatorUserId, var: creator_user_id}, {name: description, var: description}, {name: id, var: body_id}, {name: individualStudentsOptions, var: individual_students_options}, {name: materials, var: materials}, {name: scheduledTime, var: scheduled_time}, {name: state, var: state}, {name: title, var: title}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, alternate_link: $alternate_link, assignee_mode: $assignee_mode, body_course_id: $body_course_id, creation_time: $creation_time, creator_user_id: $creator_user_id, description: $description, body_id: $body_id, individual_students_options: $individual_students_options, materials: $materials, scheduled_time: $scheduled_time, state: $state, title: $title, topic_id: $topic_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of students of this course that the requester is permitted to view. This method returns the following error codes: * `NOT_FOUND` if the course does not exist. * `PERMISSION_DENIED` for access errors.
#
# GET /v1/courses/{courseId}/students
# Returns: record<nextPageToken: string, students: table<courseId: string, profile: record, studentWorkFolder: record, userId: string>>
# operationId: classroom.courses.students.list
export def "classroom-courses-students-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of items to return. The default is 30 if unspecified or `0`. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/students"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user as a student of a course. Domain administrators are permitted to [directly add](https://developers.google.com/classroom/guides/manage-users) users within their domain as students to courses within their domain. Students are permitted to add themselves to a course using an enrollment code. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to create students in this course or for access errors. * `NOT_FOUND` if the requested course ID does not exist. * `FAILED_PRECONDITION` if the requested user's account is disabled, for the following request errors: * CourseMemberLimitReached * CourseNotModifiable * UserGroupsMembershipLimitReached * InactiveCourseOwner * `ALREADY_EXISTS` if the user is already a student or teacher in the course.
#
# POST /v1/courses/{courseId}/students
# Returns: record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, studentWorkFolder: record<alternateLink: string, id: string, title: string>, userId: string>
# operationId: classroom.courses.students.create
export def "classroom-courses-students-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --enrollment-code: string # Enrollment code of the course to create the student in. This code is required if userId corresponds to the requesting user; it may be omitted if the requesting user has administrative permissions to create students for any user.
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --profile: record # Global information for a user. — shape: {emailAddress?: string, id?: string, name?: record, permissions?: list, photoUrl?: string, verifiedTeacher?: bool}
  --student-work-folder: record # Representation of a Google Drive folder. — shape: {alternateLink?: string, id?: string, title?: string}
  --user-id: string # Identifier of the user. When specified as a parameter of a request, this identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/students"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: enrollmentCode, var: enrollment_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: courseId, var: body_course_id}, {name: profile, var: profile}, {name: studentWorkFolder, var: student_work_folder}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, enrollment_code: $enrollment_code, body_course_id: $body_course_id, profile: $profile, student_work_folder: $student_work_folder, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a student of a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to delete students of this course or for access errors. * `NOT_FOUND` if no student of this course has the requested ID or if the course does not exist.
#
# DELETE /v1/courses/{courseId}/students/{userId}
# Returns: record
# operationId: classroom.courses.students.delete
export def "classroom-courses-students-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/students/{userId}"
    path_params: [{name: courseId, var: course_id}, {name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a student of a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to view students of this course or for access errors. * `NOT_FOUND` if no student of this course has the requested ID or if the course does not exist.
#
# GET /v1/courses/{courseId}/students/{userId}
# Returns: record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, studentWorkFolder: record<alternateLink: string, id: string, title: string>, userId: string>
# operationId: classroom.courses.students.get
export def "classroom-courses-students-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/students/{userId}"
    path_params: [{name: courseId, var: course_id}, {name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of teachers of this course that the requester is permitted to view. This method returns the following error codes: * `NOT_FOUND` if the course does not exist. * `PERMISSION_DENIED` for access errors.
#
# GET /v1/courses/{courseId}/teachers
# Returns: record<nextPageToken: string, teachers: table<courseId: string, profile: record, userId: string>>
# operationId: classroom.courses.teachers.list
export def "classroom-courses-teachers-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of items to return. The default is 30 if unspecified or `0`. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/teachers"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a teacher of a course. Domain administrators are permitted to [directly add](https://developers.google.com/classroom/guides/manage-users) users within their domain as teachers to courses within their domain. Non-admin users should send an Invitation instead. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to create teachers in this course or for access errors. * `NOT_FOUND` if the requested course ID does not exist. * `FAILED_PRECONDITION` if the requested user's account is disabled, for the following request errors: * CourseMemberLimitReached * CourseNotModifiable * CourseTeacherLimitReached * UserGroupsMembershipLimitReached * InactiveCourseOwner * `ALREADY_EXISTS` if the user is already a teacher or student in the course.
#
# POST /v1/courses/{courseId}/teachers
# Returns: record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, userId: string>
# operationId: classroom.courses.teachers.create
export def "classroom-courses-teachers-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --profile: record # Global information for a user. — shape: {emailAddress?: string, id?: string, name?: record, permissions?: list, photoUrl?: string, verifiedTeacher?: bool}
  --user-id: string # Identifier of the user. When specified as a parameter of a request, this identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/teachers"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: courseId, var: body_course_id}, {name: profile, var: profile}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_course_id: $body_course_id, profile: $profile, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified teacher from the specified course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to delete teachers of this course or for access errors. * `NOT_FOUND` if no teacher of this course has the requested ID or if the course does not exist. * `FAILED_PRECONDITION` if the requested ID belongs to the primary teacher of this course. * `FAILED_PRECONDITION` if the requested ID belongs to the owner of the course Drive folder. * `FAILED_PRECONDITION` if the course no longer has an active owner.
#
# DELETE /v1/courses/{courseId}/teachers/{userId}
# Returns: record
# operationId: classroom.courses.teachers.delete
export def "classroom-courses-teachers-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/teachers/{userId}"
    path_params: [{name: courseId, var: course_id}, {name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a teacher of a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to view teachers of this course or for access errors. * `NOT_FOUND` if no teacher of this course has the requested ID or if the course does not exist.
#
# GET /v1/courses/{courseId}/teachers/{userId}
# Returns: record<courseId: string, profile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, userId: string>
# operationId: classroom.courses.teachers.get
export def "classroom-courses-teachers-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/teachers/{userId}"
    path_params: [{name: courseId, var: course_id}, {name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of topics that the requester is permitted to view. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# GET /v1/courses/{courseId}/topics
# Returns: record<nextPageToken: string, topic: table<courseId: string, name: string, topicId: string, updateTime: string>>
# operationId: classroom.courses.topics.list
export def "classroom-courses-topics-list" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/topics"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a topic. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course, create a topic in the requested course, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course does not exist.
#
# POST /v1/courses/{courseId}/topics
# Returns: record<courseId: string, name: string, topicId: string, updateTime: string>
# operationId: classroom.courses.topics.create
export def "classroom-courses-topics-create" [
  course_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --name: string # The name of the topic, generated by the user. Leading and trailing whitespaces, if any, are trimmed. Also, multiple consecutive whitespaces are collapsed into one inside the name. The result must be a non-empty string. Topic names are case sensitive, and must be no longer than 100 characters.
  --topic-id: string # Unique identifier for the topic. Read-only.
  --update-time: string # The time the topic was last updated by the system. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/courses/{courseId}/topics"
    path_params: [{name: courseId, var: course_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: courseId, var: body_course_id}, {name: name, var: name}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_course_id: $body_course_id, name: $name, topic_id: $topic_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a topic. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not allowed to delete the requested topic or for access errors. * `FAILED_PRECONDITION` if the requested topic has already been deleted. * `NOT_FOUND` if no course or topic exists with the requested ID.
#
# DELETE /v1/courses/{courseId}/topics/{id}
# Returns: record
# operationId: classroom.courses.topics.delete
export def "classroom-courses-topics-delete" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{courseId}/topics/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a topic. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or topic, or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or topic does not exist.
#
# GET /v1/courses/{courseId}/topics/{id}
# Returns: record<courseId: string, name: string, topicId: string, updateTime: string>
# operationId: classroom.courses.topics.get
export def "classroom-courses-topics-get" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{courseId}/topics/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields of a topic. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting developer project did not create the corresponding topic or for access errors. * `INVALID_ARGUMENT` if the request is malformed. * `NOT_FOUND` if the requested course or topic does not exist
#
# PATCH /v1/courses/{courseId}/topics/{id}
# Returns: record<courseId: string, name: string, topicId: string, updateTime: string>
# operationId: classroom.courses.topics.patch
export def "classroom-courses-topics-patch" [
  course_id: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the topic to update. This field is required to do an update. The update fails if invalid fields are specified. If a field supports empty values, it can be cleared by specifying it in the update mask and not in the Topic object. If a field that does not support empty values is included in the update mask and not set in the Topic object, an `INVALID_ARGUMENT` error is returned. The following fields may be specified: * `name`
  --body-course-id: string # Identifier of the course. Read-only. (spec name: courseId)
  --name: string # The name of the topic, generated by the user. Leading and trailing whitespaces, if any, are trimmed. Also, multiple consecutive whitespaces are collapsed into one inside the name. The result must be a non-empty string. Topic names are case sensitive, and must be no longer than 100 characters.
  --topic-id: string # Unique identifier for the topic. Read-only.
  --update-time: string # The time the topic was last updated by the system. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{courseId}/topics/{id}"
    path_params: [{name: courseId, var: course_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: courseId, var: body_course_id}, {name: name, var: name}, {name: topicId, var: topic_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    course_id: $course_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, body_course_id: $body_course_id, name: $name, topic_id: $topic_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to delete the requested course or for access errors. * `NOT_FOUND` if no course exists with the requested ID.
#
# DELETE /v1/courses/{id}
# Returns: record
# operationId: classroom.courses.delete
export def "classroom-courses-delete" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/courses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access the requested course or for access errors. * `NOT_FOUND` if no course exists with the requested ID.
#
# GET /v1/courses/{id}
# Returns: record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>
# operationId: classroom.courses.get
export def "classroom-courses-get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/courses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates one or more fields in a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to modify the requested course or for access errors. * `NOT_FOUND` if no course exists with the requested ID. * `INVALID_ARGUMENT` if invalid fields are specified in the update mask or if no update mask is supplied. * `FAILED_PRECONDITION` for the following request errors: * CourseNotModifiable * InactiveCourseOwner * IneligibleOwner
#
# PATCH /v1/courses/{id}
# Returns: record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>
# operationId: classroom.courses.patch
export def "classroom-courses-patch" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the course to update. This field is required to do an update. The update will fail if invalid fields are specified. The following fields are valid: * `name` * `section` * `descriptionHeading` * `description` * `room` * `courseState` * `ownerId` Note: patches to ownerId are treated as being effective immediately, but in practice it may take some time for the ownership transfer of all affected resources to complete. When set in a query parameter, this field should be specified as `updateMask=,,...`
  --alternate-link: string # Absolute link to this course in the Classroom web UI. Read-only.
  --calendar-id: string # The Calendar ID for a calendar that all course members can see, to which Classroom adds events for course work and announcements in the course. Read-only.
  --course-group-email: string # The email address of a Google group containing all members of the course. This group does not accept email and can only be used for permissions. Read-only.
  --course-material-sets: list # Sets of materials that appear on the "about" page of this course. Read-only. — item shape: {materials?: list, title?: string}
  --course-state: string@course-state-completer # State of the course. If unspecified, the default state is `PROVISIONED`.
  --creation-time: string # Creation time of the course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
  --description: string # Optional description. For example, "We'll be learning about the structure of living creatures from a combination of textbooks, guest lectures, and lab work. Expect to be excited!" If set, this field must be a valid UTF-8 string and no longer than 30,000 characters.
  --description-heading: string # Optional heading for the description. For example, "Welcome to 10th Grade Biology." If set, this field must be a valid UTF-8 string and no longer than 3600 characters.
  --enrollment-code: string # Enrollment code to use when joining this course. Specifying this field in a course update mask results in an error. Read-only.
  --gradebook-settings: record # The gradebook settings for a course. See the [help center article](https://support.google.com/edu/classroom/answer/9184995) for details. — shape: {calculationType?: "CALCULATION_TYPE_UNSPECIFIED"|"TOTAL_POINTS"|"WEIGHTED_CATEGORIES", displaySetting?: "DISPLAY_SETTING_UNSPECIFIED"|"SHOW_OVERALL_GRADE"|"HIDE_OVERALL_GRADE"|"SHOW_TEACHERS_ONLY", gradeCategories?: list}
  --guardians-enabled: oneof<nothing, bool> # Whether or not guardian notifications are enabled for this course. Read-only.
  --body-id: string # Identifier for this course assigned by Classroom. When creating a course, you may optionally set this identifier to an alias string in the request to create a corresponding alias. The `id` is still assigned by Classroom and cannot be updated after the course is created. Specifying this field in a course update mask results in an error. (spec name: id)
  --name: string # Name of the course. For example, "10th Grade Biology". The name is required. It must be between 1 and 750 characters and a valid UTF-8 string.
  --owner-id: string # The identifier of the owner of a course. When specified as a parameter of a create course request, this field is required. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user This must be set in a create request. Admins can also specify this field in a patch course request to transfer ownership. In other contexts, it is read-only.
  --room: string # Optional room location. For example, "301". If set, this field must be a valid UTF-8 string and no longer than 650 characters.
  --section: string # Section of the course. For example, "Period 2". If set, this field must be a valid UTF-8 string and no longer than 2800 characters.
  --teacher-folder: record # Representation of a Google Drive folder. — shape: {alternateLink?: string, id?: string, title?: string}
  --teacher-group-email: string # The email address of a Google group containing all teachers of the course. This group does not accept email and can only be used for permissions. Read-only.
  --update-time: string # Time of the most recent update to this course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/courses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: calendarId, var: calendar_id}, {name: courseGroupEmail, var: course_group_email}, {name: courseMaterialSets, var: course_material_sets}, {name: courseState, var: course_state}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: descriptionHeading, var: description_heading}, {name: enrollmentCode, var: enrollment_code}, {name: gradebookSettings, var: gradebook_settings}, {name: guardiansEnabled, var: guardians_enabled}, {name: id, var: body_id}, {name: name, var: name}, {name: ownerId, var: owner_id}, {name: room, var: room}, {name: section, var: section}, {name: teacherFolder, var: teacher_folder}, {name: teacherGroupEmail, var: teacher_group_email}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, alternate_link: $alternate_link, calendar_id: $calendar_id, course_group_email: $course_group_email, course_material_sets: $course_material_sets, course_state: $course_state, creation_time: $creation_time, description: $description, description_heading: $description_heading, enrollment_code: $enrollment_code, gradebook_settings: $gradebook_settings, guardians_enabled: $guardians_enabled, body_id: $body_id, name: $name, owner_id: $owner_id, room: $room, section: $section, teacher_folder: $teacher_folder, teacher_group_email: $teacher_group_email, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a course. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to modify the requested course or for access errors. * `NOT_FOUND` if no course exists with the requested ID. * `FAILED_PRECONDITION` for the following request errors: * CourseNotModifiable
#
# PUT /v1/courses/{id}
# Returns: record<alternateLink: string, calendarId: string, courseGroupEmail: string, courseMaterialSets: table<materials: list, title: string>, courseState: string, creationTime: string, description: string, descriptionHeading: string, enrollmentCode: string, gradebookSettings: record<calculationType: string, displaySetting: string, gradeCategories: list<record>>, guardiansEnabled: bool, id: string, name: string, ownerId: string, room: string, section: string, teacherFolder: record<alternateLink: string, id: string, title: string>, teacherGroupEmail: string, updateTime: string>
# operationId: classroom.courses.update
export def "classroom-courses-update" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alternate-link: string # Absolute link to this course in the Classroom web UI. Read-only.
  --calendar-id: string # The Calendar ID for a calendar that all course members can see, to which Classroom adds events for course work and announcements in the course. Read-only.
  --course-group-email: string # The email address of a Google group containing all members of the course. This group does not accept email and can only be used for permissions. Read-only.
  --course-material-sets: list # Sets of materials that appear on the "about" page of this course. Read-only. — item shape: {materials?: list, title?: string}
  --course-state: string@course-state-completer # State of the course. If unspecified, the default state is `PROVISIONED`.
  --creation-time: string # Creation time of the course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
  --description: string # Optional description. For example, "We'll be learning about the structure of living creatures from a combination of textbooks, guest lectures, and lab work. Expect to be excited!" If set, this field must be a valid UTF-8 string and no longer than 30,000 characters.
  --description-heading: string # Optional heading for the description. For example, "Welcome to 10th Grade Biology." If set, this field must be a valid UTF-8 string and no longer than 3600 characters.
  --enrollment-code: string # Enrollment code to use when joining this course. Specifying this field in a course update mask results in an error. Read-only.
  --gradebook-settings: record # The gradebook settings for a course. See the [help center article](https://support.google.com/edu/classroom/answer/9184995) for details. — shape: {calculationType?: "CALCULATION_TYPE_UNSPECIFIED"|"TOTAL_POINTS"|"WEIGHTED_CATEGORIES", displaySetting?: "DISPLAY_SETTING_UNSPECIFIED"|"SHOW_OVERALL_GRADE"|"HIDE_OVERALL_GRADE"|"SHOW_TEACHERS_ONLY", gradeCategories?: list}
  --guardians-enabled: oneof<nothing, bool> # Whether or not guardian notifications are enabled for this course. Read-only.
  --body-id: string # Identifier for this course assigned by Classroom. When creating a course, you may optionally set this identifier to an alias string in the request to create a corresponding alias. The `id` is still assigned by Classroom and cannot be updated after the course is created. Specifying this field in a course update mask results in an error. (spec name: id)
  --name: string # Name of the course. For example, "10th Grade Biology". The name is required. It must be between 1 and 750 characters and a valid UTF-8 string.
  --owner-id: string # The identifier of the owner of a course. When specified as a parameter of a create course request, this field is required. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user This must be set in a create request. Admins can also specify this field in a patch course request to transfer ownership. In other contexts, it is read-only.
  --room: string # Optional room location. For example, "301". If set, this field must be a valid UTF-8 string and no longer than 650 characters.
  --section: string # Section of the course. For example, "Period 2". If set, this field must be a valid UTF-8 string and no longer than 2800 characters.
  --teacher-folder: record # Representation of a Google Drive folder. — shape: {alternateLink?: string, id?: string, title?: string}
  --teacher-group-email: string # The email address of a Google group containing all teachers of the course. This group does not accept email and can only be used for permissions. Read-only.
  --update-time: string # Time of the most recent update to this course. Specifying this field in a course update mask results in an error. Read-only. (format: google-datetime)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/courses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateLink, var: alternate_link}, {name: calendarId, var: calendar_id}, {name: courseGroupEmail, var: course_group_email}, {name: courseMaterialSets, var: course_material_sets}, {name: courseState, var: course_state}, {name: creationTime, var: creation_time}, {name: description, var: description}, {name: descriptionHeading, var: description_heading}, {name: enrollmentCode, var: enrollment_code}, {name: gradebookSettings, var: gradebook_settings}, {name: guardiansEnabled, var: guardians_enabled}, {name: id, var: body_id}, {name: name, var: name}, {name: ownerId, var: owner_id}, {name: room, var: room}, {name: section, var: section}, {name: teacherFolder, var: teacher_folder}, {name: teacherGroupEmail, var: teacher_group_email}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_link: $alternate_link, calendar_id: $calendar_id, course_group_email: $course_group_email, course_material_sets: $course_material_sets, course_state: $course_state, creation_time: $creation_time, description: $description, description_heading: $description_heading, enrollment_code: $enrollment_code, gradebook_settings: $gradebook_settings, guardians_enabled: $guardians_enabled, body_id: $body_id, name: $name, owner_id: $owner_id, room: $room, section: $section, teacher_folder: $teacher_folder, teacher_group_email: $teacher_group_email, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of invitations that the requesting user is permitted to view, restricted to those that match the list request. *Note:* At least one of `user_id` or `course_id` must be supplied. Both fields can be supplied. This method returns the following error codes: * `PERMISSION_DENIED` for access errors.
#
# GET /v1/invitations
# Returns: record<invitations: table<courseId: string, id: string, role: string, userId: string>, nextPageToken: string>
# operationId: classroom.invitations.list
export def "classroom-invitations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --course-id: string # Restricts returned invitations to those for a course with the specified identifier.
  --page-size: int # Maximum number of items to return. The default is 500 if unspecified or `0`. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
  --user-id: string # Restricts returned invitations to those for a specific user. The identifier can be one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/invitations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: courseId, var: course_id}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, course_id: $course_id, page_size: $page_size, page_token: $page_token, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an invitation. Only one invitation for a user and course may exist at a time. Delete and re-create an invitation to make changes. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to create invitations for this course or for access errors. * `NOT_FOUND` if the course or the user does not exist. * `FAILED_PRECONDITION`: * if the requested user's account is disabled. * if the user already has this role or a role with greater permissions. * for the following request errors: * IneligibleOwner * `ALREADY_EXISTS` if an invitation for the specified user and course already exists.
#
# POST /v1/invitations
# Returns: record<courseId: string, id: string, role: string, userId: string>
# operationId: classroom.invitations.create
export def "classroom-invitations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --course-id: string # Identifier of the course to invite the user to.
  --id: string # Identifier assigned by Classroom. Read-only.
  --role: string@role-completer # Role to invite the user to have. Must not be `COURSE_ROLE_UNSPECIFIED`.
  --user-id: string # Identifier of the invited user. When specified as a parameter of a request, this identifier can be set to one of the following: * the numeric identifier for the user * the email address of the user * the string literal `"me"`, indicating the requesting user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/invitations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: courseId, var: course_id}, {name: id, var: id}, {name: role, var: role}, {name: userId, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, course_id: $course_id, id: $id, role: $role, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an invitation. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to delete the requested invitation or for access errors. * `NOT_FOUND` if no invitation exists with the requested ID.
#
# DELETE /v1/invitations/{id}
# Returns: record
# operationId: classroom.invitations.delete
export def "classroom-invitations-delete" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/invitations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an invitation. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to view the requested invitation or for access errors. * `NOT_FOUND` if no invitation exists with the requested ID.
#
# GET /v1/invitations/{id}
# Returns: record<courseId: string, id: string, role: string, userId: string>
# operationId: classroom.invitations.get
export def "classroom-invitations-get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/invitations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accepts an invitation, removing it and adding the invited user to the teachers or students (as appropriate) of the specified course. Only the invited user may accept an invitation. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to accept the requested invitation or for access errors. * `FAILED_PRECONDITION` for the following request errors: * CourseMemberLimitReached * CourseNotModifiable * CourseTeacherLimitReached * UserGroupsMembershipLimitReached * `NOT_FOUND` if no invitation exists with the requested ID.
#
# POST /v1/invitations/{id}:accept
# Returns: record
# operationId: classroom.invitations.accept
export def "classroom-invitations-accept" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/invitations/{id}:accept"
    path_params: [{name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a `Registration`, causing Classroom to start sending notifications from the provided `feed` to the destination provided in `cloudPubSubTopic`. Returns the created `Registration`. Currently, this will be the same as the argument, but with server-assigned fields such as `expiry_time` and `id` filled in. Note that any value specified for the `expiry_time` or `id` fields will be ignored. While Classroom may validate the `cloudPubSubTopic` and return errors on a best effort basis, it is the caller's responsibility to ensure that it exists and that Classroom has permission to publish to it. This method may return the following error codes: * `PERMISSION_DENIED` if: * the authenticated user does not have permission to receive notifications from the requested field; or * the current user has not granted access to the current Cloud project with the appropriate scope for the requested feed. Note that domain-wide delegation of authority is not currently supported for this purpose. If the request has the appropriate scope, but no grant exists, a Request Errors is returned. * another access error is encountered. * `INVALID_ARGUMENT` if: * no `cloudPubsubTopic` is specified, or the specified `cloudPubsubTopic` is not valid; or * no `feed` is specified, or the specified `feed` is not valid. * `NOT_FOUND` if: * the specified `feed` cannot be located, or the requesting user does not have permission to determine whether or not it exists; or * the specified `cloudPubsubTopic` cannot be located, or Classroom has not been granted permission to publish to it.
#
# POST /v1/registrations
# Returns: record<cloudPubsubTopic: record<topicName: string>, expiryTime: string, feed: record<courseRosterChangesInfo: record<courseId: string>, courseWorkChangesInfo: record<courseId: string>, feedType: string>, registrationId: string>
# operationId: classroom.registrations.create
export def "classroom-registrations-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cloud-pubsub-topic: record # A reference to a Cloud Pub/Sub topic. To register for notifications, the owner of the topic must grant `classroom-notifications@system.gserviceaccount.com` the `projects.topics.publish` permission. — shape: {topicName?: string}
  --expiry-time: string # The time until which the `Registration` is effective. This is a read-only field assigned by the server. (format: google-datetime)
  --feed: record # A class of notifications that an application can register to receive. For example: "all roster changes for a domain". — shape: {courseRosterChangesInfo?: record, courseWorkChangesInfo?: record, feedType?: "FEED_TYPE_UNSPECIFIED"|"DOMAIN_ROSTER_CHANGES"|"COURSE_ROSTER_CHANGES"|"COURSE_WORK_CHANGES"}
  --registration-id: string # A server-generated unique identifier for this `Registration`. Read-only.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/registrations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloudPubsubTopic, var: cloud_pubsub_topic}, {name: expiryTime, var: expiry_time}, {name: feed, var: feed}, {name: registrationId, var: registration_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cloud_pubsub_topic: $cloud_pubsub_topic, expiry_time: $expiry_time, feed: $feed, registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a `Registration`, causing Classroom to stop sending notifications for that `Registration`.
#
# DELETE /v1/registrations/{registrationId}
# Returns: record
# operationId: classroom.registrations.delete
export def "classroom-registrations-delete" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/registrations/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of guardian invitations that the requesting user is permitted to view, filtered by the parameters provided. This method returns the following error codes: * `PERMISSION_DENIED` if a `student_id` is specified, and the requesting user is not permitted to view guardian invitations for that student, if `"-"` is specified as the `student_id` and the user is not a domain administrator, if guardians are not enabled for the domain in question, or for other access errors. * `INVALID_ARGUMENT` if a `student_id` is specified, but its format cannot be recognized (it is not an email address, nor a `student_id` from the API, nor the literal string `me`). May also be returned if an invalid `page_token` or `state` is provided. * `NOT_FOUND` if a `student_id` is specified, and its format can be recognized, but Classroom has no record of that student.
#
# GET /v1/userProfiles/{studentId}/guardianInvitations
# Returns: record<guardianInvitations: table<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>, nextPageToken: string>
# operationId: classroom.userProfiles.guardianInvitations.list
export def "classroom-user-profiles-guardian-invitations-list" [
  student_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --invited-email-address: string # If specified, only results with the specified `invited_email_address` are returned.
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
  --states: list<string> # If specified, only results with the specified `state` values are returned. Otherwise, results with a `state` of `PENDING` are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userProfiles/{studentId}/guardianInvitations"
    path_params: [{name: studentId, var: student_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: invitedEmailAddress, var: invited_email_address}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: states, var: states, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, invited_email_address: $invited_email_address, page_size: $page_size, page_token: $page_token, states: $states
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a guardian invitation, and sends an email to the guardian asking them to confirm that they are the student's guardian. Once the guardian accepts the invitation, their `state` will change to `COMPLETED` and they will start receiving guardian notifications. A `Guardian` resource will also be created to represent the active guardian. The request object must have the `student_id` and `invited_email_address` fields set. Failing to set these fields, or setting any other fields in the request, will result in an error. This method returns the following error codes: * `PERMISSION_DENIED` if the current user does not have permission to manage guardians, if the guardian in question has already rejected too many requests for that student, if guardians are not enabled for the domain in question, or for other access errors. * `RESOURCE_EXHAUSTED` if the student or guardian has exceeded the guardian link limit. * `INVALID_ARGUMENT` if the guardian email address is not valid (for example, if it is too long), or if the format of the student ID provided cannot be recognized (it is not an email address, nor a `user_id` from this API). This error will also be returned if read-only fields are set, or if the `state` field is set to to a value other than `PENDING`. * `NOT_FOUND` if the student ID provided is a valid student ID, but Classroom has no record of that student. * `ALREADY_EXISTS` if there is already a pending guardian invitation for the student and `invited_email_address` provided, or if the provided `invited_email_address` matches the Google account of an existing `Guardian` for this user.
#
# POST /v1/userProfiles/{studentId}/guardianInvitations
# Returns: record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>
# operationId: classroom.userProfiles.guardianInvitations.create
export def "classroom-user-profiles-guardian-invitations-create" [
  student_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --creation-time: string # The time that this invitation was created. Read-only. (format: google-datetime)
  --invitation-id: string # Unique identifier for this invitation. Read-only.
  --invited-email-address: string # Email address that the invitation was sent to. This field is only visible to domain administrators.
  --state: string@state-completer-4 # The state that this invitation is in.
  --body-student-id: string # ID of the student (in standard format) (spec name: studentId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/userProfiles/{studentId}/guardianInvitations"
    path_params: [{name: studentId, var: student_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationTime, var: creation_time}, {name: invitationId, var: invitation_id}, {name: invitedEmailAddress, var: invited_email_address}, {name: state, var: state}, {name: studentId, var: body_student_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, creation_time: $creation_time, invitation_id: $invitation_id, invited_email_address: $invited_email_address, state: $state, body_student_id: $body_student_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a specific guardian invitation. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to view guardian invitations for the student identified by the `student_id`, if guardians are not enabled for the domain in question, or for other access errors. * `INVALID_ARGUMENT` if a `student_id` is specified, but its format cannot be recognized (it is not an email address, nor a `student_id` from the API, nor the literal string `me`). * `NOT_FOUND` if Classroom cannot find any record of the given student or `invitation_id`. May also be returned if the student exists, but the requesting user does not have access to see that student.
#
# GET /v1/userProfiles/{studentId}/guardianInvitations/{invitationId}
# Returns: record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>
# operationId: classroom.userProfiles.guardianInvitations.get
export def "classroom-user-profiles-guardian-invitations-get" [
  student_id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userProfiles/{studentId}/guardianInvitations/{invitationId}"
    path_params: [{name: studentId, var: student_id}, {name: invitationId, var: invitation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, invitation_id: $invitation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies a guardian invitation. Currently, the only valid modification is to change the `state` from `PENDING` to `COMPLETE`. This has the effect of withdrawing the invitation. This method returns the following error codes: * `PERMISSION_DENIED` if the current user does not have permission to manage guardians, if guardians are not enabled for the domain in question or for other access errors. * `FAILED_PRECONDITION` if the guardian link is not in the `PENDING` state. * `INVALID_ARGUMENT` if the format of the student ID provided cannot be recognized (it is not an email address, nor a `user_id` from this API), or if the passed `GuardianInvitation` has a `state` other than `COMPLETE`, or if it modifies fields other than `state`. * `NOT_FOUND` if the student ID provided is a valid student ID, but Classroom has no record of that student, or if the `id` field does not refer to a guardian invitation known to Classroom.
#
# PATCH /v1/userProfiles/{studentId}/guardianInvitations/{invitationId}
# Returns: record<creationTime: string, invitationId: string, invitedEmailAddress: string, state: string, studentId: string>
# operationId: classroom.userProfiles.guardianInvitations.patch
export def "classroom-user-profiles-guardian-invitations-patch" [
  student_id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Mask that identifies which fields on the course to update. This field is required to do an update. The update fails if invalid fields are specified. The following fields are valid: * `state` When set in a query parameter, this field should be specified as `updateMask=,,...`
  --creation-time: string # The time that this invitation was created. Read-only. (format: google-datetime)
  --body-invitation-id: string # Unique identifier for this invitation. Read-only. (spec name: invitationId)
  --invited-email-address: string # Email address that the invitation was sent to. This field is only visible to domain administrators.
  --state: string@state-completer-4 # The state that this invitation is in.
  --body-student-id: string # ID of the student (in standard format) (spec name: studentId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/userProfiles/{studentId}/guardianInvitations/{invitationId}"
    path_params: [{name: studentId, var: student_id}, {name: invitationId, var: invitation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationTime, var: creation_time}, {name: invitationId, var: body_invitation_id}, {name: invitedEmailAddress, var: invited_email_address}, {name: state, var: state}, {name: studentId, var: body_student_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, invitation_id: $invitation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, creation_time: $creation_time, body_invitation_id: $body_invitation_id, invited_email_address: $invited_email_address, state: $state, body_student_id: $body_student_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of guardians that the requesting user is permitted to view, restricted to those that match the request. To list guardians for any student that the requesting user may view guardians for, use the literal character `-` for the student ID. This method returns the following error codes: * `PERMISSION_DENIED` if a `student_id` is specified, and the requesting user is not permitted to view guardian information for that student, if `"-"` is specified as the `student_id` and the user is not a domain administrator, if guardians are not enabled for the domain in question, if the `invited_email_address` filter is set by a user who is not a domain administrator, or for other access errors. * `INVALID_ARGUMENT` if a `student_id` is specified, but its format cannot be recognized (it is not an email address, nor a `student_id` from the API, nor the literal string `me`). May also be returned if an invalid `page_token` is provided. * `NOT_FOUND` if a `student_id` is specified, and its format can be recognized, but Classroom has no record of that student.
#
# GET /v1/userProfiles/{studentId}/guardians
# Returns: record<guardians: table<guardianId: string, guardianProfile: record, invitedEmailAddress: string, studentId: string>, nextPageToken: string>
# operationId: classroom.userProfiles.guardians.list
export def "classroom-user-profiles-guardians-list" [
  student_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --invited-email-address: string # Filter results by the email address that the original invitation was sent to, resulting in this guardian link. This filter can only be used by domain administrators.
  --page-size: int # Maximum number of items to return. Zero or unspecified indicates that the server may assign a maximum. The server may return fewer than the specified number of results.
  --page-token: string # nextPageToken value returned from a previous list call, indicating that the subsequent page of results should be returned. The list request must be otherwise identical to the one that resulted in this token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userProfiles/{studentId}/guardians"
    path_params: [{name: studentId, var: student_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: invitedEmailAddress, var: invited_email_address}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, invited_email_address: $invited_email_address, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a guardian. The guardian will no longer receive guardian notifications and the guardian will no longer be accessible via the API. This method returns the following error codes: * `PERMISSION_DENIED` if no user that matches the provided `student_id` is visible to the requesting user, if the requesting user is not permitted to manage guardians for the student identified by the `student_id`, if guardians are not enabled for the domain in question, or for other access errors. * `INVALID_ARGUMENT` if a `student_id` is specified, but its format cannot be recognized (it is not an email address, nor a `student_id` from the API). * `NOT_FOUND` if the requesting user is permitted to modify guardians for the requested `student_id`, but no `Guardian` record exists for that student with the provided `guardian_id`.
#
# DELETE /v1/userProfiles/{studentId}/guardians/{guardianId}
# Returns: record
# operationId: classroom.userProfiles.guardians.delete
export def "classroom-user-profiles-guardians-delete" [
  student_id: string
  guardian_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/userProfiles/{studentId}/guardians/{guardianId}"
    path_params: [{name: studentId, var: student_id}, {name: guardianId, var: guardian_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, guardian_id: $guardian_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a specific guardian. This method returns the following error codes: * `PERMISSION_DENIED` if no user that matches the provided `student_id` is visible to the requesting user, if the requesting user is not permitted to view guardian information for the student identified by the `student_id`, if guardians are not enabled for the domain in question, or for other access errors. * `INVALID_ARGUMENT` if a `student_id` is specified, but its format cannot be recognized (it is not an email address, nor a `student_id` from the API, nor the literal string `me`). * `NOT_FOUND` if the requesting user is permitted to view guardians for the requested `student_id`, but no `Guardian` record exists for that student that matches the provided `guardian_id`.
#
# GET /v1/userProfiles/{studentId}/guardians/{guardianId}
# Returns: record<guardianId: string, guardianProfile: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: list<record>, photoUrl: string, verifiedTeacher: bool>, invitedEmailAddress: string, studentId: string>
# operationId: classroom.userProfiles.guardians.get
export def "classroom-user-profiles-guardians-get" [
  student_id: string
  guardian_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userProfiles/{studentId}/guardians/{guardianId}"
    path_params: [{name: studentId, var: student_id}, {name: guardianId, var: guardian_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    student_id: $student_id, guardian_id: $guardian_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a user profile. This method returns the following error codes: * `PERMISSION_DENIED` if the requesting user is not permitted to access this user profile, if no profile exists with the requested ID, or for access errors.
#
# GET /v1/userProfiles/{userId}
# Returns: record<emailAddress: string, id: string, name: record<familyName: string, fullName: string, givenName: string>, permissions: table<permission: string>, photoUrl: string, verifiedTeacher: bool>
# operationId: classroom.userProfiles.get
export def "classroom-user-profiles-get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/userProfiles/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
