# Auto-generated client for Increase API v0.0.1
# Source: https://api.apis.guru/v2/specs/increase.com/0.0.1/openapi.json
# Auth: --token flag or $env.INCREASE_API_TOKEN

const CLIENT = {
  base_url: "https://api.increase.com"
  token_env_var: "INCREASE_API_TOKEN"
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

def base-url-completer [] { ["https://api.increase.com" "https://sandbox.increase.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["active" "canceled" "disabled"] }
def status-completer-1 [] { ["closed" "open"] }
def credit-debit-indicator-completer [] { ["credit" "debit"] }
def standard-entry-class-code-completer [] { ["corporate_credit_or_debit" "internet_initiated" "prearranged_payments_and_deposit"] }
def funding-completer [] { ["checking" "savings"] }
def relationship-completer [] { ["affiliated" "informational" "unaffiliated"] }
def structure-completer [] { ["corporation" "joint" "natural_person" "trust"] }
def selected-event-category-completer [] { ["account.created" "account.updated" "account_number.created" "account_number.updated" "account_statement.created" "account_transfer.created" "account_transfer.updated" "ach_prenotification.created" "ach_prenotification.updated" "ach_transfer.created" "ach_transfer.updated" "card.created" "card.updated" "card_dispute.created" "card_dispute.updated" "check_deposit.created" "check_deposit.updated" "check_transfer.created" "check_transfer.updated" "declined_transaction.created" "digital_wallet_token.created" "digital_wallet_token.updated" "document.created" "entity.created" "entity.updated" "external_account.created" "file.created" "group.heartbeat" "group.updated" "inbound_ach_transfer_return.created" "inbound_ach_transfer_return.updated" "inbound_wire_drawdown_request.created" "oauth_connection.created" "oauth_connection.deactivated" "pending_transaction.created" "pending_transaction.updated" "real_time_decision.card_authorization_requested" "real_time_decision.digital_wallet_authentication_requested" "real_time_decision.digital_wallet_token_requested" "real_time_payments_request_for_payment.created" "real_time_payments_request_for_payment.updated" "real_time_payments_transfer.created" "real_time_payments_transfer.updated" "transaction.created" "wire_drawdown_request.created" "wire_drawdown_request.updated" "wire_transfer.created" "wire_transfer.updated"] }
def status-completer-2 [] { ["active" "deleted" "disabled"] }
def funding-completer-1 [] { ["checking" "other" "savings"] }
def status-completer-3 [] { ["active" "archived"] }
def purpose-completer [] { ["check_image_back" "check_image_front" "digital_wallet_app_icon" "digital_wallet_artwork" "entity_supplemental_document" "form_ss_4" "identity_document" "other" "trust_formation_document"] }
def reason-completer [] { ["authorization_revoked_by_customer" "beneficiary_or_account_holder_deceased" "corporate_customer_advised_not_authorized" "credit_entry_refused_by_receiver" "customer_advised_unauthorized_improper_ineligible_or_incomplete" "duplicate_entry" "payment_stopped" "representative_payee_deceased_or_unable_to_continue_in_that_capacity"] }
def interval-completer [] { ["all_time" "day" "month" "transaction" "week" "year"] }
def metric-completer [] { ["count" "volume"] }
def status-completer-4 [] { ["active" "inactive"] }
def reason-completer-1 [] { ["account_closed" "account_frozen_entry_returned_per_ofac_instruction" "addenda_error" "amount_field_error" "authorization_revoked_by_customer" "corporate_customer_advised_not_authorized" "credit_entry_refused_by_receiver" "customer_advised_unauthorized_improper_ineligible_or_incomplete" "enr_invalid_individual_name" "file_record_edit_criteria" "incorrectly_coded_outbound_international_payment" "insufficient_fund" "invalid_account_number_structure" "invalid_ach_routing_number" "limited_participation_dfi" "no_account" "non_transaction_account" "other" "payment_stopped" "returned_per_odfi_request" "routing_number_check_digit_error" "unauthorized_debit_to_consumer_account_using_corporate_sec_code" "uncollected_funds"] }
def status-completer-5 [] { ["accepted" "rejected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-account-numbers: "record<data: table<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>, next_cursor: string>"
    create-an-account-number: "record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>"
    retrieve-an-account-number: "record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>"
    update-an-account-number: "record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>"
    list-account-statements: "record<data: table<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>, next_cursor: string>"
    retrieve-an-account-statement: "record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>"
    list-account-transfers: "record<data: table<account_id: string, amount: int, approval: record, cancellation: record, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>, next_cursor: string>"
    create-an-account-transfer: "record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>"
    retrieve-an-account-transfer: "record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>"
    approve-an-account-transfer: "record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>"
    cancel-an-account-transfer: "record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>"
    list-accounts: "record<data: table<balances: record, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>, next_cursor: string>"
    create-an-account: "record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>"
    retrieve-an-account: "record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>"
    update-an-account: "record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>"
    close-an-account: "record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>"
    list-ach-prenotifications: "record<data: table<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record, routing_number: string, status: string, type: string>, next_cursor: string>"
    create-an-ach-prenotification: "record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string>"
    retrieve-an-ach-prenotification: "record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string>"
    list-ach-transfers: "record<data: table<account_id: string, account_number: string, addendum: string, amount: int, approval: record, cancellation: record, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record, return: record, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string>"
    create-an-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    retrieve-an-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    approve-an-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    cancel-a-pending-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    list-card-disputes: "record<data: table<acceptance: record, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record, status: string, type: string>, next_cursor: string>"
    create-a-card-dispute: "record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>"
    retrieve-a-card-dispute: "record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>"
    list-card-profiles: "record<data: table<created_at: string, description: string, digital_wallets: record, id: string, status: string, type: string>, next_cursor: string>"
    create-a-card-profile: "record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string>"
    retrieve-a-card-profile: "record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string>"
    list-cards: "record<data: table<account_id: string, billing_address: record, created_at: string, description: string, digital_wallet: record, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>, next_cursor: string>"
    create-a-card: "record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>"
    retrieve-a-card: "record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>"
    update-a-card: "record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>"
    retrieve-sensitive-details-for-a-card: "record<card_id: string, expiration_month: int, expiration_year: int, primary_account_number: string, type: string, verification_code: string>"
    list-check-deposits: "record<data: table<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record, deposit_rejection: record, deposit_return: record, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>, next_cursor: string>"
    create-a-check-deposit: "record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>"
    retrieve-a-check-deposit: "record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>"
    list-check-transfers: "record<data: table<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record, status: string, stop_payment_request: record, submission: record, submitted_at: string, template_id: string, transaction_id: string, type: string>, next_cursor: string>"
    create-a-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    retrieve-a-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    approve-a-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    cancel-a-pending-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    request-a-stop-payment-on-a-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    list-declined-transactions: "record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string>"
    retrieve-a-declined-transaction: "record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_id: string, originator_company_name: string, reason: string, receiver_id_number: string, receiver_name: string, trace_number: string>, card_decline: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string, network: string, network_details: record, real_time_decision_id: string, reason: string>, card_route_decline: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_decline: record<amount: int, auxiliary_on_us: string, reason: string>, inbound_real_time_payments_transfer_decline: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, reason: string, remittance_information: string, transaction_identification: string>, international_ach_decline: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>>, type: string>"
    list-digital-wallet-tokens: "record<data: table<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string>, next_cursor: string>"
    retrieve-a-digital-wallet-token: "record<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string>"
    list-documents: "record<data: table<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>, next_cursor: string>"
    retrieve-a-document: "record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>"
    list-entities: "record<data: table<corporation: record, description: string, id: string, joint: record, natural_person: record, relationship: string, structure: string, supplemental_documents: list, trust: record, type: string>, next_cursor: string>"
    create-an-entity: "record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>"
    retrieve-an-entity: "record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>"
    create-a-supplemental-document-for-an-entity: "record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>"
    list-event-subscriptions: "record<data: table<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>, next_cursor: string>"
    create-an-event-subscription: "record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>"
    retrieve-an-event-subscription: "record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>"
    update-an-event-subscription: "record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>"
    list-events: "record<data: table<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string>, next_cursor: string>"
    retrieve-an-event: "record<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string>"
    list-external-accounts: "record<data: table<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>, next_cursor: string>"
    create-an-external-account: "record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>"
    retrieve-an-external-account: "record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>"
    update-an-external-account: "record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>"
    list-files: "record<data: table<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>, next_cursor: string>"
    create-a-file: "record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>"
    retrieve-a-file: "record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>"
    retrieve-group-details: "record<ach_debit_status: string, activation_status: string, created_at: string, id: string, type: string>"
    list-inbound-ach-transfer-returns: "record<data: table<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record, transaction_id: string, type: string>, next_cursor: string>"
    create-an-ach-return: "record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string>"
    retrieve-an-inbound-ach-transfer-return: "record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string>"
    list-inbound-wire-drawdown-requests: "record<data: table<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>, next_cursor: string>"
    retrieve-an-inbound-wire-drawdown-request: "record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>"
    list-limits: "record<data: table<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>, next_cursor: string>"
    create-a-limit: "record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>"
    retrieve-a-limit: "record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>"
    update-a-limit: "record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>"
    list-oauth-connections: "record<data: table<created_at: string, group_id: string, id: string, status: string, type: string>, next_cursor: string>"
    retrieve-an-oauth-connection: "record<created_at: string, group_id: string, id: string, status: string, type: string>"
    list-pending-transactions: "record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, status: string, type: string>, next_cursor: string>"
    retrieve-a-pending-transaction: "record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, ach_transfer_instruction: record<amount: int, transfer_id: string>, card_authorization: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record, real_time_decision_id: string>, card_route_authorization: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_deposit_instruction: record<amount: int, back_image_file_id: string, check_deposit_id: string, currency: string, front_image_file_id: string>, check_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, inbound_funds_hold: record<amount: int, automatically_releases_at: string, currency: string, held_transaction_id: string, released_at: string, status: string>, wire_drawdown_payment_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string>, wire_transfer_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>>, status: string, type: string>"
    retrieve-a-real-time-decision: "record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string>"
    action-a-real-time-decision: "record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string>"
    list-routing-numbers: "record<data: table<ach_transfers: string, name: string, real_time_payments_transfers: string, routing_number: string, type: string, wire_transfers: string>, next_cursor: string>"
    simulate-an-account-statement-being-created: "record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>"
    complete-a-sandbox-account-transfer: "record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>"
    return-a-sandbox-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    submit-a-sandbox-ach-transfer: "record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>"
    simulate-an-authorization-on-a-card: "record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, pending_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record, ach_transfer_instruction: record, card_authorization: record, card_route_authorization: record, category: string, check_deposit_instruction: record, check_transfer_instruction: record, inbound_funds_hold: record, wire_drawdown_payment_instruction: record, wire_transfer_instruction: record>, status: string, type: string>, type: string>"
    simulates-advancing-the-state-of-a-card-dispute: "record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>"
    simulate-a-refund-on-a-card: "record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>"
    simulate-settling-a-card-authorization: "record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>"
    reject-a-sandbox-check-deposit: "record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>"
    return-a-sandbox-check-deposit: "record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>"
    submit-a-sandbox-check-deposit: "record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>"
    deposit-a-sandbox-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    mail-a-sandbox-check-transfer: "record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>"
    simulate-digital-wallet-provisioning-for-a-card: "record<decline_reason: string, digital_wallet_token_id: string, type: string>"
    simulate-a-tax-document-being-created: "record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>"
    simulate-an-ach-transfer-to-your-account: "record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>"
    simulate-a-real-time-payments-transfer-to-your-account: "record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>"
    simulate-an-inbound-wire-drawdown-request-being-created: "record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>"
    simulate-a-wire-transfer-to-your-account: "record<transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>"
    reverse-a-sandbox-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
    submit-a-sandbox-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
    list-transactions: "record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string>"
    retrieve-a-transaction: "record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>"
    list-wire-drawdown-requests: "record<data: table<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record, type: string>, next_cursor: string>"
    create-a-wire-drawdown-request: "record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string>"
    retrieve-a-wire-drawdown-request: "record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string>"
    list-wire-transfers: "record<data: table<account_id: string, account_number: string, amount: int, approval: record, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record, routing_number: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string>"
    create-a-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
    retrieve-a-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
    approve-a-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
    cancel-a-pending-wire-transfer: "record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-account-numbers" "create-an-account-number" "retrieve-an-account-number" "update-an-account-number" "list-account-statements" "retrieve-an-account-statement" "list-account-transfers" "create-an-account-transfer" "retrieve-an-account-transfer" "approve-an-account-transfer" "cancel-an-account-transfer" "list-accounts" "create-an-account" "retrieve-an-account" "update-an-account" "close-an-account" "list-ach-prenotifications" "create-an-ach-prenotification" "retrieve-an-ach-prenotification" "list-ach-transfers" "create-an-ach-transfer" "retrieve-an-ach-transfer" "approve-an-ach-transfer" "cancel-a-pending-ach-transfer" "list-card-disputes" "create-a-card-dispute" "retrieve-a-card-dispute" "list-card-profiles" "create-a-card-profile" "retrieve-a-card-profile" "list-cards" "create-a-card" "retrieve-a-card" "update-a-card" "retrieve-sensitive-details-for-a-card" "list-check-deposits" "create-a-check-deposit" "retrieve-a-check-deposit" "list-check-transfers" "create-a-check-transfer" "retrieve-a-check-transfer" "approve-a-check-transfer" "cancel-a-pending-check-transfer" "request-a-stop-payment-on-a-check-transfer" "list-declined-transactions" "retrieve-a-declined-transaction" "list-digital-wallet-tokens" "retrieve-a-digital-wallet-token" "list-documents" "retrieve-a-document" "list-entities" "create-an-entity" "retrieve-an-entity" "create-a-supplemental-document-for-an-entity" "list-event-subscriptions" "create-an-event-subscription" "retrieve-an-event-subscription" "update-an-event-subscription" "list-events" "retrieve-an-event" "list-external-accounts" "create-an-external-account" "retrieve-an-external-account" "update-an-external-account" "list-files" "create-a-file" "retrieve-a-file" "retrieve-group-details" "list-inbound-ach-transfer-returns" "create-an-ach-return" "retrieve-an-inbound-ach-transfer-return" "list-inbound-wire-drawdown-requests" "retrieve-an-inbound-wire-drawdown-request" "list-limits" "create-a-limit" "retrieve-a-limit" "update-a-limit" "list-oauth-connections" "retrieve-an-oauth-connection" "list-pending-transactions" "retrieve-a-pending-transaction" "retrieve-a-real-time-decision" "action-a-real-time-decision" "list-routing-numbers" "simulate-an-account-statement-being-created" "complete-a-sandbox-account-transfer" "return-a-sandbox-ach-transfer" "submit-a-sandbox-ach-transfer" "simulate-an-authorization-on-a-card" "simulates-advancing-the-state-of-a-card-dispute" "simulate-a-refund-on-a-card" "simulate-settling-a-card-authorization" "reject-a-sandbox-check-deposit" "return-a-sandbox-check-deposit" "submit-a-sandbox-check-deposit" "deposit-a-sandbox-check-transfer" "mail-a-sandbox-check-transfer" "simulate-digital-wallet-provisioning-for-a-card" "simulate-a-tax-document-being-created" "simulate-an-ach-transfer-to-your-account" "simulate-a-real-time-payments-transfer-to-your-account" "simulate-an-inbound-wire-drawdown-request-being-created" "simulate-a-wire-transfer-to-your-account" "reverse-a-sandbox-wire-transfer" "submit-a-sandbox-wire-transfer" "list-transactions" "retrieve-a-transaction" "list-wire-drawdown-requests" "create-a-wire-drawdown-request" "retrieve-a-wire-drawdown-request" "list-wire-transfers" "create-a-wire-transfer" "retrieve-a-wire-transfer" "approve-a-wire-transfer" "cancel-a-pending-wire-transfer" "commands"] | sort) } | get name | first)
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

# List Account Numbers
#
# GET /account_numbers
# Returns: record<data: table<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>, next_cursor: string>
# operationId: list_account_numbers
export def "list-account-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --status: string@status-completer
  --account-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account_numbers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: status, var: status}, {name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, status: $status, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Account Number
#
# POST /account_numbers
# Returns: record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>
# operationId: create_an_account_number
export def "create-an-account-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Account the Account Number should belong to.
  name: string # The name you choose for the Account Number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account_numbers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Account Number
#
# GET /account_numbers/{account_number_id}
# Returns: record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>
# operationId: retrieve_an_account_number
export def "retrieve-an-account-number" [
  account_number_id: string
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
    path: "/account_numbers/{account_number_id}"
    path_params: [{name: account_number_id, var: account_number_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Account Number
#
# PATCH /account_numbers/{account_number_id}
# Returns: record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>
# operationId: update_an_account_number
export def "update-an-account-number" [
  account_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name you choose for the Account Number.
  --status: string@status-completer # This indicates if transfers can be made to the Account Number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account_numbers/{account_number_id}"
    path_params: [{name: account_number_id, var: account_number_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Account Statements
#
# GET /account_statements
# Returns: record<data: table<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>, next_cursor: string>
# operationId: list_account_statements
export def "list-account-statements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --statement-period-start-after: string # format: date-time
  --statement-period-start-before: string # format: date-time
  --statement-period-start-on-or-after: string # format: date-time
  --statement-period-start-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account_statements"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "statement_period_start.after", var: statement_period_start_after}, {name: "statement_period_start.before", var: statement_period_start_before}, {name: "statement_period_start.on_or_after", var: statement_period_start_on_or_after}, {name: "statement_period_start.on_or_before", var: statement_period_start_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, statement_period_start_after: $statement_period_start_after, statement_period_start_before: $statement_period_start_before, statement_period_start_on_or_after: $statement_period_start_on_or_after, statement_period_start_on_or_before: $statement_period_start_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Account Statement
#
# GET /account_statements/{account_statement_id}
# Returns: record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>
# operationId: retrieve_an_account_statement
export def "retrieve-an-account-statement" [
  account_statement_id: string
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
    path: "/account_statements/{account_statement_id}"
    path_params: [{name: account_statement_id, var: account_statement_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_statement_id: $account_statement_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Account Transfers
#
# GET /account_transfers
# Returns: record<data: table<account_id: string, amount: int, approval: record, cancellation: record, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_account_transfers
export def "list-account-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account_transfers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Account Transfer
#
# POST /account_transfers
# Returns: record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>
# operationId: create_an_account_transfer
export def "create-an-account-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  amount: int # The transfer amount in the minor unit of the account currency. For dollars, for example, this is cents.
  description: string # The description you choose to give the transfer.
  destination_account_id: string # The identifier for the account that will receive the transfer.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: amount, var: amount}, {name: description, var: description}, {name: destination_account_id, var: destination_account_id}, {name: require_approval, var: require_approval}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, amount: $amount, description: $description, destination_account_id: $destination_account_id, require_approval: $require_approval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Account Transfer
#
# GET /account_transfers/{account_transfer_id}
# Returns: record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>
# operationId: retrieve_an_account_transfer
export def "retrieve-an-account-transfer" [
  account_transfer_id: string
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
    path: "/account_transfers/{account_transfer_id}"
    path_params: [{name: account_transfer_id, var: account_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_transfer_id: $account_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve an Account Transfer
#
# POST /account_transfers/{account_transfer_id}/approve
# Returns: record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>
# operationId: approve_an_account_transfer
export def "approve-an-account-transfer" [
  account_transfer_id: string
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
    path: "/account_transfers/{account_transfer_id}/approve"
    path_params: [{name: account_transfer_id, var: account_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_transfer_id: $account_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel an Account Transfer
#
# POST /account_transfers/{account_transfer_id}/cancel
# Returns: record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>
# operationId: cancel_an_account_transfer
export def "cancel-an-account-transfer" [
  account_transfer_id: string
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
    path: "/account_transfers/{account_transfer_id}/cancel"
    path_params: [{name: account_transfer_id, var: account_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_transfer_id: $account_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Accounts
#
# GET /accounts
# Returns: record<data: table<balances: record, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>, next_cursor: string>
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
  --cursor: string
  --limit: int
  --entity-id: string # e.g. entity_n8y8tnk2p9339ti393yi
  --status: string@status-completer-1
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: entity_id, var: entity_id}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, entity_id: $entity_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Account
#
# POST /accounts
# Returns: record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>
# operationId: create_an_account
export def "create-an-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # The identifier for the Entity that will own the Account.
  --informational-entity-id: string # The identifier of an Entity that, while not owning the Account, is associated with its activity. Its relationship to your group must be `informational`.
  name: string # The name you choose for the Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: entity_id, var: entity_id}, {name: informational_entity_id, var: informational_entity_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, informational_entity_id: $informational_entity_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Account
#
# GET /accounts/{account_id}
# Returns: record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>
# operationId: retrieve_an_account
export def "retrieve-an-account" [
  account_id: string
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
    path: "/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Account
#
# PATCH /accounts/{account_id}
# Returns: record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>
# operationId: update_an_account
export def "update-an-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/accounts/{account_id}"
    path_params: [{name: account_id, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Close an Account
#
# POST /accounts/{account_id}/close
# Returns: record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>
# operationId: close_an_account
export def "close-an-account" [
  account_id: string
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
    path: "/accounts/{account_id}/close"
    path_params: [{name: account_id, var: account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ACH Prenotifications
#
# GET /ach_prenotifications
# Returns: record<data: table<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record, routing_number: string, status: string, type: string>, next_cursor: string>
# operationId: list_ach_prenotifications
export def "list-ach-prenotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ach_prenotifications"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an ACH Prenotification
#
# POST /ach_prenotifications
# Returns: record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string>
# operationId: create_an_ach_prenotification
export def "create-an-ach-prenotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The account number for the destination account.
  --addendum: string # Additional information that will be sent to the recipient.
  --company-descriptive-date: string # The description of the date of the transfer.
  --company-discretionary-data: string # The data you choose to associate with the transfer.
  --company-entry-description: string # The description of the transfer you wish to be shown to the recipient.
  --company-name: string # The name by which the recipient knows you.
  --credit-debit-indicator: string@credit-debit-indicator-completer # Whether the Prenotification is for a future debit or credit.
  --effective-date: string # The transfer effective date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date)
  --individual-id: string # Your identifer for the transfer recipient.
  --individual-name: string # The name of the transfer recipient. This value is information and not verified by the recipient's bank.
  routing_number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
  --standard-entry-class-code: string@standard-entry-class-code-completer # The Standard Entry Class (SEC) code to use for the ACH Prenotification.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ach_prenotifications"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number, var: account_number}, {name: addendum, var: addendum}, {name: company_descriptive_date, var: company_descriptive_date}, {name: company_discretionary_data, var: company_discretionary_data}, {name: company_entry_description, var: company_entry_description}, {name: company_name, var: company_name}, {name: credit_debit_indicator, var: credit_debit_indicator}, {name: effective_date, var: effective_date}, {name: individual_id, var: individual_id}, {name: individual_name, var: individual_name}, {name: routing_number, var: routing_number}, {name: standard_entry_class_code, var: standard_entry_class_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number: $account_number, addendum: $addendum, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_name: $company_name, credit_debit_indicator: $credit_debit_indicator, effective_date: $effective_date, individual_id: $individual_id, individual_name: $individual_name, routing_number: $routing_number, standard_entry_class_code: $standard_entry_class_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an ACH Prenotification
#
# GET /ach_prenotifications/{ach_prenotification_id}
# Returns: record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string>
# operationId: retrieve_an_ach_prenotification
export def "retrieve-an-ach-prenotification" [
  ach_prenotification_id: string
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
    path: "/ach_prenotifications/{ach_prenotification_id}"
    path_params: [{name: ach_prenotification_id, var: ach_prenotification_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_prenotification_id: $ach_prenotification_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List ACH Transfers
#
# GET /ach_transfers
# Returns: record<data: table<account_id: string, account_number: string, addendum: string, amount: int, approval: record, cancellation: record, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record, return: record, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_ach_transfers
export def "list-ach-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --external-account-id: string
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/ach_transfers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: external_account_id, var: external_account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, external_account_id: $external_account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an ACH Transfer
#
# POST /ach_transfers
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: create_an_ach_transfer
export def "create-an-ach-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Increase identifier for the account that will send the transfer.
  --account-number: string # The account number for the destination account.
  --addendum: string # Additional information that will be sent to the recipient. This is included in the transfer data sent to the receiving bank.
  amount: int # The transfer amount in cents. A positive amount originates a credit transfer pushing funds to the receiving account. A negative amount originates a debit transfer pulling funds from the receiving account.
  --company-descriptive-date: string # The description of the date of the transfer, usually in the format `YYYYMMDD`. This is included in the transfer data sent to the receiving bank.
  --company-discretionary-data: string # The data you choose to associate with the transfer. This is included in the transfer data sent to the receiving bank.
  --company-entry-description: string # A description of the transfer. This is included in the transfer data sent to the receiving bank.
  --company-name: string # The name by which the recipient knows you. This is included in the transfer data sent to the receiving bank.
  --effective-date: string # The transfer effective date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date)
  --external-account-id: string # The ID of an External Account to initiate a transfer to. If this parameter is provided, `account_number`, `routing_number`, and `funding` must be absent.
  --funding: string@funding-completer # The type of the account to which the transfer will be sent.
  --individual-id: string # Your identifer for the transfer recipient.
  --individual-name: string # The name of the transfer recipient. This value is informational and not verified by the recipient's bank.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --routing-number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
  --standard-entry-class-code: string@standard-entry-class-code-completer # The Standard Entry Class (SEC) code to use for the transfer.
  statement_descriptor: string # A description you choose to give the transfer. This will be saved with the transfer details, displayed in the dashboard, and returned by the API. If `individual_name` and `company_name` are not explicitly set by this API, the `statement_descriptor` will be sent in those fields to the receiving bank to help the customer recognize the transfer. You are highly encouraged to pass `individual_name` and `company_name` instead of relying on this fallback.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ach_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: account_number, var: account_number}, {name: addendum, var: addendum}, {name: amount, var: amount}, {name: company_descriptive_date, var: company_descriptive_date}, {name: company_discretionary_data, var: company_discretionary_data}, {name: company_entry_description, var: company_entry_description}, {name: company_name, var: company_name}, {name: effective_date, var: effective_date}, {name: external_account_id, var: external_account_id}, {name: funding, var: funding}, {name: individual_id, var: individual_id}, {name: individual_name, var: individual_name}, {name: require_approval, var: require_approval}, {name: routing_number, var: routing_number}, {name: standard_entry_class_code, var: standard_entry_class_code}, {name: statement_descriptor, var: statement_descriptor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, account_number: $account_number, addendum: $addendum, amount: $amount, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_name: $company_name, effective_date: $effective_date, external_account_id: $external_account_id, funding: $funding, individual_id: $individual_id, individual_name: $individual_name, require_approval: $require_approval, routing_number: $routing_number, standard_entry_class_code: $standard_entry_class_code, statement_descriptor: $statement_descriptor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an ACH Transfer
#
# GET /ach_transfers/{ach_transfer_id}
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: retrieve_an_ach_transfer
export def "retrieve-an-ach-transfer" [
  ach_transfer_id: string
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
    path: "/ach_transfers/{ach_transfer_id}"
    path_params: [{name: ach_transfer_id, var: ach_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_transfer_id: $ach_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve an ACH Transfer
#
# POST /ach_transfers/{ach_transfer_id}/approve
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: approve_an_ach_transfer
export def "approve-an-ach-transfer" [
  ach_transfer_id: string
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
    path: "/ach_transfers/{ach_transfer_id}/approve"
    path_params: [{name: ach_transfer_id, var: ach_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_transfer_id: $ach_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a pending ACH Transfer
#
# POST /ach_transfers/{ach_transfer_id}/cancel
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: cancel_a_pending_ach_transfer
export def "cancel-a-pending-ach-transfer" [
  ach_transfer_id: string
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
    path: "/ach_transfers/{ach_transfer_id}/cancel"
    path_params: [{name: ach_transfer_id, var: ach_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_transfer_id: $ach_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Card Disputes
#
# GET /card_disputes
# Returns: record<data: table<acceptance: record, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record, status: string, type: string>, next_cursor: string>
# operationId: list_card_disputes
export def "list-card-disputes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
  --status-in: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/card_disputes"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}, {name: "status.in", var: status_in, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before, status_in: $status_in
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Card Dispute
#
# POST /card_disputes
# Returns: record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>
# operationId: create_a_card_dispute
export def "create-a-card-dispute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  disputed_transaction_id: string # The Transaction you wish to dispute. This Transaction must have a `source_type` of `card_settlement`.
  explanation: string # Why you are disputing this Transaction.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/card_disputes"
    body: {content_type: "application/json", kind: json, fields: [{name: disputed_transaction_id, var: disputed_transaction_id}, {name: explanation, var: explanation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    disputed_transaction_id: $disputed_transaction_id, explanation: $explanation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Card Dispute
#
# GET /card_disputes/{card_dispute_id}
# Returns: record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>
# operationId: retrieve_a_card_dispute
export def "retrieve-a-card-dispute" [
  card_dispute_id: string
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
    path: "/card_disputes/{card_dispute_id}"
    path_params: [{name: card_dispute_id, var: card_dispute_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_dispute_id: $card_dispute_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Card Profiles
#
# GET /card_profiles
# Returns: record<data: table<created_at: string, description: string, digital_wallets: record, id: string, status: string, type: string>, next_cursor: string>
# operationId: list_card_profiles
export def "list-card-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --status-in: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/card_profiles"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "status.in", var: status_in, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, status_in: $status_in
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Card Profile
#
# POST /card_profiles
# Returns: record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string>
# operationId: create_a_card_profile
export def "create-a-card-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # A description you can use to identify the Card Profile.
  digital_wallets: record # How Cards should appear in digital wallets such as Apple Pay. Different wallets will use these values to render card artwork appropriately for their app. — shape: {app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email?: string, contact_phone?: string, contact_website?: string, issuer_name: string, text_color?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/card_profiles"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: digital_wallets, var: digital_wallets}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, digital_wallets: $digital_wallets
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Card Profile
#
# GET /card_profiles/{card_profile_id}
# Returns: record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string>
# operationId: retrieve_a_card_profile
export def "retrieve-a-card-profile" [
  card_profile_id: string
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
    path: "/card_profiles/{card_profile_id}"
    path_params: [{name: card_profile_id, var: card_profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_profile_id: $card_profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Cards
#
# GET /cards
# Returns: record<data: table<account_id: string, billing_address: record, created_at: string, description: string, digital_wallet: record, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>, next_cursor: string>
# operationId: list_cards
export def "list-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cards"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Card
#
# POST /cards
# Returns: record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>
# operationId: create_a_card
export def "create-a-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Account the card should belong to.
  --billing-address: record # The card's billing address. — shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
  --description: string # The description you choose to give the card.
  --digital-wallet: record # The contact information used in the two-factor steps for digital wallet card creation. At least one field must be present to complete the digital wallet steps. — shape: {card_profile_id?: string, email?: string, phone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cards"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: billing_address, var: billing_address}, {name: description, var: description}, {name: digital_wallet, var: digital_wallet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, billing_address: $billing_address, description: $description, digital_wallet: $digital_wallet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Card
#
# GET /cards/{card_id}
# Returns: record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>
# operationId: retrieve_a_card
export def "retrieve-a-card" [
  card_id: string
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
    path: "/cards/{card_id}"
    path_params: [{name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Card
#
# PATCH /cards/{card_id}
# Returns: record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>
# operationId: update_a_card
export def "update-a-card" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-address: record # The card's updated billing address. — shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
  --description: string # The description you choose to give the card.
  --digital-wallet: record # The contact information used in the two-factor steps for digital wallet card creation. At least one field must be present to complete the digital wallet steps. — shape: {card_profile_id?: string, email?: string, phone?: string}
  --status: string@status-completer # The status to update the Card with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/cards/{card_id}"
    path_params: [{name: card_id, var: card_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: billing_address, var: billing_address}, {name: description, var: description}, {name: digital_wallet, var: digital_wallet}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id, billing_address: $billing_address, description: $description, digital_wallet: $digital_wallet, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve sensitive details for a Card
#
# GET /cards/{card_id}/details
# Returns: record<card_id: string, expiration_month: int, expiration_year: int, primary_account_number: string, type: string, verification_code: string>
# operationId: retrieve_sensitive_details_for_a_card
export def "retrieve-sensitive-details-for-a-card" [
  card_id: string
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
    path: "/cards/{card_id}/details"
    path_params: [{name: card_id, var: card_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Check Deposits
#
# GET /check_deposits
# Returns: record<data: table<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record, deposit_rejection: record, deposit_return: record, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_check_deposits
export def "list-check-deposits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/check_deposits"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Check Deposit
#
# POST /check_deposits
# Returns: record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>
# operationId: create_a_check_deposit
export def "create-a-check-deposit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the Account to deposit the check in.
  amount: int # The deposit amount in the minor unit of the account currency. For dollars, for example, this is cents.
  back_image_file_id: string # The File containing the check's back image.
  currency: string # The currency to use for the deposit.
  front_image_file_id: string # The File containing the check's front image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/check_deposits"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: amount, var: amount}, {name: back_image_file_id, var: back_image_file_id}, {name: currency, var: currency}, {name: front_image_file_id, var: front_image_file_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, amount: $amount, back_image_file_id: $back_image_file_id, currency: $currency, front_image_file_id: $front_image_file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Check Deposit
#
# GET /check_deposits/{check_deposit_id}
# Returns: record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>
# operationId: retrieve_a_check_deposit
export def "retrieve-a-check-deposit" [
  check_deposit_id: string
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
    path: "/check_deposits/{check_deposit_id}"
    path_params: [{name: check_deposit_id, var: check_deposit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_deposit_id: $check_deposit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Check Transfers
#
# GET /check_transfers
# Returns: record<data: table<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record, status: string, stop_payment_request: record, submission: record, submitted_at: string, template_id: string, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_check_transfers
export def "list-check-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/check_transfers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Check Transfer
#
# POST /check_transfers
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: create_a_check_transfer
export def "create-a-check-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  address_city: string # The city of the check's destination.
  address_line1: string # The street address of the check's destination.
  --address-line2: string # The second line of the address of the check's destination.
  address_state: string # The state of the check's destination.
  address_zip: string # The postal code of the check's destination.
  amount: int # The transfer amount in cents.
  message: string # The descriptor that will be printed on the memo field on the check.
  --note: string # The descriptor that will be printed on the letter included with the check.
  recipient_name: string # The name that will be printed on the check.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --return-address: record # The return address to be printed on the check. If omitted this will default to the address of the Entity of the Account used to make the Check Transfer. — shape: {city: string, line1: string, line2?: string, name: string, state: string, zip: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/check_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: address_city, var: address_city}, {name: address_line1, var: address_line1}, {name: address_line2, var: address_line2}, {name: address_state, var: address_state}, {name: address_zip, var: address_zip}, {name: amount, var: amount}, {name: message, var: message}, {name: note, var: note}, {name: recipient_name, var: recipient_name}, {name: require_approval, var: require_approval}, {name: return_address, var: return_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, address_city: $address_city, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip, amount: $amount, message: $message, note: $note, recipient_name: $recipient_name, require_approval: $require_approval, return_address: $return_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Check Transfer
#
# GET /check_transfers/{check_transfer_id}
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: retrieve_a_check_transfer
export def "retrieve-a-check-transfer" [
  check_transfer_id: string
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
    path: "/check_transfers/{check_transfer_id}"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve a Check Transfer
#
# POST /check_transfers/{check_transfer_id}/approve
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: approve_a_check_transfer
export def "approve-a-check-transfer" [
  check_transfer_id: string
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
    path: "/check_transfers/{check_transfer_id}/approve"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a pending Check Transfer
#
# POST /check_transfers/{check_transfer_id}/cancel
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: cancel_a_pending_check_transfer
export def "cancel-a-pending-check-transfer" [
  check_transfer_id: string
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
    path: "/check_transfers/{check_transfer_id}/cancel"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request a stop payment on a Check Transfer
#
# POST /check_transfers/{check_transfer_id}/stop_payment
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: request_a_stop_payment_on_a_check_transfer
export def "request-a-stop-payment-on-a-check-transfer" [
  check_transfer_id: string
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
    path: "/check_transfers/{check_transfer_id}/stop_payment"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Declined Transactions
#
# GET /declined_transactions
# Returns: record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string>
# operationId: list_declined_transactions
export def "list-declined-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
  --route-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/declined_transactions"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}, {name: route_id, var: route_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before, route_id: $route_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Declined Transaction
#
# GET /declined_transactions/{declined_transaction_id}
# Returns: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_id: string, originator_company_name: string, reason: string, receiver_id_number: string, receiver_name: string, trace_number: string>, card_decline: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string, network: string, network_details: record, real_time_decision_id: string, reason: string>, card_route_decline: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_decline: record<amount: int, auxiliary_on_us: string, reason: string>, inbound_real_time_payments_transfer_decline: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, reason: string, remittance_information: string, transaction_identification: string>, international_ach_decline: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>>, type: string>
# operationId: retrieve_a_declined_transaction
export def "retrieve-a-declined-transaction" [
  declined_transaction_id: string
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
    path: "/declined_transactions/{declined_transaction_id}"
    path_params: [{name: declined_transaction_id, var: declined_transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    declined_transaction_id: $declined_transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Digital Wallet Tokens
#
# GET /digital_wallet_tokens
# Returns: record<data: table<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string>, next_cursor: string>
# operationId: list_digital_wallet_tokens
export def "list-digital-wallet-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --card-id: string # e.g. card_oubs0hwk5rn6knuecxg2
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/digital_wallet_tokens"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: card_id, var: card_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, card_id: $card_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Digital Wallet Token
#
# GET /digital_wallet_tokens/{digital_wallet_token_id}
# Returns: record<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string>
# operationId: retrieve_a_digital_wallet_token
export def "retrieve-a-digital-wallet-token" [
  digital_wallet_token_id: string
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
    path: "/digital_wallet_tokens/{digital_wallet_token_id}"
    path_params: [{name: digital_wallet_token_id, var: digital_wallet_token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    digital_wallet_token_id: $digital_wallet_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Documents
#
# GET /documents
# Returns: record<data: table<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>, next_cursor: string>
# operationId: list_documents
export def "list-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --entity-id: string
  --category-in: list<string>
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: entity_id, var: entity_id}, {name: "category.in", var: category_in, style: multi}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, entity_id: $entity_id, category_in: $category_in, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Document
#
# GET /documents/{document_id}
# Returns: record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>
# operationId: retrieve_a_document
export def "retrieve-a-document" [
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
    path: "/documents/{document_id}"
    path_params: [{name: document_id, var: document_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Entities
#
# GET /entities
# Returns: record<data: table<corporation: record, description: string, id: string, joint: record, natural_person: record, relationship: string, structure: string, supplemental_documents: list, trust: record, type: string>, next_cursor: string>
# operationId: list_entities
export def "list-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/entities"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Entity
#
# POST /entities
# Returns: record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>
# operationId: create_an_entity
export def "create-an-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporation: record # Details of the corporation entity to create. Required if `structure` is equal to `corporation`. — shape: {address: record, beneficial_owners: list, incorporation_state?: string, name: string, tax_identifier: string, website?: string}
  --description: string # The description you choose to give the entity.
  --joint: record # Details of the joint entity to create. Required if `structure` is equal to `joint`. — shape: {individuals: list, name?: string}
  --natural-person: record # Details of the natural person entity to create. Required if `structure` is equal to `natural_person`. Natural people entities should be submitted with `social_security_number` or `individual_taxpayer_identification_number` identification methods. — shape: {address: record, confirmed_no_us_tax_id?: bool, date_of_birth: string, identification: record, name: string}
  relationship: string@relationship-completer # The relationship between your group and the entity.
  structure: string@structure-completer # The type of Entity to create.
  --supplemental-documents: list # Additional documentation associated with the entity. — item shape: {file_id: string}
  --trust: record # Details of the trust entity to create. Required if `structure` is equal to `trust`. — shape: {address: record, category: "revocable"|"irrevocable", formation_document_file_id?: string, formation_state?: string, grantor?: record, name: string, tax_identifier?: string, trustees: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entities"
    body: {content_type: "application/json", kind: json, fields: [{name: corporation, var: corporation}, {name: description, var: description}, {name: joint, var: joint}, {name: natural_person, var: natural_person}, {name: relationship, var: relationship}, {name: structure, var: structure}, {name: supplemental_documents, var: supplemental_documents}, {name: trust, var: trust}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    corporation: $corporation, description: $description, joint: $joint, natural_person: $natural_person, relationship: $relationship, structure: $structure, supplemental_documents: $supplemental_documents, trust: $trust
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Entity
#
# GET /entities/{entity_id}
# Returns: record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>
# operationId: retrieve_an_entity
export def "retrieve-an-entity" [
  entity_id: string
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
    path: "/entities/{entity_id}"
    path_params: [{name: entity_id, var: entity_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a supplemental document for an Entity
#
# POST /entities/{entity_id}/supplemental_documents
# Returns: record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string>
# operationId: create_a_supplemental_document_for_an_entity
export def "create-a-supplemental-document-for-an-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # The identifier of the File containing the document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/entities/{entity_id}/supplemental_documents"
    path_params: [{name: entity_id, var: entity_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: file_id, var: file_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Event Subscriptions
#
# GET /event_subscriptions
# Returns: record<data: table<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>, next_cursor: string>
# operationId: list_event_subscriptions
export def "list-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event_subscriptions"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Event Subscription
#
# POST /event_subscriptions
# Returns: record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>
# operationId: create_an_event_subscription
export def "create-an-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --selected-event-category: string@selected-event-category-completer # If specified, this subscription will only receive webhooks for Events with the specified `category`.
  --shared-secret: string # The key that will be used to sign webhooks. If no value is passed, a random string will be used as default.
  url: string # The URL you'd like us to send webhooks to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/event_subscriptions"
    body: {content_type: "application/json", kind: json, fields: [{name: selected_event_category, var: selected_event_category}, {name: shared_secret, var: shared_secret}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_event_category: $selected_event_category, shared_secret: $shared_secret, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Event Subscription
#
# GET /event_subscriptions/{event_subscription_id}
# Returns: record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>
# operationId: retrieve_an_event_subscription
export def "retrieve-an-event-subscription" [
  event_subscription_id: string
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
    path: "/event_subscriptions/{event_subscription_id}"
    path_params: [{name: event_subscription_id, var: event_subscription_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_subscription_id: $event_subscription_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Event Subscription
#
# PATCH /event_subscriptions/{event_subscription_id}
# Returns: record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>
# operationId: update_an_event_subscription
export def "update-an-event-subscription" [
  event_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # The status to update the Event Subscription with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/event_subscriptions/{event_subscription_id}"
    path_params: [{name: event_subscription_id, var: event_subscription_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_subscription_id: $event_subscription_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Events
#
# GET /events
# Returns: record<data: table<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string>, next_cursor: string>
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
  --cursor: string
  --limit: int
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
  --category-in: list<string>
  --associated-object-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}, {name: "category.in", var: category_in, style: multi}, {name: associated_object_id, var: associated_object_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before, category_in: $category_in, associated_object_id: $associated_object_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Event
#
# GET /events/{event_id}
# Returns: record<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string>
# operationId: retrieve_an_event
export def "retrieve-an-event" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events/{event_id}"
    path_params: [{name: event_id, var: event_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_id: $event_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List External Accounts
#
# GET /external_accounts
# Returns: record<data: table<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>, next_cursor: string>
# operationId: list_external_accounts
export def "list-external-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --status-in: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/external_accounts"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "status.in", var: status_in, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, status_in: $status_in
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an External Account
#
# POST /external_accounts
# Returns: record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>
# operationId: create_an_external_account
export def "create-an-external-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The account number for the destination account.
  description: string # The name you choose for the Account.
  --funding: string@funding-completer-1 # The type of the destination account. Defaults to `checking`.
  routing_number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/external_accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number, var: account_number}, {name: description, var: description}, {name: funding, var: funding}, {name: routing_number, var: routing_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number: $account_number, description: $description, funding: $funding, routing_number: $routing_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an External Account
#
# GET /external_accounts/{external_account_id}
# Returns: record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>
# operationId: retrieve_an_external_account
export def "retrieve-an-external-account" [
  external_account_id: string
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
    path: "/external_accounts/{external_account_id}"
    path_params: [{name: external_account_id, var: external_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_account_id: $external_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an External Account
#
# PATCH /external_accounts/{external_account_id}
# Returns: record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>
# operationId: update_an_external_account
export def "update-an-external-account" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description you choose to give the external account.
  --status: string@status-completer-3 # The status of the External Account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/external_accounts/{external_account_id}"
    path_params: [{name: external_account_id, var: external_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_account_id: $external_account_id, description: $description, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Files
#
# GET /files
# Returns: record<data: table<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>, next_cursor: string>
# operationId: list_files
export def "list-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
  --purpose-in: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}, {name: "purpose.in", var: purpose_in, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before, purpose_in: $purpose_in
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a File
#
# POST /files
# Returns: record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>
# operationId: create_a_file
export def "create-a-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description you choose to give the File.
  file: string # The file contents. This should follow the specifications of [RFC 7578](https://datatracker.ietf.org/doc/html/rfc7578) which defines file transfers for the multipart/form-data protocol. (format: binary)
  purpose: string@purpose-completer # What the File will be used for in Increase's systems.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: description, var: description}, {name: file, var: file}, {name: purpose, var: purpose}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, file: $file, purpose: $purpose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a File
#
# GET /files/{file_id}
# Returns: record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>
# operationId: retrieve_a_file
export def "retrieve-a-file" [
  file_id: string
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
    path: "/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Group details
#
# GET /groups/current
# Returns: record<ach_debit_status: string, activation_status: string, created_at: string, id: string, type: string>
# operationId: retrieve_group_details
export def "retrieve-group-details" [
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
    path: "/groups/current"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Inbound ACH Transfer Returns
#
# GET /inbound_ach_transfer_returns
# Returns: record<data: table<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_inbound_ach_transfer_returns
export def "list-inbound-ach-transfer-returns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inbound_ach_transfer_returns"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an ACH Return
#
# POST /inbound_ach_transfer_returns
# Returns: record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string>
# operationId: create_an_ach_return
export def "create-an-ach-return" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string@reason-completer # The reason why this transfer will be returned. The most usual return codes are `payment_stopped` for debits and `credit_entry_refused_by_receiver` for credits.
  transaction_id: string # The transaction identifier of the Inbound ACH Transfer to return to the originating financial institution.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/inbound_ach_transfer_returns"
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}, {name: transaction_id, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reason: $reason, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Inbound ACH Transfer Return
#
# GET /inbound_ach_transfer_returns/{inbound_ach_transfer_return_id}
# Returns: record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string>
# operationId: retrieve_an_inbound_ach_transfer_return
export def "retrieve-an-inbound-ach-transfer-return" [
  inbound_ach_transfer_return_id: string
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
    path: "/inbound_ach_transfer_returns/{inbound_ach_transfer_return_id}"
    path_params: [{name: inbound_ach_transfer_return_id, var: inbound_ach_transfer_return_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    inbound_ach_transfer_return_id: $inbound_ach_transfer_return_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Inbound Wire Drawdown Requests
#
# GET /inbound_wire_drawdown_requests
# Returns: record<data: table<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>, next_cursor: string>
# operationId: list_inbound_wire_drawdown_requests
export def "list-inbound-wire-drawdown-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/inbound_wire_drawdown_requests"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an Inbound Wire Drawdown Request
#
# GET /inbound_wire_drawdown_requests/{inbound_wire_drawdown_request_id}
# Returns: record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>
# operationId: retrieve_an_inbound_wire_drawdown_request
export def "retrieve-an-inbound-wire-drawdown-request" [
  inbound_wire_drawdown_request_id: string
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
    path: "/inbound_wire_drawdown_requests/{inbound_wire_drawdown_request_id}"
    path_params: [{name: inbound_wire_drawdown_request_id, var: inbound_wire_drawdown_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    inbound_wire_drawdown_request_id: $inbound_wire_drawdown_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Limits
#
# GET /limits
# Returns: record<data: table<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>, next_cursor: string>
# operationId: list_limits
export def "list-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --model-id: string # e.g. account_number_v18nkfqm6afpsrvy82b2
  --status: string # e.g. active
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/limits"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: model_id, var: model_id}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, model_id: $model_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Limit
#
# POST /limits
# Returns: record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>
# operationId: create_a_limit
export def "create-a-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer # The interval for the metric. Required if `metric` is `count` or `volume`.
  metric: string@metric-completer # The metric for the limit.
  model_id: string # The identifier of the Account or Account Number you wish to associate the limit with.
  value: int # The value to test the limit against.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/limits"
    body: {content_type: "application/json", kind: json, fields: [{name: interval, var: interval}, {name: metric, var: metric}, {name: model_id, var: model_id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    interval: $interval, metric: $metric, model_id: $model_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Limit
#
# GET /limits/{limit_id}
# Returns: record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>
# operationId: retrieve_a_limit
export def "retrieve-a-limit" [
  limit_id: string
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
    path: "/limits/{limit_id}"
    path_params: [{name: limit_id, var: limit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit_id: $limit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Limit
#
# PATCH /limits/{limit_id}
# Returns: record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>
# operationId: update_a_limit
export def "update-a-limit" [
  limit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-4 # The status to update the limit with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/limits/{limit_id}"
    path_params: [{name: limit_id, var: limit_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit_id: $limit_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List OAuth Connections
#
# GET /oauth_connections
# Returns: record<data: table<created_at: string, group_id: string, id: string, status: string, type: string>, next_cursor: string>
# operationId: list_oauth_connections
export def "list-oauth-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth_connections"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an OAuth Connection
#
# GET /oauth_connections/{oauth_connection_id}
# Returns: record<created_at: string, group_id: string, id: string, status: string, type: string>
# operationId: retrieve_an_oauth_connection
export def "retrieve-an-oauth-connection" [
  oauth_connection_id: string
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
    path: "/oauth_connections/{oauth_connection_id}"
    path_params: [{name: oauth_connection_id, var: oauth_connection_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    oauth_connection_id: $oauth_connection_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Pending Transactions
#
# GET /pending_transactions
# Returns: record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, status: string, type: string>, next_cursor: string>
# operationId: list_pending_transactions
export def "list-pending-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --route-id: string
  --source-id: string
  --status-in: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pending_transactions"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: route_id, var: route_id}, {name: source_id, var: source_id}, {name: "status.in", var: status_in, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, route_id: $route_id, source_id: $source_id, status_in: $status_in
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Pending Transaction
#
# GET /pending_transactions/{pending_transaction_id}
# Returns: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, ach_transfer_instruction: record<amount: int, transfer_id: string>, card_authorization: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record, real_time_decision_id: string>, card_route_authorization: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_deposit_instruction: record<amount: int, back_image_file_id: string, check_deposit_id: string, currency: string, front_image_file_id: string>, check_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, inbound_funds_hold: record<amount: int, automatically_releases_at: string, currency: string, held_transaction_id: string, released_at: string, status: string>, wire_drawdown_payment_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string>, wire_transfer_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>>, status: string, type: string>
# operationId: retrieve_a_pending_transaction
export def "retrieve-a-pending-transaction" [
  pending_transaction_id: string
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
    path: "/pending_transactions/{pending_transaction_id}"
    path_params: [{name: pending_transaction_id, var: pending_transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pending_transaction_id: $pending_transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Real-Time Decision
#
# GET /real_time_decisions/{real_time_decision_id}
# Returns: record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string>
# operationId: retrieve_a_real_time_decision
export def "retrieve-a-real-time-decision" [
  real_time_decision_id: string
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
    path: "/real_time_decisions/{real_time_decision_id}"
    path_params: [{name: real_time_decision_id, var: real_time_decision_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    real_time_decision_id: $real_time_decision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Action a Real-Time Decision
#
# POST /real_time_decisions/{real_time_decision_id}/action
# Returns: record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string>
# operationId: action_a_real_time_decision
export def "action-a-real-time-decision" [
  real_time_decision_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-authorization: record # If the Real-Time Decision relates to a card authorization attempt, this object contains your response to the authorization. — shape: {decision: "approve"|"decline"}
  --digital-wallet-authentication: record # If the Real-Time Decision relates to a digital wallet authentication attempt, this object contains your response to the authentication. — shape: {result: "success"|"failure"}
  --digital-wallet-token: record # If the Real-Time Decision relates to a digital wallet token provisioning attempt, this object contains your response to the attempt. — shape: {approval?: record, decline?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/real_time_decisions/{real_time_decision_id}/action"
    path_params: [{name: real_time_decision_id, var: real_time_decision_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: card_authorization, var: card_authorization}, {name: digital_wallet_authentication, var: digital_wallet_authentication}, {name: digital_wallet_token, var: digital_wallet_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    real_time_decision_id: $real_time_decision_id, card_authorization: $card_authorization, digital_wallet_authentication: $digital_wallet_authentication, digital_wallet_token: $digital_wallet_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Routing Numbers
#
# GET /routing_numbers
# Returns: record<data: table<ach_transfers: string, name: string, real_time_payments_transfers: string, routing_number: string, type: string, wire_transfers: string>, next_cursor: string>
# operationId: list_routing_numbers
export def "list-routing-numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --routing-number: string # required, e.g. 021000021
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/routing_numbers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: routing_number, var: routing_number, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, routing_number: $routing_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate an Account Statement being created
#
# POST /simulations/account_statements
# Returns: record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>
# operationId: simulate_an_account_statement_being_created
export def "simulate-an-account-statement-being-created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier of the Account the statement is for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/account_statements"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete a Sandbox Account Transfer
#
# POST /simulations/account_transfers/{account_transfer_id}/complete
# Returns: record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>
# operationId: complete_a_sandbox_account_transfer
export def "complete-a-sandbox-account-transfer" [
  account_transfer_id: string
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
    path: "/simulations/account_transfers/{account_transfer_id}/complete"
    path_params: [{name: account_transfer_id, var: account_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_transfer_id: $account_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a Sandbox ACH Transfer
#
# POST /simulations/ach_transfers/{ach_transfer_id}/return
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: return_a_sandbox_ach_transfer
export def "return-a-sandbox-ach-transfer" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string@reason-completer-1 # The reason why the Federal Reserve or destination bank returned this transfer. Defaults to `no_account`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/ach_transfers/{ach_transfer_id}/return"
    path_params: [{name: ach_transfer_id, var: ach_transfer_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_transfer_id: $ach_transfer_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a Sandbox ACH Transfer
#
# POST /simulations/ach_transfers/{ach_transfer_id}/submit
# Returns: record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string>
# operationId: submit_a_sandbox_ach_transfer
export def "submit-a-sandbox-ach-transfer" [
  ach_transfer_id: string
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
    path: "/simulations/ach_transfers/{ach_transfer_id}/submit"
    path_params: [{name: ach_transfer_id, var: ach_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ach_transfer_id: $ach_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate an authorization on a Card
#
# POST /simulations/card_authorizations
# Returns: record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, pending_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record, ach_transfer_instruction: record, card_authorization: record, card_route_authorization: record, category: string, check_deposit_instruction: record, check_transfer_instruction: record, inbound_funds_hold: record, wire_drawdown_payment_instruction: record, wire_transfer_instruction: record>, status: string, type: string>, type: string>
# operationId: simulate_an_authorization_on_a_card
export def "simulate-an-authorization-on-a-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The authorization amount in cents.
  --card-id: string # The identifier of the Card to be authorized.
  --digital-wallet-token-id: string # The identifier of the Digital Wallet Token to be authorized.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/card_authorizations"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: card_id, var: card_id}, {name: digital_wallet_token_id, var: digital_wallet_token_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, card_id: $card_id, digital_wallet_token_id: $digital_wallet_token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulates advancing the state of a card dispute
#
# POST /simulations/card_disputes/{card_dispute_id}/action
# Returns: record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string>
# operationId: simulates_advancing_the_state_of_a_card_dispute
export def "simulates-advancing-the-state-of-a-card-dispute" [
  card_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --explanation: string # Why the dispute was rejected. Not required for accepting disputes.
  status: string@status-completer-5 # The status to move the dispute to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/card_disputes/{card_dispute_id}/action"
    path_params: [{name: card_dispute_id, var: card_dispute_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: explanation, var: explanation}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_dispute_id: $card_dispute_id, explanation: $explanation, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate a refund on a card
#
# POST /simulations/card_refunds
# Returns: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>
# operationId: simulate_a_refund_on_a_card
export def "simulate-a-refund-on-a-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction_id: string # The identifier for the Transaction to refund. The Transaction's source must have a category of card_settlement.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/card_refunds"
    body: {content_type: "application/json", kind: json, fields: [{name: transaction_id, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate settling a card authorization
#
# POST /simulations/card_settlements
# Returns: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>
# operationId: simulate_settling_a_card_authorization
export def "simulate-settling-a-card-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The amount to be settled. This defaults to the amount of the Pending Transaction being settled.
  card_id: string # The identifier of the Card to create a settlement on.
  pending_transaction_id: string # The identifier of the Pending Transaction for the Card Authorization you wish to settle.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/card_settlements"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: card_id, var: card_id}, {name: pending_transaction_id, var: pending_transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, card_id: $card_id, pending_transaction_id: $pending_transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/reject
# Returns: record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>
# operationId: reject_a_sandbox_check_deposit
export def "reject-a-sandbox-check-deposit" [
  check_deposit_id: string
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
    path: "/simulations/check_deposits/{check_deposit_id}/reject"
    path_params: [{name: check_deposit_id, var: check_deposit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_deposit_id: $check_deposit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/return
# Returns: record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>
# operationId: return_a_sandbox_check_deposit
export def "return-a-sandbox-check-deposit" [
  check_deposit_id: string
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
    path: "/simulations/check_deposits/{check_deposit_id}/return"
    path_params: [{name: check_deposit_id, var: check_deposit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_deposit_id: $check_deposit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/submit
# Returns: record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>
# operationId: submit_a_sandbox_check_deposit
export def "submit-a-sandbox-check-deposit" [
  check_deposit_id: string
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
    path: "/simulations/check_deposits/{check_deposit_id}/submit"
    path_params: [{name: check_deposit_id, var: check_deposit_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_deposit_id: $check_deposit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deposit a Sandbox Check Transfer
#
# POST /simulations/check_transfers/{check_transfer_id}/deposit
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: deposit_a_sandbox_check_transfer
export def "deposit-a-sandbox-check-transfer" [
  check_transfer_id: string
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
    path: "/simulations/check_transfers/{check_transfer_id}/deposit"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mail a Sandbox Check Transfer
#
# POST /simulations/check_transfers/{check_transfer_id}/mail
# Returns: record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string>
# operationId: mail_a_sandbox_check_transfer
export def "mail-a-sandbox-check-transfer" [
  check_transfer_id: string
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
    path: "/simulations/check_transfers/{check_transfer_id}/mail"
    path_params: [{name: check_transfer_id, var: check_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    check_transfer_id: $check_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate digital wallet provisioning for a card
#
# POST /simulations/digital_wallet_token_requests
# Returns: record<decline_reason: string, digital_wallet_token_id: string, type: string>
# operationId: simulate_digital_wallet_provisioning_for_a_card
export def "simulate-digital-wallet-provisioning-for-a-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: string # The identifier of the Card to be authorized.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/digital_wallet_token_requests"
    body: {content_type: "application/json", kind: json, fields: [{name: card_id, var: card_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    card_id: $card_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate a tax document being created
#
# POST /simulations/documents
# Returns: record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>
# operationId: simulate_a_tax_document_being_created
export def "simulate-a-tax-document-being-created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier of the Account the tax document is for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/documents"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate an ACH Transfer to your account
#
# POST /simulations/inbound_ach_transfers
# Returns: record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>
# operationId: simulate_an_ach_transfer_to_your_account
export def "simulate-an-ach-transfer-to-your-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound ACH Transfer is for.
  amount: int # The transfer amount in cents. A positive amount originates a credit transfer pushing funds to the receiving account. A negative amount originates a debit transfer pulling funds from the receiving account.
  --company-descriptive-date: string # The description of the date of the transfer.
  --company-discretionary-data: string # Data associated with the transfer set by the sender.
  --company-entry-description: string # The description of the transfer set by the sender.
  --company-id: string # The sender's company id.
  --company-name: string # The name of the sender.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/inbound_ach_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number_id, var: account_number_id}, {name: amount, var: amount}, {name: company_descriptive_date, var: company_descriptive_date}, {name: company_discretionary_data, var: company_discretionary_data}, {name: company_entry_description, var: company_entry_description}, {name: company_id, var: company_id}, {name: company_name, var: company_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id, amount: $amount, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_id: $company_id, company_name: $company_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate a Real Time Payments Transfer to your account
#
# POST /simulations/inbound_real_time_payments_transfers
# Returns: record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>
# operationId: simulate_a_real_time_payments_transfer_to_your_account
export def "simulate-a-real-time-payments-transfer-to-your-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound Real Time Payments Transfer is for.
  amount: int # The transfer amount in USD cents. Must be positive.
  --debtor-account-number: string # The account number of the account that sent the transfer.
  --debtor-name: string # The name provided by the sender of the transfer.
  --debtor-routing-number: string # The routing number of the account that sent the transfer.
  --remittance-information: string # Additional information included with the transfer.
  --request-for-payment-id: string # The identifier of a pending Request for Payment that this transfer will fulfill.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/inbound_real_time_payments_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number_id, var: account_number_id}, {name: amount, var: amount}, {name: debtor_account_number, var: debtor_account_number}, {name: debtor_name, var: debtor_name}, {name: debtor_routing_number, var: debtor_routing_number}, {name: remittance_information, var: remittance_information}, {name: request_for_payment_id, var: request_for_payment_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id, amount: $amount, debtor_account_number: $debtor_account_number, debtor_name: $debtor_name, debtor_routing_number: $debtor_routing_number, remittance_information: $remittance_information, request_for_payment_id: $request_for_payment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate an Inbound Wire Drawdown request being created
#
# POST /simulations/inbound_wire_drawdown_requests
# Returns: record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>
# operationId: simulate_an_inbound_wire_drawdown_request_being_created
export def "simulate-an-inbound-wire-drawdown-request-being-created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The amount being requested in cents.
  beneficiary_account_number: string # The drawdown request's beneficiary's account number.
  --beneficiary-address-line1: string # Line 1 of the drawdown request's beneficiary's address.
  --beneficiary-address-line2: string # Line 2 of the drawdown request's beneficiary's address.
  --beneficiary-address-line3: string # Line 3 of the drawdown request's beneficiary's address.
  --beneficiary-name: string # The drawdown request's beneficiary's name.
  beneficiary_routing_number: string # The drawdown request's beneficiary's routing number.
  currency: string # The [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) code for the amount being requested. Will always be "USD".
  message_to_recipient: string # A message from the drawdown request's originator.
  originator_account_number: string # The drawdown request's originator's account number.
  --originator-address-line1: string # Line 1 of the drawdown request's originator's address.
  --originator-address-line2: string # Line 2 of the drawdown request's originator's address.
  --originator-address-line3: string # Line 3 of the drawdown request's originator's address.
  --originator-name: string # The drawdown request's originator's name.
  originator_routing_number: string # The drawdown request's originator's routing number.
  --originator-to-beneficiary-information-line1: string # Line 1 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line2: string # Line 2 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line3: string # Line 3 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line4: string # Line 4 of the information conveyed from the originator of the message to the beneficiary.
  recipient_account_number_id: string # The Account Number to which the recipient of this request is being requested to send funds from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/inbound_wire_drawdown_requests"
    body: {content_type: "application/json", kind: json, fields: [{name: amount, var: amount}, {name: beneficiary_account_number, var: beneficiary_account_number}, {name: beneficiary_address_line1, var: beneficiary_address_line1}, {name: beneficiary_address_line2, var: beneficiary_address_line2}, {name: beneficiary_address_line3, var: beneficiary_address_line3}, {name: beneficiary_name, var: beneficiary_name}, {name: beneficiary_routing_number, var: beneficiary_routing_number}, {name: currency, var: currency}, {name: message_to_recipient, var: message_to_recipient}, {name: originator_account_number, var: originator_account_number}, {name: originator_address_line1, var: originator_address_line1}, {name: originator_address_line2, var: originator_address_line2}, {name: originator_address_line3, var: originator_address_line3}, {name: originator_name, var: originator_name}, {name: originator_routing_number, var: originator_routing_number}, {name: originator_to_beneficiary_information_line1, var: originator_to_beneficiary_information_line1}, {name: originator_to_beneficiary_information_line2, var: originator_to_beneficiary_information_line2}, {name: originator_to_beneficiary_information_line3, var: originator_to_beneficiary_information_line3}, {name: originator_to_beneficiary_information_line4, var: originator_to_beneficiary_information_line4}, {name: recipient_account_number_id, var: recipient_account_number_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    amount: $amount, beneficiary_account_number: $beneficiary_account_number, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, beneficiary_routing_number: $beneficiary_routing_number, currency: $currency, message_to_recipient: $message_to_recipient, originator_account_number: $originator_account_number, originator_address_line1: $originator_address_line1, originator_address_line2: $originator_address_line2, originator_address_line3: $originator_address_line3, originator_name: $originator_name, originator_routing_number: $originator_routing_number, originator_to_beneficiary_information_line1: $originator_to_beneficiary_information_line1, originator_to_beneficiary_information_line2: $originator_to_beneficiary_information_line2, originator_to_beneficiary_information_line3: $originator_to_beneficiary_information_line3, originator_to_beneficiary_information_line4: $originator_to_beneficiary_information_line4, recipient_account_number_id: $recipient_account_number_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Simulate a Wire Transfer to your account
#
# POST /simulations/inbound_wire_transfers
# Returns: record<transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string>
# operationId: simulate_a_wire_transfer_to_your_account
export def "simulate-a-wire-transfer-to-your-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound Wire Transfer is for.
  amount: int # The transfer amount in cents. Must be positive.
  --beneficiary-address-line1: string # The sending bank will set beneficiary_address_line1 in production. You can simulate any value here.
  --beneficiary-address-line2: string # The sending bank will set beneficiary_address_line2 in production. You can simulate any value here.
  --beneficiary-address-line3: string # The sending bank will set beneficiary_address_line3 in production. You can simulate any value here.
  --beneficiary-name: string # The sending bank will set beneficiary_name in production. You can simulate any value here.
  --beneficiary-reference: string # The sending bank will set beneficiary_reference in production. You can simulate any value here.
  --originator-address-line1: string # The sending bank will set originator_address_line1 in production. You can simulate any value here.
  --originator-address-line2: string # The sending bank will set originator_address_line2 in production. You can simulate any value here.
  --originator-address-line3: string # The sending bank will set originator_address_line3 in production. You can simulate any value here.
  --originator-name: string # The sending bank will set originator_name in production. You can simulate any value here.
  --originator-to-beneficiary-information-line1: string # The sending bank will set originator_to_beneficiary_information_line1 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line2: string # The sending bank will set originator_to_beneficiary_information_line2 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line3: string # The sending bank will set originator_to_beneficiary_information_line3 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line4: string # The sending bank will set originator_to_beneficiary_information_line4 in production. You can simulate any value here.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/simulations/inbound_wire_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number_id, var: account_number_id}, {name: amount, var: amount}, {name: beneficiary_address_line1, var: beneficiary_address_line1}, {name: beneficiary_address_line2, var: beneficiary_address_line2}, {name: beneficiary_address_line3, var: beneficiary_address_line3}, {name: beneficiary_name, var: beneficiary_name}, {name: beneficiary_reference, var: beneficiary_reference}, {name: originator_address_line1, var: originator_address_line1}, {name: originator_address_line2, var: originator_address_line2}, {name: originator_address_line3, var: originator_address_line3}, {name: originator_name, var: originator_name}, {name: originator_to_beneficiary_information_line1, var: originator_to_beneficiary_information_line1}, {name: originator_to_beneficiary_information_line2, var: originator_to_beneficiary_information_line2}, {name: originator_to_beneficiary_information_line3, var: originator_to_beneficiary_information_line3}, {name: originator_to_beneficiary_information_line4, var: originator_to_beneficiary_information_line4}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id, amount: $amount, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, beneficiary_reference: $beneficiary_reference, originator_address_line1: $originator_address_line1, originator_address_line2: $originator_address_line2, originator_address_line3: $originator_address_line3, originator_name: $originator_name, originator_to_beneficiary_information_line1: $originator_to_beneficiary_information_line1, originator_to_beneficiary_information_line2: $originator_to_beneficiary_information_line2, originator_to_beneficiary_information_line3: $originator_to_beneficiary_information_line3, originator_to_beneficiary_information_line4: $originator_to_beneficiary_information_line4
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverse a Sandbox Wire Transfer
#
# POST /simulations/wire_transfers/{wire_transfer_id}/reverse
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: reverse_a_sandbox_wire_transfer
export def "reverse-a-sandbox-wire-transfer" [
  wire_transfer_id: string
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
    path: "/simulations/wire_transfers/{wire_transfer_id}/reverse"
    path_params: [{name: wire_transfer_id, var: wire_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_transfer_id: $wire_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a Sandbox Wire Transfer
#
# POST /simulations/wire_transfers/{wire_transfer_id}/submit
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: submit_a_sandbox_wire_transfer
export def "submit-a-sandbox-wire-transfer" [
  wire_transfer_id: string
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
    path: "/simulations/wire_transfers/{wire_transfer_id}/submit"
    path_params: [{name: wire_transfer_id, var: wire_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_transfer_id: $wire_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Transactions
#
# GET /transactions
# Returns: record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string>
# operationId: list_transactions
export def "list-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
  --category-in: list<string>
  --route-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}, {name: "category.in", var: category_in, style: multi}, {name: route_id, var: route_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before, category_in: $category_in, route_id: $route_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Transaction
#
# GET /transactions/{transaction_id}
# Returns: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string>
# operationId: retrieve_a_transaction
export def "retrieve-a-transaction" [
  transaction_id: string
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
    path: "/transactions/{transaction_id}"
    path_params: [{name: transaction_id, var: transaction_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Wire Drawdown Requests
#
# GET /wire_drawdown_requests
# Returns: record<data: table<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record, type: string>, next_cursor: string>
# operationId: list_wire_drawdown_requests
export def "list-wire-drawdown-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wire_drawdown_requests"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Wire Drawdown Request
#
# POST /wire_drawdown_requests
# Returns: record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string>
# operationId: create_a_wire_drawdown_request
export def "create-a-wire-drawdown-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The Account Number to which the recipient should send funds.
  amount: int # The amount requested from the recipient, in cents.
  message_to_recipient: string # A message the recipient will see as part of the request.
  recipient_account_number: string # The drawdown request's recipient's account number.
  --recipient-address-line1: string # Line 1 of the drawdown request's recipient's address.
  --recipient-address-line2: string # Line 2 of the drawdown request's recipient's address.
  --recipient-address-line3: string # Line 3 of the drawdown request's recipient's address.
  recipient_name: string # The drawdown request's recipient's name.
  recipient_routing_number: string # The drawdown request's recipient's routing number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wire_drawdown_requests"
    body: {content_type: "application/json", kind: json, fields: [{name: account_number_id, var: account_number_id}, {name: amount, var: amount}, {name: message_to_recipient, var: message_to_recipient}, {name: recipient_account_number, var: recipient_account_number}, {name: recipient_address_line1, var: recipient_address_line1}, {name: recipient_address_line2, var: recipient_address_line2}, {name: recipient_address_line3, var: recipient_address_line3}, {name: recipient_name, var: recipient_name}, {name: recipient_routing_number, var: recipient_routing_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_number_id: $account_number_id, amount: $amount, message_to_recipient: $message_to_recipient, recipient_account_number: $recipient_account_number, recipient_address_line1: $recipient_address_line1, recipient_address_line2: $recipient_address_line2, recipient_address_line3: $recipient_address_line3, recipient_name: $recipient_name, recipient_routing_number: $recipient_routing_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Wire Drawdown Request
#
# GET /wire_drawdown_requests/{wire_drawdown_request_id}
# Returns: record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string>
# operationId: retrieve_a_wire_drawdown_request
export def "retrieve-a-wire-drawdown-request" [
  wire_drawdown_request_id: string
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
    path: "/wire_drawdown_requests/{wire_drawdown_request_id}"
    path_params: [{name: wire_drawdown_request_id, var: wire_drawdown_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_drawdown_request_id: $wire_drawdown_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Wire Transfers
#
# GET /wire_transfers
# Returns: record<data: table<account_id: string, account_number: string, amount: int, approval: record, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record, routing_number: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string>
# operationId: list_wire_transfers
export def "list-wire-transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --external-account-id: string
  --created-at-after: string # format: date-time
  --created-at-before: string # format: date-time
  --created-at-on-or-after: string # format: date-time
  --created-at-on-or-before: string # format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/wire_transfers"
    query: [{name: cursor, var: cursor}, {name: limit, var: limit}, {name: account_id, var: account_id}, {name: external_account_id, var: external_account_id}, {name: "created_at.after", var: created_at_after}, {name: "created_at.before", var: created_at_before}, {name: "created_at.on_or_after", var: created_at_on_or_after}, {name: "created_at.on_or_before", var: created_at_on_or_before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, limit: $limit, account_id: $account_id, external_account_id: $external_account_id, created_at_after: $created_at_after, created_at_before: $created_at_before, created_at_on_or_after: $created_at_on_or_after, created_at_on_or_before: $created_at_on_or_before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Wire Transfer
#
# POST /wire_transfers
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: create_a_wire_transfer
export def "create-a-wire-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  --account-number: string # The account number for the destination account.
  amount: int # The transfer amount in cents.
  --beneficiary-address-line1: string # The beneficiary's address line 1.
  --beneficiary-address-line2: string # The beneficiary's address line 2.
  --beneficiary-address-line3: string # The beneficiary's address line 3.
  beneficiary_name: string # The beneficiary's name.
  --external-account-id: string # The ID of an External Account to initiate a transfer to. If this parameter is provided, `account_number` and `routing_number` must be absent.
  message_to_recipient: string # The message that will show on the recipient's bank statement.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --routing-number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/wire_transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: account_number, var: account_number}, {name: amount, var: amount}, {name: beneficiary_address_line1, var: beneficiary_address_line1}, {name: beneficiary_address_line2, var: beneficiary_address_line2}, {name: beneficiary_address_line3, var: beneficiary_address_line3}, {name: beneficiary_name, var: beneficiary_name}, {name: external_account_id, var: external_account_id}, {name: message_to_recipient, var: message_to_recipient}, {name: require_approval, var: require_approval}, {name: routing_number, var: routing_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, account_number: $account_number, amount: $amount, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, external_account_id: $external_account_id, message_to_recipient: $message_to_recipient, require_approval: $require_approval, routing_number: $routing_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Wire Transfer
#
# GET /wire_transfers/{wire_transfer_id}
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: retrieve_a_wire_transfer
export def "retrieve-a-wire-transfer" [
  wire_transfer_id: string
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
    path: "/wire_transfers/{wire_transfer_id}"
    path_params: [{name: wire_transfer_id, var: wire_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_transfer_id: $wire_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve a Wire Transfer
#
# POST /wire_transfers/{wire_transfer_id}/approve
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: approve_a_wire_transfer
export def "approve-a-wire-transfer" [
  wire_transfer_id: string
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
    path: "/wire_transfers/{wire_transfer_id}/approve"
    path_params: [{name: wire_transfer_id, var: wire_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_transfer_id: $wire_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a pending Wire Transfer
#
# POST /wire_transfers/{wire_transfer_id}/cancel
# Returns: record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string>
# operationId: cancel_a_pending_wire_transfer
export def "cancel-a-pending-wire-transfer" [
  wire_transfer_id: string
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
    path: "/wire_transfers/{wire_transfer_id}/cancel"
    path_params: [{name: wire_transfer_id, var: wire_transfer_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    wire_transfer_id: $wire_transfer_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
