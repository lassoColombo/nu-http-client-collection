# Auto-generated client for Cloud Debugger API v2
# Source: https://api.apis.guru/v2/specs/googleapis.com/clouddebugger/v2/openapi.json
# Auth: --token flag or $env.CLOUD_DEBUGGER_API_TOKEN

const CLIENT = {
  base_url: "https://clouddebugger.googleapis.com"
  token_env_var: "CLOUD_DEBUGGER_API_TOKEN"
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

def base-url-completer [] { ["https://clouddebugger.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def action-value-completer [] { ["CAPTURE" "LOG"] }
def canary-option-completer [] { ["CANARY_OPTION_TRY_DISABLE" "CANARY_OPTION_TRY_ENABLE" "CANARY_OPTION_UNSPECIFIED"] }
def action-completer [] { ["CAPTURE" "LOG"] }
def log-level-completer [] { ["ERROR" "INFO" "WARNING"] }
def state-completer [] { ["STATE_CANARY_ACTIVE" "STATE_CANARY_PENDING_AGENTS" "STATE_IS_FINAL" "STATE_ROLLING_TO_ALL" "STATE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    clouddebugger-controller-debuggees-register: "record<agentId: string, debuggee: record<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list<record>, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list<record>, status: record<description: record, isError: bool, refersTo: string>, uniquifier: string>>"
    clouddebugger-controller-debuggees-breakpoints-list: "record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string, waitExpired: bool>"
    clouddebugger-controller-debuggees-breakpoints-update: "record"
    clouddebugger-debugger-debuggees-list: "record<debuggees: table<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list, status: record, uniquifier: string>>"
    clouddebugger-debugger-debuggees-breakpoints-list: "record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string>"
    clouddebugger-debugger-debuggees-breakpoints-set: "record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>>"
    clouddebugger-debugger-debuggees-breakpoints-delete: "record"
    clouddebugger-debugger-debuggees-breakpoints-get: "record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["clouddebugger-controller-debuggees-register" "clouddebugger-controller-debuggees-breakpoints-list" "clouddebugger-controller-debuggees-breakpoints-update" "clouddebugger-debugger-debuggees-list" "clouddebugger-debugger-debuggees-breakpoints-list" "clouddebugger-debugger-debuggees-breakpoints-set" "clouddebugger-debugger-debuggees-breakpoints-delete" "clouddebugger-debugger-debuggees-breakpoints-get" "commands"] | sort) } | get name | first)
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

# Registers the debuggee with the controller service. All agents attached to the same application must call this method with exactly the same request content to get back the same stable `debuggee_id`. Agents should call this method again whenever `google.rpc.Code.NOT_FOUND` is returned from any controller method. This protocol allows the controller service to disable debuggees, recover from data loss, or change the `debuggee_id` format. Agents must handle `debuggee_id` value changing upon re-registration.
#
# POST /v2/controller/debuggees/register
# Returns: record<agentId: string, debuggee: record<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list<record>, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list<record>, status: record<description: record, isError: bool, refersTo: string>, uniquifier: string>>
# operationId: clouddebugger.controller.debuggees.register
export def "clouddebugger-controller-debuggees-register" [
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
  --debuggee: record # Represents the debugged application. The application may include one or more replicated processes executing the same code. Each of these processes is attached with a debugger agent, carrying out the debugging commands. Agents attached to the same debuggee identify themselves as such by using exactly the same Debuggee message value when registering. — shape: {agentVersion?: string, canaryMode?: "CANARY_MODE_UNSPECIFIED"|"CANARY_MODE_ALWAYS_ENABLED"|"CANARY_MODE_ALWAYS_DISABLED"|"CANARY_MODE_DEFAULT_ENABLED"|"CANARY_MODE_DEFAULT_DISABLED", description?: string, extSourceContexts?: list, id?: string, isDisabled?: bool, isInactive?: bool, labels?: record, project?: string, sourceContexts?: list, status?: record, uniquifier?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/controller/debuggees/register"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: debuggee, var: debuggee}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, debuggee: $debuggee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of all active breakpoints for the debuggee. The breakpoint specification (`location`, `condition`, and `expressions` fields) is semantically immutable, although the field values may change. For example, an agent may update the location line number to reflect the actual line where the breakpoint was set, but this doesn't change the breakpoint semantics. This means that an agent does not need to check if a breakpoint has changed when it encounters the same breakpoint on a successive call. Moreover, an agent should remember the breakpoints that are completed until the controller removes them from the active list to avoid setting those breakpoints again.
#
# GET /v2/controller/debuggees/{debuggeeId}/breakpoints
# Returns: record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string, waitExpired: bool>
# operationId: clouddebugger.controller.debuggees.breakpoints.list
export def "clouddebugger-controller-debuggees-breakpoints-list" [
  debuggee_id: string
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
  --agent-id: string # Identifies the agent. This is the ID returned in the RegisterDebuggee response.
  --success-on-timeout: oneof<nothing, bool> # If set to `true` (recommended), returns `google.rpc.Code.OK` status and sets the `wait_expired` response field to `true` when the server-selected timeout has expired. If set to `false` (deprecated), returns `google.rpc.Code.ABORTED` status when the server-selected timeout has expired.
  --wait-token: string # A token that, if specified, blocks the method call until the list of active breakpoints has changed, or a server-selected timeout has expired. The value should be set from the `next_wait_token` field in the last response. The initial value should be set to `"init"`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/controller/debuggees/{debuggeeId}/breakpoints"
    path_params: [{name: debuggeeId, var: debuggee_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: agentId, var: agent_id}, {name: successOnTimeout, var: success_on_timeout}, {name: waitToken, var: wait_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, agent_id: $agent_id, success_on_timeout: $success_on_timeout, wait_token: $wait_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the breakpoint state or mutable fields. The entire Breakpoint message must be sent back to the controller service. Updates to active breakpoint fields are only allowed if the new value does not change the breakpoint specification. Updates to the `location`, `condition` and `expressions` fields should not alter the breakpoint semantics. These may only make changes such as canonicalizing a value or snapping the location to the correct line of code.
#
# PUT /v2/controller/debuggees/{debuggeeId}/breakpoints/{id}
# Returns: record
# operationId: clouddebugger.controller.debuggees.breakpoints.update
export def "clouddebugger-controller-debuggees-breakpoints-update" [
  debuggee_id: string
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
  --breakpoint: record # ------------------------------------------------------------------------------ ## Breakpoint (the resource) Represents the breakpoint specification, status and results. — shape: {action?: "CAPTURE"|"LOG", canaryExpireTime?: string, condition?: string, createTime?: string, evaluatedExpressions?: list, expressions?: list<string>, finalTime?: string, id?: string, isFinalState?: bool, labels?: record, location?: record, logLevel?: "INFO"|"WARNING"|"ERROR", logMessageFormat?: string, stackFrames?: list, state?: "STATE_UNSPECIFIED"|"STATE_CANARY_PENDING_AGENTS"|"STATE_CANARY_ACTIVE"|"STATE_ROLLING_TO_ALL"|"STATE_IS_FINAL", status?: record, userEmail?: string, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/controller/debuggees/{debuggeeId}/breakpoints/{id}"
    path_params: [{name: debuggeeId, var: debuggee_id}, {name: id, var: id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: breakpoint, var: breakpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, id: $id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, breakpoint: $breakpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the debuggees that the user has access to.
#
# GET /v2/debugger/debuggees
# Returns: record<debuggees: table<agentVersion: string, canaryMode: string, description: string, extSourceContexts: list, id: string, isDisabled: bool, isInactive: bool, labels: record, project: string, sourceContexts: list, status: record, uniquifier: string>>
# operationId: clouddebugger.debugger.debuggees.list
export def "clouddebugger-debugger-debuggees-list" [
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
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --include-inactive: oneof<nothing, bool> # When set to `true`, the result includes all debuggees. Otherwise, the result includes only debuggees that are active.
  --project: string # Required. Project number of a Google Cloud project whose debuggees to list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/debugger/debuggees"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientVersion, var: client_version}, {name: includeInactive, var: include_inactive}, {name: project, var: project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_version: $client_version, include_inactive: $include_inactive, project: $project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all breakpoints for the debuggee.
#
# GET /v2/debugger/debuggees/{debuggeeId}/breakpoints
# Returns: record<breakpoints: table<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list, expressions: list, finalTime: string, id: string, isFinalState: bool, labels: record, location: record, logLevel: string, logMessageFormat: string, stackFrames: list, state: string, status: record, userEmail: string, variableTable: list>, nextWaitToken: string>
# operationId: clouddebugger.debugger.debuggees.breakpoints.list
export def "clouddebugger-debugger-debuggees-breakpoints-list" [
  debuggee_id: string
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
  --action-value: string@action-value-completer # Only breakpoints with the specified action will pass the filter.
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --include-all-users: oneof<nothing, bool> # When set to `true`, the response includes the list of breakpoints set by any user. Otherwise, it includes only breakpoints set by the caller.
  --include-inactive: oneof<nothing, bool> # When set to `true`, the response includes active and inactive breakpoints. Otherwise, it includes only active breakpoints.
  --strip-results: oneof<nothing, bool> # This field is deprecated. The following fields are always stripped out of the result: `stack_frames`, `evaluated_expressions` and `variable_table`.
  --wait-token: string # A wait token that, if specified, blocks the call until the breakpoints list has changed, or a server selected timeout has expired. The value should be set from the last response. The error code `google.rpc.Code.ABORTED` (RPC) is returned on wait timeout, which should be called again with the same `wait_token`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/debugger/debuggees/{debuggeeId}/breakpoints"
    path_params: [{name: debuggeeId, var: debuggee_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "action.value", var: action_value}, {name: clientVersion, var: client_version}, {name: includeAllUsers, var: include_all_users}, {name: includeInactive, var: include_inactive}, {name: stripResults, var: strip_results}, {name: waitToken, var: wait_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action_value: $action_value, client_version: $client_version, include_all_users: $include_all_users, include_inactive: $include_inactive, strip_results: $strip_results, wait_token: $wait_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the breakpoint to the debuggee.
#
# POST /v2/debugger/debuggees/{debuggeeId}/breakpoints/set
# Returns: record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>>
# operationId: clouddebugger.debugger.debuggees.breakpoints.set
export def "clouddebugger-debugger-debuggees-breakpoints-set" [
  debuggee_id: string
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
  --canary-option: string@canary-option-completer # The canary option set by the user upon setting breakpoint.
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
  --action: string@action-completer # Action that the agent should perform when the code at the breakpoint location is hit.
  --canary-expire-time: string # The deadline for the breakpoint to stay in CANARY_ACTIVE state. The value is meaningless when the breakpoint is not in CANARY_ACTIVE state. (format: google-datetime)
  --condition: string # Condition that triggers the breakpoint. The condition is a compound boolean expression composed using expressions in a programming language at the source location.
  --create-time: string # Time this breakpoint was created by the server in seconds resolution. (format: google-datetime)
  --evaluated-expressions: list # Values of evaluated expressions at breakpoint time. The evaluated expressions appear in exactly the same order they are listed in the `expressions` field. The `name` field holds the original expression text, the `value` or `members` field holds the result of the evaluated expression. If the expression cannot be evaluated, the `status` inside the `Variable` will indicate an error and contain the error text. — item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
  --expressions: list<string> # List of read-only expressions to evaluate at the breakpoint location. The expressions are composed using expressions in the programming language at the source location. If the breakpoint action is `LOG`, the evaluated expressions are included in log statements.
  --final-time: string # Time this breakpoint was finalized as seen by the server in seconds resolution. (format: google-datetime)
  --id: string # Breakpoint identifier, unique in the scope of the debuggee.
  --is-final-state: oneof<nothing, bool> # When true, indicates that this is a final result and the breakpoint state will not change from here on.
  --labels: record # A set of custom breakpoint properties, populated by the agent, to be displayed to the user.
  --location: record # Represents a location in the source code. — shape: {column?: int, line?: int, path?: string}
  --log-level: string@log-level-completer # Indicates the severity of the log. Only relevant when action is `LOG`.
  --log-message-format: string # Only relevant when action is `LOG`. Defines the message to log when the breakpoint hits. The message may include parameter placeholders `$0`, `$1`, etc. These placeholders are replaced with the evaluated value of the appropriate expression. Expressions not referenced in `log_message_format` are not logged. Example: `Message received, id = $0, count = $1` with `expressions` = `[ message.id, message.count ]`.
  --stack-frames: list # The stack at breakpoint time, where stack_frames[0] represents the most recently entered function. — item shape: {arguments?: list, function?: string, locals?: list, location?: record}
  --state: string@state-completer # The current state of the breakpoint.
  --status: record # Represents a contextual status message. The message can indicate an error or informational status, and refer to specific parts of the containing object. For example, the `Breakpoint.status` field can indicate an error referring to the `BREAKPOINT_SOURCE_LOCATION` with the message `Location not found`. — shape: {description?: record, isError?: bool, refersTo?: "UNSPECIFIED"|"BREAKPOINT_SOURCE_LOCATION"|"BREAKPOINT_CONDITION"|"BREAKPOINT_EXPRESSION"|"BREAKPOINT_AGE"|"BREAKPOINT_CANARY_FAILED"|"VARIABLE_NAME"|"VARIABLE_VALUE"}
  --user-email: string # E-mail address of the user that created this breakpoint
  --variable-table: list # The `variable_table` exists to aid with computation, memory and network traffic optimization. It enables storing a variable once and reference it from multiple variables, including variables stored in the `variable_table` itself. For example, the same `this` object, which may appear at many levels of the stack, can have all of its data stored once in this table. The stack frame variables then would hold only a reference to it. The variable `var_table_index` field is an index into this repeated field. The stored objects are nameless and get their name from the referencing variable. The effective variable is a merge of the referencing variable and the referenced variable. — item shape: {members?: list, name?: string, status?: record, type?: string, value?: string, varTableIndex?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/debugger/debuggees/{debuggeeId}/breakpoints/set"
    path_params: [{name: debuggeeId, var: debuggee_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: canaryOption, var: canary_option}, {name: clientVersion, var: client_version}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: canaryExpireTime, var: canary_expire_time}, {name: condition, var: condition}, {name: createTime, var: create_time}, {name: evaluatedExpressions, var: evaluated_expressions}, {name: expressions, var: expressions}, {name: finalTime, var: final_time}, {name: id, var: id}, {name: isFinalState, var: is_final_state}, {name: labels, var: labels}, {name: location, var: location}, {name: logLevel, var: log_level}, {name: logMessageFormat, var: log_message_format}, {name: stackFrames, var: stack_frames}, {name: state, var: state}, {name: status, var: status}, {name: userEmail, var: user_email}, {name: variableTable, var: variable_table}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, canary_option: $canary_option, client_version: $client_version, action: $action, canary_expire_time: $canary_expire_time, condition: $condition, create_time: $create_time, evaluated_expressions: $evaluated_expressions, expressions: $expressions, final_time: $final_time, id: $id, is_final_state: $is_final_state, labels: $labels, location: $location, log_level: $log_level, log_message_format: $log_message_format, stack_frames: $stack_frames, state: $state, status: $status, user_email: $user_email, variable_table: $variable_table
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the breakpoint from the debuggee.
#
# DELETE /v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}
# Returns: record
# operationId: clouddebugger.debugger.debuggees.breakpoints.delete
export def "clouddebugger-debugger-debuggees-breakpoints-delete" [
  debuggee_id: string
  breakpoint_id: string
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
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}"
    path_params: [{name: debuggeeId, var: debuggee_id}, {name: breakpointId, var: breakpoint_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientVersion, var: client_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, breakpoint_id: $breakpoint_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_version: $client_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets breakpoint information.
#
# GET /v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}
# Returns: record<breakpoint: record<action: string, canaryExpireTime: string, condition: string, createTime: string, evaluatedExpressions: list<record>, expressions: list<string>, finalTime: string, id: string, isFinalState: bool, labels: record, location: record<column: int, line: int, path: string>, logLevel: string, logMessageFormat: string, stackFrames: list<record>, state: string, status: record<description: record, isError: bool, refersTo: string>, userEmail: string, variableTable: list<record>>>
# operationId: clouddebugger.debugger.debuggees.breakpoints.get
export def "clouddebugger-debugger-debuggees-breakpoints-get" [
  debuggee_id: string
  breakpoint_id: string
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
  --client-version: string # Required. The client version making the call. Schema: `domain/type/version` (e.g., `google.com/intellij/v1`).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/debugger/debuggees/{debuggeeId}/breakpoints/{breakpointId}"
    path_params: [{name: debuggeeId, var: debuggee_id}, {name: breakpointId, var: breakpoint_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clientVersion, var: client_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    debuggee_id: $debuggee_id, breakpoint_id: $breakpoint_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_version: $client_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
