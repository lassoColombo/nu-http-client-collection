# Auto-generated client for Google Home v2.0
# Source: https://api.apis.guru/v2/specs/google.home/2.0/openapi.json
# Auth: --token flag or $env.GOOGLE_HOME_TOKEN

const CLIENT = {
  base_url: "http://example.com/setup"
  token_env_var: "GOOGLE_HOME_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: cast-local-authorization-token, in: header, header_name: cast-local-authorization-token, prefix: ""}
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

def base-url-completer [] { ["http://example.com/setup"] }
def auth-scheme-completer [] { ["cast-local-authorization-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    legal-notice: "string"
    accessibility: "record<endpoint_enabled: bool, hotword_enabled: bool>"
    get-alarmsand-timers: "record<alarm: table<date_pattern: record, fire_time: float, id: string, status: int, time_pattern: record>, timer: table<fire_time: int, id: string, original_duration: int, status: int>>"
    delete-alarmsand-timers: "record<success: bool>"
    alarm-volume: "record<volume: float>"
    check-ready-status: "record<can_enroll: bool, enrollment_state: int, error_code: int, ready: bool, retryable: bool>"
    do-not-disturb: "record<notifications_enabled: bool>"
    night-modesettings: "record<do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: table<days: list, length_hours: float, start_hour: float>>"
    forgetpaireddevice: "record"
    pairwith-speaker: "record"
    change-discoverability: "record"
    get-paired-devices: "table<bond_date: float, device_class: int, device_type: int, last_connect_date: float, mac_address: string, name: string, rssi: int, service_uuids: list<string>>"
    scanfordevices: "record"
    get-scan-results: "table<device_class: int, device_type: int, expected_profiles: int, mac_address: string, name: string, rssi: int>"
    status: "record<audio_mode: int, connected_devices: table<device: record, enabled_profiles: int>, connecting_devices: list<string>, discovery_enabled: bool, remote_sink: record<bond_date: float, device_class: int, device_type: int, last_connect_date: int, mac_address: string, name: string, rssi: int, service_uuids: list<string>>, scanning_enabled: bool>"
    get-saved-networks: "table<ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int>"
    eureka-info: "record<aogh: record<aogh_api_version: string>, audio: record<digital: bool>, build_info: record<build_type: int, cast_build_revision: string, cast_control_version: int, preview_channel_state: int, release_track: string, system_build_number: string>, detail: record<icon_list: list<record>, locale: record<display_string: string>, timezone: record<display_string: string, offset: int>>, device_info: record<\"4k_blocked\": int, capabilities: record<aogh_supported: bool, assistant_supported: bool, audio_hdr_supported: bool, audio_surround_mode_supported: bool, ble_supported: bool, bluetooth_audio_sink_supported: bool, bluetooth_audio_source_supported: bool, bluetooth_supported: bool, cloudcast_supported: bool, content_filters_supported: bool, display_supported: bool, fdr_supported: bool, hdmi_prefer_50hz_supported: bool, hdmi_prefer_high_fps_supported: bool, hotspot_supported: bool, https_setup_supported: bool, input_management_supported: bool, keep_hotspot_until_connected_supported: bool, multi_user_supported: bool, multichannel_group_supported: bool, multizone_supported: bool, night_mode_supported: bool, night_mode_supported_v2: bool, opencast_supported: bool, preview_channel_supported: bool, reboot_supported: bool, remote_ducking_supported: bool, separate_tts_volume_supported: bool, setup_supported: bool, sleep_mode_supported: bool, stats_supported: bool, system_sound_effects_supported: bool, user_eq_supported: bool, wifi_auto_save_supported: bool, wifi_regulatory_domain_locked: bool, wifi_supported: bool>, cloud_device_id: string, factory_country_code: string, hotspot_bssid: string, local_authorization_token_hash: string, mac_address: string, manufacturer: string, model_name: string, product_name: string, public_key: string, ssdp_udn: string, uma_client_id: string, uptime: float, weave_device_id: string>, multizone: record<audio_output_delay: int, audio_output_delay_hdmi: int, audio_output_delay_oem: int, aux_in_group: string, dynamic_groups: list<string>, groups: list<string>, multichannel_status: int>, name: string, net: record<ethernet_connected: bool, ip_address: string, online: bool>, night_mode_params: record<device_override_do_not_disturb: int, do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: list<record>>, opencast: record<pin_code: string>, opt_in: record<audio_hdr: bool, audio_surround_mode: int, autoplay_on_signal: bool, cloud_ipc: bool, hdmi_prefer_50hz: bool, hdmi_prefer_high_fps: bool, managed_mode: bool, opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool, ui_flipped: bool, wpa3_support_enabled: bool>, proxy: record<mode: string>, settings: record<closed_caption: record, control_notifications: int, country_code: string, locale: string, network_standby: int, system_sound_effects: bool, time_format: int, timezone: string, wake_on_cast: int>, setup: record<qr_ssid_suffix: string, setup_state: int, ssid_suffix: string, stats: record<num_check_connectivity: int, num_connect_wifi: int, num_connected_wifi_not_saved: int, num_initial_eureka_info: int, num_obtain_ip: int>, tos_accepted: bool>, sign: record<certificate: string, intermediate_certs: list<string>, nonce: string, signed_data: string>, user_eq: record<high_shelf: record<frequency: int, gain_db: int, quality: float>, low_shelf: record<frequency: int, gain_db: int, quality: float>, max_peaking_eqs: int, peaking_eqs: list<string>>, version: int, wifi: record<bssid: string, has_changes: bool, noise_level: int, signal_level: int, ssid: string, wpa_configured: bool, wpa_id: int, wpa_state: int>>"
    forget-wi-fi-network: "record"
    app-device-id: "record<app_device_id: string, certificate: string, signed_data: string>"
    offer: "record<token: string>"
    rebootand-factory-reset: "record"
    get-wi-fi-scan-results: "table<bssid: string, signal_level: int, ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int>"
    scanfor-networks: "record"
    set-eureka-info: "record"
    locales: "table<display_string: string, locale: string>"
    timezones: "table<display_string: string, offset: int, timezone: string>"
    test-internet-download-speed: "record<bytes_received: int, response_code: int, time_for_data_fetch: int, time_for_http_response: int>"
    set-equalizer-values: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["legal-notice" "accessibility" "get-alarmsand-timers" "delete-alarmsand-timers" "alarm-volume" "check-ready-status" "do-not-disturb" "night-modesettings" "forgetpaireddevice" "pairwith-speaker" "change-discoverability" "get-paired-devices" "scanfordevices" "get-scan-results" "status" "get-saved-networks" "connectto-wi-fi-network" "eureka-info" "forget-wi-fi-network" "app-device-id" "chromecast-icon" "offer" "rebootand-factory-reset" "get-wi-fi-scan-results" "scanfor-networks" "set-eureka-info" "locales" "timezones" "test-internet-download-speed" "set-equalizer-values" "commands"] | sort) } | get name | first)
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

# Legal Notice
#
# GET /NOTICE.html.gz
# Returns: string
# operationId: LegalNotice
export def "legal-notice" [
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
    path: "/NOTICE.html.gz"
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accessibility
#
# POST /assistant/a11y_mode
# Returns: record<endpoint_enabled: bool, hotword_enabled: bool>
# operationId: Accessibility
export def "accessibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-enabled: oneof<nothing, bool>
  --hotword-enabled: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assistant/a11y_mode"
    body: {content_type: "application/json", kind: json, fields: [{name: endpoint_enabled, var: endpoint_enabled, required: true}, {name: hotword_enabled, var: hotword_enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    endpoint_enabled: $endpoint_enabled, hotword_enabled: $hotword_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Alarms and Timers
#
# GET /assistant/alarms
# Returns: record<alarm: table<date_pattern: record, fire_time: float, id: string, status: int, time_pattern: record>, timer: table<fire_time: int, id: string, original_duration: int, status: int>>
# operationId: GetAlarmsandTimers
export def "get-alarmsand-timers" [
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
    path: "/assistant/alarms"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Alarms and Timers
#
# POST /assistant/alarms/delete
# Returns: record<success: bool>
# operationId: DeleteAlarmsandTimers
export def "delete-alarmsand-timers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assistant/alarms/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Alarm Volume
#
# POST /assistant/alarms/volume
# Returns: record<volume: float>
# operationId: AlarmVolume
export def "alarm-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  volume: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assistant/alarms/volume"
    body: {content_type: "application/json", kind: json, fields: [{name: volume, var: volume}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    volume: $volume
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check Ready Status
#
# POST /assistant/check_ready_status
# Returns: record<can_enroll: bool, enrollment_state: int, error_code: int, ready: bool, retryable: bool>
# operationId: CheckReadyStatus
export def "check-ready-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --play-ready-message: oneof<nothing, bool>
  user_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assistant/check_ready_status"
    body: {content_type: "application/json", kind: json, fields: [{name: play_ready_message, var: play_ready_message, required: true}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    play_ready_message: $play_ready_message, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Do Not Disturb
#
# POST /assistant/notifications
# Returns: record<notifications_enabled: bool>
# operationId: DoNotDisturb
export def "do-not-disturb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required, e.g. application/json
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/assistant/notifications"
    header: [{name: Content-Type, var: content_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    content_type: $content_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Night Mode settings
#
# POST /assistant/set_night_mode_params
# Returns: record<do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: table<days: list, length_hours: float, start_hour: float>>
# operationId: NightModesettings
export def "night-modesettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --demo-to-user: oneof<nothing, bool>
  --do-not-disturb: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  led_brightness: float
  volume: float
  windows: list # item shape: {days: list<int>, length_hours: int, start_hour: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assistant/set_night_mode_params"
    body: {content_type: "application/json", kind: json, fields: [{name: demo_to_user, var: demo_to_user, required: true}, {name: do_not_disturb, var: do_not_disturb, required: true}, {name: enabled, var: enabled, required: true}, {name: led_brightness, var: led_brightness}, {name: volume, var: volume}, {name: windows, var: windows}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    demo_to_user: $demo_to_user, do_not_disturb: $do_not_disturb, enabled: $enabled, led_brightness: $led_brightness, volume: $volume, windows: $windows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forget paired device
#
# POST /bluetooth/bond
# Returns: record
# operationId: Forgetpaireddevice
export def "forgetpaireddevice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bond: oneof<nothing, bool>
  mac_address: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bluetooth/bond"
    body: {content_type: "application/json", kind: json, fields: [{name: bond, var: bond, required: true}, {name: mac_address, var: mac_address}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    bond: $bond, mac_address: $mac_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pair with Speaker
#
# POST /bluetooth/connect
# Returns: record
# operationId: PairwithSpeaker
export def "pairwith-speaker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connect: oneof<nothing, bool>
  mac_address: string
  profile: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bluetooth/connect"
    body: {content_type: "application/json", kind: json, fields: [{name: connect, var: connect, required: true}, {name: mac_address, var: mac_address}, {name: profile, var: profile}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    connect: $connect, mac_address: $mac_address, profile: $profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Discoverability
#
# POST /bluetooth/discovery
# Returns: record
# operationId: ChangeDiscoverability
export def "change-discoverability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable-discovery: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bluetooth/discovery"
    body: {content_type: "application/json", kind: json, fields: [{name: enable_discovery, var: enable_discovery, required: true}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    enable_discovery: $enable_discovery
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Paired Devices
#
# GET /bluetooth/get_bonded
# Returns: table<bond_date: float, device_class: int, device_type: int, last_connect_date: float, mac_address: string, name: string, rssi: int, service_uuids: list<string>>
# operationId: GetPairedDevices
export def "get-paired-devices" [
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
    path: "/bluetooth/get_bonded"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan for devices
#
# POST /bluetooth/scan
# Returns: record
# operationId: Scanfordevices
export def "scanfordevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-results: oneof<nothing, bool>
  --enable: oneof<nothing, bool>
  timeout: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bluetooth/scan"
    body: {content_type: "application/json", kind: json, fields: [{name: clear_results, var: clear_results, required: true}, {name: enable, var: enable, required: true}, {name: timeout, var: timeout}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    clear_results: $clear_results, enable: $enable, timeout: $timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Scan Results
#
# GET /bluetooth/scan_results
# Returns: table<device_class: int, device_type: int, expected_profiles: int, mac_address: string, name: string, rssi: int>
# operationId: GetScanResults
export def "get-scan-results" [
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
    path: "/bluetooth/scan_results"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Status
#
# GET /bluetooth/status
# Returns: record<audio_mode: int, connected_devices: table<device: record, enabled_profiles: int>, connecting_devices: list<string>, discovery_enabled: bool, remote_sink: record<bond_date: float, device_class: int, device_type: int, last_connect_date: int, mac_address: string, name: string, rssi: int, service_uuids: list<string>>, scanning_enabled: bool>
# operationId: Status
export def "status" [
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
    path: "/bluetooth/status"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Saved Networks
#
# GET /configured_networks
# Returns: table<ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int>
# operationId: GetSavedNetworks
export def "get-saved-networks" [
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
    path: "/configured_networks"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect to Wi-Fi Network
#
# POST /connect_wifi
# operationId: ConnecttoWi-FiNetwork
export def "connectto-wi-fi-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bssid: string
  enc_passwd: string
  signal_level: int # format: int32
  ssid: string
  wpa_auth: int # format: int32
  wpa_cipher: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/connect_wifi"
    body: {content_type: "application/json", kind: json, fields: [{name: bssid, var: bssid}, {name: enc_passwd, var: enc_passwd}, {name: signal_level, var: signal_level}, {name: ssid, var: ssid}, {name: wpa_auth, var: wpa_auth}, {name: wpa_cipher, var: wpa_cipher}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    bssid: $bssid, enc_passwd: $enc_passwd, signal_level: $signal_level, ssid: $ssid, wpa_auth: $wpa_auth, wpa_cipher: $wpa_cipher
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Eureka Info
#
# GET /eureka_info
# Returns: record<aogh: record<aogh_api_version: string>, audio: record<digital: bool>, build_info: record<build_type: int, cast_build_revision: string, cast_control_version: int, preview_channel_state: int, release_track: string, system_build_number: string>, detail: record<icon_list: list<record>, locale: record<display_string: string>, timezone: record<display_string: string, offset: int>>, device_info: record<"4k_blocked": int, capabilities: record<aogh_supported: bool, assistant_supported: bool, audio_hdr_supported: bool, audio_surround_mode_supported: bool, ble_supported: bool, bluetooth_audio_sink_supported: bool, bluetooth_audio_source_supported: bool, bluetooth_supported: bool, cloudcast_supported: bool, content_filters_supported: bool, display_supported: bool, fdr_supported: bool, hdmi_prefer_50hz_supported: bool, hdmi_prefer_high_fps_supported: bool, hotspot_supported: bool, https_setup_supported: bool, input_management_supported: bool, keep_hotspot_until_connected_supported: bool, multi_user_supported: bool, multichannel_group_supported: bool, multizone_supported: bool, night_mode_supported: bool, night_mode_supported_v2: bool, opencast_supported: bool, preview_channel_supported: bool, reboot_supported: bool, remote_ducking_supported: bool, separate_tts_volume_supported: bool, setup_supported: bool, sleep_mode_supported: bool, stats_supported: bool, system_sound_effects_supported: bool, user_eq_supported: bool, wifi_auto_save_supported: bool, wifi_regulatory_domain_locked: bool, wifi_supported: bool>, cloud_device_id: string, factory_country_code: string, hotspot_bssid: string, local_authorization_token_hash: string, mac_address: string, manufacturer: string, model_name: string, product_name: string, public_key: string, ssdp_udn: string, uma_client_id: string, uptime: float, weave_device_id: string>, multizone: record<audio_output_delay: int, audio_output_delay_hdmi: int, audio_output_delay_oem: int, aux_in_group: string, dynamic_groups: list<string>, groups: list<string>, multichannel_status: int>, name: string, net: record<ethernet_connected: bool, ip_address: string, online: bool>, night_mode_params: record<device_override_do_not_disturb: int, do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: list<record>>, opencast: record<pin_code: string>, opt_in: record<audio_hdr: bool, audio_surround_mode: int, autoplay_on_signal: bool, cloud_ipc: bool, hdmi_prefer_50hz: bool, hdmi_prefer_high_fps: bool, managed_mode: bool, opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool, ui_flipped: bool, wpa3_support_enabled: bool>, proxy: record<mode: string>, settings: record<closed_caption: record, control_notifications: int, country_code: string, locale: string, network_standby: int, system_sound_effects: bool, time_format: int, timezone: string, wake_on_cast: int>, setup: record<qr_ssid_suffix: string, setup_state: int, ssid_suffix: string, stats: record<num_check_connectivity: int, num_connect_wifi: int, num_connected_wifi_not_saved: int, num_initial_eureka_info: int, num_obtain_ip: int>, tos_accepted: bool>, sign: record<certificate: string, intermediate_certs: list<string>, nonce: string, signed_data: string>, user_eq: record<high_shelf: record<frequency: int, gain_db: int, quality: float>, low_shelf: record<frequency: int, gain_db: int, quality: float>, max_peaking_eqs: int, peaking_eqs: list<string>>, version: int, wifi: record<bssid: string, has_changes: bool, noise_level: int, signal_level: int, ssid: string, wpa_configured: bool, wpa_id: int, wpa_state: int>>
# operationId: EurekaInfo
export def "eureka-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # required, e.g. version,audio,name,build_info,detail,device_info,net,wifi,setup,settings,opt_in,opencast,multizone,proxy,night_mode_params,user_eq,room_equalizer,sign,aogh,ultrasound,mesh
  --options: string # required, e.g. detail,sign
  --nonce: int # required, format: int32, e.g. 1234512345
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/eureka_info"
    query: [{name: params, var: params, required: true}, {name: options, var: options, required: true}, {name: nonce, var: nonce, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    params: $params, options: $options, nonce: $nonce
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forget Wi-Fi Network
#
# POST /forget_wifi
# Returns: record
# operationId: ForgetWi-FiNetwork
export def "forget-wi-fi-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  wpa_id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forget_wifi"
    body: {content_type: "application/json", kind: json, fields: [{name: wpa_id, var: wpa_id}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    wpa_id: $wpa_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# App Device ID
#
# POST /get_app_device_id
# Returns: record<app_device_id: string, certificate: string, signed_data: string>
# operationId: AppDeviceID
export def "app-device-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/get_app_device_id"
    body: {content_type: "application/json", kind: json, fields: [{name: app_id, var: app_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Chromecast Icon
#
# GET /icon.png
# operationId: ChromecastIcon
export def "chromecast-icon" [
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
    path: "/icon.png"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Offer
#
# GET /offer
# Returns: record<token: string>
# operationId: Offer
export def "offer" [
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
    path: "/offer"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboot and Factory Reset
#
# POST /reboot
# Returns: record
# operationId: RebootandFactoryReset
export def "rebootand-factory-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  params: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reboot"
    body: {content_type: "application/json", kind: json, fields: [{name: params, var: params}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    params: $params
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Wi-Fi Scan Results
#
# GET /scan_results
# Returns: table<bssid: string, signal_level: int, ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int>
# operationId: GetWi-FiScanResults
export def "get-wi-fi-scan-results" [
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
    path: "/scan_results"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Scan for Networks
#
# POST /scan_wifi
# Returns: record
# operationId: ScanforNetworks
export def "scanfor-networks" [
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
    path: "/scan_wifi"
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Eureka Info
#
# POST /set_eureka_info
# Returns: record
# operationId: SetEurekaInfo
export def "set-eureka-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  opt_in: record # e.g. {opencast: true, preview_channel: true, remote_ducking: true, stats: true} — shape: {opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool}
  settings: record # e.g. {control_notifications: 2} — shape: {control_notifications: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/set_eureka_info"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: opt_in, var: opt_in}, {name: settings, var: settings}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    name: $name, opt_in: $opt_in, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Locales
#
# GET /supported_locales
# Returns: table<display_string: string, locale: string>
# operationId: Locales
export def "locales" [
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
    path: "/supported_locales"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Timezones
#
# GET /supported_timezones
# Returns: table<display_string: string, offset: int, timezone: string>
# operationId: Timezones
export def "timezones" [
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
    path: "/supported_timezones"
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Internet Download Speed
#
# POST /test_internet_download_speed
# Returns: record<bytes_received: int, response_code: int, time_for_data_fetch: int, time_for_http_response: int>
# operationId: TestInternetDownloadSpeed
export def "test-internet-download-speed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/test_internet_download_speed"
    body: {content_type: "application/json", kind: json, fields: [{name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Equalizer Values
#
# POST /user_eq/set_equalizer
# Returns: record
# operationId: SetEqualizerValues
export def "set-equalizer-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  high_shelf: record # e.g. {gain_db: 0} — shape: {gain_db: int}
  low_shelf: record # e.g. {gain_db: 0} — shape: {gain_db: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user_eq/set_equalizer"
    body: {content_type: "application/json", kind: json, fields: [{name: high_shelf, var: high_shelf}, {name: low_shelf, var: low_shelf}]}
    accept: ["text/plain"]
    ok: [200]
    auth: cast-local-authorization-token
  } {
    high_shelf: $high_shelf, low_shelf: $low_shelf
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
