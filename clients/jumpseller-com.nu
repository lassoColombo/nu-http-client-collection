# Auto-generated client for Jumpseller API v1.0.0
# Source: https://api.apis.guru/v2/specs/jumpseller.com/1.0.0/openapi.json
# Auth: --token flag or $env.JUMPSELLER_API_TOKEN

const CLIENT = {
  base_url: "https://api.jumpseller.com/v1"
  token_env_var: "JUMPSELLER_API_TOKEN"
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

def base-url-completer [] { ["https://api.jumpseller.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["Abandoned" "Canceled" "Paid" "Pending Payment"] }
def fields-completer [] { ["barcode" "brand" "custom_fields" "custom_fields_selects" "description" "name" "option_name" "sku" "variants"] }
def status-completer-1 [] { ["available" "disabled" "not-available"] }
def plan-name-completer [] { ["plus" "premium" "pro"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-categories-json: "record<category: record<id: int, name: string, parent_id: int, permalink: string>>"
    post-categories-json: "record<category: record<id: int, name: string, parent_id: int, permalink: string>>"
    get-categories-count-json: "record<count: int>"
    delete-categories-id-json: "string"
    get-categories-id-json: "record<category: record<id: int, name: string, parent_id: int, permalink: string>>"
    put-categories-id-json: "record<category: record<id: int, name: string, parent_id: int, permalink: string>>"
    get-checkout-custom-fields-json: "table<checkout_custom_field: record<area: string, custom_field_select_options: list, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>"
    post-checkout-custom-fields-json: "record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>"
    delete-checkout-custom-fields-id-json: "string"
    get-checkout-custom-fields-id-json: "record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>"
    put-checkout-custom-fields-id-json: "record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>"
    get-countries-json: "table<code: string, name: string>"
    get-countries-country-code-json: "record<code: string, name: string>"
    get-countries-country-code-regions-json: "table<code: string, name: string>"
    get-countries-country-code-regions-region-code-json: "record<code: string, name: string>"
    get-custom-fields-json: "table<custom_field: record<id: int, label: string, type: string, values: list>>"
    post-custom-fields-json: "record<custom_field: record<id: int, label: string, type: string, values: list<string>>>"
    delete-custom-fields-id-json: "string"
    get-custom-fields-id-json: "record<custom_field: record<id: int, label: string, type: string, values: list<string>>>"
    put-custom-fields-id-json: "record<custom_field: record<id: int, label: string, type: string, values: list<string>>>"
    get-custom-fields-id-select-options-json: "table<custom_field_select_option: record<id: int, value: string>>"
    post-custom-fields-id-select-options-json: "record<custom_field_select_option: record<id: int, value: string>>"
    delete-custom-fields-id-select-options-custom-field-select-option-id-json: "string"
    get-custom-fields-id-select-options-custom-field-select-option-id-json: "record<custom_field_select_option: record<id: int, value: string>>"
    put-custom-fields-id-select-options-custom-field-select-option-id-json: "record<custom_field_select_option: record<id: int, value: string>>"
    get-customer-categories-json: "table<category: record<code: string, id: int, name: string>>"
    post-customer-categories-json: "record<category: record<code: string, id: int, name: string>>"
    delete-customer-categories-id-json: "string"
    get-customer-categories-id-json: "record<category: record<code: string, id: int, name: string>>"
    put-customer-categories-id-json: "record<category: record<code: string, id: int, name: string>>"
    delete-customer-categories-id-customers-json: "string"
    get-customer-categories-id-customers-json: "table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>"
    post-customer-categories-id-customers-json: "table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>"
    get-customers-json: "table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>"
    post-customers-json: "record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>"
    get-customers-count-json: "record<count: int>"
    get-customers-email-email-json: "record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>"
    delete-customers-id-json: "string"
    get-customers-id-json: "record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>"
    put-customers-id-json: "record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>"
    get-customers-id-fields: "table<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>"
    post-customers-id-fields: "record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>"
    delete-customers-id-fields-field-id: "string"
    get-customers-id-fields-field-id: "record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>"
    put-customers-id-fields-field-id: "record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>"
    get-fulfillments-json: "table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>"
    get-fulfillments-count-json: "record<count: int>"
    get-fulfillments-id-json: "record<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>"
    get-hooks-json: "table<hook: record<created_at: string, event: string, id: int, name: string, url: string>>"
    post-hooks-json: "record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>"
    delete-hooks-id-json: "string"
    get-hooks-id-json: "record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>"
    put-hooks-id-json: "record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>"
    get-jsapps-json: "record<apps: table<author: string, code: string, description: string, js: bool, name: string, page: string>>"
    post-jsapps-json: "record<element: string, template: string, url: string>"
    delete-jsapps-code-json: "string"
    get-jsapps-code-json: "record<element: string, template: string, url: string>"
    get-order-id-fulfillments-json: "table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>"
    get-orders-json: "table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    post-orders-json: "record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    get-orders-after-id-json: "record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    get-orders-count-json: "record<count: int>"
    get-orders-status-status-json: "table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    get-orders-id-json: "record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    put-orders-id-json: "record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>"
    get-orders-id-history-json: "table<order_history: record<created_at: string, id: int, message: string>>"
    post-orders-id-history-json: "record<order_history: record<created_at: string, id: int, message: string>>"
    get-pages-json: "table<page: record<body: string, categories: list, id: int, image: record, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record, title: string>>"
    post-pages-json: "record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>"
    get-pages-count-json: "record<count: int>"
    delete-pages-id-json: "string"
    get-pages-id-json: "record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>"
    put-pages-id-json: "record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>"
    get-partners-stores-json: "table<code: string, stats: record<best_sold: list, conversions: record, currency: string, daily_visits: list, from: string, new_vs_returning_customers: record, new_vs_returning_orders: record, orders: record, payment_methods: list, referrers: list, region_orders: record, search_frequencies_all: list, search_frequencies_without_results: list, shipping_methods: list, to: string, traffic_type: list, visits: int>>"
    get-payment-methods-json: "table<payment_method: record<id: int, name: string, type: string>>"
    get-payment-methods-id-json: "record<payment_method: record<id: int, name: string, type: string>>"
    get-products-json: "table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>"
    post-products-json: "record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>"
    get-products-after-id-json: "table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>"
    get-products-category-category-id-json: "table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>"
    get-products-category-category-id-count-json: "record<count: int>"
    get-products-count-json: "record<count: int>"
    get-products-search-json: "table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>"
    get-products-status-status-json: "table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>"
    get-products-status-status-count-json: "record<count: int>"
    delete-products-id-json: "string"
    get-products-id-json: "record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>"
    put-products-id-json: "record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>"
    get-products-id-attachments-json: "table<attachment: record<id: int, url: string>>"
    post-products-id-attachments-json: "record<attachment: record<id: int, url: string>>"
    get-products-id-attachments-count-json: "record<count: int>"
    delete-products-id-attachments-attachment-id-json: "string"
    get-products-id-attachments-attachment-id-json: "record<attachment: record<id: int, url: string>>"
    get-products-id-digital-products-json: "table<digital_product: record<expiration_seconds: int, id: int, url: string>>"
    post-products-id-digital-products-json: "record<digital_product: record<expiration_seconds: int, id: int, url: string>>"
    get-products-id-digital-products-count-json: "record<count: int>"
    delete-products-id-digital-products-digital-product-id-json: "string"
    get-products-id-digital-products-digital-product-id-json: "record<digital_product: record<expiration_seconds: int, id: int, url: string>>"
    get-products-id-fields-json: "table<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>>"
    post-products-id-fields-json: "record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>"
    get-products-id-fields-count-json: "record<count: int>"
    get-products-id-images-json: "table<image: record<id: int, position: int, url: string>>"
    post-products-id-images-json: "record<image: record<id: int, position: int, url: string>>"
    get-products-id-images-count-json: "record<count: int>"
    delete-products-id-images-image-id-json: "string"
    get-products-id-images-image-id-json: "record<image: record<id: int, position: int, url: string>>"
    get-products-id-options-json: "table<option: record<id: int, name: string, option_type: string, position: int, values: list>>"
    post-products-id-options-json: "record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>"
    get-products-id-options-count-json: "record<count: int>"
    delete-products-id-options-option-id-json: "string"
    get-products-id-options-option-id-json: "record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>"
    put-products-id-options-option-id-json: "record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>"
    get-products-id-options-option-id-values-json: "table<value: record<id: int, name: string, position: int, product_option: record, variants: list>>"
    post-products-id-options-option-id-values-json: "record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>"
    get-products-id-options-option-id-values-count-json: "record<count: int>"
    delete-products-id-options-option-id-values-value-id-json: "string"
    get-products-id-options-option-id-values-value-id-json: "record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>"
    put-products-id-options-option-id-values-value-id-json: "record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>"
    get-products-id-variants-json: "table<variant: record<id: int, image: record, options: list, price: float, sku: string, stock: int, stock_unlimited: bool>>"
    post-products-id-variants-json: "record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>"
    get-products-id-variants-count-json: "record<count: int>"
    get-products-id-variants-variant-id-json: "record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>"
    put-products-id-variants-variant-id-json: "record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>"
    delete-products-product-id-fields-field-id-json: "record<message: string>"
    put-products-product-id-fields-field-id-json: "record<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>>"
    get-promotions-json: "table<promotion: record<begins_at: string, categories: list, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list, products_x: list, quantity_x: int, status: string, times_used: int>>"
    post-promotions-json: "record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>"
    delete-promotions-id-json: "string"
    get-promotions-id-json: "record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>"
    put-promotions-id-json: "record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>"
    get-shipping-methods-json: "table<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list, state: string, type: string>>"
    post-shipping-methods-json: "record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>"
    delete-shipping-methods-id-json: "string"
    get-shipping-methods-id-json: "record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>"
    put-shipping-methods-id-json: "record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>"
    post-store-create-json: "record<store: record<code: string>>"
    get-store-info-json: "record<address: record<address: string, city: string, country: string, country_code: string, postal: string, region: string, region_code: string>, code: string, country: string, currency: string, email: string, hooks_token: string, logo: string, name: string, timezone: string, url: string, weight_unit: string>"
    get-store-languages-json: "table<code: string, name: string>"
    get-taxes-json: "table<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>"
    post-taxes-json: "record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>"
    get-taxes-id-json: "record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-categories-json" "post-categories-json" "get-categories-count-json" "delete-categories-id-json" "get-categories-id-json" "put-categories-id-json" "get-checkout-custom-fields-json" "post-checkout-custom-fields-json" "delete-checkout-custom-fields-id-json" "get-checkout-custom-fields-id-json" "put-checkout-custom-fields-id-json" "get-countries-json" "get-countries-country-code-json" "get-countries-country-code-regions-json" "get-countries-country-code-regions-region-code-json" "get-custom-fields-json" "post-custom-fields-json" "delete-custom-fields-id-json" "get-custom-fields-id-json" "put-custom-fields-id-json" "get-custom-fields-id-select-options-json" "post-custom-fields-id-select-options-json" "delete-custom-fields-id-select-options-custom-field-select-option-id-json" "get-custom-fields-id-select-options-custom-field-select-option-id-json" "put-custom-fields-id-select-options-custom-field-select-option-id-json" "get-customer-categories-json" "post-customer-categories-json" "delete-customer-categories-id-json" "get-customer-categories-id-json" "put-customer-categories-id-json" "delete-customer-categories-id-customers-json" "get-customer-categories-id-customers-json" "post-customer-categories-id-customers-json" "get-customers-json" "post-customers-json" "get-customers-count-json" "get-customers-email-email-json" "delete-customers-id-json" "get-customers-id-json" "put-customers-id-json" "get-customers-id-fields" "post-customers-id-fields" "delete-customers-id-fields-field-id" "get-customers-id-fields-field-id" "put-customers-id-fields-field-id" "get-fulfillments-json" "get-fulfillments-count-json" "get-fulfillments-id-json" "get-hooks-json" "post-hooks-json" "delete-hooks-id-json" "get-hooks-id-json" "put-hooks-id-json" "get-jsapps-json" "post-jsapps-json" "delete-jsapps-code-json" "get-jsapps-code-json" "get-order-id-fulfillments-json" "get-orders-json" "post-orders-json" "get-orders-after-id-json" "get-orders-count-json" "get-orders-status-status-json" "get-orders-id-json" "put-orders-id-json" "get-orders-id-history-json" "post-orders-id-history-json" "get-pages-json" "post-pages-json" "get-pages-count-json" "delete-pages-id-json" "get-pages-id-json" "put-pages-id-json" "get-partners-stores-json" "get-payment-methods-json" "get-payment-methods-id-json" "get-products-json" "post-products-json" "get-products-after-id-json" "get-products-category-category-id-json" "get-products-category-category-id-count-json" "get-products-count-json" "get-products-search-json" "get-products-status-status-json" "get-products-status-status-count-json" "delete-products-id-json" "get-products-id-json" "put-products-id-json" "get-products-id-attachments-json" "post-products-id-attachments-json" "get-products-id-attachments-count-json" "delete-products-id-attachments-attachment-id-json" "get-products-id-attachments-attachment-id-json" "get-products-id-digital-products-json" "post-products-id-digital-products-json" "get-products-id-digital-products-count-json" "delete-products-id-digital-products-digital-product-id-json" "get-products-id-digital-products-digital-product-id-json" "get-products-id-fields-json" "post-products-id-fields-json" "get-products-id-fields-count-json" "get-products-id-images-json" "post-products-id-images-json" "get-products-id-images-count-json" "delete-products-id-images-image-id-json" "get-products-id-images-image-id-json" "get-products-id-options-json" "post-products-id-options-json" "get-products-id-options-count-json" "delete-products-id-options-option-id-json" "get-products-id-options-option-id-json" "put-products-id-options-option-id-json" "get-products-id-options-option-id-values-json" "post-products-id-options-option-id-values-json" "get-products-id-options-option-id-values-count-json" "delete-products-id-options-option-id-values-value-id-json" "get-products-id-options-option-id-values-value-id-json" "put-products-id-options-option-id-values-value-id-json" "get-products-id-variants-json" "post-products-id-variants-json" "get-products-id-variants-count-json" "get-products-id-variants-variant-id-json" "put-products-id-variants-variant-id-json" "delete-products-product-id-fields-field-id-json" "put-products-product-id-fields-field-id-json" "get-promotions-json" "post-promotions-json" "delete-promotions-id-json" "get-promotions-id-json" "put-promotions-id-json" "get-shipping-methods-json" "post-shipping-methods-json" "delete-shipping-methods-id-json" "get-shipping-methods-id-json" "put-shipping-methods-id-json" "get-store-check-status-json" "post-store-create-json" "get-store-info-json" "get-store-languages-json" "get-taxes-json" "post-taxes-json" "get-taxes-id-json" "commands"] | sort) } | get name | first)
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

# Retrieve all Categories.
#
# GET /categories.json
# Returns: record<category: record<id: int, name: string, parent_id: int, permalink: string>>
export def "get-categories-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Category.
#
# POST /categories.json
# Returns: record<category: record<id: int, name: string, parent_id: int, permalink: string>>
export def "post-categories-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --category: record # shape: {name?: string, parent_id?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Categories.
#
# GET /categories/count.json
# Returns: record<count: int>
export def "get-categories-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Category.
#
# DELETE /categories/{id}.json
# Returns: string
export def "delete-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Category.
#
# GET /categories/{id}.json
# Returns: record<category: record<id: int, name: string, parent_id: int, permalink: string>>
export def "get-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Category.
#
# PUT /categories/{id}.json
# Returns: record<category: record<id: int, name: string, parent_id: int, permalink: string>>
export def "put-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --category: record # shape: {name?: string, parent_id?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Checkout Custom Fields.
#
# GET /checkout_custom_fields.json
# Returns: table<checkout_custom_field: record<area: string, custom_field_select_options: list, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>
export def "get-checkout-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/checkout_custom_fields.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CheckoutCustomField.
#
# POST /checkout_custom_fields.json
# Returns: record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>
export def "post-checkout-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/checkout_custom_fields.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkout_custom_field, var: checkout_custom_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, checkout_custom_field: $checkout_custom_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing CheckoutCustomField.
#
# DELETE /checkout_custom_fields/{id}.json
# Returns: string
export def "delete-checkout-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/checkout_custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single CheckoutCustomField.
#
# GET /checkout_custom_fields/{id}.json
# Returns: record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>
export def "get-checkout-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checkout_custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a CheckoutCustomField.
#
# PUT /checkout_custom_fields/{id}.json
# Returns: record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>>
export def "put-checkout-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/checkout_custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkout_custom_field, var: checkout_custom_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, checkout_custom_field: $checkout_custom_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Countries.
#
# GET /countries.json
# Returns: table<code: string, name: string>
export def "get-countries-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/countries.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Country information.
#
# GET /countries/{country_code}.json
# Returns: record<code: string, name: string>
export def "get-countries-country-code-json" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/countries/{country_code}.json"
    path_params: [{name: country_code, var: country_code}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_code: $country_code, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Regions from a single Country.
#
# GET /countries/{country_code}/regions.json
# Returns: table<code: string, name: string>
export def "get-countries-country-code-regions-json" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/countries/{country_code}/regions.json"
    path_params: [{name: country_code, var: country_code}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_code: $country_code, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Region information object.
#
# GET /countries/{country_code}/regions/{region_code}.json
# Returns: record<code: string, name: string>
export def "get-countries-country-code-regions-region-code-json" [
  country_code: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/countries/{country_code}/regions/{region_code}.json"
    path_params: [{name: country_code, var: country_code}, {name: region_code, var: region_code}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country_code: $country_code, region_code: $region_code, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields.json
# Returns: table<custom_field: record<id: int, label: string, type: string, values: list>>
export def "get-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/custom_fields.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Custom Field.
#
# POST /custom_fields.json
# Returns: record<custom_field: record<id: int, label: string, type: string, values: list<string>>>
export def "post-custom-fields-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_fields.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_field, var: custom_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, custom_field: $custom_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing CustomField.
#
# DELETE /custom_fields/{id}.json
# Returns: string
export def "delete-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single CustomField.
#
# GET /custom_fields/{id}.json
# Returns: record<custom_field: record<id: int, label: string, type: string, values: list<string>>>
export def "get-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a CustomField.
#
# PUT /custom_fields/{id}.json
# Returns: record<custom_field: record<id: int, label: string, type: string, values: list<string>>>
export def "put-custom-fields-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom_fields/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_field, var: custom_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, custom_field: $custom_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields/{id}/select_options.json
# Returns: table<custom_field_select_option: record<id: int, value: string>>
export def "get-custom-fields-id-select-options-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/custom_fields/{id}/select_options.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Custom Field Select Option.
#
# POST /custom_fields/{id}/select_options.json
# Returns: record<custom_field_select_option: record<id: int, value: string>>
export def "post-custom-fields-id-select-options-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_fields/{id}/select_options.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_field_select_option, var: custom_field_select_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, custom_field_select_option: $custom_field_select_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing CustomFieldSelectOption.
#
# DELETE /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
# Returns: string
export def "delete-custom-fields-id-select-options-custom-field-select-option-id-json" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json"
    path_params: [{name: id, var: id}, {name: custom_field_select_option_id, var: custom_field_select_option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, custom_field_select_option_id: $custom_field_select_option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single SelectOption from a CustomField.
#
# GET /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
# Returns: record<custom_field_select_option: record<id: int, value: string>>
export def "get-custom-fields-id-select-options-custom-field-select-option-id-json" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json"
    path_params: [{name: id, var: id}, {name: custom_field_select_option_id, var: custom_field_select_option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, custom_field_select_option_id: $custom_field_select_option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SelectOption from a CustomField.
#
# PUT /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
# Returns: record<custom_field_select_option: record<id: int, value: string>>
export def "put-custom-fields-id-select-options-custom-field-select-option-id-json" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json"
    path_params: [{name: id, var: id}, {name: custom_field_select_option_id, var: custom_field_select_option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_field_select_option, var: custom_field_select_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, custom_field_select_option_id: $custom_field_select_option_id, login: $login, authtoken: $authtoken, custom_field_select_option: $custom_field_select_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Customer Categories.
#
# GET /customer_categories.json
# Returns: table<category: record<code: string, id: int, name: string>>
export def "get-customer-categories-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customer_categories.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CustomerCategory.
#
# POST /customer_categories.json
# Returns: record<category: record<code: string, id: int, name: string>>
export def "post-customer-categories-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --category: record # shape: {name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customer_categories.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing CustomerCategory.
#
# DELETE /customer_categories/{id}.json
# Returns: string
export def "delete-customer-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customer_categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single CustomerCategory.
#
# GET /customer_categories/{id}.json
# Returns: record<category: record<code: string, id: int, name: string>>
export def "get-customer-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customer_categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a CustomerCategory.
#
# PUT /customer_categories/{id}.json
# Returns: record<category: record<code: string, id: int, name: string>>
export def "put-customer-categories-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --category: record # shape: {name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customer_categories/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: category, var: category}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Customers from an existing CustomerCategory.
#
# DELETE /customer_categories/{id}/customers.json
# Returns: string
export def "delete-customer-categories-id-customers-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> any {
  $in | http-request {
    method: delete
    path: "/customer_categories/{id}/customers.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customers, var: customers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, customers: $customers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the customers in a CustomerCategory.
#
# GET /customer_categories/{id}/customers.json
# Returns: table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>
export def "get-customer-categories-id-customers-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customer_categories/{id}/customers.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds Customers to a CustomerCategory.
#
# POST /customer_categories/{id}/customers.json
# Returns: table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>
export def "post-customer-categories-id-customers-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customer_categories/{id}/customers.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customers, var: customers}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, customers: $customers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Customers.
#
# GET /customers.json
# Returns: table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>>
export def "get-customers-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Customer.
#
# POST /customers.json
# Returns: record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>
export def "post-customers-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer, var: customer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, customer: $customer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Customers.
#
# GET /customers/count.json
# Returns: record<count: int>
export def "get-customers-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Customer by email.
#
# GET /customers/email/{email}.json
# Returns: record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>
export def "get-customers-email-email-json" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/email/{email}.json"
    path_params: [{name: email, var: email}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Customer.
#
# DELETE /customers/{id}.json
# Returns: string
export def "delete-customers-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Customer by id.
#
# GET /customers/{id}.json
# Returns: record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>
export def "get-customers-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a new Customer.
#
# PUT /customers/{id}.json
# Returns: record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>>
export def "put-customers-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer, var: customer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, customer: $customer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Customer Additional Field of a Customer.
#
# GET /customers/{id}/fields
# Returns: table<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>
export def "get-customers-id-fields" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/fields"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds Customer Additional Fields to a Customer.
#
# POST /customers/{id}/fields
# Returns: record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>
export def "post-customers-id-fields" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/customers/{id}/fields"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_additional_field, var: customer_additional_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, customer_additional_field: $customer_additional_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Customer Additional Field.
#
# DELETE /customers/{id}/fields/{field_id}
# Returns: string
export def "delete-customers-id-fields-field-id" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/customers/{id}/fields/{field_id}"
    path_params: [{name: id, var: id}, {name: field_id, var: field_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, field_id: $field_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Customer Additional Field.
#
# GET /customers/{id}/fields/{field_id}
# Returns: record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>
export def "get-customers-id-fields-field-id" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/customers/{id}/fields/{field_id}"
    path_params: [{name: id, var: id}, {name: field_id, var: field_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, field_id: $field_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Customer Additional Field.
#
# PUT /customers/{id}/fields/{field_id}
# Returns: record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>>
export def "put-customers-id-fields-field-id" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/customers/{id}/fields/{field_id}"
    path_params: [{name: id, var: id}, {name: field_id, var: field_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: customer_additional_field, var: customer_additional_field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, field_id: $field_id, login: $login, authtoken: $authtoken, customer_additional_field: $customer_additional_field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Fulfillments.
#
# GET /fulfillments.json
# Returns: table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>
export def "get-fulfillments-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/fulfillments.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Fulfillments.
#
# GET /fulfillments/count.json
# Returns: record<count: int>
export def "get-fulfillments-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fulfillments/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Fulfillment.
#
# GET /fulfillments/{id}.json
# Returns: record<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>
export def "get-fulfillments-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/fulfillments/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Hooks.
#
# GET /hooks.json
# Returns: table<hook: record<created_at: string, event: string, id: int, name: string, url: string>>
export def "get-hooks-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/hooks.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Hook.
#
# POST /hooks.json
# Returns: record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>
export def "post-hooks-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --hook: record # shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/hooks.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hook, var: hook}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, hook: $hook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Hook.
#
# DELETE /hooks/{id}.json
# Returns: string
export def "delete-hooks-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/hooks/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Hook.
#
# GET /hooks/{id}.json
# Returns: record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>
export def "get-hooks-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/hooks/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Hook.
#
# PUT /hooks/{id}.json
# Returns: record<hook: record<created_at: string, event: string, id: int, name: string, url: string>>
export def "put-hooks-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --hook: record # shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/hooks/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hook, var: hook}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, hook: $hook
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all the Store's JSApps.
#
# GET /jsapps.json
# Returns: record<apps: table<author: string, code: string, description: string, js: bool, name: string, page: string>>
export def "get-jsapps-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jsapps.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Store JSApp.
#
# POST /jsapps.json
# Returns: record<element: string, template: string, url: string>
export def "post-jsapps-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --app: record # shape: {element?: string, template?: string, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/jsapps.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: app, var: app}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, app: $app
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing JSApp.
#
# DELETE /jsapps/{code}.json
# Returns: string
export def "delete-jsapps-code-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/jsapps/{code}.json"
    path_params: [{name: code, var: code}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a JSApp.
#
# GET /jsapps/{code}.json
# Returns: record<element: string, template: string, url: string>
export def "get-jsapps-code-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jsapps/{code}.json"
    path_params: [{name: code, var: code}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the Fulfillments associated with the Order.
#
# GET /order/{id}/fulfillments.json
# Returns: table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>>
export def "get-order-id-fulfillments-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/order/{id}/fulfillments.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Orders.
#
# GET /orders.json
# Returns: table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "get-orders-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Order.
#
# POST /orders.json
# Returns: record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "post-orders-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --order: any # shape: {customer?: record, products?: list, shipping_method_id?: int, shipping_method_name?: string, shipping_price?: float, status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve orders filtered by Order Id.
#
# GET /orders/after/{id}.json
# Returns: record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "get-orders-after-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/after/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Orders.
#
# GET /orders/count.json
# Returns: record<count: int>
export def "get-orders-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve orders filtered by status.
#
# GET /orders/status/{status}.json
# Returns: table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "get-orders-status-status-json" [
  status: string@status-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders/status/{status}.json"
    path_params: [{name: status, var: status}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Order.
#
# GET /orders/{id}.json
# Returns: record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "get-orders-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Order.
#
# PUT /orders/{id}.json
# Returns: record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>>
export def "put-orders-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --order: any # shape: {additional_fields?: list, additional_information?: string, shipment_status?: "requested"|"in_transit"|"delivered"|"failed"|"pickup_available", status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid", tracking_company?: string, tracking_number?: string, tracking_url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/orders/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Order History.
#
# GET /orders/{id}/history.json
# Returns: table<order_history: record<created_at: string, id: int, message: string>>
export def "get-orders-id-history-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/orders/{id}/history.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Order History Entry.
#
# POST /orders/{id}/history.json
# Returns: record<order_history: record<created_at: string, id: int, message: string>>
export def "post-orders-id-history-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --order-history: record # shape: {message?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders/{id}/history.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: order_history, var: order_history}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, order_history: $order_history
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Pages.
#
# GET /pages.json
# Returns: table<page: record<body: string, categories: list, id: int, image: record, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record, title: string>>
export def "get-pages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/pages.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Page.
#
# POST /pages.json
# Returns: record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>
export def "post-pages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --page: record # shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/pages.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: page, var: page}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Pages.
#
# GET /pages/count.json
# Returns: record<count: int>
export def "get-pages-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pages/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Page.
#
# DELETE /pages/{id}.json
# Returns: string
export def "delete-pages-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/pages/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Page by id.
#
# GET /pages/{id}.json
# Returns: record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>
export def "get-pages-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pages/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Page.
#
# PUT /pages/{id}.json
# Returns: record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>>
export def "put-pages-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --page: record # shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/pages/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: page, var: page}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve statistics.
#
# GET /partners/stores.json
# Returns: table<code: string, stats: record<best_sold: list, conversions: record, currency: string, daily_visits: list, from: string, new_vs_returning_customers: record, new_vs_returning_orders: record, orders: record, payment_methods: list, referrers: list, region_orders: record, search_frequencies_all: list, search_frequencies_without_results: list, shipping_methods: list, to: string, traffic_type: list, visits: int>>
export def "get-partners-stores-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (required, format: string)
  --auth-token: string # Partner authentication token. (required, format: string)
  --page: int # List page (format: integer, default: 1)
  --from: string # Statistics start date. Should be in format 'Y-m-d'. (required, format: string)
  --to: string # Statistics end date. Should be in format 'Y-m-d'. (required, format: sting)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/partners/stores.json"
    query: [{name: partner_code, var: partner_code, required: true}, {name: auth_token, var: auth_token, required: true}, {name: page, var: page}, {name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partner_code: $partner_code, auth_token: $auth_token, page: $page, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Store's Payment Methods.
#
# GET /payment_methods.json
# Returns: table<payment_method: record<id: int, name: string, type: string>>
export def "get-payment-methods-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/payment_methods.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Payment Method.
#
# GET /payment_methods/{id}.json
# Returns: record<payment_method: record<id: int, name: string, type: string>>
export def "get-payment-methods-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/payment_methods/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Products.
#
# GET /products.json
# Returns: table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>
export def "get-products-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product.
#
# POST /products.json
# Returns: record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>
export def "post-products-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
  --product: record # shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    body: {content_type: "application/json", kind: json, fields: [{name: product, var: product}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, locale: $locale, product: $product
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves Products after the given id.
#
# GET /products/after/{id}.json
# Returns: table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>
export def "get-products-after-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/after/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Products filtered by category.
#
# GET /products/category/{category_id}.json
# Returns: table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>
export def "get-products-category-category-id-json" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/category/{category_id}.json"
    path_params: [{name: category_id, var: category_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count Products filtered by category.
#
# GET /products/category/{category_id}/count.json
# Returns: record<count: int>
export def "get-products-category-category-id-count-json" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/category/{category_id}/count.json"
    path_params: [{name: category_id, var: category_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Products.
#
# GET /products/count.json
# Returns: record<count: int>
export def "get-products-count-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/count.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Product List from a query.
#
# GET /products/search.json
# Returns: table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>
export def "get-products-search-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
  --query: string # Text to query for the Product (required, format: string)
  --fields: string@fields-completer # Comma separated values of the fields to query for the Product (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/search.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}, {name: query, var: query, required: true}, {name: fields, var: fields}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, locale: $locale, query: $query, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Products filtered by status.
#
# GET /products/status/{status}.json
# Returns: table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>>
export def "get-products-status-status-json" [
  status: string@status-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/status/{status}.json"
    path_params: [{name: status, var: status}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count Products filtered by status.
#
# GET /products/status/{status}/count.json
# Returns: record<count: int>
export def "get-products-status-status-count-json" [
  status: string@status-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/status/{status}/count.json"
    path_params: [{name: status, var: status}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Product.
#
# DELETE /products/{id}.json
# Returns: string
export def "delete-products-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product.
#
# GET /products/{id}.json
# Returns: record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>
export def "get-products-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Product.
#
# PUT /products/{id}.json
# Returns: record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>
export def "put-products-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --locale: string # Locale code of the translation (format: string)
  --product: record # shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/products/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: locale, var: locale}]
    body: {content_type: "application/json", kind: json, fields: [{name: product, var: product}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, locale: $locale, product: $product
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Attachments.
#
# GET /products/{id}/attachments.json
# Returns: table<attachment: record<id: int, url: string>>
export def "get-products-id-attachments-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/attachments.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product Attachment.
#
# POST /products/{id}/attachments.json
# Returns: record<attachment: record<id: int, url: string>>
export def "post-products-id-attachments-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --attachment: record # shape: {filename?: string, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/attachments.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attachment, var: attachment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, attachment: $attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Attachments.
#
# GET /products/{id}/attachments/count.json
# Returns: record<count: int>
export def "get-products-id-attachments-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/attachments/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Product Attachment.
#
# DELETE /products/{id}/attachments/{attachment_id}.json
# Returns: string
export def "delete-products-id-attachments-attachment-id-json" [
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}/attachments/{attachment_id}.json"
    path_params: [{name: id, var: id}, {name: attachment_id, var: attachment_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, attachment_id: $attachment_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product Attachment.
#
# GET /products/{id}/attachments/{attachment_id}.json
# Returns: record<attachment: record<id: int, url: string>>
export def "get-products-id-attachments-attachment-id-json" [
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/attachments/{attachment_id}.json"
    path_params: [{name: id, var: id}, {name: attachment_id, var: attachment_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, attachment_id: $attachment_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product DigitalProducts.
#
# GET /products/{id}/digital_products.json
# Returns: table<digital_product: record<expiration_seconds: int, id: int, url: string>>
export def "get-products-id-digital-products-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/digital_products.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product DigitalProduct.
#
# POST /products/{id}/digital_products.json
# Returns: record<digital_product: record<expiration_seconds: int, id: int, url: string>>
export def "post-products-id-digital-products-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --digital-product: record # shape: {filename?: string, url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/digital_products.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: digital_product, var: digital_product}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, digital_product: $digital_product
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product DigitalProducts.
#
# GET /products/{id}/digital_products/count.json
# Returns: record<count: int>
export def "get-products-id-digital-products-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/digital_products/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Product DigitalProduct.
#
# DELETE /products/{id}/digital_products/{digital_product_id}.json
# Returns: string
export def "delete-products-id-digital-products-digital-product-id-json" [
  id: int
  digital_product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}/digital_products/{digital_product_id}.json"
    path_params: [{name: id, var: id}, {name: digital_product_id, var: digital_product_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, digital_product_id: $digital_product_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product DigitalProduct.
#
# GET /products/{id}/digital_products/{digital_product_id}.json
# Returns: record<digital_product: record<expiration_seconds: int, id: int, url: string>>
export def "get-products-id-digital-products-digital-product-id-json" [
  id: int
  digital_product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/digital_products/{digital_product_id}.json"
    path_params: [{name: id, var: id}, {name: digital_product_id, var: digital_product_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, digital_product_id: $digital_product_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Custom Fields
#
# GET /products/{id}/fields.json
# Returns: table<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>>
export def "get-products-id-fields-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/fields.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an existing Custom Field to a Product.
#
# POST /products/{id}/fields.json
# Returns: record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>>
export def "post-products-id-fields-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --field: record # shape: {id?: int, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/fields.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: field, var: field}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, field: $field
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Custom Fields.
#
# GET /products/{id}/fields/count.json
# Returns: record<count: int>
export def "get-products-id-fields-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/fields/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Images.
#
# GET /products/{id}/images.json
# Returns: table<image: record<id: int, position: int, url: string>>
export def "get-products-id-images-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/images.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product Image.
#
# POST /products/{id}/images.json
# Returns: record<image: record<id: int, position: int, url: string>>
export def "post-products-id-images-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --image: record # shape: {url?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/images.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Images.
#
# GET /products/{id}/images/count.json
# Returns: record<count: int>
export def "get-products-id-images-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/images/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Product Image.
#
# DELETE /products/{id}/images/{image_id}.json
# Returns: string
export def "delete-products-id-images-image-id-json" [
  id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}/images/{image_id}.json"
    path_params: [{name: id, var: id}, {name: image_id, var: image_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, image_id: $image_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product Image.
#
# GET /products/{id}/images/{image_id}.json
# Returns: record<image: record<id: int, position: int, url: string>>
export def "get-products-id-images-image-id-json" [
  id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/images/{image_id}.json"
    path_params: [{name: id, var: id}, {name: image_id, var: image_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, image_id: $image_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Options.
#
# GET /products/{id}/options.json
# Returns: table<option: record<id: int, name: string, option_type: string, position: int, values: list>>
export def "get-products-id-options-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product Option.
#
# POST /products/{id}/options.json
# Returns: record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>
export def "post-products-id-options-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/options.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: option, var: option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, option: $option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Options.
#
# GET /products/{id}/options/count.json
# Returns: record<count: int>
export def "get-products-id-options-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Product Option.
#
# DELETE /products/{id}/options/{option_id}.json
# Returns: string
export def "delete-products-id-options-option-id-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}/options/{option_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product Option.
#
# GET /products/{id}/options/{option_id}.json
# Returns: record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>
export def "get-products-id-options-option-id-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options/{option_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Product Option.
#
# PUT /products/{id}/options/{option_id}.json
# Returns: record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>>
export def "put-products-id-options-option-id-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/products/{id}/options/{option_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: option, var: option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken, option: $option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values.json
# Returns: table<value: record<id: int, name: string, position: int, product_option: record, variants: list>>
export def "get-products-id-options-option-id-values-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options/{option_id}/values.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product Option Value.
#
# POST /products/{id}/options/{option_id}/values.json
# Returns: record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>
export def "post-products-id-options-option-id-values-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/options/{option_id}/values.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values/count.json
# Returns: record<count: int>
export def "get-products-id-options-option-id-values-count-json" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options/{option_id}/values/count.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Product Option Value.
#
# DELETE /products/{id}/options/{option_id}/values/{value_id}.json
# Returns: string
export def "delete-products-id-options-option-id-values-value-id-json" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/products/{id}/options/{option_id}/values/{value_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}, {name: value_id, var: value_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, value_id: $value_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product Option Value.
#
# GET /products/{id}/options/{option_id}/values/{value_id}.json
# Returns: record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>
export def "get-products-id-options-option-id-values-value-id-json" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/options/{option_id}/values/{value_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}, {name: value_id, var: value_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, value_id: $value_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Product Option Value.
#
# PUT /products/{id}/options/{option_id}/values/{value_id}.json
# Returns: record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>>
export def "put-products-id-options-option-id-values-value-id-json" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/products/{id}/options/{option_id}/values/{value_id}.json"
    path_params: [{name: id, var: id}, {name: option_id, var: option_id}, {name: value_id, var: value_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, option_id: $option_id, value_id: $value_id, login: $login, authtoken: $authtoken, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Product Variants.
#
# GET /products/{id}/variants.json
# Returns: table<variant: record<id: int, image: record, options: list, price: float, sku: string, stock: int, stock_unlimited: bool>>
export def "get-products-id-variants-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/variants.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Product Variant.
#
# POST /products/{id}/variants.json
# Returns: record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>
export def "post-products-id-variants-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/products/{id}/variants.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: variant, var: variant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, variant: $variant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Count all Product Variants.
#
# GET /products/{id}/variants/count.json
# Returns: record<count: int>
export def "get-products-id-variants-count-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/variants/count.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Product Variant.
#
# GET /products/{id}/variants/{variant_id}.json
# Returns: record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>
export def "get-products-id-variants-variant-id-json" [
  id: int
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/products/{id}/variants/{variant_id}.json"
    path_params: [{name: id, var: id}, {name: variant_id, var: variant_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, variant_id: $variant_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify an existing Product Variant.
#
# PUT /products/{id}/variants/{variant_id}.json
# Returns: record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>>
export def "put-products-id-variants-variant-id-json" [
  id: int
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/products/{id}/variants/{variant_id}.json"
    path_params: [{name: id, var: id}, {name: variant_id, var: variant_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: variant, var: variant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, variant_id: $variant_id, login: $login, authtoken: $authtoken, variant: $variant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete value of Product Custom Field
#
# DELETE /products/{product_id}/fields/{field_id}.json
# Returns: record<message: string>
export def "delete-products-product-id-fields-field-id-json" [
  product_id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/products/{product_id}/fields/{field_id}.json"
    path_params: [{name: product_id, var: product_id}, {name: field_id, var: field_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    product_id: $product_id, field_id: $field_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update value of Product Custom Field
#
# PUT /products/{product_id}/fields/{field_id}.json
# Returns: record<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>>
export def "put-products-product-id-fields-field-id-json" [
  product_id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/products/{product_id}/fields/{field_id}.json"
    path_params: [{name: product_id, var: product_id}, {name: field_id, var: field_id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    product_id: $product_id, field_id: $field_id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Promotions.
#
# GET /promotions.json
# Returns: table<promotion: record<begins_at: string, categories: list, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list, products_x: list, quantity_x: int, status: string, times_used: int>>
export def "get-promotions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --limit: int # Promotions' list restriction (default: 50 | max: 200). (format: integer)
  --page: int # Promotions' list page (default: 1). (format: integer)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/promotions.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}, {name: limit, var: limit}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, limit: $limit, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Promotion.
#
# POST /promotions.json
# Returns: record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>
export def "post-promotions-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --promotion: record # shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/promotions.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: promotion, var: promotion}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, promotion: $promotion
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Promotion.
#
# DELETE /promotions/{id}.json
# Returns: string
export def "delete-promotions-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/promotions/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Promotion.
#
# GET /promotions/{id}.json
# Returns: record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>
export def "get-promotions-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/promotions/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Promotion.
#
# PUT /promotions/{id}.json
# Returns: record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>>
export def "put-promotions-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --promotion: record # shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/promotions/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: promotion, var: promotion}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, promotion: $promotion
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Store's Shipping Methods.
#
# GET /shipping_methods.json
# Returns: table<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list, state: string, type: string>>
export def "get-shipping-methods-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/shipping_methods.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Shipping Method.
#
# POST /shipping_methods.json
# Returns: record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>
export def "post-shipping-methods-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --shipping-method: record # shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shipping_methods.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shipping_method, var: shipping_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, shipping_method: $shipping_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing Shipping Method.
#
# DELETE /shipping_methods/{id}.json
# Returns: string
export def "delete-shipping-methods-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> any {
  http-request {
    method: delete
    path: "/shipping_methods/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Shipping Method.
#
# GET /shipping_methods/{id}.json
# Returns: record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>
export def "get-shipping-methods-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shipping_methods/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Shipping Method.
#
# PUT /shipping_methods/{id}.json
# Returns: record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>>
export def "put-shipping-methods-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --shipping-method: record # shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/shipping_methods/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: shipping_method, var: shipping_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken, shipping_method: $shipping_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrive store creation status.
#
# GET /store/check_status.json
export def "get-store-check-status-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (required, format: string)
  --auth-token: string # Partner authentication token. (required, format: string)
  --store-code: string # Store Code (required, format: string)
  --locale: string # ISO 3166-2 code of the language used in the response messages. (format: string, default: en)
]: nothing -> any {
  http-request {
    method: get
    path: "/store/check_status.json"
    query: [{name: partner_code, var: partner_code, required: true}, {name: auth_token, var: auth_token, required: true}, {name: store_code, var: store_code, required: true}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partner_code: $partner_code, auth_token: $auth_token, store_code: $store_code, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Partnered Store
#
# POST /store/create.json
# Returns: record<store: record<code: string>>
export def "post-store-create-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (required, format: string)
  --auth-token: string # Partner authentication token. (required, format: string)
  --aff: string # Partner code.
  --email: string # New Store administrator email. (format: email)
  --locale: string # ISO3166-2 code for the store langauge. (default: en)
  --password: string # New Store administrator password. (format: string)
  --plan-name: string@plan-name-completer # New Store plan name. (default: pro)
  --reject-duplicates: oneof<nothing, bool> # Indicates whether the request should fail if the Store name provided is already in use. (default: false)
  --store-name: string # New Store name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/store/create.json"
    query: [{name: partner_code, var: partner_code, required: true}, {name: auth_token, var: auth_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aff, var: aff}, {name: email, var: email}, {name: locale, var: locale}, {name: password, var: password}, {name: plan_name, var: plan_name}, {name: reject_duplicates, var: reject_duplicates}, {name: store_name, var: store_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    partner_code: $partner_code, auth_token: $auth_token, aff: $aff, email: $email, locale: $locale, password: $password, plan_name: $plan_name, reject_duplicates: $reject_duplicates, store_name: $store_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Store Information.
#
# GET /store/info.json
# Returns: record<address: record<address: string, city: string, country: string, country_code: string, postal: string, region: string, region_code: string>, code: string, country: string, currency: string, email: string, hooks_token: string, logo: string, name: string, timezone: string, url: string, weight_unit: string>
export def "get-store-info-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/store/info.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Store Languages.
#
# GET /store/languages.json
# Returns: table<code: string, name: string>
export def "get-store-languages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/store/languages.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Taxes.
#
# GET /taxes.json
# Returns: table<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>
export def "get-taxes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/taxes.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Tax.
#
# POST /taxes.json
# Returns: record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>
export def "post-taxes-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
  --tax: record # shape: {category_id?: int, country?: string, fixed?: bool, name?: string, region?: string, shipping?: bool, tax?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/taxes.json"
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tax, var: tax}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login, authtoken: $authtoken, tax: $tax
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single Tax information.
#
# GET /taxes/{id}.json
# Returns: record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>>
export def "get-taxes-id-json" [
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
  --login: string # API OAuth login. (required, format: string)
  --authtoken: string # API OAuth token. (required, format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/taxes/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: login, var: login, required: true}, {name: authtoken, var: authtoken, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, login: $login, authtoken: $authtoken
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
