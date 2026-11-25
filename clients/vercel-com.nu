# Auto-generated client for Vercel API v0.0.1
# Source: https://api.apis.guru/v2/specs/vercel.com/0.0.1/openapi.json
# Auth: --token flag or $env.VERCEL_API_TOKEN

const CLIENT = {
  base_url: "https://api.vercel.com"
  token_env_var: "VERCEL_API_TOKEN"
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

def base-url-completer [] { ["https://api.vercel.com"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def conclusion-completer [] { ["canceled" "failed" "neutral" "skipped" "succeeded"] }
def status-completer [] { ["completed" "running"] }
def type-completer [] { ["A" "AAAA" "ALIAS" "CAA" "CNAME" "MX" "NS" "SRV" "TXT"] }
def view-completer [] { ["account" "project"] }
def provider-completer [] { ["bitbucket" "github" "gitlab"] }
def delivery-format-completer [] { ["json" "ndjson"] }
def environment-completer [] { ["preview" "production"] }
def confirmed-completer [] { ["true"] }
def type-completer-1 [] { ["encrypted" "plain" "secret" "sensitive" "system"] }
def force-new-completer [] { ["0" "1"] }
def skip-auto-detection-confirmation-completer [] { ["0" "1"] }
def framework-completer [] { ["angular" "astro" "blitzjs" "brunch" "create-react-app" "docusaurus" "docusaurus-2" "dojo" "eleventy" "ember" "gatsby" "gridsome" "hexo" "hugo" "hydrogen" "ionic-angular" "ionic-react" "jekyll" "middleman" "nextjs" "nuxtjs" "parcel" "polymer" "preact" "redwoodjs" "remix" "saber" "sanity" "sapper" "scully" "solidstart" "stencil" "svelte" "sveltekit" "sveltekit-1" "umijs" "vite" "vitepress" "vue" "vuepress" "zola"] }
def target-completer [] { ["production" "staging"] }
def direction-completer [] { ["backward" "forward"] }
def follow-completer [] { ["0" "1"] }
def delimiter-completer [] { ["0" "1"] }
def builds-completer [] { ["0" "1"] }
def accept-completer [] { ["application/json" "application/stream+json"] }
def delivery-format-completer-1 [] { ["json" "ndjson" "syslog"] }
def role-completer [] { ["DEVELOPER" "MEMBER" "OWNER" "VIEWER"] }
def decrypt-completer [] { ["false" "true"] }
def type-completer-2 [] { ["oauth2-token"] }
def type-completer-3 [] { ["new" "renewal"] }
def target-completer-1 [] { ["preview" "production"] }
def git-fork-protection-completer [] { ["0" "1"] }
def node-version-completer [] { ["10.x" "12.x" "14.x" "16.x" "18.x"] }
def production-completer [] { ["false" "true"] }
def redirects-completer [] { ["false" "true"] }
def verified-completer [] { ["false" "true"] }
def order-completer [] { ["ASC" "DESC"] }
def redirect-status-code-completer [] { ["301" "302" "307" "308"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-edge-configs: "record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string>"
    create-edge-config: "record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float>"
    get-edge-config: "record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string>"
    update-edge-config: "record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float>"
    get-edge-config-item: "record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any>"
    get-edge-config-items: "record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any>"
    patcht-edge-config-items: "record<status: string>"
    create-edge-config-token: "record<id: string, token: string>"
    get-edge-config-token: "record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string>"
    get-edge-config-tokens: "record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string>"
    email-login: "record<securityCode: string, token: string>"
    verify-token: "record<email: string, teamId: string, token: string>"
    get-all-checks: "record<checks: table<completedAt: float, conclusion: string, createdAt: float, detailsUrl: string, id: string, integrationId: string, name: string, output: record, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>>"
    create-check: "record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>"
    get-check: "record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string>"
    update-check: "record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>"
    rerequest-check: "record"
    update-record: "record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string>"
    git-namespaces: "table<id: any, name: string, ownerType: string, provider: string, slug: string>"
    get-v1-integrations-search-repo: "record<gitAccount: record<namespaceId: any, provider: string>, repos: table<defaultBranch: string, id: any, name: string, namespace: string, ownerType: string, private: bool, slug: string, updatedAt: float, url: string>>"
    get-configurable-log-drains: "table<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>"
    create-configurable-log-drain: "record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, secret: string, sources: list<string>, type: string, url: string>"
    get-configurable-log-drain: "record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>"
    get-project-env: "record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>"
    create-team: "record<id: string>"
    delete-team: "record<id: string>"
    delete-team-invite-code: "record<id: string>"
    invite-user-to-team: "record<email: string, role: string, uid: string, username: string>"
    join-team: "record<from: string, name: string, slug: string, teamId: string>"
    remove-team-member: "record<id: string>"
    update-team-member: "record<id: string>"
    request-access-to-team: "record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string>"
    get-team-access-request: "record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string>"
    request-delete: "record<email: string, id: string, message: string>"
    create-webhook: "record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, secret: string, updatedAt: float, url: string>"
    get-webhook: "record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, updatedAt: float, url: string>"
    list-deployment-builds: "record<builds: table<config: record, copiedFrom: string, createdAt: float, createdIn: string, deployedAt: float, deploymentId: string, entrypoint: string, fingerprint: string, id: string, output: list, readyState: string, readyStateAt: float, scheduledAt: float, use: string>>"
    cancel-deployment: "record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: table<config: record, src: string, use: string>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float>"
    create-deployment: "record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: list<record>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float>"
    delete-deployment: "record<state: string, uid: string>"
    delete-alias: "record<status: string>"
    get-deployment-events: "list<any>"
    list-deployment-aliases: "record<aliases: table<alias: string, created: string, protectionBypass: record, redirect: string, uid: string>>"
    assign-alias: "record<alias: string, created: string, oldDeploymentId: string, uid: string>"
    remove-record: "record"
    get-integration-log-drains: "table<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>"
    create-log-drain: "record<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>"
    delete-secret: "record<created: float, name: string, uid: string>"
    rename-secret: "record<created: string, name: string, oldName: string, uid: string>"
    create-secret: "record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: record<data: list<float>, type: string>>"
    get-teams: "record<pagination: record<count: float, next: float, prev: float>, teams: list<any>>"
    get-team: "record"
    patch-team: "record"
    get-team-members: "record<emailInviteCodes: table<createdAt: float, email: string, id: string, isDSyncUser: bool, role: string>, members: table<accessRequestedAt: float, avatar: string, bitbucket: record, confirmed: bool, createdAt: float, email: string, github: record, gitlab: record, joinedFrom: record, name: string, role: string, uid: string, username: string>, pagination: record<count: float, hasNext: bool, next: float, prev: float>>"
    get-auth-user: "record<user: any>"
    list-user-events: "record<events: table<createdAt: float, entities: list, id: string, text: string, user: record, userId: string>>"
    get-secrets: "record<pagination: record<count: float, next: float, prev: float>, secrets: table<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>>"
    get-secret: "record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>"
    create-auth-token: "record<bearerToken: string, token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>>"
    delete-auth-token: "record<tokenId: string>"
    list-aliases: "record<aliases: table<alias: string, created: string, createdAt: float, creator: record, deletedAt: float, deployment: record, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>, pagination: record<count: float, next: float, prev: float>>"
    get-alias: "record<alias: string, created: string, createdAt: float, creator: record<email: string, uid: string, username: string>, deletedAt: float, deployment: record<id: string, meta: string, url: string>, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>"
    create-or-transfer-domain: "record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>>"
    buy-domain: "record<domain: record<created: float, ns: list<string>, pending: bool, uid: string, verified: bool>>"
    check-domain-price: "record<period: float, price: float>"
    check-domain-status: "record<available: bool>"
    get-domains: "record<domains: table<boughtAt: float, createdAt: float, creator: record, customNameservers: list, expiresAt: float, id: string, intendedNameservers: list, name: string, nameservers: list, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>, pagination: record<count: float, next: float, prev: float>>"
    get-domain: "record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, suffix: bool, transferStartedAt: float, transferredAt: float, verified: bool>>"
    list-auth-tokens: "record<pagination: record<count: float, next: float, prev: float>, testingToken: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>, tokens: table<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list, type: string>>"
    get-auth-token: "record<token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>>"
    get-deployments: "record<deployments: table<aliasAssigned: any, aliasError: record, buildingAt: float, checksConclusion: string, checksState: string, created: float, createdAt: float, creator: record, inspectorUrl: string, isRollbackCandidate: bool, meta: record, name: string, ready: float, source: string, state: string, target: string, type: string, uid: string, url: string>, pagination: record<count: float, next: float, prev: float>>"
    list-deployment-files: "table<children: list<any>, contentType: string, mode: float, name: string, symlink: string, type: string, uid: string>"
    delete-domain: "record<uid: string>"
    get-domain-config: "record<acceptedChallenges: list<string>, configuredBy: string, misconfigured: bool>"
    issue-cert: "record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>"
    upload-cert: "record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>"
    remove-cert: "record"
    get-cert-by-id: "record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>"
    artifact-query: "record"
    status: "record<status: string>"
    artifact-exists: "record"
    upload-artifact: "record<urls: list<string>>"
    get-projects: "record<pagination: record<count: float, next: float, prev: float>, projects: table<accountId: string, analytics: record, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: list, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record, latestDeployments: list, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record, permissions: record, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>>"
    create-project: "record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>"
    get-project: "record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>"
    update-project: "record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>"
    get-project-domains: "record<domains: table<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: list, verified: bool>, pagination: record<count: float, next: float, prev: float>>"
    add-project-domain: "record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>"
    remove-project-domain: "record"
    get-project-domain: "record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>"
    update-project-domain: "record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>"
    verify-project-domain: "record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>"
    edit-project-env: "record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-edge-configs" "create-edge-config" "delete-edge-config" "get-edge-config" "update-edge-config" "get-edge-config-item" "get-edge-config-items" "patcht-edge-config-items" "create-edge-config-token" "get-edge-config-token" "delete-edge-config-tokens" "get-edge-config-tokens" "email-login" "verify-token" "get-all-checks" "create-check" "get-check" "update-check" "rerequest-check" "update-record" "delete-configuration" "get-configuration" "get-configurations" "git-namespaces" "delete-integration-log-drain" "get-v1-integrations-search-repo" "get-configurable-log-drains" "create-configurable-log-drain" "delete-configurable-log-drain" "get-configurable-log-drain" "get-project-env" "create-team" "delete-team" "delete-team-invite-code" "invite-user-to-team" "join-team" "remove-team-member" "update-team-member" "request-access-to-team" "get-team-access-request" "request-delete" "get-webhooks" "create-webhook" "delete-webhook" "get-webhook" "create-project-env" "list-deployment-builds" "cancel-deployment" "create-deployment" "get-deployment" "delete-deployment" "delete-alias" "get-deployment-events" "list-deployment-aliases" "assign-alias" "create-record" "remove-record" "upload-file" "get-integration-log-drains" "create-log-drain" "delete-secret" "rename-secret" "create-secret" "get-teams" "get-team" "patch-team" "get-team-members" "get-auth-user" "list-user-events" "get-secrets" "get-secret" "create-auth-token" "delete-auth-token" "list-aliases" "get-alias" "create-or-transfer-domain" "buy-domain" "check-domain-price" "check-domain-status" "get-records" "get-domains" "get-domain" "list-auth-tokens" "get-auth-token" "get-deployments" "list-deployment-files" "get-deployment-file-contents" "delete-domain" "get-domain-config" "issue-cert" "upload-cert" "remove-cert" "get-cert-by-id" "artifact-query" "record-events" "status" "download-artifact" "artifact-exists" "upload-artifact" "get-projects" "create-project" "delete-project" "get-project" "update-project" "get-project-domains" "add-project-domain" "remove-project-domain" "get-project-domain" "update-project-domain" "verify-project-domain" "filter-project-envs" "remove-project-env" "edit-project-env" "commands"] | sort) } | get name | first)
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

# Get Edge Configs
#
# GET /edge-config
# Returns: record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string>
# operationId: getEdgeConfigs
export def "get-edge-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config"
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Edge Config
#
# POST /edge-config
# Returns: record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float>
# operationId: createEdgeConfig
export def "create-edge-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --items: record
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/edge-config"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    team_id: $team_id, items: $items, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Edge Config
#
# DELETE /edge-config/{edgeConfigId}
# operationId: deleteEdgeConfig
export def "delete-edge-config" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/edge-config/{edgeConfigId}"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Edge Config
#
# GET /edge-config/{edgeConfigId}
# Returns: record<createdAt: float, creator: string, domain: string, id: string, itemCount: float, name: string, recordType: string, sizeInBytes: float, ttl: float, type: string, value: string>
# operationId: getEdgeConfig
export def "get-edge-config" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config/{edgeConfigId}"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an Edge Config
#
# PUT /edge-config/{edgeConfigId}
# Returns: record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, itemCount: float, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, sizeInBytes: float, startedAt: float, status: string, updatedAt: float>
# operationId: updateEdgeConfig
export def "update-edge-config" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/edge-config/{edgeConfigId}"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Edge Config item
#
# GET /edge-config/{edgeConfigId}/item/{edgeConfigItemKey}
# Returns: record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any>
# operationId: getEdgeConfigItem
export def "get-edge-config-item" [
  edge_config_id: string
  edge_config_item_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config/{edgeConfigId}/item/{edgeConfigItemKey}"
    path_params: [{name: edgeConfigId, var: edge_config_id}, {name: edgeConfigItemKey, var: edge_config_item_key}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, edge_config_item_key: $edge_config_item_key, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Edge Config items
#
# GET /edge-config/{edgeConfigId}/items
# Returns: record<createdAt: float, edgeConfigId: string, key: string, updatedAt: float, value: any>
# operationId: getEdgeConfigItems
export def "get-edge-config-items" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config/{edgeConfigId}/items"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Edge Config items in batch
#
# PATCH /edge-config/{edgeConfigId}/items
# Returns: record<status: string>
# operationId: patchtEdgeConfigItems
export def "patcht-edge-config-items" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  items: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/edge-config/{edgeConfigId}/items"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Edge Config token
#
# POST /edge-config/{edgeConfigId}/token
# Returns: record<id: string, token: string>
# operationId: createEdgeConfigToken
export def "create-edge-config-token" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  label: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/edge-config/{edgeConfigId}/token"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: label, var: label}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id, label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Edge Config token meta data
#
# GET /edge-config/{edgeConfigId}/token/{token}
# Returns: record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string>
# operationId: getEdgeConfigToken
export def "get-edge-config-token" [
  edge_config_id: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config/{edgeConfigId}/token/{token}"
    path_params: [{name: edgeConfigId, var: edge_config_id}, {name: token, var: token_arg}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, token_arg: $token_arg, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete one or more Edge Config tokens
#
# DELETE /edge-config/{edgeConfigId}/tokens
# operationId: deleteEdgeConfigTokens
export def "delete-edge-config-tokens" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  tokens: list<string>
]: any -> any {
  $in | http-request {
    method: delete
    path: "/edge-config/{edgeConfigId}/tokens"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tokens, var: tokens}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id, tokens: $tokens
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tokens of an Edge Config
#
# GET /edge-config/{edgeConfigId}/tokens
# Returns: record<createdAt: float, edgeConfigId: string, id: string, label: string, token: string>
# operationId: getEdgeConfigTokens
export def "get-edge-config-tokens" [
  edge_config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/edge-config/{edgeConfigId}/tokens"
    path_params: [{name: edgeConfigId, var: edge_config_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    edge_config_id: $edge_config_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login with email
#
# POST /registration
# Returns: record<securityCode: string, token: string>
# operationId: emailLogin
export def "email-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The user email.
  --token-name: string # The desired name for the token. It will be displayed on the user account details.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/registration"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: tokenName, var: token_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email, token_name: $token_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify a login request to get an authentication token
#
# GET /registration/verify
# Returns: record<email: string, teamId: string, token: string>
# operationId: verifyToken
export def "verify-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email to verify the login.
  --qp-token: string # The token returned when the login was requested. (required) (spec name: token)
  --token-name: string # The desired name for the token. It will be displayed on the user account details.
  --sso-user-id: string # The SAML Profile ID, when connecting a SAML Profile to a Team member for the first time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/registration/verify"
    query: [{name: email, var: email}, {name: token, var: qp_token, required: true}, {name: tokenName, var: token_name}, {name: ssoUserId, var: sso_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    email: $email, qp_token: $qp_token, token_name: $token_name, sso_user_id: $sso_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of all checks
#
# GET /v1/deployments/{deploymentId}/checks
# Returns: record<checks: table<completedAt: float, conclusion: string, createdAt: float, detailsUrl: string, id: string, integrationId: string, name: string, output: record, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>>
# operationId: getAllChecks
export def "get-all-checks" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/deployments/{deploymentId}/checks"
    path_params: [{name: deploymentId, var: deployment_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Check
#
# POST /v1/deployments/{deploymentId}/checks
# Returns: record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>
# operationId: createCheck
export def "create-check" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --blocking: oneof<nothing, bool> # Whether the check should block a deployment from succeeding
  --details-url: string # URL to display for further details
  --external-id: string # An identifier that can be used as an external reference
  name: string # The name of the check being created
  --path: string # Path of the page that is being checked
  --rerequestable: oneof<nothing, bool> # Whether a user should be able to request for the check to be rerun if it fails
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/deployments/{deploymentId}/checks"
    path_params: [{name: deploymentId, var: deployment_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: blocking, var: blocking, required: true}, {name: detailsUrl, var: details_url}, {name: externalId, var: external_id}, {name: name, var: name}, {name: path, var: path}, {name: rerequestable, var: rerequestable}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, team_id: $team_id, blocking: $blocking, details_url: $details_url, external_id: $external_id, name: $name, path: $path, rerequestable: $rerequestable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single check
#
# GET /v1/deployments/{deploymentId}/checks/{checkId}
# Returns: record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string>
# operationId: getCheck
export def "get-check" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/deployments/{deploymentId}/checks/{checkId}"
    path_params: [{name: deploymentId, var: deployment_id}, {name: checkId, var: check_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, check_id: $check_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a check
#
# PATCH /v1/deployments/{deploymentId}/checks/{checkId}
# Returns: record<blocking: bool, completedAt: float, conclusion: string, createdAt: float, deploymentId: string, detailsUrl: string, externalId: string, id: string, integrationId: string, name: string, output: record<metrics: record<CLS: record, FCP: record, LCP: record, TBT: record, virtualExperienceScore: record>>, path: string, rerequestable: bool, startedAt: float, status: string, updatedAt: float>
# operationId: updateCheck
export def "update-check" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --conclusion: any@conclusion-completer # The result of the check being run
  --details-url: string # A URL a user may visit to see more information about the check
  --external-id: string # An identifier that can be used as an external reference
  --name: string # The name of the check being created
  --output: record # The results of the check Run — shape: {metrics?: record}
  --path: string # Path of the page that is being checked
  --status: any@status-completer # The current status of the check
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/deployments/{deploymentId}/checks/{checkId}"
    path_params: [{name: deploymentId, var: deployment_id}, {name: checkId, var: check_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: conclusion, var: conclusion}, {name: detailsUrl, var: details_url}, {name: externalId, var: external_id}, {name: name, var: name}, {name: output, var: output}, {name: path, var: path}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, check_id: $check_id, team_id: $team_id, conclusion: $conclusion, details_url: $details_url, external_id: $external_id, name: $name, output: $output, path: $path, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rerequest a check
#
# POST /v1/deployments/{deploymentId}/checks/{checkId}/rerequest
# Returns: record
# operationId: rerequestCheck
export def "rerequest-check" [
  deployment_id: string
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/deployments/{deploymentId}/checks/{checkId}/rerequest"
    path_params: [{name: deploymentId, var: deployment_id}, {name: checkId, var: check_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, check_id: $check_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing DNS record
#
# PATCH /v1/domains/records/{recordId}
# Returns: record<createdAt: float, creator: string, domain: string, id: string, name: string, recordType: string, ttl: float, type: string, value: string>
# operationId: updateRecord
export def "update-record" [
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --mx-priority: int # The MX priority value of the DNS record (nullable)
  --name: string # The name of the DNS record (nullable)
  --srv: record # nullable — shape: {port: int, priority: int, target: string, weight: int}
  --ttl: int # The Time to live (TTL) value of the DNS record (nullable)
  --type: string@type-completer # The type of the DNS record (nullable)
  --value: string # The value of the DNS record (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/domains/records/{recordId}"
    path_params: [{name: recordId, var: record_id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: mxPriority, var: mx_priority}, {name: name, var: name}, {name: srv, var: srv}, {name: ttl, var: ttl}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    record_id: $record_id, team_id: $team_id, mx_priority: $mx_priority, name: $name, srv: $srv, ttl: $ttl, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an integration configuration
#
# DELETE /v1/integrations/configuration/{id}
# operationId: deleteConfiguration
export def "delete-configuration" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/integrations/configuration/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an integration configuration
#
# GET /v1/integrations/configuration/{id}
# operationId: getConfiguration
export def "get-configuration" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/integrations/configuration/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configurations for the authenticated user or team
#
# GET /v1/integrations/configurations
# operationId: getConfigurations
export def "get-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer # required
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/integrations/configurations"
    query: [{name: view, var: view, required: true}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    view: $view, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List git namespaces by provider
#
# GET /v1/integrations/git-namespaces
# Returns: table<id: any, name: string, ownerType: string, provider: string, slug: string>
# operationId: gitNamespaces
export def "git-namespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string@provider-completer
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/integrations/git-namespaces"
    query: [{name: provider, var: provider}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider: $provider, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Integration log drain with the provided `id`
#
# DELETE /v1/integrations/log-drains/{id}
# operationId: deleteIntegrationLogDrain
export def "delete-integration-log-drain" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/integrations/log-drains/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List git repositories linked to namespace by provider
#
# GET /v1/integrations/search-repo
# Returns: record<gitAccount: record<namespaceId: any, provider: string>, repos: table<defaultBranch: string, id: any, name: string, namespace: string, ownerType: string, private: bool, slug: string, updatedAt: float, url: string>>
export def "get-v1-integrations-search-repo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string
  --namespace-id: string # nullable
  --provider: string@provider-completer
  --installation-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/integrations/search-repo"
    query: [{name: query, var: query}, {name: namespaceId, var: namespace_id}, {name: provider, var: provider}, {name: installationId, var: installation_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, namespace_id: $namespace_id, provider: $provider, installation_id: $installation_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of Configurable Log Drains
#
# GET /v1/log-drains
# Returns: table<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>
# operationId: getConfigurableLogDrains
export def "get-configurable-log-drains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/log-drains"
    query: [{name: projectId, var: project_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Configurable Log Drain
#
# POST /v1/log-drains
# Returns: record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, secret: string, sources: list<string>, type: string, url: string>
# operationId: createConfigurableLogDrain
export def "create-configurable-log-drain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  delivery_format: any@delivery-format-completer # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  --project-ids: list<string>
  sources: list<string>
  url: string # The log drain url (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/log-drains"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: deliveryFormat, var: delivery_format}, {name: environment, var: environment}, {name: headers, var: headers}, {name: projectIds, var: project_ids}, {name: sources, var: sources}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, branch: $branch, delivery_format: $delivery_format, environment: $environment, headers: $headers, project_ids: $project_ids, sources: $sources, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Configurable Log Drain
#
# DELETE /v1/log-drains/{id}
# operationId: deleteConfigurableLogDrain
export def "delete-configurable-log-drain" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/log-drains/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Configurable Log Drain
#
# GET /v1/log-drains/{id}
# Returns: record<branch: string, configurationId: string, createdAt: float, deliveryFormat: string, environment: string, headers: record, id: string, ownerId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>
# operationId: getConfigurableLogDrain
export def "get-configurable-log-drain" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/log-drains/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the decrypted value of an environment variable of a project by id
#
# GET /v1/projects/{idOrName}/env/{id}
# Returns: record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>
# operationId: getProjectEnv
export def "get-project-env" [
  id_or_name: string
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/projects/{idOrName}/env/{id}"
    path_params: [{name: idOrName, var: id_or_name}, {name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Team
#
# POST /v1/teams
# Returns: record<id: string>
# operationId: createTeam
export def "create-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The desired name for the Team. It will be generated from the provided slug if nothing is provided
  slug: string # The desired slug for the Team
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Team
#
# DELETE /v1/teams/{teamId}
# Returns: record<id: string>
# operationId: deleteTeam
export def "delete-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the team is being deleted. — item shape: {description: string, slug: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v1/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: reasons, var: reasons}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, reasons: $reasons
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Team invite code
#
# DELETE /v1/teams/{teamId}/invites/{inviteId}
# Returns: record<id: string>
# operationId: deleteTeamInviteCode
export def "delete-team-invite-code" [
  team_id: string
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v1/teams/{teamId}/invites/{inviteId}"
    path_params: [{name: teamId, var: team_id}, {name: inviteId, var: invite_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, invite_id: $invite_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite a user
#
# POST /v1/teams/{teamId}/members
# Returns: record<email: string, role: string, uid: string, username: string>
# operationId: inviteUserToTeam
export def "invite-user-to-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user to invite (format: email)
  --uid: string # The id of the user to invite
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams/{teamId}/members"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, email: $email, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Join a team
#
# POST /v1/teams/{teamId}/members/teams/join
# Returns: record<from: string, name: string, slug: string, teamId: string>
# operationId: joinTeam
export def "join-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invite-code: string # The invite code to join the team.
  --body-team-id: string # The team ID. (spec name: teamId)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams/{teamId}/members/teams/join"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: inviteCode, var: invite_code}, {name: teamId, var: body_team_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, invite_code: $invite_code, body_team_id: $body_team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a Team Member
#
# DELETE /v1/teams/{teamId}/members/{uid}
# Returns: record<id: string>
# operationId: removeTeamMember
export def "remove-team-member" [
  team_id: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v1/teams/{teamId}/members/{uid}"
    path_params: [{name: teamId, var: team_id}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Team Member
#
# PATCH /v1/teams/{teamId}/members/{uid}
# Returns: record<id: string>
# operationId: updateTeamMember
export def "update-team-member" [
  team_id: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmed: oneof<nothing, bool> # Accept a user who requested access to the team.
  --joined-from: record # shape: {ssoUserId?: any}
  --role: string # The role in the team of the member. (default: [MEMBER, VIEWER])
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/teams/{teamId}/members/{uid}"
    path_params: [{name: teamId, var: team_id}, {name: uid, var: uid}]
    body: {content_type: "application/json", kind: json, fields: [{name: confirmed, var: confirmed}, {name: joinedFrom, var: joined_from}, {name: role, var: role}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, uid: $uid, confirmed: $confirmed, joined_from: $joined_from, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request access to a team
#
# POST /v1/teams/{teamId}/request
# Returns: record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string>
# operationId: requestAccessToTeam
export def "request-access-to-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  joined_from: record # shape: {commitId?: string, gitUserId?: any, gitUserLogin?: string, origin: "import"|"teams"|"github"|"gitlab"|"bitbucket"|"feedback", repoId?: string, repoPath?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/teams/{teamId}/request"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: joinedFrom, var: joined_from}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, joined_from: $joined_from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get access request status
#
# GET /v1/teams/{teamId}/request/{userId}
# Returns: record<accessRequestedAt: float, bitbucket: record<login: string>, confirmed: bool, github: record<login: string>, gitlab: record<login: string>, joinedFrom: record<commitId: string, dsyncConnectedAt: float, dsyncUserId: string, gitUserId: any, gitUserLogin: string, idpUserId: string, origin: string, repoId: string, repoPath: string, ssoConnectedAt: float, ssoUserId: string>, teamName: string, teamSlug: string>
# operationId: getTeamAccessRequest
export def "get-team-access-request" [
  team_id: string
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
    path: "/v1/teams/{teamId}/request/{userId}"
    path_params: [{name: teamId, var: team_id}, {name: userId, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User Account
#
# DELETE /v1/user
# Returns: record<email: string, id: string, message: string>
# operationId: requestDelete
export def "request-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reasons: list # Optional array of objects that describe the reason why the User account is being deleted. — item shape: {description: string, slug: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v1/user"
    body: {content_type: "application/json", kind: json, fields: [{name: reasons, var: reasons}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    reasons: $reasons
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of webhooks
#
# GET /v1/webhooks
# operationId: getWebhooks
export def "get-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v1/webhooks"
    query: [{name: projectId, var: project_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a webhook
#
# POST /v1/webhooks
# Returns: record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, secret: string, updatedAt: float, url: string>
# operationId: createWebhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  events: list<string>
  --project-ids: list<string>
  url: string # format: uri
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/webhooks"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: projectIds, var: project_ids}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, events: $events, project_ids: $project_ids, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a webhook
#
# DELETE /v1/webhooks/{id}
# operationId: deleteWebhook
export def "delete-webhook" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/webhooks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook
#
# GET /v1/webhooks/{id}
# Returns: record<createdAt: float, events: list<string>, id: string, ownerId: string, projectIds: list<string>, updatedAt: float, url: string>
# operationId: getWebhook
export def "get-webhook" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/webhooks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create one or more environment variables
#
# POST /v10/projects/{idOrName}/env
# operationId: createProjectEnv
export def "create-project-env" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> any {
  $in | http-request {
    method: post
    path: "/v10/projects/{idOrName}/env"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, accepts: list, fields: [{name: gitBranch, var: git_branch}, {name: key, var: key}, {name: target, var: target}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id, git_branch: $git_branch, key: $key, target: $target, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Deployment Builds
#
# GET /v11/deployments/{deploymentId}/builds
# Returns: record<builds: table<config: record, copiedFrom: string, createdAt: float, createdIn: string, deployedAt: float, deploymentId: string, entrypoint: string, fingerprint: string, id: string, output: list, readyState: string, readyStateAt: float, scheduledAt: float, use: string>>
# operationId: listDeploymentBuilds
export def "list-deployment-builds" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v11/deployments/{deploymentId}/builds"
    path_params: [{name: deploymentId, var: deployment_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deployment_id: $deployment_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a deployment
#
# PATCH /v12/deployments/{id}/cancel
# Returns: record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: table<config: record, src: string, use: string>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float>
# operationId: cancelDeployment
export def "cancel-deployment" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/v12/deployments/{id}/cancel"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new deployment
#
# POST /v13/deployments
# Returns: record<alias: list<string>, aliasAssigned: bool, aliasAssignedAt: any, aliasError: record<code: string, message: string>, aliasFinal: string, aliasWarning: record<action: string, code: string, link: string, message: string>, automaticAliases: list<string>, bootedAt: float, build: record<env: list<string>>, buildErrorAt: float, buildingAt: float, builds: list<record>, canceledAt: float, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record<uid: string, username: string>, env: list<string>, errorCode: string, errorLink: string, errorMessage: string, errorStep: string, functions: record, gitRepo: any, gitSource: any, id: string, inspectorUrl: string, isInConcurrentBuildsQueue: bool, lambdas: table<createdAt: float, entrypoint: string, id: string, output: list, readyState: string, readyStateAt: float>, meta: record, monorepoManager: string, name: string, ownerId: string, plan: string, previewCommentsEnabled: bool, projectId: string, public: bool, readyState: string, regions: list<string>, routes: list<any>, source: string, target: string, team: record<id: string, name: string, slug: string>, type: string, url: string, userAliases: list<string>, version: float>
# operationId: createDeployment
@deprecated --flag build
@deprecated --flag builds
@deprecated --flag body-env
@deprecated --flag routes
export def "create-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-new: string@force-new-completer # Forces a new deployment even if there is a previous similar deployment
  --skip-auto-detection-confirmation: string@skip-auto-detection-confirmation-completer # Allows to skip framework detection so the API would not fail to ask for confirmation
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --schema: string # Ignored. Can be set to get completions, validations and documentation in some editors.
  --alias: list<string> # Aliases that will get assigned when the deployment is `READY` and the target is `production`. The client needs to make a `GET` request to its API to ensure the assignment
  --build: record # An object containing another object with information to be passed to the Build Process (DEPRECATED) — shape: {env?: record}
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --builds: list # A list of build descriptions whose src references valid source files. (DEPRECATED) — item shape: {config?: record, src?: string, use: string}
  --clean-urls: oneof<nothing, bool> # When set to `true`, all HTML files and Serverless Functions will have their extension removed. When visiting a path that ends with the extension, a 308 response will redirect the client to the extensionless path.
  --crons: list # An array of cron jobs that should be created for production Deployments. — item shape: {path: string, schedule: string}
  --deployment-id: string # An deployment id for an existing deployment to redeploy
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --body-env: record # An object containing the deployment's environment variable names and values. Secrets can be referenced by prefixing the value with `@` (DEPRECATED) (spec name: env)
  --files: list # A list of objects with the files to be deployed
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --functions: record # An object describing custom options for your Serverless Functions. Each key must be glob pattern that matches the paths of the Serverless Functions you would like to customize (like `api/*.js` or `api/test.js`).
  --git: record # shape: {deploymentEnabled?: any}
  --git-metadata: record # Populates initial git metadata for different git providers. — shape: {commitAuthorName?: string, commitMessage?: string, commitRef?: string, commitSha?: string, dirty?: bool, remoteUrl: string}
  --git-source: any # Defines the Git Repository source to be deployed. This property can not be used in combination with `files`.
  --headers: list # A list of header definitions. — item shape: {has?: list, headers: list, missing?: list, source: string}
  --ignore-command: string # nullable
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --meta: record # An object containing the deployment's metadata. Multiple key-value pairs can be attached to a deployment
  --monorepo-manager: string # The monorepo manager that is being used for this deployment. When `null` is used no monorepo manager is selected (nullable)
  name: string # A string with the project name used in the deployment URL
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --project: string # The target project identifier in which the deployment will be created. When defined, this parameter overrides name
  --project-settings: record # Project settings that will be applied to the deployment. It is required for the first deployment of a project and will be saved for any following deployments — shape: {buildCommand?: string, commandForIgnoringBuildStep?: string, devCommand?: string, ... (7 more fields)}
  --public: oneof<nothing, bool> # Whether a deployment's source and logs are available publicly
  --redirects: list # A list of redirect definitions. — item shape: {destination: string, has?: list, missing?: list, permanent?: bool, source: string}
  --regions: list<string> # An array of the regions the deployment's Serverless Functions should be deployed to
  --rewrites: list # A list of rewrite definitions. — item shape: {destination: string, has?: list, missing?: list, source: string}
  --routes: list # A list of routes objects used to rewrite paths to point towards other internal or external paths (DEPRECATED)
  --target: string@target-completer # Either not defined, `staging`, or `production`. If `staging`, a staging alias in the format `..now.sh` will be assigned. If `production`, any aliases defined in `alias` will be assigned
  --trailing-slash: oneof<nothing, bool> # When `false`, visiting a path that ends with a forward slash will respond with a `308` status code and redirect to the path without the trailing slash.
  --with-latest-commit: oneof<nothing, bool> # When `true` and `deploymentId` is passed in, the sha from the previous deployment's `gitSource` is removed forcing the latest commit to be used.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v13/deployments"
    query: [{name: forceNew, var: force_new}, {name: skipAutoDetectionConfirmation, var: skip_auto_detection_confirmation}, {name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: "$schema", var: schema}, {name: alias, var: alias}, {name: build, var: build}, {name: buildCommand, var: build_command}, {name: builds, var: builds}, {name: cleanUrls, var: clean_urls}, {name: crons, var: crons}, {name: deploymentId, var: deployment_id}, {name: devCommand, var: dev_command}, {name: env, var: body_env}, {name: files, var: files}, {name: framework, var: framework}, {name: functions, var: functions}, {name: git, var: git}, {name: gitMetadata, var: git_metadata}, {name: gitSource, var: git_source}, {name: headers, var: headers}, {name: ignoreCommand, var: ignore_command}, {name: installCommand, var: install_command}, {name: meta, var: meta}, {name: monorepoManager, var: monorepo_manager}, {name: name, var: name}, {name: outputDirectory, var: output_directory}, {name: project, var: project}, {name: projectSettings, var: project_settings}, {name: public, var: public}, {name: redirects, var: redirects}, {name: regions, var: regions}, {name: rewrites, var: rewrites}, {name: routes, var: routes}, {name: target, var: target}, {name: trailingSlash, var: trailing_slash}, {name: withLatestCommit, var: with_latest_commit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    force_new: $force_new, skip_auto_detection_confirmation: $skip_auto_detection_confirmation, team_id: $team_id, schema: $schema, alias: $alias, build: $build, build_command: $build_command, builds: $builds, clean_urls: $clean_urls, crons: $crons, deployment_id: $deployment_id, dev_command: $dev_command, body_env: $body_env, files: $files, framework: $framework, functions: $functions, git: $git, git_metadata: $git_metadata, git_source: $git_source, headers: $headers, ignore_command: $ignore_command, install_command: $install_command, meta: $meta, monorepo_manager: $monorepo_manager, name: $name, output_directory: $output_directory, project: $project, project_settings: $project_settings, public: $public, redirects: $redirects, regions: $regions, rewrites: $rewrites, routes: $routes, target: $target, trailing_slash: $trailing_slash, with_latest_commit: $with_latest_commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a deployment by ID or URL
#
# GET /v13/deployments/{idOrUrl}
# operationId: getDeployment
export def "get-deployment" [
  id_or_url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-git-repo-info: string # Whether to add in gitRepo information.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v13/deployments/{idOrUrl}"
    path_params: [{name: idOrUrl, var: id_or_url}]
    query: [{name: withGitRepoInfo, var: with_git_repo_info}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_url: $id_or_url, with_git_repo_info: $with_git_repo_info, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Deployment
#
# DELETE /v13/deployments/{id}
# Returns: record<state: string, uid: string>
# operationId: deleteDeployment
export def "delete-deployment" [
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
  --url: string # A Deployment or Alias URL. In case it is passed, the ID will be ignored
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v13/deployments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: url, var: url}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, url: $url, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Alias
#
# DELETE /v2/aliases/{aliasId}
# Returns: record<status: string>
# operationId: deleteAlias
export def "delete-alias" [
  alias_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/aliases/{aliasId}"
    path_params: [{name: aliasId, var: alias_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alias_id: $alias_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get deployment events
#
# GET /v2/deployments/{idOrUrl}/events
# Returns: list<any>
# operationId: getDeploymentEvents
export def "get-deployment-events" [
  id_or_url: string
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
  --direction: string@direction-completer # Order of the returned events based on the timestamp. (default: forward)
  --follow: float@follow-completer # When enabled, this endpoint will return live events as they happen.
  --limit: float # Maximum number of events to return. Provide `-1` to return all available logs.
  --name: string # Deployment build ID.
  --since: float # Timestamp for when build logs should be pulled from.
  --until: float # Timestamp for when the build logs should be pulled up until.
  --status-code: string # HTTP status code range to filter events by.
  --delimiter: float@delimiter-completer
  --builds: float@builds-completer
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/deployments/{idOrUrl}/events"
    path_params: [{name: idOrUrl, var: id_or_url}]
    query: [{name: direction, var: direction}, {name: follow, var: follow}, {name: limit, var: limit}, {name: name, var: name}, {name: since, var: since}, {name: until, var: until}, {name: statusCode, var: status_code}, {name: delimiter, var: delimiter}, {name: builds, var: builds}, {name: teamId, var: team_id}]
    accept: ["application/json", "application/stream+json"]
    ok: [200]
    auth: bearer
  } {
    id_or_url: $id_or_url, direction: $direction, follow: $follow, limit: $limit, name: $name, since: $since, until: $until, status_code: $status_code, delimiter: $delimiter, builds: $builds, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List Deployment Aliases
#
# GET /v2/deployments/{id}/aliases
# Returns: record<aliases: table<alias: string, created: string, protectionBypass: record, redirect: string, uid: string>>
# operationId: listDeploymentAliases
export def "list-deployment-aliases" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/deployments/{id}/aliases"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign an Alias
#
# POST /v2/deployments/{id}/aliases
# Returns: record<alias: string, created: string, oldDeploymentId: string, uid: string>
# operationId: assignAlias
export def "assign-alias" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --alias: string # The alias we want to assign to the deployment defined in the URL
  --redirect: string # The redirect property will take precedence over the deployment id from the URL and consists of a hostname (like test.com) to which the alias should redirect using status code 307 (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/deployments/{id}/aliases"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: redirect, var: redirect}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id, alias: $alias, redirect: $redirect
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a DNS record
#
# POST /v2/domains/{domain}/records
# operationId: createRecord
export def "create-record" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  type: string@type-completer # The type of record, it could be one of the valid DNS records.
  name: string # A subdomain name or an empty string for the root domain.
  --ttl: float # The TTL value. Must be a number between 60 and 2147483647. Default value is 60.
  --value: string # The record value must be a valid IPv4 address. (format: ipv4)
  --mx-priority: float
  --srv: record # shape: {port: float, priority: float, target?: string, weight: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/domains/{domain}/records"
    path_params: [{name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: name, var: name}, {name: ttl, var: ttl}, {name: value, var: value}, {name: mxPriority, var: mx_priority}, {name: srv, var: srv}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, team_id: $team_id, type: $type, name: $name, ttl: $ttl, value: $value, mx_priority: $mx_priority, srv: $srv
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a DNS record
#
# DELETE /v2/domains/{domain}/records/{recordId}
# Returns: record
# operationId: removeRecord
export def "remove-record" [
  domain: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/domains/{domain}/records/{recordId}"
    path_params: [{name: domain, var: domain}, {name: recordId, var: record_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, record_id: $record_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload Deployment Files
#
# POST /v2/files
# operationId: uploadFile
export def "upload-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --content-length: float # The file size in bytes
  --x-vercel-digest: string # The file SHA1 used to check the integrity
  --x-now-digest: string # The file SHA1 used to check the integrity
  --x-now-size: float # The file size as an alternative to `Content-Length`
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/files"
    query: [{name: teamId, var: team_id}]
    header: [{name: Content-Length, var: content_length}, {name: x-vercel-digest, var: x_vercel_digest}, {name: x-now-digest, var: x_now_digest}, {name: x-now-size, var: x_now_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, content_length: $content_length, x_vercel_digest: $x_vercel_digest, x_now_digest: $x_now_digest, x_now_size: $x_now_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of Integration log drains
#
# GET /v2/integrations/log-drains
# Returns: table<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>
# operationId: getIntegrationLogDrains
export def "get-integration-log-drains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/integrations/log-drains"
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Integration Log Drain
#
# POST /v2/integrations/log-drains
# Returns: record<branch: string, clientId: string, configurationId: string, createdAt: float, createdFrom: string, deliveryFormat: string, environment: string, headers: record, id: string, name: string, ownerId: string, projectId: string, projectIds: list<string>, sources: list<string>, type: string, url: string>
# operationId: createLogDrain
export def "create-log-drain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --branch: string # The branch regexp of log drain
  --delivery-format: any@delivery-format-completer-1 # The delivery log format
  --environment: any@environment-completer # The environment of log drain
  --headers: record # Headers to be sent together with the request
  name: string # The name of the log drain
  --project-ids: list<string>
  --secret: string # A secret to sign log drain notification headers so a consumer can verify their authenticity
  --sources: list<string>
  url: string # The url where you will receive logs. The protocol must be `https://` or `http://` when type is `json` and `ndjson`, and `syslog+tls:` or `syslog:` when the type is `syslog`. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/integrations/log-drains"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: deliveryFormat, var: delivery_format}, {name: environment, var: environment}, {name: headers, var: headers}, {name: name, var: name}, {name: projectIds, var: project_ids}, {name: secret, var: secret}, {name: sources, var: sources}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, branch: $branch, delivery_format: $delivery_format, environment: $environment, headers: $headers, name: $name, project_ids: $project_ids, secret: $secret, sources: $sources, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a secret
#
# DELETE /v2/secrets/{idOrName}
# Returns: record<created: float, name: string, uid: string>
# operationId: deleteSecret
export def "delete-secret" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v2/secrets/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change secret name
#
# PATCH /v2/secrets/{name}
# Returns: record<created: string, name: string, oldName: string, uid: string>
# operationId: renameSecret
export def "rename-secret" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --body-name: string # The name of the new secret. (spec name: name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/secrets/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: body_name, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, team_id: $team_id, body_name: $body_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new secret
#
# POST /v2/secrets/{name}
# Returns: record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: record<data: list<float>, type: string>>
# operationId: createSecret
@deprecated --flag project-id
export def "create-secret" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --decryptable: oneof<nothing, bool> # Whether the secret value can be decrypted after it has been created.
  --body-name: string # The name of the secret (max 100 characters). (spec name: name)
  --project-id: string # Associate a secret to a project. (DEPRECATED)
  value: string # The value of the new secret.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/secrets/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: decryptable, var: decryptable}, {name: name, var: body_name, required: true}, {name: projectId, var: project_id}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, team_id: $team_id, decryptable: $decryptable, body_name: $body_name, project_id: $project_id, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all teams
#
# GET /v2/teams
# Returns: record<pagination: record<count: float, next: float, prev: float>, teams: list<any>>
# operationId: getTeams
export def "get-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of Teams which may be returned.
  --since: float # Timestamp (in milliseconds) to only include Teams created since then.
  --until: float # Timestamp (in milliseconds) to only include Teams created until then.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/teams"
    query: [{name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, since: $since, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Team
#
# GET /v2/teams/{teamId}
# Returns: record
# operationId: getTeam
export def "get-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: slug, var: slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Team
#
# PATCH /v2/teams/{teamId}
# Returns: record
# operationId: patchTeam
export def "patch-team" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatar: string # The hash value of an uploaded image. (format: regex)
  --description: string # A short text that describes the team.
  --email-domain: string # nullable, format: regex
  --enable-preview-feedback: string # Enable preview comments: one of on, off or default.
  --migrate-existing-env-variables-to-sensitive: oneof<nothing, bool> # Runs a task that migrates all existing environment variables to sensitive environment variables.
  --name: string # The name of the team.
  --preview-deployment-suffix: string # Suffix that will be used for all preview deployments. (nullable, format: hostname)
  --regenerate-invite-code: oneof<nothing, bool> # Create a new invite code and replace the current one.
  --remote-caching: record # Whether or not remote caching is enabled for the team — shape: {enabled?: bool}
  --saml: record # shape: {enforced?: bool, roles?: record}
  --sensitive-environment-variable-policy: string # Sensitive environment variable policy: one of on, off or default.
  --slug: string # A new slug for the team.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/teams/{teamId}"
    path_params: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatar, var: avatar}, {name: description, var: description}, {name: emailDomain, var: email_domain}, {name: enablePreviewFeedback, var: enable_preview_feedback}, {name: migrateExistingEnvVariablesToSensitive, var: migrate_existing_env_variables_to_sensitive}, {name: name, var: name}, {name: previewDeploymentSuffix, var: preview_deployment_suffix}, {name: regenerateInviteCode, var: regenerate_invite_code}, {name: remoteCaching, var: remote_caching}, {name: saml, var: saml}, {name: sensitiveEnvironmentVariablePolicy, var: sensitive_environment_variable_policy}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, avatar: $avatar, description: $description, email_domain: $email_domain, enable_preview_feedback: $enable_preview_feedback, migrate_existing_env_variables_to_sensitive: $migrate_existing_env_variables_to_sensitive, name: $name, preview_deployment_suffix: $preview_deployment_suffix, regenerate_invite_code: $regenerate_invite_code, remote_caching: $remote_caching, saml: $saml, sensitive_environment_variable_policy: $sensitive_environment_variable_policy, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List team members
#
# GET /v2/teams/{teamId}/members
# Returns: record<emailInviteCodes: table<createdAt: float, email: string, id: string, isDSyncUser: bool, role: string>, members: table<accessRequestedAt: float, avatar: string, bitbucket: record, confirmed: bool, createdAt: float, email: string, github: record, gitlab: record, joinedFrom: record, name: string, role: string, uid: string, username: string>, pagination: record<count: float, hasNext: bool, next: float, prev: float>>
# operationId: getTeamMembers
export def "get-team-members" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit how many teams should be returned
  --since: float # Timestamp in milliseconds to only include members added since then.
  --until: float # Timestamp in milliseconds to only include members added until then.
  --search: string # Search team members by their name, username, and email.
  --role: string@role-completer # Only return members with the specified team role.
  --exclude-project: string # Exclude members who belong to the specified project.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/teams/{teamId}/members"
    path_params: [{name: teamId, var: team_id}]
    query: [{name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}, {name: search, var: search}, {name: role, var: role}, {name: excludeProject, var: exclude_project}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, limit: $limit, since: $since, until: $until, search: $search, role: $role, exclude_project: $exclude_project
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the User
#
# GET /v2/user
# Returns: record<user: any>
# operationId: getAuthUser
export def "get-auth-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v2/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List User Events
#
# GET /v3/events
# Returns: record<events: table<createdAt: float, entities: list, id: string, text: string, user: record, userId: string>>
# operationId: listUserEvents
export def "list-user-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of items which may be returned.
  --since: string # Timestamp to only include items created since then.
  --until: string # Timestamp to only include items created until then.
  --types: string # Comma-delimited list of event \"types\" to filter the results by.
  --user-id: string # When retrieving events for a Team, the `userId` parameter may be specified to filter events generated by a specific member of the Team.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/events"
    query: [{name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}, {name: types, var: types}, {name: userId, var: user_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, since: $since, until: $until, types: $types, user_id: $user_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List secrets
#
# GET /v3/secrets
# Returns: record<pagination: record<count: float, next: float, prev: float>, secrets: table<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>>
# operationId: getSecrets
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
  --id: string # Filter out secrets based on comma separated secret ids.
  --project-id: string # Filter out secrets that belong to a project.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/secrets"
    query: [{name: id, var: id}, {name: projectId, var: project_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, project_id: $project_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single secret
#
# GET /v3/secrets/{idOrName}
# Returns: record<created: string, createdAt: float, decryptable: bool, name: string, projectId: string, teamId: string, uid: string, userId: string, value: string>
# operationId: getSecret
export def "get-secret" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --decrypt: string@decrypt-completer # Whether to try to decrypt the value of the secret. Only works if `decryptable` has been set to `true` when the secret was created.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/secrets/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: decrypt, var: decrypt}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, decrypt: $decrypt, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Auth Token
#
# POST /v3/user/tokens
# Returns: record<bearerToken: string, token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>>
# operationId: createAuthToken
export def "create-auth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --expires-at: float
  name: string
  --client-id: string
  --installation-id: string
  --type: any@type-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/user/tokens"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiresAt, var: expires_at}, {name: name, var: name}, {name: clientId, var: client_id}, {name: installationId, var: installation_id}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, expires_at: $expires_at, name: $name, client_id: $client_id, installation_id: $installation_id, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an authentication token
#
# DELETE /v3/user/tokens/{tokenId}
# Returns: record<tokenId: string>
# operationId: deleteAuthToken
export def "delete-auth-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v3/user/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List aliases
#
# GET /v4/aliases
# Returns: record<aliases: table<alias: string, created: string, createdAt: float, creator: record, deletedAt: float, deployment: record, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>, pagination: record<count: float, next: float, prev: float>>
# operationId: listAliases
export def "list-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # Get only aliases of the given domain name
  --from: float # Get only aliases created after the provided timestamp
  --limit: float # Maximum number of aliases to list from a request
  --project-id: string # Filter aliases from the given `projectId`
  --since: float # Get aliases created after this JavaScript timestamp
  --until: float # Get aliases created before this JavaScript timestamp
  --rollback-deployment-id: string # Get aliases that would be rolled back for the given deployment
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/aliases"
    query: [{name: domain, var: domain}, {name: from, var: from}, {name: limit, var: limit}, {name: projectId, var: project_id}, {name: since, var: since}, {name: until, var: until}, {name: rollbackDeploymentId, var: rollback_deployment_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, from: $from, limit: $limit, project_id: $project_id, since: $since, until: $until, rollback_deployment_id: $rollback_deployment_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Alias
#
# GET /v4/aliases/{idOrAlias}
# Returns: record<alias: string, created: string, createdAt: float, creator: record<email: string, uid: string, username: string>, deletedAt: float, deployment: record<id: string, meta: string, url: string>, deploymentId: string, projectId: string, protectionBypass: record, redirect: string, redirectStatusCode: float, uid: string, updatedAt: float>
# operationId: getAlias
export def "get-alias" [
  id_or_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: float # Get the alias only if it was created after the provided timestamp
  --project-id: string # Get the alias only if it is assigned to the provided project ID
  --since: float # Get the alias only if it was created after this JavaScript timestamp
  --until: float # Get the alias only if it was created before this JavaScript timestamp
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/aliases/{idOrAlias}"
    path_params: [{name: idOrAlias, var: id_or_alias}]
    query: [{name: from, var: from}, {name: projectId, var: project_id}, {name: since, var: since}, {name: until, var: until}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_alias: $id_or_alias, from: $from, project_id: $project_id, since: $since, until: $until, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register or transfer-in a new Domain
#
# POST /v4/domains
# Returns: record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>>
# operationId: createOrTransferDomain
export def "create-or-transfer-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --method: string # The domain operation to perform. It can be either `add` or `transfer-in`.
  name: string # The domain name you want to add.
  --body-token: string # The move-in token from Move Requested email. (spec name: token)
  --auth-code: string # The authorization code assigned to the domain.
  --expected-price: float # The price you expect to be charged for the required 1 year renewal.
  --cdn-enabled: oneof<nothing, bool> # Whether the domain has the Vercel Edge Network enabled or not.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/domains"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: method, var: method}, {name: name, var: name}, {name: token, var: body_token}, {name: authCode, var: auth_code}, {name: expectedPrice, var: expected_price}, {name: cdnEnabled, var: cdn_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, method: $method, name: $name, body_token: $body_token, auth_code: $auth_code, expected_price: $expected_price, cdn_enabled: $cdn_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase a domain
#
# POST /v4/domains/buy
# Returns: record<domain: record<created: float, ns: list<string>, pending: bool, uid: string, verified: bool>>
# operationId: buyDomain
export def "buy-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --expected-price: float # The price you expect to be charged for the purchase.
  name: string # The domain name to purchase.
  --renew: oneof<nothing, bool> # Indicates whether the domain should be automatically renewed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/domains/buy"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: expectedPrice, var: expected_price}, {name: name, var: name}, {name: renew, var: renew}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    team_id: $team_id, expected_price: $expected_price, name: $name, renew: $renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check the price for a domain
#
# GET /v4/domains/price
# Returns: record<period: float, price: float>
# operationId: checkDomainPrice
export def "check-domain-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which the price needs to be checked. (required)
  --type: string@type-completer-3 # In which status of the domain the price needs to be checked.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/domains/price"
    query: [{name: name, var: name, required: true}, {name: type, var: type}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, type: $type, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check a Domain Availability
#
# GET /v4/domains/status
# Returns: record<available: bool>
# operationId: checkDomainStatus
export def "check-domain-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the domain for which we would like to check the status. (required)
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/domains/status"
    query: [{name: name, var: name, required: true}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List existing DNS records
#
# GET /v4/domains/{domain}/records
# operationId: getRecords
export def "get-records" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Maximum number of records to list from a request.
  --since: string # Get records created after this JavaScript timestamp.
  --until: string # Get records created before this JavaScript timestamp.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/domains/{domain}/records"
    path_params: [{name: domain, var: domain}]
    query: [{name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, limit: $limit, since: $since, until: $until, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the domains
#
# GET /v5/domains
# Returns: record<domains: table<boughtAt: float, createdAt: float, creator: record, customNameservers: list, expiresAt: float, id: string, intendedNameservers: list, name: string, nameservers: list, orderedAt: float, renew: bool, serviceType: string, transferStartedAt: float, transferredAt: float, verified: bool>, pagination: record<count: float, next: float, prev: float>>
# operationId: getDomains
export def "get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Maximum number of domains to list from a request.
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v5/domains"
    query: [{name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, since: $since, until: $until, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Information for a Single Domain
#
# GET /v5/domains/{domain}
# Returns: record<domain: record<boughtAt: float, createdAt: float, creator: record<customerId: string, email: string, id: string, isDomainReseller: bool, username: string>, customNameservers: list<string>, expiresAt: float, id: string, intendedNameservers: list<string>, name: string, nameservers: list<string>, orderedAt: float, renew: bool, serviceType: string, suffix: bool, transferStartedAt: float, transferredAt: float, verified: bool>>
# operationId: getDomain
export def "get-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v5/domains/{domain}"
    path_params: [{name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Auth Tokens
#
# GET /v5/user/tokens
# Returns: record<pagination: record<count: float, next: float, prev: float>, testingToken: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>, tokens: table<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list, type: string>>
# operationId: listAuthTokens
export def "list-auth-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v5/user/tokens"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Auth Token Metadata
#
# GET /v5/user/tokens/{tokenId}
# Returns: record<token: record<activeAt: float, createdAt: float, expiresAt: float, id: string, name: string, origin: string, scopes: list<any>, type: string>>
# operationId: getAuthToken
export def "get-auth-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
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
    path: "/v5/user/tokens/{tokenId}"
    path_params: [{name: tokenId, var: token_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_id: $token_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List deployments
#
# GET /v6/deployments
# Returns: record<deployments: table<aliasAssigned: any, aliasError: record, buildingAt: float, checksConclusion: string, checksState: string, created: float, createdAt: float, creator: record, inspectorUrl: string, isRollbackCandidate: bool, meta: record, name: string, ready: float, source: string, state: string, target: string, type: string, uid: string, url: string>, pagination: record<count: float, next: float, prev: float>>
# operationId: getDeployments
export def "get-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app: string # Name of the deployment.
  --from: float # Gets the deployment created after this Date timestamp. (default: current time)
  --limit: float # Maximum number of deployments to list from a request.
  --project-id: string # Filter deployments from the given `projectId`.
  --target: string@target-completer-1 # Filter deployments based on the environment.
  --to: float # Gets the deployment created before this Date timestamp. (default: current time)
  --users: string # Filter out deployments based on users who have created the deployment.
  --since: float # Get Deployments created after this JavaScript timestamp.
  --until: float # Get Deployments created before this JavaScript timestamp.
  --state: string # Filter deployments based on their state (`BUILDING`, `ERROR`, `INITIALIZING`, `QUEUED`, `READY`, `CANCELED`)
  --rollback-candidate: oneof<nothing, bool> # Filter deployments based on their rollback candidacy
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v6/deployments"
    query: [{name: app, var: app}, {name: from, var: from}, {name: limit, var: limit}, {name: projectId, var: project_id}, {name: target, var: target}, {name: to, var: to}, {name: users, var: users}, {name: since, var: since}, {name: until, var: until}, {name: state, var: state}, {name: rollbackCandidate, var: rollback_candidate}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app: $app, from: $from, limit: $limit, project_id: $project_id, target: $target, to: $to, users: $users, since: $since, until: $until, state: $state, rollback_candidate: $rollback_candidate, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Deployment Files
#
# GET /v6/deployments/{id}/files
# Returns: table<children: list<any>, contentType: string, mode: float, name: string, symlink: string, type: string, uid: string>
# operationId: listDeploymentFiles
export def "list-deployment-files" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v6/deployments/{id}/files"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Deployment File Contents
#
# GET /v6/deployments/{id}/files/{fileId}
# operationId: getDeploymentFileContents
export def "get-deployment-file-contents" [
  id: string
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v6/deployments/{id}/files/{fileId}"
    path_params: [{name: id, var: id}, {name: fileId, var: file_id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    id: $id, file_id: $file_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a domain by name
#
# DELETE /v6/domains/{domain}
# Returns: record<uid: string>
# operationId: deleteDomain
export def "delete-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v6/domains/{domain}"
    path_params: [{name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Domain's configuration
#
# GET /v6/domains/{domain}/config
# Returns: record<acceptedChallenges: list<string>, configuredBy: string, misconfigured: bool>
# operationId: getDomainConfig
export def "get-domain-config" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v6/domains/{domain}/config"
    path_params: [{name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue a new cert
#
# POST /v7/certs
# Returns: record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>
# operationId: issueCert
export def "issue-cert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --cns: list<string> # The common names the cert should be issued for
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v7/certs"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cns, var: cns}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, cns: $cns
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a cert
#
# PUT /v7/certs
# Returns: record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>
# operationId: uploadCert
export def "upload-cert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  ca: string # The certificate authority
  cert: string # The certificate
  key: string # The certificate key
  --skip-validation: oneof<nothing, bool> # Skip validation of the certificate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v7/certs"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ca, var: ca}, {name: cert, var: cert}, {name: key, var: key}, {name: skipValidation, var: skip_validation}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, ca: $ca, cert: $cert, key: $key, skip_validation: $skip_validation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove cert
#
# DELETE /v7/certs/{id}
# Returns: record
# operationId: removeCert
export def "remove-cert" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v7/certs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cert by id
#
# GET /v7/certs/{id}
# Returns: record<autoRenew: bool, cns: list<string>, createdAt: float, expiresAt: float, id: string>
# operationId: getCertById
export def "get-cert-by-id" [
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v7/certs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query information about an artifact
#
# POST /v8/artifacts
# Returns: record
# operationId: artifactQuery
export def "artifact-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  hashes: list<string> # artifact hashes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v8/artifacts"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: hashes, var: hashes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, hashes: $hashes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Record an artifacts cache usage event
#
# POST /v8/artifacts/events
# operationId: recordEvents
export def "record-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/v8/artifacts/events"
    query: [{name: teamId, var: team_id}]
    header: [{name: x-artifact-client-ci, var: x_artifact_client_ci}, {name: x-artifact-client-interactive, var: x_artifact_client_interactive}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, x_artifact_client_ci: $x_artifact_client_ci, x_artifact_client_interactive: $x_artifact_client_interactive, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status of Remote Caching for this principal
#
# GET /v8/artifacts/status
# Returns: record<status: string>
# operationId: status
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v8/artifacts/status"
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a cache artifact
#
# GET /v8/artifacts/{hash}
# operationId: downloadArtifact
export def "download-artifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact is downloaded.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
]: nothing -> any {
  http-request {
    method: get
    path: "/v8/artifacts/{hash}"
    path_params: [{name: hash, var: hash}]
    query: [{name: teamId, var: team_id}]
    header: [{name: x-artifact-client-ci, var: x_artifact_client_ci}, {name: x-artifact-client-interactive, var: x_artifact_client_interactive}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hash: $hash, team_id: $team_id, x_artifact_client_ci: $x_artifact_client_ci, x_artifact_client_interactive: $x_artifact_client_interactive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if a cache artifact exists
#
# HEAD /v8/artifacts/{hash}
# Returns: record
# operationId: artifactExists
export def "artifact-exists" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v8/artifacts/{hash}"
    path_params: [{name: hash, var: hash}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hash: $hash, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a cache artifact
#
# PUT /v8/artifacts/{hash}
# Returns: record<urls: list<string>>
# operationId: uploadArtifact
export def "upload-artifact" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --content-length: float # The artifact size in bytes (required)
  --x-artifact-duration: float # The time taken to generate the uploaded artifact in milliseconds.
  --x-artifact-client-ci: string # The continuous integration or delivery environment where this artifact was generated.
  --x-artifact-client-interactive: int # 1 if the client is an interactive shell. Otherwise 0
  --x-artifact-tag: string # The base64 encoded tag for this artifact. The value is sent back to clients when the artifact is downloaded as the header `x-artifact-tag`
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v8/artifacts/{hash}"
    path_params: [{name: hash, var: hash}]
    query: [{name: teamId, var: team_id}]
    header: [{name: Content-Length, var: content_length, required: true}, {name: x-artifact-duration, var: x_artifact_duration}, {name: x-artifact-client-ci, var: x_artifact_client_ci}, {name: x-artifact-client-interactive, var: x_artifact_client_interactive}, {name: x-artifact-tag, var: x_artifact_tag}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    hash: $hash, team_id: $team_id, content_length: $content_length, x_artifact_duration: $x_artifact_duration, x_artifact_client_ci: $x_artifact_client_ci, x_artifact_client_interactive: $x_artifact_client_interactive, x_artifact_tag: $x_artifact_tag, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of projects
#
# GET /v9/projects
# Returns: record<pagination: record<count: float, next: float, prev: float>, projects: table<accountId: string, analytics: record, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: list, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record, latestDeployments: list, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record, permissions: record, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>>
# operationId: getProjects
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
  --from: string # Query only projects updated after the given timestamp
  --git-fork-protection: string@git-fork-protection-completer # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --limit: string # Limit the number of projects returned
  --search: string # Search projects by the name field
  --repo: string # Filter results by repo. Also used for project count
  --repo-id: string # Filter results by Repository ID.
  --repo-url: string # Filter results by Repository URL.
  --exclude-repos: string # Filter results by excluding those projects that belong to a repo
  --edge-config-id: string # Filter results by connected Edge Config ID
  --edge-config-token-id: string # Filter results by connected Edge Config Token ID
  --connect-configuration-id: string # Filter results by linked Connect configuration ID
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v9/projects"
    query: [{name: from, var: from}, {name: gitForkProtection, var: git_fork_protection}, {name: limit, var: limit}, {name: search, var: search}, {name: repo, var: repo}, {name: repoId, var: repo_id}, {name: repoUrl, var: repo_url}, {name: excludeRepos, var: exclude_repos}, {name: edgeConfigId, var: edge_config_id}, {name: edgeConfigTokenId, var: edge_config_token_id}, {name: connectConfigurationId, var: connect_configuration_id}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    from: $from, git_fork_protection: $git_fork_protection, limit: $limit, search: $search, repo: $repo, repo_id: $repo_id, repo_url: $repo_url, exclude_repos: $exclude_repos, edge_config_id: $edge_config_id, edge_config_token_id: $edge_config_token_id, connect_configuration_id: $connect_configuration_id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project
#
# POST /v9/projects
# Returns: record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>
# operationId: createProject
@deprecated --flag skip-git-connect-during-link
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --command-for-ignoring-build-step: string # nullable
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --environment-variables: list # Collection of ENV Variables the Project will use — item shape: {gitBranch?: string, key: string, target: any, type?: "system"|"secret"|"encrypted"|"plain", value: string}
  --framework: any@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected
  --git-repository: record # The Git Repository that will be connected to the project. When this is defined, any pushes to the specified connected Git Repository will be automatically deployed — shape: {repo: string, type: "github"|"gitlab"|"bitbucket"}
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  name: string # The desired name for the project
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --public-source: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --root-directory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverless-function-region: string # The region to deploy Serverless Functions in this project (nullable)
  --skip-git-connect-during-link: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v9/projects"
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: buildCommand, var: build_command}, {name: commandForIgnoringBuildStep, var: command_for_ignoring_build_step}, {name: devCommand, var: dev_command}, {name: environmentVariables, var: environment_variables}, {name: framework, var: framework}, {name: gitRepository, var: git_repository}, {name: installCommand, var: install_command}, {name: name, var: name}, {name: outputDirectory, var: output_directory}, {name: publicSource, var: public_source}, {name: rootDirectory, var: root_directory}, {name: serverlessFunctionRegion, var: serverless_function_region}, {name: skipGitConnectDuringLink, var: skip_git_connect_during_link}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id: $team_id, build_command: $build_command, command_for_ignoring_build_step: $command_for_ignoring_build_step, dev_command: $dev_command, environment_variables: $environment_variables, framework: $framework, git_repository: $git_repository, install_command: $install_command, name: $name, output_directory: $output_directory, public_source: $public_source, root_directory: $root_directory, serverless_function_region: $serverless_function_region, skip_git_connect_during_link: $skip_git_connect_during_link
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Project
#
# DELETE /v9/projects/{idOrName}
# operationId: deleteProject
export def "delete-project" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v9/projects/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find a project by id or name
#
# GET /v9/projects/{idOrName}
# Returns: record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>
# operationId: getProject
export def "get-project" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v9/projects/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing project
#
# PATCH /v9/projects/{idOrName}
# Returns: record<accountId: string, analytics: record<canceledAt: float, disabledAt: float, enabledAt: float, id: string, paidAt: float, sampleRatePercent: float, spendLimitInDollars: float>, autoExposeSystemEnvs: bool, buildCommand: string, commandForIgnoringBuildStep: string, connectConfigurationId: string, createdAt: float, devCommand: string, directoryListing: bool, enablePreviewFeedback: bool, env: table<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>, framework: string, gitForkProtection: bool, hasFloatingAliases: bool, id: string, installCommand: string, lastRollbackTarget: record<fromDeploymentId: string, jobStatus: string, requestedAt: float, toDeploymentId: string>, latestDeployments: table<alias: list, aliasAssigned: any, aliasError: record, aliasFinal: string, automaticAliases: list, buildingAt: float, builds: list, checksConclusion: string, checksState: string, createdAt: float, createdIn: string, creator: record, deploymentHostname: string, forced: bool, id: string, meta: record, monorepoManager: string, name: string, plan: string, previewCommentsEnabled: bool, private: bool, readyAt: float, readyState: string, requestedAt: float, target: string, teamId: string, type: string, url: string, userId: string, withCache: bool>, link: any, live: bool, name: string, nodeVersion: string, outputDirectory: string, passwordProtection: record<deploymentType: string>, permissions: record<Monitoring: list<string>, aliasGlobal: list<string>, aliasProject: list<string>, aliasProtectionBypass: list<string>, analytics: list<string>, analyticsSampling: list<string>, analyticsUsage: list<string>, auditLog: list<string>, awsBillingIntegration: list<string>, billingAddress: list<string>, billingInformation: list<string>, billingInvoice: list<string>, billingInvoiceEmailRecipient: list<string>, billingInvoiceLanguage: list<string>, billingPlan: list<string>, billingPurchaseOrder: list<string>, billingTaxId: list<string>, cacheArtifact: list<string>, cacheArtifactUsageEvent: list<string>, concurrentBuilds: list<string>, connect: list<string>, connectConfiguration: list<string>, connectConfigurationLink: list<string>, deployment: list<string>, deploymentCheck: list<string>, deploymentCheckPreview: list<string>, deploymentPreview: list<string>, deploymentPrivate: list<string>, deploymentProductionGit: list<string>, deploymentRollback: list<string>, domain: list<string>, domainAcceptDelegation: list<string>, domainAuthCodes: list<string>, domainCertificate: list<string>, domainCheckConfig: list<string>, domainMove: list<string>, domainPurchase: list<string>, domainRecord: list<string>, domainTransferIn: list<string>, edgeConfig: list<string>, edgeConfigItem: list<string>, edgeConfigToken: list<string>, endpointVerification: list<string>, event: list<string>, fileUpload: list<string>, gitRepository: list<string>, integration: list<string>, integrationConfiguration: list<string>, integrationConfigurationProjects: list<string>, integrationConfigurationTransfer: list<string>, integrationVercelConfigurationOverride: list<string>, job: list<string>, logDrain: list<string>, monitoringChart: list<string>, monitoringQuery: list<string>, notificationDomainConfiguration: list<string>, notificationDomainExpire: list<string>, notificationDomainMoved: list<string>, notificationDomainPurchase: list<string>, notificationDomainRenewal: list<string>, notificationDomainTransfer: list<string>, notificationDomainUnverified: list<string>, notificationPaymentFailed: list<string>, notificationSpendCap: list<string>, notificationUsageAlert: list<string>, openTelemetryEndpoint: list<string>, passwordProtection: list<string>, paymentMethod: list<string>, permissions: list<string>, previewDeploymentSuffix: list<string>, proTrialOnboarding: list<string>, project: list<string>, projectDeploymentHook: list<string>, projectDomain: list<string>, projectDomainMove: list<string>, projectEnvVars: list<string>, projectEnvVarsProduction: list<string>, projectEnvVarsUnownedByIntegration: list<string>, projectIntegrationConfiguration: list<string>, projectLink: list<string>, projectMember: list<string>, projectProductionBranch: list<string>, projectProtectionBypass: list<string>, projectTransfer: list<string>, rateLimit: list<string>, redis: list<string>, remoteCaching: list<string>, samlConfig: list<string>, secret: list<string>, sensitiveEnvironmentVariablePolicy: list<string>, sharedEnvVars: list<string>, sharedEnvVarsProduction: list<string>, spendCapConfiguration: list<string>, spendCapState: list<string>, supportCase: list<string>, supportCaseComment: list<string>, team: list<string>, teamAccessRequest: list<string>, teamFellowMembership: list<string>, teamInvite: list<string>, teamInviteCode: list<string>, teamJoin: list<string>, teamOwnMembership: list<string>, teamOwnMembershipDisconnectSAML: list<string>, token: list<string>, usage: list<string>, user: list<string>, userConnection: list<string>, webAnalytics: list<string>, webhook: list<string>, webhook-event: list<string>>, protectionBypass: record, publicSource: bool, rootDirectory: string, serverlessFunctionRegion: string, skipGitConnectDuringLink: bool, sourceFilesOutsideRootDirectory: bool, ssoProtection: record<deploymentType: string>, targets: record, transferCompletedAt: float, transferStartedAt: float, transferToAccountId: string, transferredFromAccountId: string, updatedAt: float>
# operationId: updateProject
@deprecated --flag skip-git-connect-during-link
export def "update-project" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --auto-expose-system-envs: oneof<nothing, bool>
  --build-command: string # The build command for this project. When `null` is used this value will be automatically detected (nullable)
  --command-for-ignoring-build-step: string # nullable
  --dev-command: string # The dev command for this project. When `null` is used this value will be automatically detected (nullable)
  --directory-listing: oneof<nothing, bool>
  --enable-preview-feedback: oneof<nothing, bool> # Opt-in to Preview comments on the project level (nullable)
  --framework: string@framework-completer # The framework that is being used for this project. When `null` is used no framework is selected (nullable)
  --git-fork-protection: oneof<nothing, bool> # Specifies whether PRs from Git forks should require a team member's authorization before it can be deployed
  --install-command: string # The install command for this project. When `null` is used this value will be automatically detected (nullable)
  --name: string # The desired name for the project
  --node-version: string@node-version-completer
  --output-directory: string # The output directory of the project. When `null` is used this value will be automatically detected (nullable)
  --password-protection: record # Allows to protect project deployments with a password (nullable) — shape: {deploymentType: "all"|"preview", password?: string}
  --public-source: oneof<nothing, bool> # Specifies whether the source code and logs of the deployments for this project should be public or not (nullable)
  --root-directory: string # The name of a directory or relative path to the source code of your project. When `null` is used it will default to the project root (nullable)
  --serverless-function-region: string # The region to deploy Serverless Functions in this project (nullable)
  --skip-git-connect-during-link: oneof<nothing, bool> # Opts-out of the message prompting a CLI user to connect a Git repository in `vercel link`. (DEPRECATED)
  --source-files-outside-root-directory: oneof<nothing, bool> # Indicates if there are source files outside of the root directory
  --sso-protection: record # Ensures visitors to your Preview Deployments are logged into Vercel and have a minimum of Viewer access on your team (nullable) — shape: {deploymentType: "all"|"preview"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v9/projects/{idOrName}"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoExposeSystemEnvs, var: auto_expose_system_envs}, {name: buildCommand, var: build_command}, {name: commandForIgnoringBuildStep, var: command_for_ignoring_build_step}, {name: devCommand, var: dev_command}, {name: directoryListing, var: directory_listing}, {name: enablePreviewFeedback, var: enable_preview_feedback}, {name: framework, var: framework}, {name: gitForkProtection, var: git_fork_protection}, {name: installCommand, var: install_command}, {name: name, var: name}, {name: nodeVersion, var: node_version}, {name: outputDirectory, var: output_directory}, {name: passwordProtection, var: password_protection}, {name: publicSource, var: public_source}, {name: rootDirectory, var: root_directory}, {name: serverlessFunctionRegion, var: serverless_function_region}, {name: skipGitConnectDuringLink, var: skip_git_connect_during_link}, {name: sourceFilesOutsideRootDirectory, var: source_files_outside_root_directory}, {name: ssoProtection, var: sso_protection}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id, auto_expose_system_envs: $auto_expose_system_envs, build_command: $build_command, command_for_ignoring_build_step: $command_for_ignoring_build_step, dev_command: $dev_command, directory_listing: $directory_listing, enable_preview_feedback: $enable_preview_feedback, framework: $framework, git_fork_protection: $git_fork_protection, install_command: $install_command, name: $name, node_version: $node_version, output_directory: $output_directory, password_protection: $password_protection, public_source: $public_source, root_directory: $root_directory, serverless_function_region: $serverless_function_region, skip_git_connect_during_link: $skip_git_connect_during_link, source_files_outside_root_directory: $source_files_outside_root_directory, sso_protection: $sso_protection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve project domains by project by id or name
#
# GET /v9/projects/{idOrName}/domains
# Returns: record<domains: table<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: list, verified: bool>, pagination: record<count: float, next: float, prev: float>>
# operationId: getProjectDomains
export def "get-project-domains" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --production: string@production-completer # Filters only production domains when set to `true`. (default: false)
  --git-branch: string # Filters domains based on specific branch.
  --redirects: string@redirects-completer # Excludes redirect project domains when \"false\". Includes redirect project domains when \"true\" (default). (default: true)
  --redirect: string # Filters domains based on their redirect target.
  --verified: string@verified-completer # Filters domains based on their verification status.
  --limit: float # Maximum number of domains to list from a request (max 100).
  --since: float # Get domains created after this JavaScript timestamp.
  --until: float # Get domains created before this JavaScript timestamp.
  --order: string@order-completer # Domains sort order by createdAt (default: DESC)
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v9/projects/{idOrName}/domains"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: production, var: production}, {name: gitBranch, var: git_branch}, {name: redirects, var: redirects}, {name: redirect, var: redirect}, {name: verified, var: verified}, {name: limit, var: limit}, {name: since, var: since}, {name: until, var: until}, {name: order, var: order}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, production: $production, git_branch: $git_branch, redirects: $redirects, redirect: $redirect, verified: $verified, limit: $limit, since: $since, until: $until, order: $order, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a domain to a project
#
# POST /v9/projects/{idOrName}/domains
# Returns: record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>
# operationId: addProjectDomain
export def "add-project-domain" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # Git branch to link the project domain (nullable)
  name: string # The project domain name
  --redirect: string # Target destination domain for redirect (nullable)
  --redirect-status-code: int@redirect-status-code-completer # Status code for domain redirect (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v9/projects/{idOrName}/domains"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: gitBranch, var: git_branch}, {name: name, var: name}, {name: redirect, var: redirect}, {name: redirectStatusCode, var: redirect_status_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, team_id: $team_id, git_branch: $git_branch, name: $name, redirect: $redirect, redirect_status_code: $redirect_status_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a domain from a project
#
# DELETE /v9/projects/{idOrName}/domains/{domain}
# Returns: record
# operationId: removeProjectDomain
export def "remove-project-domain" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v9/projects/{idOrName}/domains/{domain}"
    path_params: [{name: idOrName, var: id_or_name}, {name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project domain
#
# GET /v9/projects/{idOrName}/domains/{domain}
# Returns: record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>
# operationId: getProjectDomain
export def "get-project-domain" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v9/projects/{idOrName}/domains/{domain}"
    path_params: [{name: idOrName, var: id_or_name}, {name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project domain
#
# PATCH /v9/projects/{idOrName}/domains/{domain}
# Returns: record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>
# operationId: updateProjectDomain
export def "update-project-domain" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # Git branch to link the project domain (nullable)
  --redirect: string # Target destination domain for redirect (nullable)
  --redirect-status-code: int@redirect-status-code-completer # Status code for domain redirect (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v9/projects/{idOrName}/domains/{domain}"
    path_params: [{name: idOrName, var: id_or_name}, {name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: gitBranch, var: git_branch}, {name: redirect, var: redirect}, {name: redirectStatusCode, var: redirect_status_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, domain: $domain, team_id: $team_id, git_branch: $git_branch, redirect: $redirect, redirect_status_code: $redirect_status_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify project domain
#
# POST /v9/projects/{idOrName}/domains/{domain}/verify
# Returns: record<apexName: string, createdAt: float, gitBranch: string, name: string, projectId: string, redirect: string, redirectStatusCode: float, updatedAt: float, verification: table<domain: string, reason: string, type: string, value: string>, verified: bool>
# operationId: verifyProjectDomain
export def "verify-project-domain" [
  id_or_name: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v9/projects/{idOrName}/domains/{domain}/verify"
    path_params: [{name: idOrName, var: id_or_name}, {name: domain, var: domain}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, domain: $domain, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the environment variables of a project by id or name
#
# GET /v9/projects/{idOrName}/env
# operationId: filterProjectEnvs
export def "filter-project-envs" [
  id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --git-branch: string # If defined, the git branch of the environment variable to filter the results
  --decrypt: string@decrypt-completer # If true, the environment variable value will be decrypted
  --source: string # The source that is calling the endpoint.
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: get
    path: "/v9/projects/{idOrName}/env"
    path_params: [{name: idOrName, var: id_or_name}]
    query: [{name: gitBranch, var: git_branch}, {name: decrypt, var: decrypt}, {name: source, var: source}, {name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, git_branch: $git_branch, decrypt: $decrypt, source: $source, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an environment variable
#
# DELETE /v9/projects/{idOrName}/env/{id}
# operationId: removeProjectEnv
export def "remove-project-env" [
  id_or_name: string
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v9/projects/{idOrName}/env/{id}"
    path_params: [{name: idOrName, var: id_or_name}, {name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, id: $id, team_id: $team_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an environment variable
#
# PATCH /v9/projects/{idOrName}/env/{id}
# Returns: record<configurationId: string, createdAt: float, createdBy: string, decrypted: bool, edgeConfigId: string, edgeConfigTokenId: string, gitBranch: string, id: string, key: string, target: any, type: string, updatedAt: float, updatedBy: string, value: string>
# operationId: editProjectEnv
export def "edit-project-env" [
  id_or_name: string
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
  --team-id: string # The Team identifier or slug to perform the request on behalf of.
  --git-branch: string # The git branch of the environment variable (nullable)
  --key: string # The name of the environment variable
  --target: list # The target environment of the environment variable
  --type: string@type-completer-1 # The type of environment variable
  --value: string # The value of the environment variable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v9/projects/{idOrName}/env/{id}"
    path_params: [{name: idOrName, var: id_or_name}, {name: id, var: id}]
    query: [{name: teamId, var: team_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: gitBranch, var: git_branch}, {name: key, var: key}, {name: target, var: target}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_or_name: $id_or_name, id: $id, team_id: $team_id, git_branch: $git_branch, key: $key, target: $target, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
