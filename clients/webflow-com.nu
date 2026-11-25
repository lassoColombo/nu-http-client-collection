# Auto-generated client for Lucidtech API v2023-03-01T16:45:37Z
# Source: https://api.apis.guru/v2/specs/webflow.com/2023-03-01T164537Z/openapi.json
# Auth: --token flag or $env.LUCIDTECH_API_TOKEN

const CLIENT = {
  base_url: "https://api.lucidtech.ai/v1"
  token_env_var: "LUCIDTECH_API_TOKEN"
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

def base-url-completer [] { ["https://api.lucidtech.ai/v1"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def content-type-completer [] { ["application/pdf" "image/jpeg" "image/png" "image/tiff"] }
def instance-type-completer [] { ["large-gpu" "medium-gpu" "small-gpu"] }
def status-completer [] { ["cancelled"] }
def image-quality-completer [] { ["HIGH" "LOW"] }
def rotation-completer [] { ["0" "180" "270" "90"] }
def transition-type-completer [] { ["docker" "manual"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-app-clients: "record<appClients: table<appClientId: string, callbackUrls: list, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list, logoutUrls: list, name: string, updatedBy: string, updatedTime: string>, nextToken: string>"
    options-app-clients: "record"
    post-app-clients: "record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>"
    delete-app-clients-app-client-id: "record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>"
    options-app-clients-app-client-id: "record"
    patch-app-clients-app-client-id: "record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>"
    get-assets: "record<assets: table<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>, nextToken: string>"
    options-assets: "record"
    post-assets: "record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>"
    delete-assets-asset-id: "record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>"
    get-assets-asset-id: "record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>"
    options-assets-asset-id: "record"
    patch-assets-asset-id: "record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>"
    get-datasets: "record<datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, nextToken: string>"
    options-datasets: "record"
    post-datasets: "record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>"
    delete-datasets-dataset-id: "record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>"
    get-datasets-dataset-id: "record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>"
    options-datasets-dataset-id: "record"
    patch-datasets-dataset-id: "record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>"
    get-deployment-environments: "record<deploymentEnvironments: table<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string>, nextToken: string>"
    options-deployment-environments: "record"
    get-deployment-environments-deployment-environment-id: "record<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string>"
    options-deployment-environments-deployment-environment-id: "record"
    delete-documents: "record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string>"
    get-documents: "record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string>"
    options-documents: "record"
    post-documents: "record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>"
    delete-documents-document-id: "record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>"
    get-documents-document-id: "record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>"
    options-documents-document-id: "record"
    patch-documents-document-id: "record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>"
    get-logs: "record<logs: table<events: list, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>, nextToken: string, order: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>"
    options-logs: "record"
    get-logs-log-id: "record<events: list<record>, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>"
    options-logs-log-id: "record"
    get-models: "record<models: table<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>, nextToken: string>"
    options-models: "record"
    post-models: "record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>"
    delete-models-model-id: "record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>"
    get-models-model-id: "record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>"
    options-models-model-id: "record"
    patch-models-model-id: "record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>"
    get-models-model-id-data-bundles: "record<dataBundles: table<createdBy: string, createdTime: string, dataBundleId: string, datasets: list, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>, nextToken: string, status: list<string>>"
    options-models-model-id-data-bundles: "record"
    post-models-model-id-data-bundles: "record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>"
    delete-models-model-id-data-bundles-data-bundle-id: "record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>"
    options-models-model-id-data-bundles-data-bundle-id: "record"
    patch-models-model-id-data-bundles-data-bundle-id: "record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>"
    get-models-model-id-trainings: "record<nextToken: string, status: list<string>, trainings: table<createdBy: string, createdTime: string, dataBundleIds: list, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>>"
    options-models-model-id-trainings: "record"
    post-models-model-id-trainings: "record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>"
    options-models-model-id-trainings-training-id: "record"
    patch-models-model-id-trainings-training-id: "record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>"
    get-organizations: "record<nextToken: string, organizations: table<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>>"
    options-organizations: "record"
    post-organizations: "record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>"
    get-organizations-organization-id: "record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>"
    options-organizations-organization-id: "record"
    patch-organizations-organization-id: "record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>"
    get-payment-methods: "record<nextToken: string, paymentMethods: table<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>>"
    options-payment-methods: "record"
    post-payment-methods: "record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>"
    delete-payment-methods-payment-method-id: "record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>"
    get-payment-methods-payment-method-id: "record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>"
    options-payment-methods-payment-method-id: "record"
    patch-payment-methods-payment-method-id: "record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>"
    get-plans: "record<nextToken: string, plans: table<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string>>"
    options-plans: "record"
    get-plans-plan-id: "record<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string>"
    options-plans-plan-id: "record"
    get-predictions: "record<nextToken: string, order: string, predictions: table<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list, trainingId: string>, sortBy: string>"
    options-predictions: "record"
    post-predictions: "record<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list<any>, trainingId: string>"
    get-profiles-profile-id: "record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string>"
    options-profiles-profile-id: "record"
    patch-profiles-profile-id: "record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string>"
    get-secrets: "record<nextToken: string, secrets: table<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>>"
    options-secrets: "record"
    post-secrets: "record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>"
    delete-secrets-secret-id: "record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>"
    options-secrets-secret-id: "record"
    patch-secrets-secret-id: "record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>"
    options-signup: "record"
    post-signup: "record<clientId: string, username: string>"
    get-transitions: "record<nextToken: string, transitionType: list<string>, transitions: table<assets: record, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>>"
    options-transitions: "record"
    post-transitions: "record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>"
    delete-transitions-transition-id: "record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>"
    get-transitions-transition-id: "record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>"
    options-transitions-transition-id: "record"
    patch-transitions-transition-id: "record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>"
    get-transitions-transition-id-executions: "record<executions: table<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>, nextToken: string, status: list<string>, transitionId: any>"
    options-transitions-transition-id-executions: "record"
    post-transitions-transition-id-executions: "record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>"
    get-transitions-transition-id-executions-execution-id: "record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>"
    options-transitions-transition-id-executions-execution-id: "record"
    patch-transitions-transition-id-executions-execution-id: "record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>"
    options-transitions-transition-id-executions-execution-id-heartbeats: "record"
    post-transitions-transition-id-executions-execution-id-heartbeats: "record"
    get-users: "record<nextToken: string, users: table<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>>"
    options-users: "record"
    post-users: "record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>"
    delete-users-user-id: "record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>"
    get-users-user-id: "record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>"
    options-users-user-id: "record"
    patch-users-user-id: "record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>"
    get-workflows: "record<nextToken: string, workflows: table<completedConfig: record, createdBy: string, createdTime: string, description: string, errorConfig: record, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>>"
    options-workflows: "record"
    post-workflows: "record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>"
    delete-workflows-workflow-id: "record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>"
    get-workflows-workflow-id: "record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>"
    options-workflows-workflow-id: "record"
    patch-workflows-workflow-id: "record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>"
    get-workflows-workflow-id-executions: "record<executions: table<completedBy: list, completedTaskLogId: string, endTime: string, events: list, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>, nextToken: string, order: string, sortBy: string, status: list<string>, workflowId: string>"
    options-workflows-workflow-id-executions: "record"
    post-workflows-workflow-id-executions: "record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>"
    delete-workflows-workflow-id-executions-execution-id: "record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>"
    get-workflows-workflow-id-executions-execution-id: "record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>"
    options-workflows-workflow-id-executions-execution-id: "record"
    patch-workflows-workflow-id-executions-execution-id: "record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-app-clients" "options-app-clients" "post-app-clients" "delete-app-clients-app-client-id" "options-app-clients-app-client-id" "patch-app-clients-app-client-id" "get-assets" "options-assets" "post-assets" "delete-assets-asset-id" "get-assets-asset-id" "options-assets-asset-id" "patch-assets-asset-id" "get-datasets" "options-datasets" "post-datasets" "delete-datasets-dataset-id" "get-datasets-dataset-id" "options-datasets-dataset-id" "patch-datasets-dataset-id" "get-deployment-environments" "options-deployment-environments" "get-deployment-environments-deployment-environment-id" "options-deployment-environments-deployment-environment-id" "delete-documents" "get-documents" "options-documents" "post-documents" "delete-documents-document-id" "get-documents-document-id" "options-documents-document-id" "patch-documents-document-id" "get-logs" "options-logs" "get-logs-log-id" "options-logs-log-id" "get-models" "options-models" "post-models" "delete-models-model-id" "get-models-model-id" "options-models-model-id" "patch-models-model-id" "get-models-model-id-data-bundles" "options-models-model-id-data-bundles" "post-models-model-id-data-bundles" "delete-models-model-id-data-bundles-data-bundle-id" "options-models-model-id-data-bundles-data-bundle-id" "patch-models-model-id-data-bundles-data-bundle-id" "get-models-model-id-trainings" "options-models-model-id-trainings" "post-models-model-id-trainings" "options-models-model-id-trainings-training-id" "patch-models-model-id-trainings-training-id" "get-organizations" "options-organizations" "post-organizations" "get-organizations-organization-id" "options-organizations-organization-id" "patch-organizations-organization-id" "get-payment-methods" "options-payment-methods" "post-payment-methods" "delete-payment-methods-payment-method-id" "get-payment-methods-payment-method-id" "options-payment-methods-payment-method-id" "patch-payment-methods-payment-method-id" "get-plans" "options-plans" "get-plans-plan-id" "options-plans-plan-id" "get-predictions" "options-predictions" "post-predictions" "get-profiles-profile-id" "options-profiles-profile-id" "patch-profiles-profile-id" "get-secrets" "options-secrets" "post-secrets" "delete-secrets-secret-id" "options-secrets-secret-id" "patch-secrets-secret-id" "options-signup" "post-signup" "get-transitions" "options-transitions" "post-transitions" "delete-transitions-transition-id" "get-transitions-transition-id" "options-transitions-transition-id" "patch-transitions-transition-id" "get-transitions-transition-id-executions" "options-transitions-transition-id-executions" "post-transitions-transition-id-executions" "get-transitions-transition-id-executions-execution-id" "options-transitions-transition-id-executions-execution-id" "patch-transitions-transition-id-executions-execution-id" "options-transitions-transition-id-executions-execution-id-heartbeats" "post-transitions-transition-id-executions-execution-id-heartbeats" "get-users" "options-users" "post-users" "delete-users-user-id" "get-users-user-id" "options-users-user-id" "patch-users-user-id" "get-workflows" "options-workflows" "post-workflows" "delete-workflows-workflow-id" "get-workflows-workflow-id" "options-workflows-workflow-id" "patch-workflows-workflow-id" "get-workflows-workflow-id-executions" "options-workflows-workflow-id-executions" "post-workflows-workflow-id-executions" "delete-workflows-workflow-id-executions-execution-id" "get-workflows-workflow-id-executions-execution-id" "options-workflows-workflow-id-executions-execution-id" "patch-workflows-workflow-id-executions-execution-id" "commands"] | sort) } | get name | first)
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

# GET /appClients
#
# Returns: record<appClients: table<appClientId: string, callbackUrls: list, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list, logoutUrls: list, name: string, updatedBy: string, updatedTime: string>, nextToken: string>
export def "get-app-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/appClients"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /appClients
#
# Returns: record
export def "options-app-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/appClients"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /appClients
#
# Returns: record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>
export def "post-app-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --callback-urls: list<string>
  --default-login-url: string
  --description: string # nullable
  --generate-secret: oneof<nothing, bool> # default: true
  --login-urls: list<string>
  --logout-urls: list<string>
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/appClients"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: callbackUrls, var: callback_urls}, {name: defaultLoginUrl, var: default_login_url}, {name: description, var: description}, {name: generateSecret, var: generate_secret}, {name: loginUrls, var: login_urls}, {name: logoutUrls, var: logout_urls}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, callback_urls: $callback_urls, default_login_url: $default_login_url, description: $description, generate_secret: $generate_secret, login_urls: $login_urls, logout_urls: $logout_urls, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /appClients/{appClientId}
#
# Returns: record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>
export def "delete-app-clients-app-client-id" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/appClients/{appClientId}"
    path_params: [{name: appClientId, var: app_client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    app_client_id: $app_client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /appClients/{appClientId}
#
# Returns: record
export def "options-app-clients-app-client-id" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/appClients/{appClientId}"
    path_params: [{name: appClientId, var: app_client_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_client_id: $app_client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /appClients/{appClientId}
#
# Returns: record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string>
export def "patch-app-clients-app-client-id" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --default-login-url: string
  --description: string # nullable
  --login-urls: list<string>
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/appClients/{appClientId}"
    path_params: [{name: appClientId, var: app_client_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultLoginUrl, var: default_login_url}, {name: description, var: description}, {name: loginUrls, var: login_urls}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_client_id: $app_client_id, content_type: $content_type, default_login_url: $default_login_url, description: $description, login_urls: $login_urls, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /assets
#
# Returns: record<assets: table<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>, nextToken: string>
export def "get-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/assets"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /assets
#
# Returns: record
export def "options-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/assets"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /assets
#
# Returns: record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>
export def "post-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  content: string
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/assets"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, content: $content, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /assets/{assetId}
#
# Returns: record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>
export def "delete-assets-asset-id" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /assets/{assetId}
#
# Returns: record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>
export def "get-assets-asset-id" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /assets/{assetId}
#
# Returns: record
export def "options-assets-asset-id" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /assets/{assetId}
#
# Returns: record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>
export def "patch-assets-asset-id" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --content: string
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/assets/{assetId}"
    path_params: [{name: assetId, var: asset_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    asset_id: $asset_id, content_type: $content_type, content: $content, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /datasets
#
# Returns: record<datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, nextToken: string>
export def "get-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/datasets"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /datasets
#
# Returns: record
export def "options-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/datasets"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /datasets
#
# Returns: record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>
export def "post-datasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --contains-personally-identifiable-information: oneof<nothing, bool>
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/datasets"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containsPersonallyIdentifiableInformation, var: contains_personally_identifiable_information}, {name: description, var: description}, {name: metadata, var: metadata}, {name: name, var: name}, {name: retentionInDays, var: retention_in_days}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, contains_personally_identifiable_information: $contains_personally_identifiable_information, description: $description, metadata: $metadata, name: $name, retention_in_days: $retention_in_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /datasets/{datasetId}
#
# Returns: record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>
export def "delete-datasets-dataset-id" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /datasets/{datasetId}
#
# Returns: record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>
export def "get-datasets-dataset-id" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /datasets/{datasetId}
#
# Returns: record
export def "options-datasets-dataset-id" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /datasets/{datasetId}
#
# Returns: record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>
export def "patch-datasets-dataset-id" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --contains-personally-identifiable-information: oneof<nothing, bool>
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/datasets/{datasetId}"
    path_params: [{name: datasetId, var: dataset_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: containsPersonallyIdentifiableInformation, var: contains_personally_identifiable_information}, {name: description, var: description}, {name: metadata, var: metadata}, {name: name, var: name}, {name: retentionInDays, var: retention_in_days}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, content_type: $content_type, contains_personally_identifiable_information: $contains_personally_identifiable_information, description: $description, metadata: $metadata, name: $name, retention_in_days: $retention_in_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /deploymentEnvironments
#
# Returns: record<deploymentEnvironments: table<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string>, nextToken: string>
export def "get-deployment-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deploymentEnvironments"
    query: [{name: owner, var: owner}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /deploymentEnvironments
#
# Returns: record
export def "options-deployment-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/deploymentEnvironments"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /deploymentEnvironments/{deploymentEnvironmentId}
#
# Returns: record<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string>
export def "get-deployment-environments-deployment-environment-id" [
  deployment_environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/deploymentEnvironments/{deploymentEnvironmentId}"
    path_params: [{name: deploymentEnvironmentId, var: deployment_environment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /deploymentEnvironments/{deploymentEnvironmentId}
#
# Returns: record
export def "options-deployment-environments-deployment-environment-id" [
  deployment_environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/deploymentEnvironments/{deploymentEnvironmentId}"
    path_params: [{name: deploymentEnvironmentId, var: deployment_environment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_environment_id: $deployment_environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /documents
#
# Returns: record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string>
export def "delete-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --consent-id: string
  --dataset-id: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/documents"
    query: [{name: consentId, var: consent_id}, {name: datasetId, var: dataset_id}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent_id: $consent_id, dataset_id: $dataset_id, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /documents
#
# Returns: record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string>
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
  --dataset-id: string
  --next-token: string
  --order: string
  --document-id: string
  --consent-id: string
  --max-results: string
  --sort-by: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents"
    query: [{name: datasetId, var: dataset_id}, {name: nextToken, var: next_token}, {name: order, var: order}, {name: documentId, var: document_id}, {name: consentId, var: consent_id}, {name: maxResults, var: max_results}, {name: sortBy, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dataset_id: $dataset_id, next_token: $next_token, order: $order, document_id: $document_id, consent_id: $consent_id, max_results: $max_results, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /documents
#
# Returns: record
export def "options-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/documents"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /documents
#
# Returns: record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>
export def "post-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --consent-id: string
  content: string
  --body-content-type: string@content-type-completer # nullable (spec name: contentType)
  --dataset-id: string
  --description: string # nullable
  --ground-truth: list # item shape: {label: string, value: any}
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/documents"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: consentId, var: consent_id}, {name: content, var: content}, {name: contentType, var: body_content_type}, {name: datasetId, var: dataset_id}, {name: description, var: description}, {name: groundTruth, var: ground_truth}, {name: metadata, var: metadata}, {name: name, var: name}, {name: retentionInDays, var: retention_in_days}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, consent_id: $consent_id, content: $content, body_content_type: $body_content_type, dataset_id: $dataset_id, description: $description, ground_truth: $ground_truth, metadata: $metadata, name: $name, retention_in_days: $retention_in_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /documents/{documentId}
#
# Returns: record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>
export def "delete-documents-document-id" [
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
    method: delete
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

# GET /documents/{documentId}
#
# Returns: record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>
export def "get-documents-document-id" [
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

# OPTIONS /documents/{documentId}
#
# Returns: record
export def "options-documents-document-id" [
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
    method: options
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

# PATCH /documents/{documentId}
#
# Returns: record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>
export def "patch-documents-document-id" [
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
  --content-type: string # required
  --dataset-id: string
  --description: string # nullable
  --ground-truth: list # nullable — item shape: {label: string, value: any}
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/documents/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetId, var: dataset_id}, {name: description, var: description}, {name: groundTruth, var: ground_truth}, {name: metadata, var: metadata}, {name: name, var: name}, {name: retentionInDays, var: retention_in_days}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id, content_type: $content_type, dataset_id: $dataset_id, description: $description, ground_truth: $ground_truth, metadata: $metadata, name: $name, retention_in_days: $retention_in_days
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /logs
#
# Returns: record<logs: table<events: list, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>, nextToken: string, order: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>
export def "get-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-id: string
  --next-token: string
  --order: string
  --transition-execution-id: string
  --transition-id: string
  --max-results: string
  --workflow-execution-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/logs"
    query: [{name: workflowId, var: workflow_id}, {name: nextToken, var: next_token}, {name: order, var: order}, {name: transitionExecutionId, var: transition_execution_id}, {name: transitionId, var: transition_id}, {name: maxResults, var: max_results}, {name: workflowExecutionId, var: workflow_execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, next_token: $next_token, order: $order, transition_execution_id: $transition_execution_id, transition_id: $transition_id, max_results: $max_results, workflow_execution_id: $workflow_execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /logs
#
# Returns: record
export def "options-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/logs"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /logs/{logId}
#
# Returns: record<events: list<record>, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>
export def "get-logs-log-id" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/logs/{logId}"
    path_params: [{name: logId, var: log_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    log_id: $log_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /logs/{logId}
#
# Returns: record
export def "options-logs-log-id" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/logs/{logId}"
    path_params: [{name: logId, var: log_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    log_id: $log_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /models
#
# Returns: record<models: table<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>, nextToken: string>
export def "get-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/models"
    query: [{name: owner, var: owner}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models
#
# Returns: record
export def "options-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /models
#
# Returns: record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>
export def "post-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  field_config: record
  --height: int
  --metadata: record
  --name: string # nullable
  --postprocess-config: any
  --preprocess-config: record # shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
  --width: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/models"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: fieldConfig, var: field_config}, {name: height, var: height}, {name: metadata, var: metadata}, {name: name, var: name}, {name: postprocessConfig, var: postprocess_config}, {name: preprocessConfig, var: preprocess_config}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, description: $description, field_config: $field_config, height: $height, metadata: $metadata, name: $name, postprocess_config: $postprocess_config, preprocess_config: $preprocess_config, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /models/{modelId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>
export def "delete-models-model-id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /models/{modelId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>
export def "get-models-model-id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models/{modelId}
#
# Returns: record
export def "options-models-model-id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /models/{modelId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>
export def "patch-models-model-id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --field-config: record
  --height: int
  --metadata: record
  --name: string # nullable
  --postprocess-config: any
  --preprocess-config: record # shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
  --training-id: string # nullable
  --width: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/models/{modelId}"
    path_params: [{name: modelId, var: model_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: fieldConfig, var: field_config}, {name: height, var: height}, {name: metadata, var: metadata}, {name: name, var: name}, {name: postprocessConfig, var: postprocess_config}, {name: preprocessConfig, var: preprocess_config}, {name: trainingId, var: training_id}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, content_type: $content_type, description: $description, field_config: $field_config, height: $height, metadata: $metadata, name: $name, postprocess_config: $postprocess_config, preprocess_config: $preprocess_config, training_id: $training_id, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /models/{modelId}/dataBundles
#
# Returns: record<dataBundles: table<createdBy: string, createdTime: string, dataBundleId: string, datasets: list, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>, nextToken: string, status: list<string>>
export def "get-models-model-id-data-bundles" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/models/{modelId}/dataBundles"
    path_params: [{name: modelId, var: model_id}]
    query: [{name: status, var: status}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, status: $status, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models/{modelId}/dataBundles
#
# Returns: record
export def "options-models-model-id-data-bundles" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models/{modelId}/dataBundles"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /models/{modelId}/dataBundles
#
# Returns: record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>
export def "post-models-model-id-data-bundles" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --dataset-ids: list<string>
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/models/{modelId}/dataBundles"
    path_params: [{name: modelId, var: model_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: datasetIds, var: dataset_ids}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, content_type: $content_type, dataset_ids: $dataset_ids, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /models/{modelId}/dataBundles/{dataBundleId}
#
# Returns: record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>
export def "delete-models-model-id-data-bundles-data-bundle-id" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/models/{modelId}/dataBundles/{dataBundleId}"
    path_params: [{name: modelId, var: model_id}, {name: dataBundleId, var: data_bundle_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    model_id: $model_id, data_bundle_id: $data_bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models/{modelId}/dataBundles/{dataBundleId}
#
# Returns: record
export def "options-models-model-id-data-bundles-data-bundle-id" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models/{modelId}/dataBundles/{dataBundleId}"
    path_params: [{name: modelId, var: model_id}, {name: dataBundleId, var: data_bundle_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, data_bundle_id: $data_bundle_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /models/{modelId}/dataBundles/{dataBundleId}
#
# Returns: record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>
export def "patch-models-model-id-data-bundles-data-bundle-id" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/models/{modelId}/dataBundles/{dataBundleId}"
    path_params: [{name: modelId, var: model_id}, {name: dataBundleId, var: data_bundle_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, data_bundle_id: $data_bundle_id, content_type: $content_type, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /models/{modelId}/trainings
#
# Returns: record<nextToken: string, status: list<string>, trainings: table<createdBy: string, createdTime: string, dataBundleIds: list, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>>
export def "get-models-model-id-trainings" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/models/{modelId}/trainings"
    path_params: [{name: modelId, var: model_id}]
    query: [{name: status, var: status}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, status: $status, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models/{modelId}/trainings
#
# Returns: record
export def "options-models-model-id-trainings" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models/{modelId}/trainings"
    path_params: [{name: modelId, var: model_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /models/{modelId}/trainings
#
# Returns: record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>
export def "post-models-model-id-trainings" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --data-bundle-ids: list<string>
  --data-scientist-assistance: oneof<nothing, bool>
  --description: string # nullable
  --instance-type: string@instance-type-completer # nullable
  --metadata: record
  --name: string # nullable
  --warm-start-config: record # shape: {trainingId: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/models/{modelId}/trainings"
    path_params: [{name: modelId, var: model_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataBundleIds, var: data_bundle_ids}, {name: dataScientistAssistance, var: data_scientist_assistance}, {name: description, var: description}, {name: instanceType, var: instance_type}, {name: metadata, var: metadata}, {name: name, var: name}, {name: warmStartConfig, var: warm_start_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, content_type: $content_type, data_bundle_ids: $data_bundle_ids, data_scientist_assistance: $data_scientist_assistance, description: $description, instance_type: $instance_type, metadata: $metadata, name: $name, warm_start_config: $warm_start_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /models/{modelId}/trainings/{trainingId}
#
# Returns: record
export def "options-models-model-id-trainings-training-id" [
  model_id: string
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/models/{modelId}/trainings/{trainingId}"
    path_params: [{name: modelId, var: model_id}, {name: trainingId, var: training_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, training_id: $training_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /models/{modelId}/trainings/{trainingId}
#
# Returns: record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>
export def "patch-models-model-id-trainings-training-id" [
  model_id: string
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --deployment-environment-id: string # nullable
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --status: string@status-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/models/{modelId}/trainings/{trainingId}"
    path_params: [{name: modelId, var: model_id}, {name: trainingId, var: training_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentEnvironmentId, var: deployment_environment_id}, {name: description, var: description}, {name: metadata, var: metadata}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    model_id: $model_id, training_id: $training_id, content_type: $content_type, deployment_environment_id: $deployment_environment_id, description: $description, metadata: $metadata, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organizations
#
# Returns: record<nextToken: string, organizations: table<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>>
export def "get-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organizations"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /organizations
#
# Returns: record
export def "options-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/organizations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /organizations
#
# Returns: record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>
export def "post-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /organizations/{organizationId}
#
# Returns: record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>
export def "get-organizations-organization-id" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /organizations/{organizationId}
#
# Returns: record
export def "options-organizations-organization-id" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /organizations/{organizationId}
#
# Returns: record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>
export def "patch-organizations-organization-id" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --name: string # nullable
  --payment-method-id: string
  --plan-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/organizations/{organizationId}"
    path_params: [{name: organizationId, var: organization_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: paymentMethodId, var: payment_method_id}, {name: planId, var: plan_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_id: $organization_id, content_type: $content_type, description: $description, name: $name, payment_method_id: $payment_method_id, plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /paymentMethods
#
# Returns: record<nextToken: string, paymentMethods: table<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>>
export def "get-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/paymentMethods"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /paymentMethods
#
# Returns: record
export def "options-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/paymentMethods"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /paymentMethods
#
# Returns: record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>
export def "post-payment-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/paymentMethods"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /paymentMethods/{paymentMethodId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>
export def "delete-payment-methods-payment-method-id" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/paymentMethods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /paymentMethods/{paymentMethodId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>
export def "get-payment-methods-payment-method-id" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/paymentMethods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /paymentMethods/{paymentMethodId}
#
# Returns: record
export def "options-payment-methods-payment-method-id" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/paymentMethods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_method_id: $payment_method_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /paymentMethods/{paymentMethodId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>
export def "patch-payment-methods-payment-method-id" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --name: string # nullable
  --stripe-setup-intent-secret: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/paymentMethods/{paymentMethodId}"
    path_params: [{name: paymentMethodId, var: payment_method_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: stripeSetupIntentSecret, var: stripe_setup_intent_secret}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    payment_method_id: $payment_method_id, content_type: $content_type, description: $description, name: $name, stripe_setup_intent_secret: $stripe_setup_intent_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /plans
#
# Returns: record<nextToken: string, plans: table<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string>>
export def "get-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/plans"
    query: [{name: owner, var: owner}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    owner: $owner, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /plans
#
# Returns: record
export def "options-plans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/plans"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /plans/{planId}
#
# Returns: record<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string>
export def "get-plans-plan-id" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/plans/{planId}"
    path_params: [{name: planId, var: plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /plans/{planId}
#
# Returns: record
export def "options-plans-plan-id" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/plans/{planId}"
    path_params: [{name: planId, var: plan_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    plan_id: $plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /predictions
#
# Returns: record<nextToken: string, order: string, predictions: table<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list, trainingId: string>, sortBy: string>
export def "get-predictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
  --sort-by: string
  --order: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/predictions"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}, {name: sortBy, var: sort_by}, {name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, sort_by: $sort_by, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /predictions
#
# Returns: record
export def "options-predictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/predictions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /predictions
#
# Returns: record<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list<any>, trainingId: string>
export def "post-predictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --auto-rotate: oneof<nothing, bool>
  document_id: string
  --image-quality: string@image-quality-completer
  --max-pages: int
  model_id: string
  --postprocess-config: any
  --rotation: int@rotation-completer
  --training-id: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/predictions"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoRotate, var: auto_rotate}, {name: documentId, var: document_id}, {name: imageQuality, var: image_quality}, {name: maxPages, var: max_pages}, {name: modelId, var: model_id}, {name: postprocessConfig, var: postprocess_config}, {name: rotation, var: rotation}, {name: trainingId, var: training_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, auto_rotate: $auto_rotate, document_id: $document_id, image_quality: $image_quality, max_pages: $max_pages, model_id: $model_id, postprocess_config: $postprocess_config, rotation: $rotation, training_id: $training_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /profiles/{profileId}
#
# Returns: record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string>
export def "get-profiles-profile-id" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_id: $profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /profiles/{profileId}
#
# Returns: record
export def "options-profiles-profile-id" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_id: $profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /profiles/{profileId}
#
# Returns: record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string>
export def "patch-profiles-profile-id" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/profiles/{profileId}"
    path_params: [{name: profileId, var: profile_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_id: $profile_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /secrets
#
# Returns: record<nextToken: string, secrets: table<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>>
export def "get-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/secrets"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /secrets
#
# Returns: record
export def "options-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/secrets"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /secrets
#
# Returns: record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>
export def "post-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  data: record
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/secrets"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, data: $data, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /secrets/{secretId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>
export def "delete-secrets-secret-id" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/secrets/{secretId}"
    path_params: [{name: secretId, var: secret_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    secret_id: $secret_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /secrets/{secretId}
#
# Returns: record
export def "options-secrets-secret-id" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/secrets/{secretId}"
    path_params: [{name: secretId, var: secret_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_id: $secret_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /secrets/{secretId}
#
# Returns: record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>
export def "patch-secrets-secret-id" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --data: record
  --description: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/secrets/{secretId}"
    path_params: [{name: secretId, var: secret_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_id: $secret_id, content_type: $content_type, data: $data, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /signup
#
# Returns: record
export def "options-signup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/signup"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /signup
#
# Returns: record<clientId: string, username: string>
export def "post-signup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  email: string
  --name: string # nullable
  password: string
  re_captcha_response: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/signup"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: name, var: name}, {name: password, var: password}, {name: reCaptchaResponse, var: re_captcha_response}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, email: $email, name: $name, password: $password, re_captcha_response: $re_captcha_response
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /transitions
#
# Returns: record<nextToken: string, transitionType: list<string>, transitions: table<assets: record, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>>
export def "get-transitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transition-type: string
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transitions"
    query: [{name: transitionType, var: transition_type}, {name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_type: $transition_type, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /transitions
#
# Returns: record
export def "options-transitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/transitions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /transitions
#
# Returns: record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>
export def "post-transitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --description: string # nullable
  --input-json-schema: record
  --name: string # nullable
  --output-json-schema: record
  --parameters: any
  --timeout-in-seconds: int
  transition_type: string@transition-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transitions"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: inputJsonSchema, var: input_json_schema}, {name: name, var: name}, {name: outputJsonSchema, var: output_json_schema}, {name: parameters, var: parameters}, {name: timeoutInSeconds, var: timeout_in_seconds}, {name: transitionType, var: transition_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, description: $description, input_json_schema: $input_json_schema, name: $name, output_json_schema: $output_json_schema, parameters: $parameters, timeout_in_seconds: $timeout_in_seconds, transition_type: $transition_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /transitions/{transitionId}
#
# Returns: record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>
export def "delete-transitions-transition-id" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/transitions/{transitionId}"
    path_params: [{name: transitionId, var: transition_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /transitions/{transitionId}
#
# Returns: record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>
export def "get-transitions-transition-id" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/transitions/{transitionId}"
    path_params: [{name: transitionId, var: transition_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /transitions/{transitionId}
#
# Returns: record
export def "options-transitions-transition-id" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/transitions/{transitionId}"
    path_params: [{name: transitionId, var: transition_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /transitions/{transitionId}
#
# Returns: record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>
export def "patch-transitions-transition-id" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --assets: record # shape: {jsRemoteComponent?: string}
  --description: string # nullable
  --environment: record
  --environment-secrets: list<string>
  --input-json-schema: record
  --name: string # nullable
  --output-json-schema: record
  --parameters: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transitions/{transitionId}"
    path_params: [{name: transitionId, var: transition_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: assets, var: assets}, {name: description, var: description}, {name: environment, var: environment}, {name: environmentSecrets, var: environment_secrets}, {name: inputJsonSchema, var: input_json_schema}, {name: name, var: name}, {name: outputJsonSchema, var: output_json_schema}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, content_type: $content_type, assets: $assets, description: $description, environment: $environment, environment_secrets: $environment_secrets, input_json_schema: $input_json_schema, name: $name, output_json_schema: $output_json_schema, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /transitions/{transitionId}/executions
#
# Returns: record<executions: table<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>, nextToken: string, status: list<string>, transitionId: any>
export def "get-transitions-transition-id-executions" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --order: string
  --execution-id: string
  --status: string
  --max-results: string
  --sort-by: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transitions/{transitionId}/executions"
    path_params: [{name: transitionId, var: transition_id}]
    query: [{name: nextToken, var: next_token}, {name: order, var: order}, {name: executionId, var: execution_id}, {name: status, var: status}, {name: maxResults, var: max_results}, {name: sortBy, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, next_token: $next_token, order: $order, execution_id: $execution_id, status: $status, max_results: $max_results, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /transitions/{transitionId}/executions
#
# Returns: record
export def "options-transitions-transition-id-executions" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/transitions/{transitionId}/executions"
    path_params: [{name: transitionId, var: transition_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /transitions/{transitionId}/executions
#
# Returns: record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>
export def "post-transitions-transition-id-executions" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transitions/{transitionId}/executions"
    path_params: [{name: transitionId, var: transition_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /transitions/{transitionId}/executions/{executionId}
#
# Returns: record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>
export def "get-transitions-transition-id-executions-execution-id" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/transitions/{transitionId}/executions/{executionId}"
    path_params: [{name: transitionId, var: transition_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /transitions/{transitionId}/executions/{executionId}
#
# Returns: record
export def "options-transitions-transition-id-executions-execution-id" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/transitions/{transitionId}/executions/{executionId}"
    path_params: [{name: transitionId, var: transition_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /transitions/{transitionId}/executions/{executionId}
#
# Returns: record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>
export def "patch-transitions-transition-id-executions-execution-id" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --error: record # shape: {message: string}
  --output: record
  --start-time: string # nullable
  --status: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/transitions/{transitionId}/executions/{executionId}"
    path_params: [{name: transitionId, var: transition_id}, {name: executionId, var: execution_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: error, var: error}, {name: output, var: output}, {name: startTime, var: start_time}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, execution_id: $execution_id, content_type: $content_type, error: $error, output: $output, start_time: $start_time, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /transitions/{transitionId}/executions/{executionId}/heartbeats
#
# Returns: record
export def "options-transitions-transition-id-executions-execution-id-heartbeats" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/transitions/{transitionId}/executions/{executionId}/heartbeats"
    path_params: [{name: transitionId, var: transition_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transition_id: $transition_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /transitions/{transitionId}/executions/{executionId}/heartbeats
#
# Returns: record
export def "post-transitions-transition-id-executions-execution-id-heartbeats" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transitions/{transitionId}/executions/{executionId}/heartbeats"
    path_params: [{name: transitionId, var: transition_id}, {name: executionId, var: execution_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    transition_id: $transition_id, execution_id: $execution_id, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /users
#
# Returns: record<nextToken: string, users: table<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>>
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
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /users
#
# Returns: record
export def "options-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /users
#
# Returns: record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>
export def "post-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --app-client-id: string
  --avatar: string # nullable
  email: string
  --metadata: record
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: appClientId, var: app_client_id}, {name: avatar, var: avatar}, {name: email, var: email}, {name: metadata, var: metadata}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, app_client_id: $app_client_id, avatar: $avatar, email: $email, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /users/{userId}
#
# Returns: record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>
export def "delete-users-user-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /users/{userId}
#
# Returns: record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>
export def "get-users-user-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /users/{userId}
#
# Returns: record
export def "options-users-user-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /users/{userId}
#
# Returns: record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>
export def "patch-users-user-id" [
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
  --content-type: string # required
  --avatar: string # nullable
  --metadata: record
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: metadata, var: metadata}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, content_type: $content_type, avatar: $avatar, metadata: $metadata, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /workflows
#
# Returns: record<nextToken: string, workflows: table<completedConfig: record, createdBy: string, createdTime: string, description: string, errorConfig: record, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>>
export def "get-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows"
    query: [{name: nextToken, var: next_token}, {name: maxResults, var: max_results}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /workflows
#
# Returns: record
export def "options-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/workflows"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /workflows
#
# Returns: record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>
export def "post-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --completed-config: record # shape: {environment?: record, environmentSecrets?: list<string>, imageUrl: string, secretId?: string}
  --description: string # nullable
  --error-config: record # shape: {email?: string, manualRetry?: bool}
  --name: string # nullable
  specification: record # shape: {definition: record, language?: "ASL", version?: "1.0.0"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workflows"
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: completedConfig, var: completed_config}, {name: description, var: description}, {name: errorConfig, var: error_config}, {name: name, var: name}, {name: specification, var: specification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content_type: $content_type, completed_config: $completed_config, description: $description, error_config: $error_config, name: $name, specification: $specification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /workflows/{workflowId}
#
# Returns: record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>
export def "delete-workflows-workflow-id" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workflows/{workflowId}"
    path_params: [{name: workflowId, var: workflow_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /workflows/{workflowId}
#
# Returns: record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>
export def "get-workflows-workflow-id" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workflows/{workflowId}"
    path_params: [{name: workflowId, var: workflow_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /workflows/{workflowId}
#
# Returns: record
export def "options-workflows-workflow-id" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/workflows/{workflowId}"
    path_params: [{name: workflowId, var: workflow_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /workflows/{workflowId}
#
# Returns: record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>
export def "patch-workflows-workflow-id" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  --completed-config: record # shape: {environment?: record, environmentSecrets?: list<string>, imageUrl: string, secretId?: string}
  --description: string # nullable
  --error-config: record # shape: {email?: string, manualRetry?: bool}
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workflows/{workflowId}"
    path_params: [{name: workflowId, var: workflow_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: completedConfig, var: completed_config}, {name: description, var: description}, {name: errorConfig, var: error_config}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, content_type: $content_type, completed_config: $completed_config, description: $description, error_config: $error_config, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /workflows/{workflowId}/executions
#
# Returns: record<executions: table<completedBy: list, completedTaskLogId: string, endTime: string, events: list, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>, nextToken: string, order: string, sortBy: string, status: list<string>, workflowId: string>
export def "get-workflows-workflow-id-executions" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-start-time: string
  --to-start-time: string
  --next-token: string
  --order: string
  --status: string
  --max-results: string
  --sort-by: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workflows/{workflowId}/executions"
    path_params: [{name: workflowId, var: workflow_id}]
    query: [{name: fromStartTime, var: from_start_time}, {name: toStartTime, var: to_start_time}, {name: nextToken, var: next_token}, {name: order, var: order}, {name: status, var: status}, {name: maxResults, var: max_results}, {name: sortBy, var: sort_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, from_start_time: $from_start_time, to_start_time: $to_start_time, next_token: $next_token, order: $order, status: $status, max_results: $max_results, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /workflows/{workflowId}/executions
#
# Returns: record
export def "options-workflows-workflow-id-executions" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/workflows/{workflowId}/executions"
    path_params: [{name: workflowId, var: workflow_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /workflows/{workflowId}/executions
#
# Returns: record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>
export def "post-workflows-workflow-id-executions" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  input: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workflows/{workflowId}/executions"
    path_params: [{name: workflowId, var: workflow_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, content_type: $content_type, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /workflows/{workflowId}/executions/{executionId}
#
# Returns: record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>
export def "delete-workflows-workflow-id-executions-execution-id" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workflows/{workflowId}/executions/{executionId}"
    path_params: [{name: workflowId, var: workflow_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /workflows/{workflowId}/executions/{executionId}
#
# Returns: record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>
export def "get-workflows-workflow-id-executions-execution-id" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/workflows/{workflowId}/executions/{executionId}"
    path_params: [{name: workflowId, var: workflow_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# OPTIONS /workflows/{workflowId}/executions/{executionId}
#
# Returns: record
export def "options-workflows-workflow-id-executions-execution-id" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: options
    path: "/workflows/{workflowId}/executions/{executionId}"
    path_params: [{name: workflowId, var: workflow_id}, {name: executionId, var: execution_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, execution_id: $execution_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /workflows/{workflowId}/executions/{executionId}
#
# Returns: record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>
export def "patch-workflows-workflow-id-executions-execution-id" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # required
  next_transition_id: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workflows/{workflowId}/executions/{executionId}"
    path_params: [{name: workflowId, var: workflow_id}, {name: executionId, var: execution_id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextTransitionId, var: next_transition_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workflow_id: $workflow_id, execution_id: $execution_id, content_type: $content_type, next_transition_id: $next_transition_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
