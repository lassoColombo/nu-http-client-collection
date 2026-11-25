# Auto-generated client for UniCourt Enterprise APIs v1.0.0
# Source: https://api.apis.guru/v2/specs/unicourt.com/1.0.0/openapi.json
# Auth: --token flag or $env.UNICOURT_ENTERPRISE_APIS_TOKEN

const CLIENT = {
  base_url: "https://enterpriseapi.unicourt.com"
  token_env_var: "UNICOURT_ENTERPRISE_APIS_TOKEN"
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

def base-url-completer [] { ["https://enterpriseapi.unicourt.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["COMPLETE" "FAILURE" "IN_PROGRESS"] }
def sort-by-completer [] { ["latest to oldest" "oldest to latest"] }
def party-classification-type-completer [] { ["COMPANY" "INDIVIDUAL" "OTHER"] }
def group-by-completer [] { ["Monthly" "Quarterly" "Weekly" "Yearly"] }
def sort-completer [] { ["filedDate" "relevancy"] }
def order-completer [] { ["asc" "desc"] }
def sort-completer-1 [] { ["name"] }
def sort-completer-2 [] { ["state"] }
def case-status-completer [] { ["closed" "open"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-attorney-by-id: "record<attorneyId: string, attorneyLawFirmArray: table<attorneyLawFirmId: string, firstFetchDate: string, isVisible: bool, lastFetchDate: string, name: string, object: string>, attorneyType: record<attorneyTypeId: string, createdDate: string, name: string, object: string>, barNumber: string, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyRoleGroupIdArray: list<string>, partyRoleIdArray: list<string>, possibleNormAttorneyArray: table<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, confidenceScore: float, normAttorneyAPI: string, normAttorneyId: string, normAttorneyName: string, object: string, scoreConstituents: record>, possibleNormLawFirmArray: table<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, confidenceScore: float, normLawFirmAPI: string, normLawFirmId: string, normLawFirmName: string, object: string, scoreConstituents: record, sourceDetails: record>, sourceAttorneyType: string>"
    get-attorney-associated-parties: "record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int>"
    get-billing-usage-by-billing-cycle: "record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, billingCycle: record<endDate: string, startDate: string>, days: record, object: string, totalCasesTracked: int>"
    get-billing-cycles: "record<billingCycleArray: list<string>, object: string>"
    get-callbacks: "record<caseDocumentOrderCallbacks: record<count: int, link: string>, caseExportCallbacks: record<count: int, link: string>, object: string>"
    get-case: "record<attorneys: record<attorneyArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: table<causeOfAction: record, causeOfActionAdditionalDataArray: list, object: string>, chargeArray: table<charge: record, chargeAdditionalDataArray: list, chargeDegree: record, chargeSeverity: record, object: string>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list<record>, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list<record>, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list<record>, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list<record>, sourceChargeArray: list<record>, sourceCourt: string, sourcePageData: list<record>>, sourceDataStatus: string, url: string>"
    get-case-attorneys: "record<attorneyArray: table<attorneyId: string, attorneyLawFirmArray: list, attorneyType: record, barNumber: string, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyRoleGroupIdArray: list, partyRoleIdArray: list, possibleNormAttorneyArray: list, possibleNormLawFirmArray: list, sourceAttorneyType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-case-docket-entries: "record<docketEntryArray: table<boundary: string, docketBadge: string, docketEntryDate: string, docketEntryPrimaryDocuments: record, docketEntrySecondaryDocuments: record, docketNumber: int, lastFetchDate: string, object: string, referencedDocketNumberArray: list, sortOrder: int, text: string, textStructured: record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-primary-documents-for-docket-entries: "record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-secondary-documents-for-docket-entries: "record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-case-documents: "record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-case-hearings: "record<hearingArray: table<firstFetchDate: string, hearingDate: string, hearingDescription: string, hearingStructured: record, lastFetchDate: string, location: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-case-judges: "record<judgeArray: table<contact: record, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: list, sourceJudgeType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>"
    get-case-parties: "record<nextPageAPI: string, object: string, pageNumber: int, partyArray: table<attorneyRepresentationType: record, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyClassificationType: string, partyId: string, partyRole: record, possibleNormPartyArray: list, sourcePartyRole: string>, totalCount: int, totalPages: int>"
    get-case-related-cases: "record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: table<additionalSourceData: record, caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseRelationshipType: record, isVisible: bool, object: string, sourceCaseRelationshipType: string>, totalCount: int, totalPages: int>"
    get-case-count-analytics-by-area-of-law: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<areaOfLaw: record, caseCount: int, caseSearchAPI: string, object: string>, totalAreaOfLawCount: int, totalCaseCount: int, totalPages: int>"
    get-case-count-analytics-by-case-class: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseClass: record, caseCount: int, caseSearchAPI: string, object: string>, totalCaseClassCount: int, totalCaseCount: int, totalPages: int>"
    get-case-count-analytics-by-case-filed-date: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, groupedBy: string, monthInt: int, monthString: string, object: string, quarter: string, weekOfMonth: int, weekOfYear: int, year: int>, totalCaseCount: int, totalCaseFiledDateCount: int, totalPages: int>"
    get-case-count-analytics-by-case-type: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseType: record, object: string>, totalCaseCount: int, totalCaseTypeCount: int, totalPages: int>"
    get-case-count-analytics-by-case-type-group: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseTypeGroup: record, object: string>, totalCaseCount: int, totalCaseTypeGroupCount: int, totalPages: int>"
    get-case-count-analytics-by-court: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, object: string>, totalCaseCount: int, totalCourtCount: int, totalPages: int>"
    get-case-count-analytics-by-court-location: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, courtLocation: record, object: string>, totalCaseCount: int, totalCourtLocationCount: int, totalPages: int>"
    get-case-count-analytics-by-court-system: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtSystem: record, object: string>, totalCaseCount: int, totalCourtSystemCount: int, totalPages: int>"
    get-case-count-analytics-by-court-type: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtType: record, object: string>, totalCaseCount: int, totalCourtTypeCount: int, totalPages: int>"
    get-case-count-analytics-by-jurisdiction-geo: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, jurisdictionGeo: record, object: string>, totalCaseCount: int, totalJurisdictionGeoCount: int, totalPages: int>"
    get-case-count-analytics-by-norm-attorney: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int>"
    get-case-count-analytics-by-norm-judge: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normJudgeId: string, normJudgeName: string, object: string>, totalCaseCount: int, totalNormJudgeCount: int, totalPages: int>"
    get-case-count-analytics-by-norm-law-firm: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int>"
    get-case-count-analytics-by-norm-party: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int>"
    get-case-count-analytics-by-party-role: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRole: record>, totalCaseCount: int, totalPages: int, totalPartyRoleCount: int>"
    get-case-count-analytics-by-party-role-group: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRoleGroup: record>, totalCaseCount: int, totalPages: int, totalPartyRoleGroupCount: int>"
    get-document-by-id: "record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>"
    order-case-document: "record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>"
    get-case-document-order-callbacks: "record<callbackArray: table<callbackGeneratedDate: string, caseDocument: record, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-document-order-callback-by-id: "record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>"
    get-case-export-callbacks: "record<callbackArray: table<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-export-callback-by-id: "record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>"
    export-case: "record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>"
    search-cases: "record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    search-cases-by-id: "record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    track-case: "record<message: string, object: string>"
    remove-case-track-by-id: "record<message: string, object: string>"
    get-case-track-by-id: "record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record<lastTrackDate: string, lastTrackException: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, schedule: record<days: list<int>, object: string, type: string>>"
    get-case-tracks: "record<caseTrackPreviewArray: table<caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record, object: string, pacerOptions: record, schedule: record>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    update-case: "record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string>"
    get-case-update-by-case-id: "record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string>"
    get-case-updates: "record<caseUpdatePreviewArray: table<caseAPI: string, caseId: string, exception: record, object: string, pacerOptions: record, requestedDate: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-coverage: "record<caseClassCoverageArray: table<caseClass: record, caseCount: int, caseDocumentInLibraryCount: int, caseDocumentInLibraryInLastThirtyDaysCount: int, casesInLastThirtyDaysCount: int, courtServiceStatusAPI: string, freeCaseDocumentCount: int, freeCaseDocumentsInLastThirtyDaysCount: int, object: string, paidCaseDocumentCount: int, paidCaseDocumentsInLastThirtyDaysCount: int>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, lastUpdateCountDate: string, object: string, totalCaseCount: int, totalCaseDocumentInLibraryCount: int, totalCaseDocumentInLibraryInLastThirtyDaysCount: int, totalCasesInLastThirtyDaysCount: int, totalFreeCaseDocumentCount: int, totalFreeCaseDocumentsInLastThirtyDaysCount: int, totalPaidCaseDocumentCount: int, totalPaidCaseDocumentsInLastThirtyDaysCount: int>"
    get-daily-usage-by-date: "record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, object: string, usageEndTime: string, usageStartTime: string>"
    generate-new-token: "record<accessToken: string, object: string, tokenId: string, tokenType: string>"
    invalidate-all-tokens: "record<message: string, object: string>"
    invalidate-token: "record<message: string, object: string>"
    get-judge-by-id: "record<contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record<createdDate: string, judgeTypeId: string, name: string, object: string>, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: table<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormJudgeAPI: string, confidenceScore: float, normJudgeAPI: string, normJudgeId: string, normJudgeName: string, object: string, scoreConstituents: record>, sourceJudgeType: string>"
    list-all-token-ids: "record<AccessTokenIdArray: table<issueAddress: string, issuedDate: string, object: string, tokenId: string>, object: string>"
    get-areas-of-law: "record<areaOfLawArray: table<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-area-of-law: "record<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>"
    get-attorney-representation-types: "record<attorneyRepresentationTypeArray: table<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-attorney-representation-type: "record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>"
    get-attorney-types: "record<attorneyTypeArray: table<attorneyTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-attorney-type: "record<attorneyTypeId: string, createdDate: string, name: string, object: string>"
    get-cases-class: "record<caseClassArray: table<caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-class: "record<caseClassId: string, createdDate: string, name: string, object: string>"
    get-case-relationship-types: "record<caseRelationshipTypeArray: table<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-relationship-type: "record<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>"
    get-cases-status: "record<caseStatusArray: table<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-status: "record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>"
    get-case-status-groups: "record<caseStatusGroupArray: table<caseStatusGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-status-group: "record<caseStatusGroupId: string, createdDate: string, name: string, object: string>"
    get-case-types: "record<caseTypeArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-type: "record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>"
    get-case-type-groups: "record<caseTypeGroupArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-type-group: "record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>"
    get-causes-of-action: "record<causeOfActionArray: table<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-cause-of-action: "record<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>"
    get-causes-of-action-additional-data: "record<causeOfActionAdditionalDataArray: table<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-cause-of-action-additional-data: "record<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>"
    get-causes-of-action-group: "record<causeOfActionGroupArray: table<causeOfActionGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-cause-of-action-group: "record<causeOfActionGroupId: string, createdDate: string, name: string, object: string>"
    get-charges: "record<chargeArray: table<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-charge: "record<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>"
    get-charges-additional-data: "record<chargeAdditionalDataArray: table<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-charge-additional-data: "record<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>"
    get-charges-degree: "record<chargeDegreeArray: table<chargeDegreeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-charge-degree: "record<chargeDegreeId: string, createdDate: string, name: string, object: string>"
    get-charge-groups: "record<chargeGroupArray: table<chargeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-charge-group: "record<chargeGroupId: string, createdDate: string, name: string, object: string>"
    get-charges-severity: "record<chargeSeverityArray: table<chargeSeverityId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-charge-severity: "record<chargeSeverityId: string, createdDate: string, name: string, object: string>"
    get-courts: "record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court: "record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>"
    get-appeal-courts-for-court: "record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-locations-for-court: "record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-jurisdiction-geo-for-court: "record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-locations: "record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-location: "record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>"
    get-courts-for-court-location: "record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-courts-service-status: "record<courtServiceStatusArray: table<caseClassIdArray: list, caseDocumentOrderServiceStatus: record, caseTrackServiceStatus: record, caseUpdateServiceStatus: record, courtIdArray: list, courtLocationIdArray: list, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-service-status: "record<caseClassIdArray: list<string>, caseDocumentOrderServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseTrackServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseUpdateServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, courtIdArray: list<string>, courtLocationIdArray: list<string>, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>"
    get-court-systems: "record<courtSystemArray: table<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-system: "record<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>"
    get-court-types: "record<courtTypeArray: table<courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-court-type: "record<courtTypeId: string, createdDate: string, name: string, object: string>"
    get-judge-types: "record<judgeTypeArray: table<createdDate: string, judgeTypeId: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-judge-type: "record<createdDate: string, judgeTypeId: string, name: string, object: string>"
    get-jurisdictions-geo: "record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-jurisdiction-geo: "record<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list<string>>"
    get-courts-for-jurisdiction-geo: "record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-party-roles: "record<nextPageAPI: string, object: string, pageNumber: int, partyRoleArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-party-role: "record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>"
    get-party-role-groups: "record<nextPageAPI: string, object: string, pageNumber: int, partyRoleGroupArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-party-role-group: "record<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>"
    get-norm-attorney-by-id: "record<attorneyAnalyticsAPI: record<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normAttorneyAPI: string, object: string>, barRecordArray: table<admittedDate: string, barNumber: string, barSourceData: record, barSourceType: string, contact: record, firstFetchDate: string, inactivationDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, stateCode: string, status: string>, caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, lastName: string, middleName: string, name: string, normAttorneyId: string, object: string, similarNormAttorneyArray: table<barRecordPreviewArray: list, name: string, normAttorneyAPI: string, normAttorneyId: string, normAttorneySimilarityScore: float, object: string>>"
    get-norm-judges-associated-with-norm-attorney: "record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-law-firms-associated-with-norm-attorney: "record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-parties-associated-with-norm-attorney: "record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-count-analytics-by-opposing-norm-attorney-for-a-norm-attorney: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int>"
    search-normalized-attorneys: "record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    search-normalized-attorneys-by-id: "record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    get-norm-judge-by-id: "record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, judgeAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, normJudgeAPI: string, object: string>, judicialDataArray: table<abaRatings: record, aliasArray: list, bio: record, contact: record, educationArray: list, firstFetchDate: string, judicialSource: record, judicialStatus: string, lastFetchDate: string, lastFetchDateWithUpdates: string, nameHistoryArray: list, object: string, professionalCareerArray: list, serviceHistoryArray: list>, lastName: string, middleName: string, name: string, normJudgeId: string, object: string>"
    get-norm-attorneys-associated-with-norm-judge: "record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-law-firms-associated-with-norm-judge: "record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-parties-associated-with-norm-judge: "record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    search-normalized-judges: "record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    search-normalized-judges-by-id: "record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    get-norm-law-firm-by-id: "record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, lawFirmAnalyticsAPI: record<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normLawFirmAPI: string, object: string>, name: string, normLawFirmId: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, object: string>"
    get-norm-attorneys-associated-with-norm-law-firm: "record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-judges-associated-with-norm-law-firm: "record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-parties-associated-with-norm-law-firm: "record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-count-analytics-by-opposing-norm-law-firm-for-a-norm-law-firm: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int>"
    search-normalized-law-firms: "record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    search-normalized-law-firms-by-id: "record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    get-norm-party-by-id: "record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, individualData: record<firstName: string, lastName: string, middleName: string, name: string>, name: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, normPartyId: string, object: string, partyAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normPartyAPI: string, object: string>, partyClassificationType: string, relatedNormPartyArray: table<normPartyId: string, object: string, relationshipType: string>>"
    get-norm-attorneys-associated-with-norm-party: "record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-judges-associated-with-norm-party: "record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-norm-law-firms-associated-with-norm-party: "record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>"
    get-case-count-analytics-by-opposing-norm-party-for-a-norm-party: "record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int>"
    search-normalized-parties: "record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    search-normalized-parties-by-id: "record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>"
    import-pacer-case-by-court-using-case-number: "record<courtFee: float, object: string, pacerImportCaseResultsArray: table<hasOnlyMetaInfo: bool, object: string, uniCourtContent: record>>"
    all-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    appeal-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    bankruptcy-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    civil-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    criminal-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    multi-district-courts-pacer-case-locator-case-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    all-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    appeal-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    bankruptcy-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    civil-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    criminal-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    multi-district-courts-pacer-case-locator-party-search: "record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>"
    get-pacer-credential: "record<nextPageAPI: string, object: string, pacerCredentialArray: table<defaultPacerClientCode: string, object: string, pacerUserId: string>, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>"
    add-pacer-credential: "record<message: string, object: string>"
    remove-pacer-credential-by-id: "record<message: string, object: string>"
    get-pacer-credential-by-id: "record<defaultPacerClientCode: string, object: string, pacerUserId: string>"
    get-party-by-id: "record<attorneyRepresentationType: record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyClassificationType: string, partyId: string, partyRole: record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, possibleNormPartyArray: table<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, bestMatch: bool, caseCountAnalyticsByNormPartyAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, confidenceScore: float, normPartyAPI: string, normPartyId: string, normPartyName: string, object: string, scoreConstituents: record>, sourcePartyRole: string>"
    get-party-associated-attorneys: "record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-attorney-by-id" "get-attorney-associated-parties" "get-billing-usage-by-billing-cycle" "get-billing-cycles" "get-callbacks" "get-case" "get-case-attorneys" "get-case-docket-entries" "get-primary-documents-for-docket-entries" "get-secondary-documents-for-docket-entries" "get-case-documents" "get-case-hearings" "get-case-judges" "get-case-parties" "get-case-related-cases" "get-case-count-analytics-by-area-of-law" "get-case-count-analytics-by-case-class" "get-case-count-analytics-by-case-filed-date" "get-case-count-analytics-by-case-type" "get-case-count-analytics-by-case-type-group" "get-case-count-analytics-by-court" "get-case-count-analytics-by-court-location" "get-case-count-analytics-by-court-system" "get-case-count-analytics-by-court-type" "get-case-count-analytics-by-jurisdiction-geo" "get-case-count-analytics-by-norm-attorney" "get-case-count-analytics-by-norm-judge" "get-case-count-analytics-by-norm-law-firm" "get-case-count-analytics-by-norm-party" "get-case-count-analytics-by-party-role" "get-case-count-analytics-by-party-role-group" "get-document-by-id" "get-case-document-download-by-id" "order-case-document" "get-case-document-order-callbacks" "get-case-document-order-callback-by-id" "get-case-export-callbacks" "get-case-export-callback-by-id" "export-case" "search-cases" "search-cases-by-id" "track-case" "remove-case-track-by-id" "get-case-track-by-id" "get-case-tracks" "update-case" "get-case-update-by-case-id" "get-case-updates" "get-court-coverage" "get-daily-usage-by-date" "generate-new-token" "invalidate-all-tokens" "invalidate-token" "get-judge-by-id" "list-all-token-ids" "get-areas-of-law" "get-area-of-law" "get-attorney-representation-types" "get-attorney-representation-type" "get-attorney-types" "get-attorney-type" "get-cases-class" "get-case-class" "get-case-relationship-types" "get-case-relationship-type" "get-cases-status" "get-case-status" "get-case-status-groups" "get-case-status-group" "get-case-types" "get-case-type" "get-case-type-groups" "get-case-type-group" "get-causes-of-action" "get-cause-of-action" "get-causes-of-action-additional-data" "get-cause-of-action-additional-data" "get-causes-of-action-group" "get-cause-of-action-group" "get-charges" "get-charge" "get-charges-additional-data" "get-charge-additional-data" "get-charges-degree" "get-charge-degree" "get-charge-groups" "get-charge-group" "get-charges-severity" "get-charge-severity" "get-courts" "get-court" "get-appeal-courts-for-court" "get-court-locations-for-court" "get-jurisdiction-geo-for-court" "get-court-locations" "get-court-location" "get-courts-for-court-location" "get-courts-service-status" "get-court-service-status" "get-court-systems" "get-court-system" "get-court-types" "get-court-type" "get-judge-types" "get-judge-type" "get-jurisdictions-geo" "get-jurisdiction-geo" "get-courts-for-jurisdiction-geo" "get-party-roles" "get-party-role" "get-party-role-groups" "get-party-role-group" "get-norm-attorney-by-id" "get-norm-judges-associated-with-norm-attorney" "get-norm-law-firms-associated-with-norm-attorney" "get-norm-parties-associated-with-norm-attorney" "get-case-count-analytics-by-opposing-norm-attorney-for-a-norm-attorney" "search-normalized-attorneys" "search-normalized-attorneys-by-id" "get-norm-judge-by-id" "get-norm-attorneys-associated-with-norm-judge" "get-norm-law-firms-associated-with-norm-judge" "get-norm-parties-associated-with-norm-judge" "search-normalized-judges" "search-normalized-judges-by-id" "get-norm-law-firm-by-id" "get-norm-attorneys-associated-with-norm-law-firm" "get-norm-judges-associated-with-norm-law-firm" "get-norm-parties-associated-with-norm-law-firm" "get-case-count-analytics-by-opposing-norm-law-firm-for-a-norm-law-firm" "search-normalized-law-firms" "search-normalized-law-firms-by-id" "get-norm-party-by-id" "get-norm-attorneys-associated-with-norm-party" "get-norm-judges-associated-with-norm-party" "get-norm-law-firms-associated-with-norm-party" "get-case-count-analytics-by-opposing-norm-party-for-a-norm-party" "search-normalized-parties" "search-normalized-parties-by-id" "import-pacer-case-by-court-using-case-number" "all-courts-pacer-case-locator-case-search" "appeal-courts-pacer-case-locator-case-search" "bankruptcy-courts-pacer-case-locator-case-search" "civil-courts-pacer-case-locator-case-search" "criminal-courts-pacer-case-locator-case-search" "multi-district-courts-pacer-case-locator-case-search" "all-courts-pacer-case-locator-party-search" "appeal-courts-pacer-case-locator-party-search" "bankruptcy-courts-pacer-case-locator-party-search" "civil-courts-pacer-case-locator-party-search" "criminal-courts-pacer-case-locator-party-search" "multi-district-courts-pacer-case-locator-party-search" "get-pacer-credential" "add-pacer-credential" "remove-pacer-credential-by-id" "get-pacer-credential-by-id" "get-party-by-id" "get-party-associated-attorneys" "commands"] | sort) } | get name | first)
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

# Gets details for a requested Attorney ID.
#
# GET /attorney/{attorneyId}
# Returns: record<attorneyId: string, attorneyLawFirmArray: table<attorneyLawFirmId: string, firstFetchDate: string, isVisible: bool, lastFetchDate: string, name: string, object: string>, attorneyType: record<attorneyTypeId: string, createdDate: string, name: string, object: string>, barNumber: string, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyRoleGroupIdArray: list<string>, partyRoleIdArray: list<string>, possibleNormAttorneyArray: table<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, confidenceScore: float, normAttorneyAPI: string, normAttorneyId: string, normAttorneyName: string, object: string, scoreConstituents: record>, possibleNormLawFirmArray: table<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, confidenceScore: float, normLawFirmAPI: string, normLawFirmId: string, normLawFirmName: string, object: string, scoreConstituents: record, sourceDetails: record>, sourceAttorneyType: string>
# operationId: getAttorneyById
export def "get-attorney-by-id" [
  attorney_id: string
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
    path: "/attorney/{attorneyId}"
    path_params: [{name: attorneyId, var: attorney_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attorney_id: $attorney_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Associated Party details for a requested Attorney ID.
#
# GET /attorney/{attorneyId}/associatedParties
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int>
# operationId: getAttorneyAssociatedParties
export def "get-attorney-associated-parties" [
  attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attorney/{attorneyId}/associatedParties"
    path_params: [{name: attorneyId, var: attorney_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attorney_id: $attorney_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Specify the billing cycle to know the API usage.
#
# GET /billingCycleUsage/{billingCycle}
# Returns: record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, billingCycle: record<endDate: string, startDate: string>, days: record, object: string, totalCasesTracked: int>
# operationId: getBillingUsageByBillingCycle
export def "get-billing-usage-by-billing-cycle" [
  billing_cycle: string
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
    path: "/billingCycleUsage/{billingCycle}"
    path_params: [{name: billingCycle, var: billing_cycle}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    billing_cycle: $billing_cycle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all the previous 12 billing cycles.
#
# GET /billingCycles
# Returns: record<billingCycleArray: list<string>, object: string>
# operationId: getBillingCycles
export def "get-billing-cycles" [
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
    path: "/billingCycles"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of callback types with count for a requested Date.
#
# GET /callbacks
# Returns: record<caseDocumentOrderCallbacks: record<count: int, link: string>, caseExportCallbacks: record<count: int, link: string>, object: string>
# operationId: getCallbacks
export def "get-callbacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date for which fetch the callback type list. By default, the date will be set to current date. (format: date-time)
  --status: string@status-completer # Status of the callbacks. Default status will fetch all callbacks.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/callbacks"
    query: [{name: date, var: date}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets case information for a requested Case ID.
#
# GET /case/{caseId}
# Returns: record<attorneys: record<attorneyArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: table<causeOfAction: record, causeOfActionAdditionalDataArray: list, object: string>, chargeArray: table<charge: record, chargeAdditionalDataArray: list, chargeDegree: record, chargeSeverity: record, object: string>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list<record>, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list<record>, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list<record>, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list<record>, sourceChargeArray: list<record>, sourceCourt: string, sourcePageData: list<record>>, sourceDataStatus: string, url: string>
# operationId: getCase
export def "get-case" [
  case_id: string
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
    path: "/case/{caseId}"
    path_params: [{name: caseId, var: case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Attorneys for a requested Case ID.
#
# GET /case/{caseId}/attorneys
# Returns: record<attorneyArray: table<attorneyId: string, attorneyLawFirmArray: list, attorneyType: record, barNumber: string, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyRoleGroupIdArray: list, partyRoleIdArray: list, possibleNormAttorneyArray: list, possibleNormLawFirmArray: list, sourceAttorneyType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getCaseAttorneys
export def "get-case-attorneys" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve attorneys in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/attorneys"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: isVisible, var: is_visible}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, is_visible: $is_visible, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Docket Entries for a requested Case ID.
#
# GET /case/{caseId}/docketEntries
# Returns: record<docketEntryArray: table<boundary: string, docketBadge: string, docketEntryDate: string, docketEntryPrimaryDocuments: record, docketEntrySecondaryDocuments: record, docketNumber: int, lastFetchDate: string, object: string, referencedDocketNumberArray: list, sortOrder: int, text: string, textStructured: record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getCaseDocketEntries
export def "get-case-docket-entries" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the docket entry witih the specified docket number in the case with the specified caseId value.
  --sort-by: string@sort-by-completer # Sort the retrieved docket entries in ascending order or descending order of date.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/docketEntries"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: docketNumber, var: docket_number}, {name: sortBy, var: sort_by}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, docket_number: $docket_number, sort_by: $sort_by, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Primary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/primaryDocuments
# Returns: record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getPrimaryDocumentsForDocketEntries
export def "get-primary-documents-for-docket-entries" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the primary documents associated with the specified docket number in the case with the specified caseId value. (required)
  --in-library: oneof<nothing, bool> # Retrieve the primary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --after-first-fetch-date: string # Retrieve all primary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --library-date: string # Retrieve all primary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/docketEntries/primaryDocuments"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: docketNumber, var: docket_number, required: true}, {name: inLibrary, var: in_library}, {name: afterFirstFetchDate, var: after_first_fetch_date}, {name: libraryDate, var: library_date}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, docket_number: $docket_number, in_library: $in_library, after_first_fetch_date: $after_first_fetch_date, library_date: $library_date, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Secondary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/secondaryDocuments
# Returns: record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getSecondaryDocumentsForDocketEntries
export def "get-secondary-documents-for-docket-entries" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the secondary documents associated with the specified docket number in the case with the specified caseId value. (required)
  --in-library: oneof<nothing, bool> # Retrieve the secondary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --after-first-fetch-date: string # Retrieve all secondary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --library-date: string # Retrieve all secondary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/docketEntries/secondaryDocuments"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: docketNumber, var: docket_number, required: true}, {name: inLibrary, var: in_library}, {name: afterFirstFetchDate, var: after_first_fetch_date}, {name: libraryDate, var: library_date}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, docket_number: $docket_number, in_library: $in_library, after_first_fetch_date: $after_first_fetch_date, library_date: $library_date, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Documents for a requested Case ID.
#
# GET /case/{caseId}/documents
# Returns: record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getCaseDocuments
export def "get-case-documents" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --in-library: oneof<nothing, bool> # Filter all the documents those are added to the UniCourt library. (allows empty value)
  --after-first-fetch-date: string # Get all the documents which were added to the case on or after a specific date. (nullable, format: date-time)
  --library-date: string # Sort all the documents based on the date when the document was added to the UniCourt Library. (nullable, format: date-time)
  --first-fetch-date: string # Sort all the documents based on the date it was fetched from the source site. (nullable, format: date-time)
  --sort-by: string@sort-by-completer # Sort documents with document order.
  --page-number: int # The page for which the result should be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/documents"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: inLibrary, var: in_library}, {name: afterFirstFetchDate, var: after_first_fetch_date}, {name: libraryDate, var: library_date}, {name: firstFetchDate, var: first_fetch_date}, {name: sortBy, var: sort_by}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, in_library: $in_library, after_first_fetch_date: $after_first_fetch_date, library_date: $library_date, first_fetch_date: $first_fetch_date, sort_by: $sort_by, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Hearings for a requested Case ID.
#
# GET /case/{caseId}/hearings
# Returns: record<hearingArray: table<firstFetchDate: string, hearingDate: string, hearingDescription: string, hearingStructured: record, lastFetchDate: string, location: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getCaseHearings
export def "get-case-hearings" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # Specify the sort order of hearings in the case with the specified caseId.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/hearings"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: sortBy, var: sort_by}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, sort_by: $sort_by, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Judges for a requested Case ID.
#
# GET /case/{caseId}/judges
# Returns: record<judgeArray: table<contact: record, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: list, sourceJudgeType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>
# operationId: getCaseJudges
export def "get-case-judges" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve attorneys judges in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/judges"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: isVisible, var: is_visible}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, is_visible: $is_visible, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Parties for a requested Case ID.
#
# GET /case/{caseId}/parties
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: table<attorneyRepresentationType: record, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyClassificationType: string, partyId: string, partyRole: record, possibleNormPartyArray: list, sourcePartyRole: string>, totalCount: int, totalPages: int>
# operationId: getCaseParties
export def "get-case-parties" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve parties in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
  --party-role-id: string # Retrieve all parties with the specified partyRoleId value in the case with the specified caseId value. (allows empty value)
  --party-role-group-id: string # Retrieve all parties with the specified partyRoleGroupId value in the case with the specified caseId value. (allows empty value)
  --attorney-representation-type-id: string # Retrieve all parties with the specified attorneyRepresentationTypeId value in the case with the specified caseId value. (allows empty value)
  --party-classification-type: string@party-classification-type-completer # Retrieve all parties with the specified partyClassificationType value in the case with the specified caseId value. (allows empty value)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/parties"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: isVisible, var: is_visible}, {name: pageNumber, var: page_number}, {name: partyRoleId, var: party_role_id}, {name: partyRoleGroupId, var: party_role_group_id}, {name: attorneyRepresentationTypeId, var: attorney_representation_type_id}, {name: partyClassificationType, var: party_classification_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, is_visible: $is_visible, page_number: $page_number, party_role_id: $party_role_id, party_role_group_id: $party_role_group_id, attorney_representation_type_id: $attorney_representation_type_id, party_classification_type: $party_classification_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Related Cases for a requested Case ID.
#
# GET /case/{caseId}/relatedCases
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: table<additionalSourceData: record, caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseRelationshipType: record, isVisible: bool, object: string, sourceCaseRelationshipType: string>, totalCount: int, totalPages: int>
# operationId: getCaseRelatedCases
export def "get-case-related-cases" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/case/{caseId}/relatedCases"
    path_params: [{name: caseId, var: case_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Area Of Law.
#
# GET /caseCountAnalyticsByAreaOfLaw
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<areaOfLaw: record, caseCount: int, caseSearchAPI: string, object: string>, totalAreaOfLawCount: int, totalCaseCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByAreaOfLaw
export def "get-case-count-analytics-by-area-of-law" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByAreaOfLaw"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Case Class.
#
# GET /caseCountAnalyticsByCaseClass
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseClass: record, caseCount: int, caseSearchAPI: string, object: string>, totalCaseClassCount: int, totalCaseCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCaseClass
export def "get-case-count-analytics-by-case-class" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCaseClass"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Case Filed Date.
#
# GET /caseCountAnalyticsByCaseFiledDate
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, groupedBy: string, monthInt: int, monthString: string, object: string, quarter: string, weekOfMonth: int, weekOfYear: int, year: int>, totalCaseCount: int, totalCaseFiledDateCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCaseFiledDate
export def "get-case-count-analytics-by-case-filed-date" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
  --group-by: string@group-by-completer # GroupBy (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCaseFiledDate"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}, {name: groupBy, var: group_by, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Case Type.
#
# GET /caseCountAnalyticsByCaseType
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseType: record, object: string>, totalCaseCount: int, totalCaseTypeCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCaseType
export def "get-case-count-analytics-by-case-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCaseType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Case Type Group.
#
# GET /caseCountAnalyticsByCaseTypeGroup
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseTypeGroup: record, object: string>, totalCaseCount: int, totalCaseTypeGroupCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCaseTypeGroup
export def "get-case-count-analytics-by-case-type-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCaseTypeGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Court.
#
# GET /caseCountAnalyticsByCourt
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, object: string>, totalCaseCount: int, totalCourtCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCourt
export def "get-case-count-analytics-by-court" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCourt"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Court Location.
#
# GET /caseCountAnalyticsByCourtLocation
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, courtLocation: record, object: string>, totalCaseCount: int, totalCourtLocationCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCourtLocation
export def "get-case-count-analytics-by-court-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCourtLocation"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Court System.
#
# GET /caseCountAnalyticsByCourtSystem
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtSystem: record, object: string>, totalCaseCount: int, totalCourtSystemCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCourtSystem
export def "get-case-count-analytics-by-court-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCourtSystem"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by CourtType.
#
# GET /caseCountAnalyticsByCourtType
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtType: record, object: string>, totalCaseCount: int, totalCourtTypeCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByCourtType
export def "get-case-count-analytics-by-court-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByCourtType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Jurisdiction Geo.
#
# GET /caseCountAnalyticsByJurisdictionGeo
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, jurisdictionGeo: record, object: string>, totalCaseCount: int, totalJurisdictionGeoCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByJurisdictionGeo
export def "get-case-count-analytics-by-jurisdiction-geo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByJurisdictionGeo"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Attorney.
#
# GET /caseCountAnalyticsByNormAttorney
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByNormAttorney
export def "get-case-count-analytics-by-norm-attorney" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByNormAttorney"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Judge.
#
# GET /caseCountAnalyticsByNormJudge
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normJudgeId: string, normJudgeName: string, object: string>, totalCaseCount: int, totalNormJudgeCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByNormJudge
export def "get-case-count-analytics-by-norm-judge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByNormJudge"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Norm Law Firm.
#
# GET /caseCountAnalyticsByNormLawFirm
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByNormLawFirm
export def "get-case-count-analytics-by-norm-law-firm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByNormLawFirm"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Party.
#
# GET /caseCountAnalyticsByNormParty
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByNormParty
export def "get-case-count-analytics-by-norm-party" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByNormParty"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Party Role.
#
# GET /caseCountAnalyticsByPartyRole
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRole: record>, totalCaseCount: int, totalPages: int, totalPartyRoleCount: int>
# operationId: getCaseCountAnalyticsByPartyRole
export def "get-case-count-analytics-by-party-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByPartyRole"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Party Role Group.
#
# GET /caseCountAnalyticsByPartyRoleGroup
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRoleGroup: record>, totalCaseCount: int, totalPages: int, totalPartyRoleGroupCount: int>
# operationId: getCaseCountAnalyticsByPartyRoleGroup
export def "get-case-count-analytics-by-party-role-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseCountAnalyticsByPartyRoleGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for a requested Document ID.
#
# GET /caseDocument/{caseDocumentId}
# Returns: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>
# operationId: getDocumentById
export def "get-document-by-id" [
  case_document_id: string
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
    path: "/caseDocument/{caseDocumentId}"
    path_params: [{name: caseDocumentId, var: case_document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_document_id: $case_document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets downloadable URL for a requested Document ID.
#
# GET /caseDocumentDownload/{caseDocumentId}
# operationId: getCaseDocumentDownloadById
export def "get-case-document-download-by-id" [
  case_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-preview-document: oneof<nothing, bool> # If the document you want to download is a preview of a document. (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/caseDocumentDownload/{caseDocumentId}"
    path_params: [{name: caseDocumentId, var: case_document_id}]
    query: [{name: isPreviewDocument, var: is_preview_document}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_document_id: $case_document_id, is_preview_document: $is_preview_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Case Document Order for requested Document Ids.
#
# PUT /caseDocumentOrder
# Returns: record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>
# operationId: orderCaseDocument
export def "order-case-document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_document_id: string # Document ID which you want to order. (e.g. CDOCcre989d654fa05)
  --is-preview-only: oneof<nothing, bool> # Flag value to determine if the document order is a preview order or no. (e.g. true)
  --pacer-options: record # **Applicable for PACER cases.** — shape: {pacerClientCode?: string, pacerUserId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/caseDocumentOrder"
    body: {content_type: "application/json", kind: json, fields: [{name: caseDocumentId, var: case_document_id}, {name: isPreviewOnly, var: is_preview_only, required: true}, {name: pacerOptions, var: pacer_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_document_id: $case_document_id, is_preview_only: $is_preview_only, pacer_options: $pacer_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Document Order Callback list for a requested Date.
#
# GET /caseDocumentOrder/callbacks
# Returns: record<callbackArray: table<callbackGeneratedDate: string, caseDocument: record, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseDocumentOrderCallbacks
export def "get-case-document-order-callbacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date for which fetch the Case Document Order Callback list. By default, the date will be set to current date. (format: date-time)
  --status: string@status-completer # Status of Document Order callbacks. Default status will fetch all callbacks.
  --page-number: int # Page to fetch the Case Document Order Callback list. - Minimum: 1 (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseDocumentOrder/callbacks"
    query: [{name: date, var: date}, {name: status, var: status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, status: $status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Document Order Callback for a requested Case Document Order Callback Id.
#
# GET /caseDocumentOrder/callbacks/{caseDocumentOrderCallbackId}
# Returns: record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>
# operationId: getCaseDocumentOrderCallbackById
export def "get-case-document-order-callback-by-id" [
  case_document_order_callback_id: string
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
    path: "/caseDocumentOrder/callbacks/{caseDocumentOrderCallbackId}"
    path_params: [{name: caseDocumentOrderCallbackId, var: case_document_order_callback_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_document_order_callback_id: $case_document_order_callback_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Export Callback list for a requested Date.
#
# GET /caseExport/callbacks
# Returns: record<callbackArray: table<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseExportCallbacks
export def "get-case-export-callbacks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for which callbacks are to be retrieved. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --status: string@status-completer # The status code of the callbacks to be retrieved.
  --page-number: int # The page number of the callbacks to be retrieved. - Minimum: 1 (default: 1, e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseExport/callbacks"
    query: [{name: date, var: date}, {name: status, var: status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, status: $status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Export Callback for a requested Case Export Callback Id.
#
# GET /caseExport/callbacks/{caseExportCallbackId}
# Returns: record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>
# operationId: getCaseExportCallbackById
export def "get-case-export-callback-by-id" [
  case_export_callback_id: string
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
    path: "/caseExport/callbacks/{caseExportCallbackId}"
    path_params: [{name: caseExportCallbackId, var: case_export_callback_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_export_callback_id: $case_export_callback_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets case exported for a requested Case ID.
#
# GET /caseExport/{caseId}
# Returns: record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string>
# operationId: exportCase
export def "export-case" [
  case_id: string
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
    path: "/caseExport/{caseId}"
    path_params: [{name: caseId, var: case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case search.
#
# GET /caseSearch
# Returns: record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchCases
export def "search-cases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query parameter for keyword expressions. (required)
  --sort: string@sort-completer # Query parameter specifying how results are to be sorted. Results can be sorted according to filedDate or relevancy. (default: filedDate, e.g. filedDate)
  --order: string@order-completer # Query parameter specifying whether search result are sorted in ascending or descending order. (default: desc, e.g. desc)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseSearch"
    query: [{name: q, var: q, required: true}, {name: sort, var: sort}, {name: order, var: order}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, sort: $sort, order: $order, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case search results for a given caseSearchId.
#
# GET /caseSearch/{caseSearchId}
# Returns: record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchCasesById
export def "search-cases-by-id" [
  case_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseSearch/{caseSearchId}"
    path_params: [{name: caseSearchId, var: case_search_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_search_id: $case_search_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Case Track for the requested Case Id.
#
# PUT /caseTrack
# Returns: record<message: string, object: string>
# operationId: trackCase
export def "track-case" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_track_params: record # shape: {caseId: string, pacerOptions?: record}
  schedule: record # shape: {days: list<int>, type: "daily"|"weekly"|"monthly"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/caseTrack"
    body: {content_type: "application/json", kind: json, fields: [{name: caseTrackParams, var: case_track_params}, {name: schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_track_params: $case_track_params, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Case Track for a specific Case Id.
#
# DELETE /caseTrack/{caseId}
# Returns: record<message: string, object: string>
# operationId: removeCaseTrackById
export def "remove-case-track-by-id" [
  case_id: string
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
    path: "/caseTrack/{caseId}"
    path_params: [{name: caseId, var: case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Track for a requested Case Id.
#
# GET /caseTrack/{caseId}
# Returns: record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record<lastTrackDate: string, lastTrackException: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, schedule: record<days: list<int>, object: string, type: string>>
# operationId: getCaseTrackById
export def "get-case-track-by-id" [
  case_id: string
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
    path: "/caseTrack/{caseId}"
    path_params: [{name: caseId, var: case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Track list.
#
# GET /caseTracks
# Returns: record<caseTrackPreviewArray: table<caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record, object: string, pacerOptions: record, schedule: record>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseTracks
export def "get-case-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-fetch-date: string # The lastFetchDate value of the tracked case. The date value should be entered in the format YYYY-MM-DDTHH:MM:SS+ZZ:zz. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --last-fetch-date-with-updates: string # The date on which changes were last found in the case information. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --page-number: int # The page number of the results to be retrieved. - Minimum: 1 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseTracks"
    query: [{name: lastFetchDate, var: last_fetch_date}, {name: lastFetchDateWithUpdates, var: last_fetch_date_with_updates}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    last_fetch_date: $last_fetch_date, last_fetch_date_with_updates: $last_fetch_date_with_updates, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Case Update for the requested Case Id.
#
# PUT /caseUpdate
# Returns: record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string>
# operationId: updateCase
export def "update-case" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_id: string # UniCourt's Case Id for update. (e.g. CASEhq9d8b72d0800c)
  --pacer-options: record # Applicable for PACER cases. — shape: {additionalPageArray?: list, fetchParticipantsIfOlderThanDays?: int, pacerClientCode?: string, pacerUserId: string, refreshType?: "fetchNewDocketEntries"|"fetchAllDocketEntries"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/caseUpdate"
    body: {content_type: "application/json", kind: json, fields: [{name: caseId, var: case_id}, {name: pacerOptions, var: pacer_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, pacer_options: $pacer_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Updates for a requested CaseId.
#
# GET /caseUpdate/{caseId}
# Returns: record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string>
# operationId: getCaseUpdateByCaseId
export def "get-case-update-by-case-id" [
  case_id: string
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
    path: "/caseUpdate/{caseId}"
    path_params: [{name: caseId, var: case_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Case Update list for a requested Date.
#
# GET /caseUpdates
# Returns: record<caseUpdatePreviewArray: table<caseAPI: string, caseId: string, exception: record, object: string, pacerOptions: record, requestedDate: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseUpdates
export def "get-case-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-id: string # The caseId value of the case for which updates should be retrieved.
  --requested-date: string # The date for which case updates are to be retrieved. (format: date-time)
  --status: string@status-completer # Status of the case updates to be retrieved.
  --page-number: int # The page number of the callbacks to be retrieved. - Minimum: 1 (default: 1, e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/caseUpdates"
    query: [{name: caseId, var: case_id}, {name: requestedDate, var: requested_date}, {name: status, var: status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_id: $case_id, requested_date: $requested_date, status: $status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Court Coverage of all courts of specific type.
#
# GET /courtCoverage/{courtId}
# Returns: record<caseClassCoverageArray: table<caseClass: record, caseCount: int, caseDocumentInLibraryCount: int, caseDocumentInLibraryInLastThirtyDaysCount: int, casesInLastThirtyDaysCount: int, courtServiceStatusAPI: string, freeCaseDocumentCount: int, freeCaseDocumentsInLastThirtyDaysCount: int, object: string, paidCaseDocumentCount: int, paidCaseDocumentsInLastThirtyDaysCount: int>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, lastUpdateCountDate: string, object: string, totalCaseCount: int, totalCaseDocumentInLibraryCount: int, totalCaseDocumentInLibraryInLastThirtyDaysCount: int, totalCasesInLastThirtyDaysCount: int, totalFreeCaseDocumentCount: int, totalFreeCaseDocumentsInLastThirtyDaysCount: int, totalPaidCaseDocumentCount: int, totalPaidCaseDocumentsInLastThirtyDaysCount: int>
# operationId: getCourtCoverage
export def "get-court-coverage" [
  court_id: string
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
    path: "/courtCoverage/{courtId}"
    path_params: [{name: courtId, var: court_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_id: $court_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get API usage for a requested Date.
#
# GET /dailyUsage/{date}
# Returns: record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, object: string, usageEndTime: string, usageStartTime: string>
# operationId: getDailyUsageByDate
export def "get-daily-usage-by-date" [
  date: string
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
    path: "/dailyUsage/{date}"
    path_params: [{name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new token to access API.
#
# POST /generateNewToken
# Returns: record<accessToken: string, object: string, tokenId: string, tokenType: string>
# operationId: generateNewToken
export def "generate-new-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/generateNewToken"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: clientSecret, var: client_secret}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API to invalidate all access tokens.
#
# PUT /invalidateAllTokens
# Returns: record<message: string, object: string>
# operationId: invalidateAllTokens
export def "invalidate-all-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/invalidateAllTokens"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: clientSecret, var: client_secret}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API to invalidate the access token.
#
# PUT /invalidateToken
# Returns: record<message: string, object: string>
# operationId: invalidateToken
export def "invalidate-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
  token_id: string # The Token ID of token being invalidated (e.g. TKID384a057WFC3Dp3)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/invalidateToken"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: tokenId, var: token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for a requested Judge ID.
#
# GET /judge/{judgeId}
# Returns: record<contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record<createdDate: string, judgeTypeId: string, name: string, object: string>, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: table<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormJudgeAPI: string, confidenceScore: float, normJudgeAPI: string, normJudgeId: string, normJudgeName: string, object: string, scoreConstituents: record>, sourceJudgeType: string>
# operationId: getJudgeById
export def "get-judge-by-id" [
  judge_id: string
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
    path: "/judge/{judgeId}"
    path_params: [{name: judgeId, var: judge_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    judge_id: $judge_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# API to list all the access tokens Id.
#
# PUT /listAllTokenIds
# Returns: record<AccessTokenIdArray: table<issueAddress: string, issuedDate: string, object: string, tokenId: string>, object: string>
# operationId: listAllTokenIds
export def "list-all-token-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/listAllTokenIds"
    body: {content_type: "application/json", kind: json, fields: [{name: clientId, var: client_id}, {name: clientSecret, var: client_secret}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AreaOfLaw Object.
#
# GET /masterData/areaOfLaw
# Returns: record<areaOfLawArray: table<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getAreasOfLaw
export def "get-areas-of-law" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/areaOfLaw"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# AreaOfLaw Object for the given AreaOfLaw Id.
#
# GET /masterData/areaOfLaw/{areaOfLawId}
# Returns: record<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>
# operationId: getAreaOfLaw
export def "get-area-of-law" [
  area_of_law_id: string
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
    path: "/masterData/areaOfLaw/{areaOfLawId}"
    path_params: [{name: areaOfLawId, var: area_of_law_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    area_of_law_id: $area_of_law_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorney Representation Type Object.
#
# GET /masterData/attorneyRepresentationType
# Returns: record<attorneyRepresentationTypeArray: table<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getAttorneyRepresentationTypes
export def "get-attorney-representation-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/attorneyRepresentationType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorney Representation Type Object for the given attorneyRepresentationTypeId.
#
# GET /masterData/attorneyRepresentationType/{attorneyRepresentationTypeId}
# Returns: record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>
# operationId: getAttorneyRepresentationType
export def "get-attorney-representation-type" [
  attorney_representation_type_id: string
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
    path: "/masterData/attorneyRepresentationType/{attorneyRepresentationTypeId}"
    path_params: [{name: attorneyRepresentationTypeId, var: attorney_representation_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attorney_representation_type_id: $attorney_representation_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorney Type Object.
#
# GET /masterData/attorneyType
# Returns: record<attorneyTypeArray: table<attorneyTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getAttorneyTypes
export def "get-attorney-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/attorneyType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorney Type Object for given Attorney Type Id.
#
# GET /masterData/attorneyType/{attorneyTypeId}
# Returns: record<attorneyTypeId: string, createdDate: string, name: string, object: string>
# operationId: getAttorneyType
export def "get-attorney-type" [
  attorney_type_id: string
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
    path: "/masterData/attorneyType/{attorneyTypeId}"
    path_params: [{name: attorneyTypeId, var: attorney_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attorney_type_id: $attorney_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Class Object.
#
# GET /masterData/caseClass
# Returns: record<caseClassArray: table<caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCasesClass
export def "get-cases-class" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseClass"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Class Object for the given Case Class Id.
#
# GET /masterData/caseClass/{caseClassId}
# Returns: record<caseClassId: string, createdDate: string, name: string, object: string>
# operationId: getCaseClass
export def "get-case-class" [
  case_class_id: string
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
    path: "/masterData/caseClass/{caseClassId}"
    path_params: [{name: caseClassId, var: case_class_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_class_id: $case_class_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Relationship Type Object.
#
# GET /masterData/caseRelationshipType
# Returns: record<caseRelationshipTypeArray: table<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseRelationshipTypes
export def "get-case-relationship-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseRelationshipType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Relationship Type Object for the given caseRelationshipTypeId.
#
# GET /masterData/caseRelationshipType/{caseRelationshipTypeId}
# Returns: record<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>
# operationId: getCaseRelationshipType
export def "get-case-relationship-type" [
  case_relationship_type_id: string
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
    path: "/masterData/caseRelationshipType/{caseRelationshipTypeId}"
    path_params: [{name: caseRelationshipTypeId, var: case_relationship_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_relationship_type_id: $case_relationship_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Status Object.
#
# GET /masterData/caseStatus
# Returns: record<caseStatusArray: table<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCasesStatus
export def "get-cases-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseStatus"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the caseStatus information for the given caseStatusId.
#
# GET /masterData/caseStatus/{caseStatusId}
# Returns: record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>
# operationId: getCaseStatus
export def "get-case-status" [
  case_status_id: string
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
    path: "/masterData/caseStatus/{caseStatusId}"
    path_params: [{name: caseStatusId, var: case_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_status_id: $case_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Status Group Object.
#
# GET /masterData/caseStatusGroup
# Returns: record<caseStatusGroupArray: table<caseStatusGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseStatusGroups
export def "get-case-status-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseStatusGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the caseStatusGroup information for the given caseStatusGroupId.
#
# GET /masterData/caseStatusGroup/{caseStatusGroupId}
# Returns: record<caseStatusGroupId: string, createdDate: string, name: string, object: string>
# operationId: getCaseStatusGroup
export def "get-case-status-group" [
  case_status_group_id: string
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
    path: "/masterData/caseStatusGroup/{caseStatusGroupId}"
    path_params: [{name: caseStatusGroupId, var: case_status_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_status_group_id: $case_status_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Type Object.
#
# GET /masterData/caseType
# Returns: record<caseTypeArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseTypes
export def "get-case-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CaseType Object for given Case Type Id.
#
# GET /masterData/caseType/{caseTypeId}
# Returns: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>
# operationId: getCaseType
export def "get-case-type" [
  case_type_id: string
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
    path: "/masterData/caseType/{caseTypeId}"
    path_params: [{name: caseTypeId, var: case_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_type_id: $case_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CaseTypeGroup Object.
#
# GET /masterData/caseTypeGroup
# Returns: record<caseTypeGroupArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCaseTypeGroups
export def "get-case-type-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/caseTypeGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CaseType Group for the given CaseType Group Id.
#
# GET /masterData/caseTypeGroup/{caseTypeGroupId}
# Returns: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>
# operationId: getCaseTypeGroup
export def "get-case-type-group" [
  case_type_group_id: string
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
    path: "/masterData/caseTypeGroup/{caseTypeGroupId}"
    path_params: [{name: caseTypeGroupId, var: case_type_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    case_type_group_id: $case_type_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfAction Object.
#
# GET /masterData/causeOfAction
# Returns: record<causeOfActionArray: table<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCausesOfAction
export def "get-causes-of-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/causeOfAction"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfAction Object for the given causeOfActionId.
#
# GET /masterData/causeOfAction/{causeOfActionId}
# Returns: record<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>
# operationId: getCauseOfAction
export def "get-cause-of-action" [
  cause_of_action_id: string
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
    path: "/masterData/causeOfAction/{causeOfActionId}"
    path_params: [{name: causeOfActionId, var: cause_of_action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cause_of_action_id: $cause_of_action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfActionAdditionaData Object.
#
# GET /masterData/causeOfActionAdditionalData
# Returns: record<causeOfActionAdditionalDataArray: table<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCausesOfActionAdditionalData
export def "get-causes-of-action-additional-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/causeOfActionAdditionalData"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfActionAdditionalData Object for the given causeOfActionAdditionalDataId.
#
# GET /masterData/causeOfActionAdditionalData/{causeOfActionAdditionalDataId}
# Returns: record<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>
# operationId: getCauseOfActionAdditionalData
export def "get-cause-of-action-additional-data" [
  cause_of_action_additional_data_id: string
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
    path: "/masterData/causeOfActionAdditionalData/{causeOfActionAdditionalDataId}"
    path_params: [{name: causeOfActionAdditionalDataId, var: cause_of_action_additional_data_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cause_of_action_additional_data_id: $cause_of_action_additional_data_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfActionGroup Object.
#
# GET /masterData/causeOfActionGroup
# Returns: record<causeOfActionGroupArray: table<causeOfActionGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCausesOfActionGroup
export def "get-causes-of-action-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/causeOfActionGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CauseOfActionGroup Object for the given causeOfActionGroupId.
#
# GET /masterData/causeOfActionGroup/{causeOfActionGroupId}
# Returns: record<causeOfActionGroupId: string, createdDate: string, name: string, object: string>
# operationId: getCauseOfActionGroup
export def "get-cause-of-action-group" [
  cause_of_action_group_id: string
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
    path: "/masterData/causeOfActionGroup/{causeOfActionGroupId}"
    path_params: [{name: causeOfActionGroupId, var: cause_of_action_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cause_of_action_group_id: $cause_of_action_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Object.
#
# GET /masterData/charge
# Returns: record<chargeArray: table<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCharges
export def "get-charges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/charge"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Object for the given chargeId.
#
# GET /masterData/charge/{chargeId}
# Returns: record<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>
# operationId: getCharge
export def "get-charge" [
  charge_id: string
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
    path: "/masterData/charge/{chargeId}"
    path_params: [{name: chargeId, var: charge_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    charge_id: $charge_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Additional Data Object.
#
# GET /masterData/chargeAdditionalData
# Returns: record<chargeAdditionalDataArray: table<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getChargesAdditionalData
export def "get-charges-additional-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/chargeAdditionalData"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Additional Data Object for the given chargeAdditionalDataId.
#
# GET /masterData/chargeAdditionalData/{chargeAdditionalDataId}
# Returns: record<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>
# operationId: getChargeAdditionalData
export def "get-charge-additional-data" [
  charge_additional_data_id: string
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
    path: "/masterData/chargeAdditionalData/{chargeAdditionalDataId}"
    path_params: [{name: chargeAdditionalDataId, var: charge_additional_data_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    charge_additional_data_id: $charge_additional_data_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ChargeDegree Object.
#
# GET /masterData/chargeDegree
# Returns: record<chargeDegreeArray: table<chargeDegreeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getChargesDegree
export def "get-charges-degree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/chargeDegree"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ChargeDegree Object for the given chargeDegreeId.
#
# GET /masterData/chargeDegree/{chargeDegreeId}
# Returns: record<chargeDegreeId: string, createdDate: string, name: string, object: string>
# operationId: getChargeDegree
export def "get-charge-degree" [
  charge_degree_id: string
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
    path: "/masterData/chargeDegree/{chargeDegreeId}"
    path_params: [{name: chargeDegreeId, var: charge_degree_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    charge_degree_id: $charge_degree_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Group Object.
#
# GET /masterData/chargeGroup
# Returns: record<chargeGroupArray: table<chargeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getChargeGroups
export def "get-charge-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/chargeGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Charge Group Object for the given chargeGroupId.
#
# GET /masterData/chargeGroup/{chargeGroupId}
# Returns: record<chargeGroupId: string, createdDate: string, name: string, object: string>
# operationId: getChargeGroup
export def "get-charge-group" [
  charge_group_id: string
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
    path: "/masterData/chargeGroup/{chargeGroupId}"
    path_params: [{name: chargeGroupId, var: charge_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    charge_group_id: $charge_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ChargeSeverity Object.
#
# GET /masterData/chargeSeverity
# Returns: record<chargeSeverityArray: table<chargeSeverityId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getChargesSeverity
export def "get-charges-severity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/chargeSeverity"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ChargeSeverity Object for the given chargeSeverityId.
#
# GET /masterData/chargeSeverity/{chargeSeverityId}
# Returns: record<chargeSeverityId: string, createdDate: string, name: string, object: string>
# operationId: getChargeSeverity
export def "get-charge-severity" [
  charge_severity_id: string
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
    path: "/masterData/chargeSeverity/{chargeSeverityId}"
    path_params: [{name: chargeSeverityId, var: charge_severity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    charge_severity_id: $charge_severity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Objects.
#
# GET /masterData/court
# Returns: record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourts
export def "get-courts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/court"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Object for given courtId.
#
# GET /masterData/court/{courtId}
# Returns: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>
# operationId: getCourt
export def "get-court" [
  court_id: string
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
    path: "/masterData/court/{courtId}"
    path_params: [{name: courtId, var: court_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_id: $court_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Appeal Court Objects for given courtId.
#
# GET /masterData/court/{courtId}/appealCourts
# Returns: record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getAppealCourtsForCourt
export def "get-appeal-courts-for-court" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/court/{courtId}/appealCourts"
    path_params: [{name: courtId, var: court_id}]
    query: [{name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_id: $court_id, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associated Court Location for given courtId.
#
# GET /masterData/court/{courtId}/courtLocations
# Returns: record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtLocationsForCourt
export def "get-court-locations-for-court" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/court/{courtId}/courtLocations"
    path_params: [{name: courtId, var: court_id}]
    query: [{name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_id: $court_id, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Jurisdiction Geo Objects for given courtId.
#
# GET /masterData/court/{courtId}/jurisdictionGeo
# Returns: record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getJurisdictionGeoForCourt
export def "get-jurisdiction-geo-for-court" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/court/{courtId}/jurisdictionGeo"
    path_params: [{name: courtId, var: court_id}]
    query: [{name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_id: $court_id, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Courthouse Object.
#
# GET /masterData/courtLocation
# Returns: record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtLocations
export def "get-court-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/courtLocation"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Courthouse Object for given Court Location Id.
#
# GET /masterData/courtLocation/{courtLocationId}
# Returns: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>
# operationId: getCourtLocation
export def "get-court-location" [
  court_location_id: string
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
    path: "/masterData/courtLocation/{courtLocationId}"
    path_params: [{name: courtLocationId, var: court_location_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_location_id: $court_location_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associated Court for given Court Location.
#
# GET /masterData/courtLocation/{courtLocationId}/courts
# Returns: record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtsForCourtLocation
export def "get-courts-for-court-location" [
  court_location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/courtLocation/{courtLocationId}/courts"
    path_params: [{name: courtLocationId, var: court_location_id}]
    query: [{name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_location_id: $court_location_id, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Service Status Object.
#
# GET /masterData/courtServiceStatus
# Returns: record<courtServiceStatusArray: table<caseClassIdArray: list, caseDocumentOrderServiceStatus: record, caseTrackServiceStatus: record, caseUpdateServiceStatus: record, courtIdArray: list, courtLocationIdArray: list, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtsServiceStatus
export def "get-courts-service-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/courtServiceStatus"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Service Status Object for the given courtServiceStatusId.
#
# GET /masterData/courtServiceStatus/{courtServiceStatusId}
# Returns: record<caseClassIdArray: list<string>, caseDocumentOrderServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseTrackServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseUpdateServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, courtIdArray: list<string>, courtLocationIdArray: list<string>, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>
# operationId: getCourtServiceStatus
export def "get-court-service-status" [
  court_service_status_id: string
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
    path: "/masterData/courtServiceStatus/{courtServiceStatusId}"
    path_params: [{name: courtServiceStatusId, var: court_service_status_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_service_status_id: $court_service_status_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court System Objects.
#
# GET /masterData/courtSystem
# Returns: record<courtSystemArray: table<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtSystems
export def "get-court-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/courtSystem"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court System Object for given courtSystemId.
#
# GET /masterData/courtSystem/{courtSystemId}
# Returns: record<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>
# operationId: getCourtSystem
export def "get-court-system" [
  court_system_id: string
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
    path: "/masterData/courtSystem/{courtSystemId}"
    path_params: [{name: courtSystemId, var: court_system_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_system_id: $court_system_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Type Objects.
#
# GET /masterData/courtType
# Returns: record<courtTypeArray: table<courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtTypes
export def "get-court-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/courtType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Court Type Object for given courtTypeId.
#
# GET /masterData/courtType/{courtTypeId}
# Returns: record<courtTypeId: string, createdDate: string, name: string, object: string>
# operationId: getCourtType
export def "get-court-type" [
  court_type_id: string
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
    path: "/masterData/courtType/{courtTypeId}"
    path_params: [{name: courtTypeId, var: court_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    court_type_id: $court_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judge Type Object.
#
# GET /masterData/judgeType
# Returns: record<judgeTypeArray: table<createdDate: string, judgeTypeId: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getJudgeTypes
export def "get-judge-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/judgeType"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judge Type Object for the given judgeTypeId.
#
# GET /masterData/judgeType/{judgeTypeId}
# Returns: record<createdDate: string, judgeTypeId: string, name: string, object: string>
# operationId: getJudgeType
export def "get-judge-type" [
  judge_type_id: string
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
    path: "/masterData/judgeType/{judgeTypeId}"
    path_params: [{name: judgeTypeId, var: judge_type_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    judge_type_id: $judge_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Jurisdiction Geo Object.
#
# GET /masterData/jurisdictionGeo
# Returns: record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getJurisdictionsGeo
export def "get-jurisdictions-geo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/jurisdictionGeo"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Jurisdiction Geo Object for given Jurisdiction Geo Id.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}
# Returns: record<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list<string>>
# operationId: getJurisdictionGeo
export def "get-jurisdiction-geo" [
  jurisdiction_geo_id: string
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
    path: "/masterData/jurisdictionGeo/{jurisdictionGeoId}"
    path_params: [{name: jurisdictionGeoId, var: jurisdiction_geo_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction_geo_id: $jurisdiction_geo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associated Court for given Jurisdiction Geo.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}/courts
# Returns: record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getCourtsForJurisdictionGeo
export def "get-courts-for-jurisdiction-geo" [
  jurisdiction_geo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/jurisdictionGeo/{jurisdictionGeoId}/courts"
    path_params: [{name: jurisdictionGeoId, var: jurisdiction_geo_id}]
    query: [{name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    jurisdiction_geo_id: $jurisdiction_geo_id, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Party Role Object.
#
# GET /masterData/partyRole
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, partyRoleArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getPartyRoles
export def "get-party-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/partyRole"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Party Role Object.
#
# GET /masterData/partyRole/{partyRoleId}
# Returns: record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>
# operationId: getPartyRole
export def "get-party-role" [
  party_role_id: string
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
    path: "/masterData/partyRole/{partyRoleId}"
    path_params: [{name: partyRoleId, var: party_role_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_role_id: $party_role_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Party Role Group Object.
#
# GET /masterData/partyRoleGroup
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, partyRoleGroupArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getPartyRoleGroups
export def "get-party-role-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/masterData/partyRoleGroup"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}, {name: sort, var: sort}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number, sort: $sort, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Party Role Group Object.
#
# GET /masterData/partyRoleGroup/{partyRoleGroupId}
# Returns: record<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>
# operationId: getPartyRoleGroup
export def "get-party-role-group" [
  party_role_group_id: string
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
    path: "/masterData/partyRoleGroup/{partyRoleGroupId}"
    path_params: [{name: partyRoleGroupId, var: party_role_group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_role_group_id: $party_role_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm Attorney Details.
#
# GET /normAttorney/{normAttorneyId}
# Returns: record<attorneyAnalyticsAPI: record<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normAttorneyAPI: string, object: string>, barRecordArray: table<admittedDate: string, barNumber: string, barSourceData: record, barSourceType: string, contact: record, firstFetchDate: string, inactivationDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, stateCode: string, status: string>, caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, lastName: string, middleName: string, name: string, normAttorneyId: string, object: string, similarNormAttorneyArray: table<barRecordPreviewArray: list, name: string, normAttorneyAPI: string, normAttorneyId: string, normAttorneySimilarityScore: float, object: string>>
# operationId: getNormAttorneyById
export def "get-norm-attorney-by-id" [
  norm_attorney_id: string
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
    path: "/normAttorney/{normAttorneyId}"
    path_params: [{name: normAttorneyId, var: norm_attorney_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_id: $norm_attorney_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judges faced by the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormJudges
# Returns: record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormJudgesAssociatedWithNormAttorney
export def "get-norm-judges-associated-with-norm-attorney" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorney/{normAttorneyId}/associatedNormJudges"
    path_params: [{name: normAttorneyId, var: norm_attorney_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_id: $norm_attorney_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Law Firms the attorney has worked for.
#
# GET /normAttorney/{normAttorneyId}/associatedNormLawFirms
# Returns: record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormLawFirmsAssociatedWithNormAttorney
export def "get-norm-law-firms-associated-with-norm-attorney" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorney/{normAttorneyId}/associatedNormLawFirms"
    path_params: [{name: normAttorneyId, var: norm_attorney_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_id: $norm_attorney_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parties Represented By the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormParties
# Returns: record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormPartiesAssociatedWithNormAttorney
export def "get-norm-parties-associated-with-norm-attorney" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorney/{normAttorneyId}/associatedNormParties"
    path_params: [{name: normAttorneyId, var: norm_attorney_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_id: $norm_attorney_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Opposing Norm Attorney.
#
# GET /normAttorney/{normAttorneyId}/caseCountAnalyticsByOpposingNormAttorney
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByOpposingNormAttorneyForANormAttorney
export def "get-case-count-analytics-by-opposing-norm-attorney-for-a-norm-attorney" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorney/{normAttorneyId}/caseCountAnalyticsByOpposingNormAttorney"
    path_params: [{name: normAttorneyId, var: norm_attorney_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_id: $norm_attorney_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorney search.
#
# GET /normAttorneySearch
# Returns: record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedAttorneys
export def "search-normalized-attorneys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorneySearch"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm attorney search results for a given normAttorneySearchId.
#
# GET /normAttorneySearch/{normAttorneySearchId}
# Returns: record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedAttorneysById
export def "search-normalized-attorneys-by-id" [
  norm_attorney_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normAttorneySearch/{normAttorneySearchId}"
    path_params: [{name: normAttorneySearchId, var: norm_attorney_search_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_attorney_search_id: $norm_attorney_search_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm Judge Details.
#
# GET /normJudge/{normJudgeId}
# Returns: record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, judgeAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, normJudgeAPI: string, object: string>, judicialDataArray: table<abaRatings: record, aliasArray: list, bio: record, contact: record, educationArray: list, firstFetchDate: string, judicialSource: record, judicialStatus: string, lastFetchDate: string, lastFetchDateWithUpdates: string, nameHistoryArray: list, object: string, professionalCareerArray: list, serviceHistoryArray: list>, lastName: string, middleName: string, name: string, normJudgeId: string, object: string>
# operationId: getNormJudgeById
export def "get-norm-judge-by-id" [
  norm_judge_id: string
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
    path: "/normJudge/{normJudgeId}"
    path_params: [{name: normJudgeId, var: norm_judge_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_judge_id: $norm_judge_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorneys Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormAttorneys
# Returns: record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormAttorneysAssociatedWithNormJudge
export def "get-norm-attorneys-associated-with-norm-judge" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normJudge/{normJudgeId}/associatedNormAttorneys"
    path_params: [{name: normJudgeId, var: norm_judge_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_judge_id: $norm_judge_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Law Firms Associated With the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormLawFirms
# Returns: record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormLawFirmsAssociatedWithNormJudge
export def "get-norm-law-firms-associated-with-norm-judge" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normJudge/{normJudgeId}/associatedNormLawFirms"
    path_params: [{name: normJudgeId, var: norm_judge_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_judge_id: $norm_judge_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parties Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormParties
# Returns: record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormPartiesAssociatedWithNormJudge
export def "get-norm-parties-associated-with-norm-judge" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normJudge/{normJudgeId}/associatedNormParties"
    path_params: [{name: normJudgeId, var: norm_judge_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_judge_id: $norm_judge_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judge search.
#
# GET /normJudgeSearch
# Returns: record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedJudges
export def "search-normalized-judges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normJudgeSearch"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm judge search results for a given normJudgeSearchId.
#
# GET /normJudgeSearch/{normJudgeSearchId}
# Returns: record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedJudgesById
export def "search-normalized-judges-by-id" [
  norm_judge_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normJudgeSearch/{normJudgeSearchId}"
    path_params: [{name: normJudgeSearchId, var: norm_judge_search_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_judge_search_id: $norm_judge_search_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm LawFirm Details.
#
# GET /normLawFirm/{normLawFirmId}
# Returns: record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, lawFirmAnalyticsAPI: record<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normLawFirmAPI: string, object: string>, name: string, normLawFirmId: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, object: string>
# operationId: getNormLawFirmById
export def "get-norm-law-firm-by-id" [
  norm_law_firm_id: string
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
    path: "/normLawFirm/{normLawFirmId}"
    path_params: [{name: normLawFirmId, var: norm_law_firm_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_id: $norm_law_firm_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorneys working for the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormAttorneys
# Returns: record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormAttorneysAssociatedWithNormLawFirm
export def "get-norm-attorneys-associated-with-norm-law-firm" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirm/{normLawFirmId}/associatedNormAttorneys"
    path_params: [{name: normLawFirmId, var: norm_law_firm_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_id: $norm_law_firm_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judges Faced By the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormJudges
# Returns: record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormJudgesAssociatedWithNormLawFirm
export def "get-norm-judges-associated-with-norm-law-firm" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirm/{normLawFirmId}/associatedNormJudges"
    path_params: [{name: normLawFirmId, var: norm_law_firm_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_id: $norm_law_firm_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parties Represented by the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormParties
# Returns: record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormPartiesAssociatedWithNormLawFirm
export def "get-norm-parties-associated-with-norm-law-firm" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirm/{normLawFirmId}/associatedNormParties"
    path_params: [{name: normLawFirmId, var: norm_law_firm_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_id: $norm_law_firm_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Opposing Norm Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/caseCountAnalyticsByOpposingNormLawFirm
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByOpposingNormLawFirmForANormLawFirm
export def "get-case-count-analytics-by-opposing-norm-law-firm-for-a-norm-law-firm" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirm/{normLawFirmId}/caseCountAnalyticsByOpposingNormLawFirm"
    path_params: [{name: normLawFirmId, var: norm_law_firm_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_id: $norm_law_firm_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Law firm search.
#
# GET /normLawFirmSearch
# Returns: record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedLawFirms
export def "search-normalized-law-firms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirmSearch"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm law firm search result for a given normLawFirmSearchId.
#
# GET /normLawFirmSearch/{normLawFirmSearchId}
# Returns: record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedLawFirmsById
export def "search-normalized-law-firms-by-id" [
  norm_law_firm_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normLawFirmSearch/{normLawFirmSearchId}"
    path_params: [{name: normLawFirmSearchId, var: norm_law_firm_search_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_law_firm_search_id: $norm_law_firm_search_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm Party Details.
#
# GET /normParty/{normPartyId}
# Returns: record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, individualData: record<firstName: string, lastName: string, middleName: string, name: string>, name: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, normPartyId: string, object: string, partyAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normPartyAPI: string, object: string>, partyClassificationType: string, relatedNormPartyArray: table<normPartyId: string, object: string, relationshipType: string>>
# operationId: getNormPartyById
export def "get-norm-party-by-id" [
  norm_party_id: string
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
    path: "/normParty/{normPartyId}"
    path_params: [{name: normPartyId, var: norm_party_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_id: $norm_party_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attorneys that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormAttorneys
# Returns: record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormAttorneysAssociatedWithNormParty
export def "get-norm-attorneys-associated-with-norm-party" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normParty/{normPartyId}/associatedNormAttorneys"
    path_params: [{name: normPartyId, var: norm_party_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_id: $norm_party_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Judges Faced By the Party.
#
# GET /normParty/{normPartyId}/associatedNormJudges
# Returns: record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormJudgesAssociatedWithNormParty
export def "get-norm-judges-associated-with-norm-party" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normParty/{normPartyId}/associatedNormJudges"
    path_params: [{name: normPartyId, var: norm_party_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_id: $norm_party_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Law Firms that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormLawFirms
# Returns: record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getNormLawFirmsAssociatedWithNormParty
export def "get-norm-law-firms-associated-with-norm-party" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normParty/{normPartyId}/associatedNormLawFirms"
    path_params: [{name: normPartyId, var: norm_party_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_id: $norm_party_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Case Count Analytics by Opposing Norm Party.
#
# GET /normParty/{normPartyId}/caseCountAnalyticsByOpposingNormParty
# Returns: record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int>
# operationId: getCaseCountAnalyticsByOpposingNormPartyForANormParty
export def "get-case-count-analytics-by-opposing-norm-party-for-a-norm-party" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normParty/{normPartyId}/caseCountAnalyticsByOpposingNormParty"
    path_params: [{name: normPartyId, var: norm_party_id}]
    query: [{name: q, var: q}, {name: pageNumber, var: page_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_id: $norm_party_id, q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Party search.
#
# GET /normPartySearch
# Returns: record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedParties
export def "search-normalized-parties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normPartySearch"
    query: [{name: q, var: q}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Norm party search results for a given normPartySearchId.
#
# GET /normPartySearch/{normPartySearchId}
# Returns: record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int>
# operationId: searchNormalizedPartiesById
export def "search-normalized-parties-by-id" [
  norm_party_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/normPartySearch/{normPartySearchId}"
    path_params: [{name: normPartySearchId, var: norm_party_search_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    norm_party_search_id: $norm_party_search_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find PACER Case for a requested Case Number and Court.
#
# GET /pacer/importCaseByCourtUsingCaseNumber
# Returns: record<courtFee: float, object: string, pacerImportCaseResultsArray: table<hasOnlyMetaInfo: bool, object: string, uniCourtContent: record>>
# operationId: importPacerCaseByCourtUsingCaseNumber
export def "import-pacer-case-by-court-using-case-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # Case Number which you would like to Find in PACER site and import it to UniCourt. (required, e.g. 2:15-mc-12345)
  --court-id: string # Court Id of the Case number being provided. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacer/importCaseByCourtUsingCaseNumber"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number, required: true}, {name: courtId, var: court_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, court_id: $court_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/allCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: AllCourtsPacerCaseLocatorCaseSearch
export def "all-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed. (nullable)
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/allCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/appealCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: AppealCourtsPacerCaseLocatorCaseSearch
export def "appeal-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed. (nullable)
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --nature-of-suits-array: list<string> # Search can be narrowed down by passing Nature Of Suits. Please use the APPENDIX E - Appellate Nature Of Suits mentioned in the API Documentation. Scenario: When mulitple nature of suits needs to be requested. Imagine for a given case number 12-1234 I would like to search with the nature of suit 1110 (Insurance) and 1150 (Overpayments & Enforc. of Judgments), My query in the request will look like the example mentioned below. Example: natureOfSuitsArray=1110&natureOfSuitsArray=1150
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make. (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/appealCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: natureOfSuitsArray, var: nature_of_suits_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, nature_of_suits_array: $nature_of_suits_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for Bankruptcy Courts.
#
# GET /pacerCaseLocator/caseSearch/bankruptcyCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: BankruptcyCourtsPacerCaseLocatorCaseSearch
export def "bankruptcy-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --federal-bankruptcy-chapter-array: list<string> # Search can be narrowed down by passing Federal Bankruptcy Chapters. Please use the APPENDIX D: Bankruptcy Chapters mentioned in the API Documentation. Scenario: When mulitple Federal Bankruptcy Chapters needs to be requested. Imagine for a given case number 12-1234 I would like to search with the Federal Bankruptcy Chapters 7 (Chapter 7) and 11 (Chapter 11), My query in the request will look like the example mentioned below. Example: federalBankruptcyChapterArray=7&federalBankruptcyChapterArray=11
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-discharged-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-discharged-end-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/bankruptcyCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: federalBankruptcyChapterArray, var: federal_bankruptcy_chapter_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: caseDischargedStartDate, var: case_discharged_start_date}, {name: caseDischargedEndDate, var: case_discharged_end_date}, {name: caseDismissedStartDate, var: case_dismissed_start_date}, {name: caseDismissedEndDate, var: case_dismissed_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, federal_bankruptcy_chapter_array: $federal_bankruptcy_chapter_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, case_discharged_start_date: $case_discharged_start_date, case_discharged_end_date: $case_discharged_end_date, case_dismissed_start_date: $case_dismissed_start_date, case_dismissed_end_date: $case_dismissed_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/civilCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: CivilCourtsPacerCaseLocatorCaseSearch
export def "civil-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --nature-of-suits-array: list<string> # Search can be narrowed down by passing Nature Of Suits. Please use the APPENDIX E - Civil Nature Of Suits mentioned in the API Documentation. Scenario: When mulitple nature of suits needs to be requested. Imagine for a given case number 12-1234 I would like to search with the nature of suit 110 (Insurance) and 140 (Negotiable Instrument), My query in the request will look like the example mentioned below. Example: natureOfSuitsArray=110&natureOfSuitsArray=140
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/civilCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: natureOfSuitsArray, var: nature_of_suits_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, nature_of_suits_array: $nature_of_suits_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/criminalCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: CriminalCourtsPacerCaseLocatorCaseSearch
export def "criminal-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/criminalCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/multiDistrictCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: MultiDistrictCourtsPacerCaseLocatorCaseSearch
export def "multi-district-courts-pacer-case-locator-case-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpml-number: int # Master JPML Case Number.
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/caseSearch/multiDistrictCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: jpmlNumber, var: jpml_number}, {name: pacerCaseId, var: pacer_case_id}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, jpml_number: $jpml_number, pacer_case_id: $pacer_case_id, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/allCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: AllCourtsPacerCaseLocatorPartySearch
export def "all-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/allCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/appealCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: AppealCourtsPacerCaseLocatorPartySearch
export def "appeal-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/appealCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/bankruptcyCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: BankruptcyCourtsPacerCaseLocatorPartySearch
export def "bankruptcy-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --ssn-or-ein: string # The 9 digit Social Security number or Federal Tax ID can be used in this search. The delimiter dash (-) can be used as the input to this API but wont be used during the search. A search for SSN 123-45-6789 or 12-3456789 will yield the same results as a search for 123456789. (nullable)
  --four-digit-ssn: string # Search for parties whose SSN ends with a specified four digits. Note: When specified, a last name/entity name must also be specified. (nullable)
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-discharged-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-discharged-end-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/bankruptcyCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: ssnOrEin, var: ssn_or_ein}, {name: fourDigitSsn, var: four_digit_ssn}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: caseDischargedStartDate, var: case_discharged_start_date}, {name: caseDischargedEndDate, var: case_discharged_end_date}, {name: caseDismissedStartDate, var: case_dismissed_start_date}, {name: caseDismissedEndDate, var: case_dismissed_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, ssn_or_ein: $ssn_or_ein, four_digit_ssn: $four_digit_ssn, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, case_discharged_start_date: $case_discharged_start_date, case_discharged_end_date: $case_discharged_end_date, case_dismissed_start_date: $case_dismissed_start_date, case_dismissed_end_date: $case_dismissed_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/civilCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: CivilCourtsPacerCaseLocatorPartySearch
export def "civil-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/civilCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/criminalCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: CriminalCourtsPacerCaseLocatorPartySearch
export def "criminal-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/criminalCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/multiDistrictCourts
# Returns: record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int>
# operationId: MultiDistrictCourtsPacerCaseLocatorPartySearch
export def "multi-district-courts-pacer-case-locator-party-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (required, e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (required, e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpml-number: int # Master JPML Case Number.
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCaseLocator/partySearch/multiDistrictCourts"
    query: [{name: pacerUserId, var: pacer_user_id, required: true}, {name: pacerClientCode, var: pacer_client_code, required: true}, {name: caseNumber, var: case_number}, {name: jpmlNumber, var: jpml_number}, {name: pacerCaseId, var: pacer_case_id}, {name: lastName, var: last_name}, {name: firstName, var: first_name}, {name: middleName, var: middle_name}, {name: generation, var: generation}, {name: partyType, var: party_type}, {name: partyExactNameMatch, var: party_exact_name_match}, {name: partyRoleArray, var: party_role_array, style: multi}, {name: caseTitle, var: case_title}, {name: caseOffice, var: case_office}, {name: caseSequenceNumber, var: case_sequence_number}, {name: caseYear, var: case_year}, {name: caseTypeArray, var: case_type_array, style: multi}, {name: courtRegionIdArray, var: court_region_id_array, style: multi}, {name: caseYearFrom, var: case_year_from}, {name: caseYearTo, var: case_year_to}, {name: caseFiledStartDate, var: case_filed_start_date}, {name: caseFiledEndDate, var: case_filed_end_date}, {name: caseTerminatedStartDate, var: case_terminated_start_date}, {name: caseTerminatedEndDate, var: case_terminated_end_date}, {name: sortParameterQuery, var: sort_parameter_query}, {name: caseStatus, var: case_status}, {name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id, pacer_client_code: $pacer_client_code, case_number: $case_number, jpml_number: $jpml_number, pacer_case_id: $pacer_case_id, last_name: $last_name, first_name: $first_name, middle_name: $middle_name, generation: $generation, party_type: $party_type, party_exact_name_match: $party_exact_name_match, party_role_array: $party_role_array, case_title: $case_title, case_office: $case_office, case_sequence_number: $case_sequence_number, case_year: $case_year, case_type_array: $case_type_array, court_region_id_array: $court_region_id_array, case_year_from: $case_year_from, case_year_to: $case_year_to, case_filed_start_date: $case_filed_start_date, case_filed_end_date: $case_filed_end_date, case_terminated_start_date: $case_terminated_start_date, case_terminated_end_date: $case_terminated_end_date, sort_parameter_query: $sort_parameter_query, case_status: $case_status, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Pacer Credential List.
#
# GET /pacerCredential
# Returns: record<nextPageAPI: string, object: string, pacerCredentialArray: table<defaultPacerClientCode: string, object: string, pacerUserId: string>, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int>
# operationId: getPacerCredential
export def "get-pacer-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number of the PACER credentials to be retrieved. - Minimum: 1 (e.g. 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pacerCredential"
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Pacer Credential.
#
# PUT /pacerCredential
# Returns: record<message: string, object: string>
# operationId: addPacerCredential
export def "add-pacer-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-pacer-client-code: string # Pacer Client Code. (nullable, e.g. Test UniCourt API)
  pacer_user_id: string # Pacer User Id. (e.g. URKYwer3tyh5r56gq2)
  password: string # Password. (e.g. your password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/pacerCredential"
    body: {content_type: "application/json", kind: json, fields: [{name: defaultPacerClientCode, var: default_pacer_client_code}, {name: pacerUserId, var: pacer_user_id}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    default_pacer_client_code: $default_pacer_client_code, pacer_user_id: $pacer_user_id, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Pacer credential for a specific Pacer User Id.
#
# DELETE /pacerCredential/{pacerUserId}
# Returns: record<message: string, object: string>
# operationId: removePacerCredentialById
export def "remove-pacer-credential-by-id" [
  pacer_user_id: string
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
    path: "/pacerCredential/{pacerUserId}"
    path_params: [{name: pacerUserId, var: pacer_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Pacer Credential for a requested pacer User Id.
#
# GET /pacerCredential/{pacerUserId}
# Returns: record<defaultPacerClientCode: string, object: string, pacerUserId: string>
# operationId: getPacerCredentialById
export def "get-pacer-credential-by-id" [
  pacer_user_id: string
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
    path: "/pacerCredential/{pacerUserId}"
    path_params: [{name: pacerUserId, var: pacer_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pacer_user_id: $pacer_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets details for a requested Party ID.
#
# GET /party/{partyId}
# Returns: record<attorneyRepresentationType: record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyClassificationType: string, partyId: string, partyRole: record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, possibleNormPartyArray: table<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, bestMatch: bool, caseCountAnalyticsByNormPartyAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, confidenceScore: float, normPartyAPI: string, normPartyId: string, normPartyName: string, object: string, scoreConstituents: record>, sourcePartyRole: string>
# operationId: getPartyById
export def "get-party-by-id" [
  party_id: string
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
    path: "/party/{partyId}"
    path_params: [{name: partyId, var: party_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Associated Attorney details for a requested Party ID.
#
# GET /party/{partyId}/associatedAttorneys
# Returns: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int>
# operationId: getPartyAssociatedAttorneys
export def "get-party-associated-attorneys" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/party/{partyId}/associatedAttorneys"
    path_params: [{name: partyId, var: party_id}]
    query: [{name: pageNumber, var: page_number}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    party_id: $party_id, page_number: $page_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
