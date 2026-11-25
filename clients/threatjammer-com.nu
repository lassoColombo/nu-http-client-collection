# Auto-generated client for ThreatJammer.com User API v1.2.20
# Source: https://api.apis.guru/v2/specs/threatjammer.com/1.2.20/openapi.json
# Auth: --token flag or $env.THREATJAMMER_COM_USER_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "THREATJAMMER_COM_USER_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["as" "cidr" "continent" "country" "datacenter" "useragent"] }
def status-completer [] { ["ACTIVE" "DELETED" "INACTIVE"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE"] }
def code-completer [] { ["afrinic" "apnic" "arin" "iana" "lacnic" "ripencc"] }
def code-completer-1 [] { ["allocated" "assigned" "available" "reserved"] }
def ip-protocol-version-completer [] { ["ALL" "IPV4" "IPV6"] }
def output-format-completer [] { ["AWS-WAF" "CSV" "JSON"] }
def interval-completer [] { ["HOURLY"] }
def status-id-completer [] { ["block" "bypass" "challenge" "ignore" "pass"] }
def time-range-completer [] { ["12H" "180D" "1D" "1H" "30D" "365D" "6H" "7D" "90D"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-private-allowlist-of-the-user-v1-allowlist-private-post: "string"
    get-all-private-allowlists-v1-allowlist-private-all-get: "record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-private-allowlists-by-resource-type-v1-allowlist-private-all-resource-type-get: "record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>"
    query-resource-denylists-v1-allowlist-private-ip-address-get: "record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>"
    get-single-allowlist-v1-allowlist-private-allowlist-id-get: "record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int>"
    get-allowlist-content-v1-allowlist-private-allowlist-id-content-get: "record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>>"
    get-all-public-allowlists-v1-allowlist-public-all-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-public-allowlists-by-resource-type-v1-allowlist-public-all-resource-type-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    query-resource-allowlists-v1-allowlist-public-ip-address-get: "record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>"
    get-public-allowlists-owned-by-the-user-v1-allowlist-public-owned-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-owned-allowlists-by-resource-type-v1-allowlist-public-owned-resource-type-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-single-allowlist-v1-allowlist-public-allowlist-id-get: "record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int>"
    query-ip-address-network-information-v1-asn-ip-ip-address-get: "record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>"
    query-asn-prefix-information-v1-asn-prefix-post: "record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>"
    query-registry-names-v1-asn-registry-all-get: "table<code: string, name: string, self: string>"
    query-registry-by-the-name-v1-asn-registry-code-get: "record<code: string, name: string, self: string>"
    query-status-names-v1-asn-status-all-get: "table<code: string, name: string, self: string>"
    query-status-by-the-name-v1-asn-status-code-get: "record<code: string, name: string, self: string>"
    query-asn-v1-asn-number-get: "record<country_code: string, description: string, name: string, prefixes: string, registry: string, registry_date: string, risk: string, score: int, self: string, status: string>"
    query-asn-prefixes-list-v1-asn-number-prefixes-get: "record<asn: string, prefixes_v4: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, prefixes_v6: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, self: string>"
    assess-ip-set-v1-assess-ip-post: "record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string>"
    assess-ip-set-csv-v1-assess-ip-csv-post: "record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string>"
    assess-ip-v1-assess-ip-ip-address-get: "record<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list<string>, denylisted: string, first_appearance: list<string>, last_appearance: list<string>, reason: string, risk: string, score: int, self: string, sources: list<string>>"
    query-ip-address-network-information-v1-datacenter-ip-ip-address-get: "record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>"
    query-datacenter-prefix-information-v1-datacenter-prefix-post: "record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>"
    query-datacenter-v1-datacenter-datacenter-id-get: "record<asn: string, description: string, name: string, prefixes: string, risk: string, score: int, self: string, source: string, status: string>"
    query-datacenter-prefixes-list-v1-datacenter-datacenter-id-prefixes-get: "record<prefixes_v4: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, prefixes_v6: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, self: string>"
    query-datataset-information-of-all-the-resource-types-v1-dataset-ip-get: "record<self: string, types: table<description: string, items: int, name: string, self: string, status: string, type: string>>"
    query-datataset-information-of-the-resource-type-v1-dataset-ip-name-get: "record<description: string, items: int, name: string, self: string, status: string, type: string>"
    create-private-denylist-of-the-user-v1-denylist-private-post: "string"
    get-all-private-denylists-v1-denylist-private-all-get: "record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-private-denylists-by-resource-type-v1-denylist-private-all-resource-type-get: "record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>"
    query-resource-denylists-v1-denylist-private-ip-address-get: "record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>"
    get-single-denylist-v1-denylist-private-denylist-id-get: "record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int>"
    get-denylist-content-v1-denylist-private-denylist-id-content-get: "record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>>"
    get-all-public-denylists-v1-denylist-public-all-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-public-denylists-by-resource-type-v1-denylist-public-all-resource-type-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    query-resource-denylists-v1-denylist-public-ip-address-get: "record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>"
    get-public-denylists-owned-by-the-user-v1-denylist-public-owned-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-all-owned-denylists-by-resource-type-v1-denylist-public-owned-resource-type-get: "record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>"
    get-single-denylist-v1-denylist-public-denylist-id-get: "record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int>"
    query-all-the-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-get: "record<addresses: table<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list, total_reports: int>, self: string>"
    query-an-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-ip-address-get: "record<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list<string>, total_reports: int>"
    geolocate-ip-set-v1-geo-post: "record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string>"
    assess-ip-set-csv-v1-geo-csv-post: "record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string>"
    geolocate-ip-v1-geo-ip-address-get: "record<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list<string>, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>"
    log-change-id-v1-log-ip-id-logchange-id-get: "record<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int>"
    logchanges-ip-v1-log-ip-ip-address-get: "record<logs: table<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int>, self: string>"
    query-origin-information-v1-origin-get: "record<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int>"
    update-configuration-origin-v1-origin-put: "record"
    query-origin-address-status-information-v1-origin-addresses-get: "record<addresses: table<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string>"
    query-all-origin-information-v1-origin-all-get: "record<origins: table<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int>, self: string>"
    query-origin-traffic-client-v1-origin-client-analysis-get: "record<data: table<client_browser: int, client_crawler: int, client_email: int, client_library: int, client_mobile_browser: int, client_multimedia_player: int, client_offline_browser: int, client_total: int, client_ua_anonymizer: int, client_unrecognized: int, client_validator: int, client_wap_browser: int, crawler_feed_fetcher: int, crawler_link_checker: int, crawler_marketing: int, crawler_screenshot_creator: int, crawler_search_engine_bot: int, crawler_site_monitor: int, crawler_speed_tester: int, crawler_tool: int, crawler_total: int, crawler_uncategorised: int, crawler_unrecognized: int, crawler_virus_scanner: int, crawler_vulnerability_scanner: int, crawler_web_scraper: int, timestamp: int, total: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int>"
    query-origin-cookie-id-status-information-v1-origin-cookies-get: "record<cookie_ids: table<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string>"
    query-origin-scripts-v1-origin-scripts-get: "record<detection: string, self: string>"
    query-origin-status-v1-origin-status-post: "record<address: record<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, cookie_id: record<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, self: string>"
    query-origin-status-detail-v1-origin-status-detail-status-id-get: "record<cardinality: int, description: string, self: string, status: string>"
    query-origin-status-details-v1-origin-status-details-get: "record<list: table<cardinality: int, description: string, self: string, status: string>, self: string>"
    query-origin-traffic-analysis-v1-origin-traffic-analysis-get: "record<data: table<asn_risky: int, bots: int, datacenters: int, denylists: int, network_country_mismatches: int, score_high: int, timestamp: int, total: int, webdrivers: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int>"
    query-origin-token-info-v1-origin-token-post: "record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>"
    query-all-origin-tokens-in-the-region-v1-origin-token-all-get: "record<self: string, tokens: table<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>>"
    create-a-new-origin-token-v1-origin-token-new-post: "record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>"
    get-all-sources-v1-source-ip-get: "record<self: string, sources: table<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list, updated_at: int, url: string>>"
    get-source-info-v1-source-ip-source-get: "record<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list<string>, updated_at: int, url: string>"
    get-source-and-timerange-info-v1-source-ip-source-range-time-range-get: "record<items: int, lapse: string, risk: string, score: int, self: string, source: string, updated_at: int>"
    query-token-info-v1-token-get: "record<created_at: int, last_minute_bucket_init_value: int, last_minute_bucket_refill_ratio: int, last_minute_bucket_refresh: int, last_minute_bucket_value: int, last_month_bucket_init_value: int, last_month_bucket_refresh: int, last_month_bucket_value: int, region_id: string, self: string, status: string, updated_at: int>"
    query-token-activity-v1-token-activity-get: "record<activities: table<created_at: int, data: record, description: string, event: string, self: string, source: record>, page: int, page_size: int, self: string>"
    parse-user-agents-v1-ua-post: "record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string>"
    parse-user-agents-csv-v1-ua-csv-post: "record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string>"
    query-device-by-code-v1-ua-device-code-get: "record<code: string, description: string>"
    query-family-by-code-v1-ua-family-code-get: "record<code: string, description: string>"
    query-os-by-code-v1-ua-os-code-get: "record<code: string, description: string, family: string, vendor: string>"
    query-type-by-code-v1-ua-type-code-get: "record<code: string, description: string, type: string>"
    query-vendor-by-code-v1-ua-vendor-code-get: "record<code: string, description: string>"
    parse-user-agent-v1-ua-user-agent-urlencoded-get: "record<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-private-allowlist-of-the-user-v1-allowlist-private-post" "get-all-private-allowlists-v1-allowlist-private-all-get" "get-all-private-allowlists-by-resource-type-v1-allowlist-private-all-resource-type-get" "query-resource-denylists-v1-allowlist-private-ip-address-get" "delete-the-allowlist-v1-allowlist-private-allowlist-id-delete" "get-single-allowlist-v1-allowlist-private-allowlist-id-get" "update-private-allowlist-of-the-user-v1-allowlist-private-allowlist-id-put" "delete-the-allowlist-content-v1-allowlist-private-allowlist-id-content-delete" "get-allowlist-content-v1-allowlist-private-allowlist-id-content-get" "update-private-content-of-the-allowlist-of-the-user-v1-allowlist-private-allowlist-id-content-put" "change-status-of-the-origin-allowlist-v1-allowlist-private-allowlist-id-origin-put" "get-all-public-allowlists-v1-allowlist-public-all-get" "get-all-public-allowlists-by-resource-type-v1-allowlist-public-all-resource-type-get" "query-resource-allowlists-v1-allowlist-public-ip-address-get" "get-public-allowlists-owned-by-the-user-v1-allowlist-public-owned-get" "get-all-owned-allowlists-by-resource-type-v1-allowlist-public-owned-resource-type-get" "delete-the-allowlist-v1-allowlist-public-allowlist-id-delete" "get-single-allowlist-v1-allowlist-public-allowlist-id-get" "change-status-of-the-allowlist-v1-allowlist-public-allowlist-id-put" "change-status-of-the-origin-allowlist-v1-allowlist-public-allowlist-id-origin-put" "query-ip-address-network-information-v1-asn-ip-ip-address-get" "query-asn-prefix-information-v1-asn-prefix-post" "query-registry-names-v1-asn-registry-all-get" "query-registry-by-the-name-v1-asn-registry-code-get" "query-status-names-v1-asn-status-all-get" "query-status-by-the-name-v1-asn-status-code-get" "query-asn-v1-asn-number-get" "query-asn-prefixes-list-v1-asn-number-prefixes-get" "assess-ip-set-v1-assess-ip-post" "assess-ip-set-csv-v1-assess-ip-csv-post" "assess-ip-v1-assess-ip-ip-address-get" "query-ip-address-network-information-v1-datacenter-ip-ip-address-get" "query-datacenter-prefix-information-v1-datacenter-prefix-post" "query-datacenter-v1-datacenter-datacenter-id-get" "query-datacenter-prefixes-list-v1-datacenter-datacenter-id-prefixes-get" "query-datataset-information-of-all-the-resource-types-v1-dataset-ip-get" "query-datataset-information-of-the-resource-type-v1-dataset-ip-name-get" "create-private-denylist-of-the-user-v1-denylist-private-post" "get-all-private-denylists-v1-denylist-private-all-get" "get-all-private-denylists-by-resource-type-v1-denylist-private-all-resource-type-get" "query-resource-denylists-v1-denylist-private-ip-address-get" "delete-the-denylist-v1-denylist-private-denylist-id-delete" "get-single-denylist-v1-denylist-private-denylist-id-get" "update-private-denylist-of-the-user-v1-denylist-private-denylist-id-put" "delete-the-denylist-content-v1-denylist-private-denylist-id-content-delete" "get-denylist-content-v1-denylist-private-denylist-id-content-get" "update-private-content-of-the-denylist-of-the-user-v1-denylist-private-denylist-id-content-put" "change-status-of-the-origin-denylist-v1-denylist-private-denylist-id-origin-put" "get-all-public-denylists-v1-denylist-public-all-get" "get-all-public-denylists-by-resource-type-v1-denylist-public-all-resource-type-get" "query-resource-denylists-v1-denylist-public-ip-address-get" "get-public-denylists-owned-by-the-user-v1-denylist-public-owned-get" "get-all-owned-denylists-by-resource-type-v1-denylist-public-owned-resource-type-get" "delete-the-denylist-v1-denylist-public-denylist-id-delete" "get-single-denylist-v1-denylist-public-denylist-id-get" "change-status-of-the-denylist-v1-denylist-public-denylist-id-put" "change-status-of-the-origin-denylist-v1-denylist-public-denylist-id-origin-put" "query-all-the-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-get" "delete-all-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-all-delete" "delete-an-ip-address-reported-by-the-user-v1-denylist-reported-ip-ip-address-delete" "query-an-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-ip-address-get" "geolocate-ip-set-v1-geo-post" "assess-ip-set-csv-v1-geo-csv-post" "geolocate-ip-v1-geo-ip-address-get" "log-change-id-v1-log-ip-id-logchange-id-get" "logchanges-ip-v1-log-ip-ip-address-get" "query-origin-information-v1-origin-get" "update-configuration-origin-v1-origin-put" "query-origin-address-status-information-v1-origin-addresses-get" "query-all-origin-information-v1-origin-all-get" "query-origin-traffic-client-v1-origin-client-analysis-get" "query-origin-cookie-id-status-information-v1-origin-cookies-get" "query-origin-scripts-v1-origin-scripts-get" "query-origin-status-v1-origin-status-post" "query-origin-status-detail-v1-origin-status-detail-status-id-get" "query-origin-status-details-v1-origin-status-details-get" "query-origin-traffic-analysis-v1-origin-traffic-analysis-get" "delete-token-v1-origin-token-delete" "query-origin-token-info-v1-origin-token-post" "query-all-origin-tokens-in-the-region-v1-origin-token-all-get" "disable-origin-token-v1-origin-token-disable-put" "enable-origin-token-v1-origin-token-enable-put" "create-a-new-origin-token-v1-origin-token-new-post" "get-all-sources-v1-source-ip-get" "get-source-info-v1-source-ip-source-get" "get-source-and-timerange-info-v1-source-ip-source-range-time-range-get" "query-token-info-v1-token-get" "query-token-activity-v1-token-activity-get" "parse-user-agents-v1-ua-post" "parse-user-agents-csv-v1-ua-csv-post" "query-device-by-code-v1-ua-device-code-get" "query-family-by-code-v1-ua-family-code-get" "query-os-by-code-v1-ua-os-code-get" "query-type-by-code-v1-ua-type-code-get" "query-vendor-by-code-v1-ua-vendor-code-get" "parse-user-agent-v1-ua-user-agent-urlencoded-get" "commands"] | sort) } | get name | first)
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

# Creates a new private allowlist binded to the user.
#
# POST /v1/allowlist/private
# Returns: string
# operationId: create_private_allowlist_of_the_user_v1_allowlist_private_post
export def "create-private-allowlist-of-the-user-v1-allowlist-private-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payload: record # The information needed to create a new allowlist — shape: {description: string, name: string, resource_type: "UNKNOWN"|"CIDR"|"COUNTRY"|"CONTINENT"|"AS"|"DATACENTER"|"USERAGENT", tags: list<string>, ttl?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/allowlist/private"
    body: {content_type: "application/json", kind: json, fields: [{name: payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of private allowlists of the user.
#
# GET /v1/allowlist/private/all
# Returns: record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_private_allowlists_v1_allowlist_private_all_get
export def "get-all-private-allowlists-v1-allowlist-private-all-get" [
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
    path: "/v1/allowlist/private/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of private allowlists of the user by resource type.
#
# GET /v1/allowlist/private/all/{resource_type}
# Returns: record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_private_allowlists_by_resource_type_v1_allowlist_private_all__resource_type__get
export def "get-all-private-allowlists-by-resource-type-v1-allowlist-private-all-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/allowlist/private/all/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the different private allowlists where the IP address was found.
#
# GET /v1/allowlist/private/ip/{address}
# Returns: record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>
# operationId: query_resource_denylists_v1_allowlist_private_ip__address__get
export def "query-resource-denylists-v1-allowlist-private-ip-address-get" [
  address: string
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
    path: "/v1/allowlist/private/ip/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the bindings between a user and a private allowlist.
#
# DELETE /v1/allowlist/private/{allowlist_id}
# operationId: delete_the_allowlist_v1_allowlist_private__allowlist_id__delete
export def "delete-the-allowlist-v1-allowlist-private-allowlist-id-delete" [
  allowlist_id: string
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
    path: "/v1/allowlist/private/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a specific private allowlist of the user.
#
# GET /v1/allowlist/private/{allowlist_id}
# Returns: record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int>
# operationId: get_single_allowlist_v1_allowlist_private__allowlist_id__get
export def "get-single-allowlist-v1-allowlist-private-allowlist-id-get" [
  allowlist_id: string
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
    path: "/v1/allowlist/private/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the information of an existing private allowlist of the user.
#
# PUT /v1/allowlist/private/{allowlist_id}
# operationId: update_private_allowlist_of_the_user_v1_allowlist_private__allowlist_id__put
export def "update-private-allowlist-of-the-user-v1-allowlist-private-allowlist-id-put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The human readable full description of the list
  --name: string # The name of the list
  --tags: list<string> # The list of tags to associate with the list
  --ttl: int # Optional. The Time To Live (TTL) of a resource in the list in seconds.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/allowlist/private/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: tags, var: tags}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id, description: $description, name: $name, tags: $tags, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the content of a private allowlist of the user.
#
# DELETE /v1/allowlist/private/{allowlist_id}/content
# operationId: delete_the_allowlist_content_v1_allowlist_private__allowlist_id__content_delete
export def "delete-the-allowlist-content-v1-allowlist-private-allowlist-id-content-delete" [
  allowlist_id: string
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
    path: "/v1/allowlist/private/{allowlist_id}/content"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of a private allowlist of the user.
#
# GET /v1/allowlist/private/{allowlist_id}/content
# Returns: record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>>
# operationId: get_allowlist_content_v1_allowlist_private__allowlist_id__content_get
export def "get-allowlist-content-v1-allowlist-private-allowlist-id-content-get" [
  allowlist_id: string
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
    path: "/v1/allowlist/private/{allowlist_id}/content"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or remove content of a private allowlist of the user.
#
# PUT /v1/allowlist/private/{allowlist_id}/content
# operationId: update_private_content_of_the_allowlist_of_the_user_v1_allowlist_private__allowlist_id__content_put
export def "update-private-content-of-the-allowlist-of-the-user-v1-allowlist-private-allowlist-id-content-put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --append: list<string> # The name of the resources to append to the allowlist
  --remove: list<string> # The name of the resources to remove from the allowlist
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/allowlist/private/{allowlist_id}/content"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: append, var: append}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id, append: $append, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of the origin in an allow list.
#
# PUT /v1/allowlist/private/{allowlist_id}/origin
# operationId: change_status_of_the_origin_allowlist_v1_allowlist_private__allowlist_id__origin_put
export def "change-status-of-the-origin-allowlist-v1-allowlist-private-allowlist-id-origin-put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/allowlist/private/{allowlist_id}/origin"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: origin, var: origin}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id, origin: $origin, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public allowlists.
#
# GET /v1/allowlist/public/all
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_public_allowlists_v1_allowlist_public_all_get
export def "get-all-public-allowlists-v1-allowlist-public-all-get" [
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
    path: "/v1/allowlist/public/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public allowlists by resource type.
#
# GET /v1/allowlist/public/all/{resource_type}
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_public_allowlists_by_resource_type_v1_allowlist_public_all__resource_type__get
export def "get-all-public-allowlists-by-resource-type-v1-allowlist-public-all-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/allowlist/public/all/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the different public allowlists where the IP address was found.
#
# GET /v1/allowlist/public/ip/{address}
# Returns: record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>
# operationId: query_resource_allowlists_v1_allowlist_public_ip__address__get
export def "query-resource-allowlists-v1-allowlist-public-ip-address-get" [
  address: string
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
    path: "/v1/allowlist/public/ip/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of owned allowlists.
#
# GET /v1/allowlist/public/owned
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_public_allowlists_owned_by_the_user_v1_allowlist_public_owned_get
export def "get-public-allowlists-owned-by-the-user-v1-allowlist-public-owned-get" [
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
    path: "/v1/allowlist/public/owned"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public allowlists of a user by resource type.
#
# GET /v1/allowlist/public/owned/{resource_type}
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_owned_allowlists_by_resource_type_v1_allowlist_public_owned__resource_type__get
export def "get-all-owned-allowlists-by-resource-type-v1-allowlist-public-owned-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/allowlist/public/owned/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the bindings between a user and an allowlist.
#
# DELETE /v1/allowlist/public/{allowlist_id}
# operationId: delete_the_allowlist_v1_allowlist_public__allowlist_id__delete
export def "delete-the-allowlist-v1-allowlist-public-allowlist-id-delete" [
  allowlist_id: string
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
    path: "/v1/allowlist/public/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of the allowlist.
#
# GET /v1/allowlist/public/{allowlist_id}
# Returns: record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int>
# operationId: get_single_allowlist_v1_allowlist_public__allowlist_id__get
export def "get-single-allowlist-v1-allowlist-public-allowlist-id-get" [
  allowlist_id: string
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
    path: "/v1/allowlist/public/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of an allow list.
#
# PUT /v1/allowlist/public/{allowlist_id}
# operationId: change_status_of_the_allowlist_v1_allowlist_public__allowlist_id__put
export def "change-status-of-the-allowlist-v1-allowlist-public-allowlist-id-put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-1 # The status of the list. ACTIVE or INACTIVE
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/allowlist/public/{allowlist_id}"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of the origin in an allow list.
#
# PUT /v1/allowlist/public/{allowlist_id}/origin
# operationId: change_status_of_the_origin_allowlist_v1_allowlist_public__allowlist_id__origin_put
export def "change-status-of-the-origin-allowlist-v1-allowlist-public-allowlist-id-origin-put" [
  allowlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/allowlist/public/{allowlist_id}/origin"
    path_params: [{name: allowlist_id, var: allowlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: origin, var: origin}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allowlist_id: $allowlist_id, origin: $origin, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the IPv4 or IPv6 prefix of the IP address given.
#
# GET /v1/asn/ip/{ip_address}
# Returns: record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>
# operationId: query_IP_address_network_information_v1_asn_ip__ip_address__get
export def "query-ip-address-network-information-v1-asn-ip-ip-address-get" [
  ip_address: string
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
    path: "/v1/asn/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the IPv4 or IPv6 prefix of the CIDR given.
#
# POST /v1/asn/prefix
# Returns: record<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>
# operationId: query_asn_prefix_information_v1_asn_prefix_post
export def "query-asn-prefix-information-v1-asn-prefix-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  prefix: string # format: ipvanynetwork
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/asn/prefix"
    body: {content_type: "application/json", kind: json, fields: [{name: prefix, var: prefix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prefix: $prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the Regional Internet Registries (RIRs) entities worldwide.
#
# GET /v1/asn/registry/all
# Returns: table<code: string, name: string, self: string>
# operationId: query_registry_names_v1_asn_registry_all_get
export def "query-registry-names-v1-asn-registry-all-get" [
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
    path: "/v1/asn/registry/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of a Regional Internet Registries (RIRs) given.
#
# GET /v1/asn/registry/{code}
# Returns: record<code: string, name: string, self: string>
# operationId: query_registry_by_the_name_v1_asn_registry__code__get
export def "query-registry-by-the-name-v1-asn-registry-code-get" [
  code: string@code-completer
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
    path: "/v1/asn/registry/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of status of an object in a registry.
#
# GET /v1/asn/status/all
# Returns: table<code: string, name: string, self: string>
# operationId: query_status_names_v1_asn_status_all_get
export def "query-status-names-v1-asn-status-all-get" [
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
    path: "/v1/asn/status/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of a status given.
#
# GET /v1/asn/status/{code}
# Returns: record<code: string, name: string, self: string>
# operationId: query_status_by_the_name_v1_asn_status__code__get
export def "query-status-by-the-name-v1-asn-status-code-get" [
  code: string@code-completer-1
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
    path: "/v1/asn/status/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Autonomous System details of the AS number given.
#
# GET /v1/asn/{number}
# Returns: record<country_code: string, description: string, name: string, prefixes: string, registry: string, registry_date: string, risk: string, score: int, self: string, status: string>
# operationId: query_asn_v1_asn__number__get
export def "query-asn-v1-asn-number-get" [
  number: int
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
    path: "/v1/asn/{number}"
    path_params: [{name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of IPv4 and IPv6 prefixes of the AS number given.
#
# GET /v1/asn/{number}/prefixes
# Returns: record<asn: string, prefixes_v4: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, prefixes_v6: table<asn: string, description: string, mantainer: string, object_type: string, registry_date: string, registry_status: string, risk: string, score: int, self: string>, self: string>
# operationId: query_asn_prefixes_list_v1_asn__number__prefixes_get
export def "query-asn-prefixes-list-v1-asn-number-prefixes-get" [
  number: int
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
    path: "/v1/asn/{number}/prefixes"
    path_params: [{name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the risk score of all IP address passed in the body and other data signals.
#
# POST /v1/assess/ip
# Returns: record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string>
# operationId: assess_ip_set_v1_assess_ip_post
export def "assess-ip-set-v1-assess-ip-post" [
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
    path: "/v1/assess/ip"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the risk score of all IP address uploaded and other data signals.
#
# POST /v1/assess/ip/csv
# Returns: record<results: table<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list, denylisted: string, first_appearance: list, last_appearance: list, reason: string, risk: string, score: int, self: string, sources: list>, self: string>
# operationId: assess_ip_set_csv_v1_assess_ip_csv_post
export def "assess-ip-set-csv-v1-assess-ip-csv-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strict-parse: oneof<nothing, bool> # When `true`, if any IP address entry in the file is malformed, the assessment is canceled. If `false`, the malformed IP addresses are ignored. Default is `false`. (default: false)
  csv_file: string # The CSV file with the IP addresses (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/assess/ip/csv"
    query: [{name: strict_parse, var: strict_parse}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: csv_file, var: csv_file}], files: [csv_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    strict_parse: $strict_parse, csv_file: $csv_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a risk score of the IP address and different data signals.
#
# GET /v1/assess/ip/{ip_address}
# Returns: record<allowlisted: string, asn: string, asn_prefix: string, datacenter: string, datacenter_prefix: string, datasets: list<string>, denylisted: string, first_appearance: list<string>, last_appearance: list<string>, reason: string, risk: string, score: int, self: string, sources: list<string>>
# operationId: assess_ip_v1_assess_ip__ip_address__get
export def "assess-ip-v1-assess-ip-ip-address-get" [
  ip_address: string
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
    path: "/v1/assess/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the IPv4 or IPv6 prefix of the IP address given.
#
# GET /v1/datacenter/ip/{ip_address}
# Returns: record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>
# operationId: query_IP_address_network_information_v1_datacenter_ip__ip_address__get
export def "query-ip-address-network-information-v1-datacenter-ip-ip-address-get" [
  ip_address: string
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
    path: "/v1/datacenter/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the IPv4 or IPv6 prefix of the CIDR given.
#
# POST /v1/datacenter/prefix
# Returns: record<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>
# operationId: query_datacenter_prefix_information_v1_datacenter_prefix_post
export def "query-datacenter-prefix-information-v1-datacenter-prefix-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  prefix: string # format: ipvanynetwork
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/datacenter/prefix"
    body: {content_type: "application/json", kind: json, fields: [{name: prefix, var: prefix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    prefix: $prefix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Datacenter details of datacente given.
#
# GET /v1/datacenter/{datacenter_id}
# Returns: record<asn: string, description: string, name: string, prefixes: string, risk: string, score: int, self: string, source: string, status: string>
# operationId: query_datacenter_v1_datacenter__datacenter_id__get
export def "query-datacenter-v1-datacenter-datacenter-id-get" [
  datacenter_id: string
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
    path: "/v1/datacenter/{datacenter_id}"
    path_params: [{name: datacenter_id, var: datacenter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    datacenter_id: $datacenter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of IPv4 and IPv6 prefixes of the Datacenter given.
#
# GET /v1/datacenter/{datacenter_id}/prefixes
# Returns: record<prefixes_v4: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, prefixes_v6: table<datacenter: string, ip_abuse_total: int, max_score: int, min_score: int, risk: string, score: int, self: string>, self: string>
# operationId: query_datacenter_prefixes_list_v1_datacenter__datacenter_id__prefixes_get
export def "query-datacenter-prefixes-list-v1-datacenter-datacenter-id-prefixes-get" [
  datacenter_id: string
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
    path: "/v1/datacenter/{datacenter_id}/prefixes"
    path_params: [{name: datacenter_id, var: datacenter_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    datacenter_id: $datacenter_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of all the datasets available in the platform.
#
# GET /v1/dataset/ip
# Returns: record<self: string, types: table<description: string, items: int, name: string, self: string, status: string, type: string>>
# operationId: query_datataset_information_of_all_the_resource_types_v1_dataset_ip_get
export def "query-datataset-information-of-all-the-resource-types-v1-dataset-ip-get" [
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
    path: "/v1/dataset/ip"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the detailed information of the dataset queried.
#
# GET /v1/dataset/ip/{name}
# Returns: record<description: string, items: int, name: string, self: string, status: string, type: string>
# operationId: query_datataset_information_of_the_resource_type_v1_dataset_ip__name__get
export def "query-datataset-information-of-the-resource-type-v1-dataset-ip-name-get" [
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
    path: "/v1/dataset/ip/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new private denylist binded to the user.
#
# POST /v1/denylist/private
# Returns: string
# operationId: create_private_denylist_of_the_user_v1_denylist_private_post
export def "create-private-denylist-of-the-user-v1-denylist-private-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payload: record # The information needed to create a new denylist — shape: {description: string, name: string, resource_type: "UNKNOWN"|"CIDR"|"COUNTRY"|"CONTINENT"|"AS"|"DATACENTER"|"USERAGENT", tags: list<string>, ttl?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/denylist/private"
    body: {content_type: "application/json", kind: json, fields: [{name: payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of private denylists of the user.
#
# GET /v1/denylist/private/all
# Returns: record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_private_denylists_v1_denylist_private_all_get
export def "get-all-private-denylists-v1-denylist-private-all-get" [
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
    path: "/v1/denylist/private/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of private denylists of the user by resource type.
#
# GET /v1/denylist/private/all/{resource_type}
# Returns: record<lists: table<content: string, created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_private_denylists_by_resource_type_v1_denylist_private_all__resource_type__get
export def "get-all-private-denylists-by-resource-type-v1-denylist-private-all-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/denylist/private/all/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the different denylists where the IP address was found.
#
# GET /v1/denylist/private/ip/{address}
# Returns: record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>
# operationId: query_resource_denylists_v1_denylist_private_ip__address__get
export def "query-resource-denylists-v1-denylist-private-ip-address-get" [
  address: string
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
    path: "/v1/denylist/private/ip/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the bindings between a user and a private denylist.
#
# DELETE /v1/denylist/private/{denylist_id}
# operationId: delete_the_denylist_v1_denylist_private__denylist_id__delete
export def "delete-the-denylist-v1-denylist-private-denylist-id-delete" [
  denylist_id: string
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
    path: "/v1/denylist/private/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of a specific private denylist of the user.
#
# GET /v1/denylist/private/{denylist_id}
# Returns: record<content: string, created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, tags: list<string>, ttl: int, updated_at: int>
# operationId: get_single_denylist_v1_denylist_private__denylist_id__get
export def "get-single-denylist-v1-denylist-private-denylist-id-get" [
  denylist_id: string
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
    path: "/v1/denylist/private/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the information of an existing private denylist of the user.
#
# PUT /v1/denylist/private/{denylist_id}
# operationId: update_private_denylist_of_the_user_v1_denylist_private__denylist_id__put
export def "update-private-denylist-of-the-user-v1-denylist-private-denylist-id-put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The human readable full description of the list
  --name: string # The name of the list
  --tags: list<string> # The list of tags to associate with the list
  --ttl: int # Optional. The Time To Live (TTL) of a resource in the list in seconds.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/denylist/private/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: tags, var: tags}, {name: ttl, var: ttl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id, description: $description, name: $name, tags: $tags, ttl: $ttl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the content of a private denylist of the user.
#
# DELETE /v1/denylist/private/{denylist_id}/content
# operationId: delete_the_denylist_content_v1_denylist_private__denylist_id__content_delete
export def "delete-the-denylist-content-v1-denylist-private-denylist-id-content-delete" [
  denylist_id: string
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
    path: "/v1/denylist/private/{denylist_id}/content"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content of a private denylist of the user.
#
# GET /v1/denylist/private/{denylist_id}/content
# Returns: record<asns: list<int>, cidrs: list<any>, continents: list<string>, countries: list<string>, datacenters: list<string>, self: string, user_agents: list<string>>
# operationId: get_denylist_content_v1_denylist_private__denylist_id__content_get
export def "get-denylist-content-v1-denylist-private-denylist-id-content-get" [
  denylist_id: string
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
    path: "/v1/denylist/private/{denylist_id}/content"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or remove content of a private denylist of the user.
#
# PUT /v1/denylist/private/{denylist_id}/content
# operationId: update_private_content_of_the_denylist_of_the_user_v1_denylist_private__denylist_id__content_put
export def "update-private-content-of-the-denylist-of-the-user-v1-denylist-private-denylist-id-content-put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --append: list<string> # The name of the resources to append to the denylist
  --remove: list<string> # The name of the resources to remove from the denylist
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/denylist/private/{denylist_id}/content"
    path_params: [{name: denylist_id, var: denylist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: append, var: append}, {name: remove, var: remove}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id, append: $append, remove: $remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of the origin in a deny list.
#
# PUT /v1/denylist/private/{denylist_id}/origin
# operationId: change_status_of_the_origin_denylist_v1_denylist_private__denylist_id__origin_put
export def "change-status-of-the-origin-denylist-v1-denylist-private-denylist-id-origin-put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/denylist/private/{denylist_id}/origin"
    path_params: [{name: denylist_id, var: denylist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: origin, var: origin}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id, origin: $origin, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public denylists.
#
# GET /v1/denylist/public/all
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_public_denylists_v1_denylist_public_all_get
export def "get-all-public-denylists-v1-denylist-public-all-get" [
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
    path: "/v1/denylist/public/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public denylists by resource type.
#
# GET /v1/denylist/public/all/{resource_type}
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_public_denylists_by_resource_type_v1_denylist_public_all__resource_type__get
export def "get-all-public-denylists-by-resource-type-v1-denylist-public-all-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/denylist/public/all/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the different public denylists where the IP address was found.
#
# GET /v1/denylist/public/ip/{address}
# Returns: record<asns: list<string>, cidrs: list<string>, continents: list<string>, countries: list<string>, datacenters: list<string>, reported: list<string>, self: string>
# operationId: query_resource_denylists_v1_denylist_public_ip__address__get
export def "query-resource-denylists-v1-denylist-public-ip-address-get" [
  address: string
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
    path: "/v1/denylist/public/ip/{address}"
    path_params: [{name: address, var: address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of owned denylists.
#
# GET /v1/denylist/public/owned
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_public_denylists_owned_by_the_user_v1_denylist_public_owned_get
export def "get-public-denylists-owned-by-the-user-v1-denylist-public-owned-get" [
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
    path: "/v1/denylist/public/owned"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the set of public denylists of a user by resource type.
#
# GET /v1/denylist/public/owned/{resource_type}
# Returns: record<lists: table<created_at: int, description: string, list_type: string, name: string, origins: record, resource_type: string, self: string, status: string, tags: list, ttl: int, updated_at: int>, self: string>
# operationId: get_all_owned_denylists_by_resource_type_v1_denylist_public_owned__resource_type__get
export def "get-all-owned-denylists-by-resource-type-v1-denylist-public-owned-resource-type-get" [
  resource_type: string@resource-type-completer
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
    path: "/v1/denylist/public/owned/{resource_type}"
    path_params: [{name: resource_type, var: resource_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the bindings between a user and an denylist.
#
# DELETE /v1/denylist/public/{denylist_id}
# operationId: delete_the_denylist_v1_denylist_public__denylist_id__delete
export def "delete-the-denylist-v1-denylist-public-denylist-id-delete" [
  denylist_id: string
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
    path: "/v1/denylist/public/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of the denylist.
#
# GET /v1/denylist/public/{denylist_id}
# Returns: record<created_at: int, description: string, list_type: string, name: string, origins: record<lists: list<record>, self: string>, resource_type: string, self: string, status: string, tags: list<string>, ttl: int, updated_at: int>
# operationId: get_single_denylist_v1_denylist_public__denylist_id__get
export def "get-single-denylist-v1-denylist-public-denylist-id-get" [
  denylist_id: string
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
    path: "/v1/denylist/public/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of an deny list.
#
# PUT /v1/denylist/public/{denylist_id}
# operationId: change_status_of_the_denylist_v1_denylist_public__denylist_id__put
export def "change-status-of-the-denylist-v1-denylist-public-denylist-id-put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-1 # The status of the list. ACTIVE or INACTIVE
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/denylist/public/{denylist_id}"
    path_params: [{name: denylist_id, var: denylist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toogle the status of the origin in a deny list.
#
# PUT /v1/denylist/public/{denylist_id}/origin
# operationId: change_status_of_the_origin_denylist_v1_denylist_public__denylist_id__origin_put
export def "change-status-of-the-origin-denylist-v1-denylist-public-denylist-id-origin-put" [
  denylist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin: string # The protocol and domain of the origin to change the status (format: uri)
  status: string@status-completer # The status of the list. ACTIVE, INACTIVE, DELETED
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/denylist/public/{denylist_id}/origin"
    path_params: [{name: denylist_id, var: denylist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: origin, var: origin}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    denylist_id: $denylist_id, origin: $origin, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of automatically reported IP addresses by the user.
#
# GET /v1/denylist/reported/ip
# Returns: record<addresses: table<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list, total_reports: int>, self: string>
# operationId: query_all_the_ip_addresses_reported_by_the_user_v1_denylist_reported_ip_get
export def "query-all-the-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataset: string # The dataset list type to filter for. Must be uppercase, numbers and underscore
  --reported-before: int # Restricts the result displaying only the IP addresses reported before `reported_before`. It must be a UNIX timestamp in seconds.
  --reported-after: int # Restricts the result displaying only the IP addresses reported after `reported_after`. It must be a UNIX timestamp in seconds.
  --expires-before: int # Restricts the result displaying only the IP addresses that will expire before `expires_before`. It must be a UNIX timestamp in seconds greater than the current UNIX timestamp.
  --expires-after: int # Restricts the result displaying only the IP addresses that will expire after `expires_after`. It must be a UNIX timestamp in seconds greater than the current UNIX timestamp.
  --greater-than: int # Restricts the result displaying only the IP addresses reported more times than `greater_than`. It must be an integer greater than 0.
  --less-than: int # Restricts the result displaying only the IP addresses reported less times than `less_than`. It must be an integer greater than 1.
  --ip-protocol-version: string@ip-protocol-version-completer # Restrict the result displaying the IP protocol version requested (IPV4 or IPV6) or both (ALL). Some output formats MUST filter by IP protocol version first. (default: ALL)
  --output-format: string@output-format-completer # The output format of the datasets. (default: JSON)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/denylist/reported/ip"
    query: [{name: dataset, var: dataset}, {name: reported_before, var: reported_before}, {name: reported_after, var: reported_after}, {name: expires_before, var: expires_before}, {name: expires_after, var: expires_after}, {name: greater_than, var: greater_than}, {name: less_than, var: less_than}, {name: ip_protocol_version, var: ip_protocol_version}, {name: output_format, var: output_format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset: $dataset, reported_before: $reported_before, reported_after: $reported_after, expires_before: $expires_before, expires_after: $expires_after, greater_than: $greater_than, less_than: $less_than, ip_protocol_version: $ip_protocol_version, output_format: $output_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all the automatically reported IP addresses by the user.
#
# DELETE /v1/denylist/reported/ip/all
# operationId: delete_all_ip_addresses_reported_by_the_user_v1_denylist_reported_ip_all_delete
export def "delete-all-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-all-delete" [
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
    path: "/v1/denylist/reported/ip/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the automatically reported IP address by the user.
#
# DELETE /v1/denylist/reported/ip/{ip_address}
# operationId: delete_an_ip_address_reported_by_the_user_v1_denylist_reported_ip__ip_address__delete
export def "delete-an-ip-address-reported-by-the-user-v1-denylist-reported-ip-ip-address-delete" [
  ip_address: string
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
    path: "/v1/denylist/reported/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the details of an automatically reported IP addresses by the user.
#
# GET /v1/denylist/reported/ip/{ip_address}
# Returns: record<dataset: string, expiry: int, last_report: int, protocol: string, self: string, tags: list<string>, total_reports: int>
# operationId: query_an_ip_addresses_reported_by_the_user_v1_denylist_reported_ip__ip_address__get
export def "query-an-ip-addresses-reported-by-the-user-v1-denylist-reported-ip-ip-address-get" [
  ip_address: string
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
    path: "/v1/denylist/reported/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the geolocation data of the IP addresses set.
#
# POST /v1/geo
# Returns: record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string>
# operationId: geolocate_ip_set_v1_geo_post
export def "geolocate-ip-set-v1-geo-post" [
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
    path: "/v1/geo"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the geolocation data of all the IP addresses uploaded.
#
# POST /v1/geo/csv
# Returns: record<results: table<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>, self: string>
# operationId: assess_ip_set_csv_v1_geo_csv_post
export def "assess-ip-set-csv-v1-geo-csv-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strict-parse: oneof<nothing, bool> # When `true`, if any IP address entry in the file is malformed, the assessment is canceled. If `false`, the malformed IP addresses are ignored. Default is `false`. (default: false)
  csv_file: string # The CSV file with the IP addresses (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/geo/csv"
    query: [{name: strict_parse, var: strict_parse}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: csv_file, var: csv_file}], files: [csv_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    strict_parse: $strict_parse, csv_file: $csv_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the geo location data of the IP address.
#
# GET /v1/geo/{ip_address}
# Returns: record<accuracy_radius: float, asn_country_iso_code: string, city_geoname_code: int, city_name: string, continent_code: string, country_iso_code: string, hostnames: list<string>, latitude: float, longitude: float, postal_code: string, region_geoname_code: int, region_name: string, self: string, time_zone: string>
# operationId: geolocate_ip_v1_geo__ip_address__get
export def "geolocate-ip-v1-geo-ip-address-get" [
  ip_address: string
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
    path: "/v1/geo/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a log event.
#
# GET /v1/log/ip/id/{logchange_id}
# Returns: record<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int>
# operationId: log_change_id_v1_log_ip_id__logchange_id__get
export def "log-change-id-v1-log-ip-id-logchange-id-get" [
  logchange_id: int
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
    path: "/v1/log/ip/id/{logchange_id}"
    path_params: [{name: logchange_id, var: logchange_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    logchange_id: $logchange_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the changes logged in the different datasets of an IP address.
#
# GET /v1/log/ip/{ip_address}
# Returns: record<logs: table<action: string, cidr: string, dataset: string, lapse: string, risk: string, score: int, self: string, source: string, timestamp: int>, self: string>
# operationId: logchanges_ip_v1_log_ip__ip_address__get
export def "logchanges-ip-v1-log-ip-ip-address-get" [
  ip_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataset: string # The name of the dataset to restrict the query
  --logged-after: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after this value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/log/ip/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    query: [{name: dataset, var: dataset}, {name: logged_after, var: logged_after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address, dataset: $dataset, logged_after: $logged_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of an origin of the user in the region.
#
# GET /v1/origin
# Returns: record<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int>
# operationId: query_origin_information_v1_origin_get
export def "query-origin-information-v1-origin-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the configuration of an origin of the user in the region.
#
# PUT /v1/origin
# Returns: record
# operationId: update_configuration_origin_v1_origin_put
export def "update-configuration-origin-v1-origin-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # The configuration information to store in the origin.
  origin: string # The origin site to modify the configruation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/origin"
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: origin, var: origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    config: $config, origin: $origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the address status of the origin of the user in the region.
#
# GET /v1/origin/addresses
# Returns: record<addresses: table<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string>
# operationId: query_origin_address_status_information_v1_origin_addresses_get
export def "query-origin-address-status-information-v1-origin-addresses-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin/addresses"
    query: [{name: query, var: query, required: true}, {name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the origins of the user in the region.
#
# GET /v1/origin/all
# Returns: record<origins: table<actions: string, addresses: string, config: record, cookies: string, created_at: int, logs: string, origin: string, scripts: string, self: string, status: string, token: string, updated_at: int>, self: string>
# operationId: query_all_origin_information_v1_origin_all_get
export def "query-all-origin-information-v1-origin-all-get" [
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
    path: "/v1/origin/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the type of clients of the trafffic of the origin.
#
# GET /v1/origin/client/analysis
# Returns: record<data: table<client_browser: int, client_crawler: int, client_email: int, client_library: int, client_mobile_browser: int, client_multimedia_player: int, client_offline_browser: int, client_total: int, client_ua_anonymizer: int, client_unrecognized: int, client_validator: int, client_wap_browser: int, crawler_feed_fetcher: int, crawler_link_checker: int, crawler_marketing: int, crawler_screenshot_creator: int, crawler_search_engine_bot: int, crawler_site_monitor: int, crawler_speed_tester: int, crawler_tool: int, crawler_total: int, crawler_uncategorised: int, crawler_unrecognized: int, crawler_virus_scanner: int, crawler_vulnerability_scanner: int, crawler_web_scraper: int, timestamp: int, total: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int>
# operationId: query_origin_traffic_client_v1_origin_client_analysis_get
export def "query-origin-traffic-client-v1-origin-client-analysis-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
  --interval: string@interval-completer # The data inteval to aggregate the result dataset (required)
  --from-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after or equal to this value. (required)
  --to-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged before this value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin/client/analysis"
    query: [{name: query, var: query, required: true}, {name: interval, var: interval, required: true, default: HOURLY}, {name: from_timestamp, var: from_timestamp, required: true}, {name: to_timestamp, var: to_timestamp}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, interval: $interval, from_timestamp: $from_timestamp, to_timestamp: $to_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the tracking cookie ID status of the origin of the user in the region.
#
# GET /v1/origin/cookies
# Returns: record<cookie_ids: table<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, page: int, page_size: int, self: string>
# operationId: query_origin_cookie_id_status_information_v1_origin_cookies_get
export def "query-origin-cookie-id-status-information-v1-origin-cookies-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin/cookies"
    query: [{name: query, var: query, required: true}, {name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the code snippets of an origin of the user in the region.
#
# GET /v1/origin/scripts
# Returns: record<detection: string, self: string>
# operationId: query_origin_scripts_v1_origin_scripts_get
export def "query-origin-scripts-v1-origin-scripts-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin/scripts"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the current cookie ID and IP address status of the origin of user in the region.
#
# POST /v1/origin/status
# Returns: record<address: record<address: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, cookie_id: record<cookie_id: string, created_at: int, expiry: int, log_id: string, status: string, updated_at: int>, self: string>
# operationId: query_origin_status_v1_origin_status_post
export def "query-origin-status-v1-origin-status-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
  --address: any # The IP address to query the status
  --cookie-id: string # The cookie id to query the status (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/origin/status"
    query: [{name: query, var: query, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: cookie_id, var: cookie_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, address: $address, cookie_id: $cookie_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detail of a status available in the platform.
#
# GET /v1/origin/status/detail/{status_id}
# Returns: record<cardinality: int, description: string, self: string, status: string>
# operationId: query_origin_status_detail_v1_origin_status_detail__status_id__get
export def "query-origin-status-detail-v1-origin-status-detail-status-id-get" [
  status_id: string@status-id-completer
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
    path: "/v1/origin/status/detail/{status_id}"
    path_params: [{name: status_id, var: status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status_id: $status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of different status available in the platform.
#
# GET /v1/origin/status/details
# Returns: record<list: table<cardinality: int, description: string, self: string, status: string>, self: string>
# operationId: query_origin_status_details_v1_origin_status_details_get
export def "query-origin-status-details-v1-origin-status-details-get" [
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
    path: "/v1/origin/status/details"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the traffic analysis of the origin.
#
# GET /v1/origin/traffic/analysis
# Returns: record<data: table<asn_risky: int, bots: int, datacenters: int, denylists: int, network_country_mismatches: int, score_high: int, timestamp: int, total: int, webdrivers: int>, from_timestamp: int, interval: string, self: string, to_timestamp: int>
# operationId: query_origin_traffic_analysis_v1_origin_traffic_analysis_get
export def "query-origin-traffic-analysis-v1-origin-traffic-analysis-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The origin site to query (required)
  --interval: string@interval-completer # The data inteval to aggregate the result dataset (required)
  --from-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged after or equal to this value. (required)
  --to-timestamp: int # A UNIX timestamp in milliseconds to restrict the results of the query to entries logged before this value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/origin/traffic/analysis"
    query: [{name: query, var: query, required: true}, {name: interval, var: interval, required: true, default: HOURLY}, {name: from_timestamp, var: from_timestamp, required: true}, {name: to_timestamp, var: to_timestamp}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, interval: $interval, from_timestamp: $from_timestamp, to_timestamp: $to_timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an origin token of the user in the region.
#
# DELETE /v1/origin_token
# operationId: delete_token_v1_origin_token_delete
export def "delete-token-v1-origin-token-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin_token_id: string
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v1/origin_token"
    body: {content_type: "application/json", kind: json, fields: [{name: origin_token_id, var: origin_token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    origin_token_id: $origin_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of an origin token of the user in the region.
#
# POST /v1/origin_token
# Returns: record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>
# operationId: query_origin_token_info_v1_origin_token_post
export def "query-origin-token-info-v1-origin-token-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin_token_id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/origin_token"
    body: {content_type: "application/json", kind: json, fields: [{name: origin_token_id, var: origin_token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    origin_token_id: $origin_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the origin tokens of the user in the region.
#
# GET /v1/origin_token/all
# Returns: record<self: string, tokens: table<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>>
# operationId: query_all_origin_tokens_in_the_region_v1_origin_token_all_get
export def "query-all-origin-tokens-in-the-region-v1-origin-token-all-get" [
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
    path: "/v1/origin_token/all"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a enabled origin token of the user in the region.
#
# PUT /v1/origin_token/disable
# operationId: disable_origin_token_v1_origin_token_disable_put
export def "disable-origin-token-v1-origin-token-disable-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin_token_id: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/origin_token/disable"
    body: {content_type: "application/json", kind: json, fields: [{name: origin_token_id, var: origin_token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    origin_token_id: $origin_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a disabled origin token of the user in the region.
#
# PUT /v1/origin_token/enable
# operationId: enable_origin_token_v1_origin_token_enable_put
export def "enable-origin-token-v1-origin-token-enable-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin_token_id: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/origin_token/enable"
    body: {content_type: "application/json", kind: json, fields: [{name: origin_token_id, var: origin_token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    origin_token_id: $origin_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an origin token of the user in the region.
#
# POST /v1/origin_token/new
# Returns: record<created_at: int, origin: string, region_id: string, self: string, status: string, updated_at: int>
# operationId: create_a_new_origin_token_v1_origin_token_new_post
export def "create-a-new-origin-token-v1-origin-token-new-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  origin: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/origin_token/new"
    body: {content_type: "application/json", kind: json, fields: [{name: origin, var: origin}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    origin: $origin
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the full information of all the source lists for the subscription level given.
#
# GET /v1/source/ip
# Returns: record<self: string, sources: table<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list, updated_at: int, url: string>>
# operationId: get_all_sources_v1_source_ip_get
export def "get-all-sources-v1-source-ip-get" [
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
    path: "/v1/source/ip"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the full information of the source list given as argument.
#
# GET /v1/source/ip/{source}
# Returns: record<dataset: string, description: string, maximum_risk: string, maximum_score: int, minimum_risk: string, minimum_score: int, name: string, refresh: string, self: string, source: string, time_ranges: list<string>, updated_at: int, url: string>
# operationId: get_source_info_v1_source_ip__source__get
export def "get-source-info-v1-source-ip-source-get" [
  source: string
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
    path: "/v1/source/ip/{source}"
    path_params: [{name: source, var: source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the source list given for a specific time range.
#
# GET /v1/source/ip/{source}/range/{time_range}
# Returns: record<items: int, lapse: string, risk: string, score: int, self: string, source: string, updated_at: int>
# operationId: get_source_and_timerange_info_v1_source_ip__source__range__time_range__get
export def "get-source-and-timerange-info-v1-source-ip-source-range-time-range-get" [
  source: string
  time_range: string@time-range-completer
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
    path: "/v1/source/ip/{source}/range/{time_range}"
    path_params: [{name: source, var: source}, {name: time_range, var: time_range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the user's token in the region.
#
# GET /v1/token
# Returns: record<created_at: int, last_minute_bucket_init_value: int, last_minute_bucket_refill_ratio: int, last_minute_bucket_refresh: int, last_minute_bucket_value: int, last_month_bucket_init_value: int, last_month_bucket_refresh: int, last_month_bucket_value: int, region_id: string, self: string, status: string, updated_at: int>
# operationId: query_token_info_v1_token_get
export def "query-token-info-v1-token-get" [
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
    path: "/v1/token"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the activity information of the token in the region.
#
# GET /v1/token/activity
# Returns: record<activities: table<created_at: int, data: record, description: string, event: string, self: string, source: record>, page: int, page_size: int, self: string>
# operationId: query_token_activity_v1_token_activity_get
export def "query-token-activity-v1-token-activity-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page to be returned (default: 1)
  --page-size: int # The number of items per page (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/token/activity"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information found in a set of User Agents.
#
# POST /v1/ua
# Returns: record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string>
# operationId: parse_user_agents_v1_ua_post
export def "parse-user-agents-v1-ua-post" [
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
    path: "/v1/ua"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information found in the set of User Agents uploaded.
#
# POST /v1/ua/csv
# Returns: record<results: table<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>, self: string>
# operationId: parse_user_agents_csv_v1_ua_csv_post
export def "parse-user-agents-csv-v1-ua-csv-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  csv_file: string # The CSV file with the User Agents to parse (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/ua/csv"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: csv_file, var: csv_file}], files: [csv_file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    csv_file: $csv_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the device of a user agent.
#
# GET /v1/ua/device/{code}
# Returns: record<code: string, description: string>
# operationId: query_device_by_code_v1_ua_device__code__get
export def "query-device-by-code-v1-ua-device-code-get" [
  code: string
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
    path: "/v1/ua/device/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the family of a user agent.
#
# GET /v1/ua/family/{code}
# Returns: record<code: string, description: string>
# operationId: query_family_by_code_v1_ua_family__code__get
export def "query-family-by-code-v1-ua-family-code-get" [
  code: string
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
    path: "/v1/ua/family/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the Operating System of a user agent.
#
# GET /v1/ua/os/{code}
# Returns: record<code: string, description: string, family: string, vendor: string>
# operationId: query_os_by_code_v1_ua_os__code__get
export def "query-os-by-code-v1-ua-os-code-get" [
  code: string
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
    path: "/v1/ua/os/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the type of a user agent.
#
# GET /v1/ua/type/{code}
# Returns: record<code: string, description: string, type: string>
# operationId: query_type_by_code_v1_ua_type__code__get
export def "query-type-by-code-v1-ua-type-code-get" [
  code: string
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
    path: "/v1/ua/type/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information of the vendor of a user agent.
#
# GET /v1/ua/vendor/{code}
# Returns: record<code: string, description: string>
# operationId: query_vendor_by_code_v1_ua_vendor__code__get
export def "query-vendor-by-code-v1-ua-vendor-code-get" [
  code: string
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
    path: "/v1/ua/vendor/{code}"
    path_params: [{name: code, var: code}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the information found in an User Agent.
#
# GET /v1/ua/{user_agent_urlencoded}
# Returns: record<agent: string, classification: string, device: string, engine: string, family: string, frequent: string, latest: string, os: string, self: string, string: string, type: string, vendor: string, version: string>
# operationId: parse_user_agent_v1_ua__user_agent_urlencoded__get
export def "parse-user-agent-v1-ua-user-agent-urlencoded-get" [
  user_agent_urlencoded: string
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
    path: "/v1/ua/{user_agent_urlencoded}"
    path_params: [{name: user_agent_urlencoded, var: user_agent_urlencoded}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_agent_urlencoded: $user_agent_urlencoded
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
