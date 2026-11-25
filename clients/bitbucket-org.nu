# Auto-generated client for Bitbucket API v2.0
# Source: https://api.apis.guru/v2/specs/bitbucket.org/2.0/openapi.json
# Auth: --token flag or $env.BITBUCKET_API_TOKEN

const CLIENT = {
  base_url: "https://api.bitbucket.org/2.0"
  token_env_var: "BITBUCKET_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://api.bitbucket.org/2.0"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def subject-type-completer [] { ["repository" "workspace"] }
def state-completer [] { ["DECLINED" "MERGED" "OPEN" "SUPERSEDED"] }
def role-completer [] { ["admin" "contributor" "member" "owner"] }
def fork-policy-completer [] { ["allow_forks" "no_forks" "no_public_forks"] }
def scm-completer [] { ["git"] }
def report-type-completer [] { ["BUG" "COVERAGE" "SECURITY" "TEST"] }
def result-completer [] { ["FAILED" "PASSED" "PENDING"] }
def annotation-type-completer [] { ["BUG" "CODE_SMELL" "VULNERABILITY"] }
def result-completer-1 [] { ["FAILED" "IGNORED" "PASSED" "SKIPPED"] }
def severity-completer [] { ["CRITICAL" "HIGH" "LOW" "MEDIUM"] }
def state-completer-1 [] { ["FAILED" "INPROGRESS" "STOPPED" "SUCCESSFUL"] }
def kind-completer [] { ["bug" "enhancement" "proposal" "task"] }
def priority-completer [] { ["blocker" "critical" "major" "minor" "trivial"] }
def state-completer-2 [] { ["closed" "duplicate" "invalid" "new" "on hold" "open" "resolved" "wontfix"] }
def merge-strategy-completer [] { ["fast_forward" "merge_commit" "squash"] }
def format-completer [] { ["meta"] }
def format-completer-1 [] { ["meta" "rendered"] }
def role-completer-1 [] { ["contributor" "member" "owner"] }
def accept-completer [] { ["application/json" "multipart/form-data" "multipart/related"] }
def role-completer-2 [] { ["collaborator" "member" "owner"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-hook-events: "record<repository: record<events: record<href: string, name: string>>, workspace: record<events: record<href: string, name: string>>>"
    get-hook-events-subject-type: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<category: string, description: string, event: string, label: string>>"
    get-pullrequests-selected-user: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>"
    get-repositories: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>"
    get-repositories-workspace: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>"
    get-repositories-workspace-repo-slug: "record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>"
    post-repositories-workspace-repo-slug: "record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>"
    put-repositories-workspace-repo-slug: "record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>"
    get-repositories-workspace-repo-slug-branch-restrictions: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, groups: list, users: list>>"
    post-repositories-workspace-repo-slug-branch-restrictions: "record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-branch-restrictions-id: "record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    put-repositories-workspace-repo-slug-branch-restrictions-id: "record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-branching-model: "record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>>"
    get-repositories-workspace-repo-slug-branching-model-settings: "record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>"
    put-repositories-workspace-repo-slug-branching-model-settings: "record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>"
    get-repositories-workspace-repo-slug-commit-commit: "record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    post-repositories-workspace-repo-slug-commit-commit-approve: "record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-commit-commit-comments: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, commit: record>>"
    get-repositories-workspace-repo-slug-commit-commit-comments-comment-id: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, commit: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>>"
    get-commit-hosted-property-value: "record<_attributes: list<string>>"
    get-pullrequests-for-commit: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>"
    get-reports-for-commit: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, data: list, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>>"
    get-report: "record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>"
    create-or-update-report: "record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>"
    get-annotations-for-report: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>>"
    bulk-create-or-update-annotations: "table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>"
    get-annotation: "record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>"
    create-or-update-annotation: "record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>"
    get-repositories-workspace-repo-slug-commit-commit-statuses: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>>"
    post-repositories-workspace-repo-slug-commit-commit-statuses-build: "record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>"
    get-repositories-workspace-repo-slug-commit-commit-statuses-build-key: "record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>"
    put-repositories-workspace-repo-slug-commit-commit-statuses-build-key: "record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>"
    get-repositories-workspace-repo-slug-commits: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>"
    post-repositories-workspace-repo-slug-commits: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>"
    get-repositories-workspace-repo-slug-commits-revision: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>"
    post-repositories-workspace-repo-slug-commits-revision: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>"
    get-repositories-workspace-repo-slug-components: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>"
    get-repositories-workspace-repo-slug-components-component-id: "record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>"
    get-repositories-workspace-repo-slug-default-reviewers: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-default-reviewers-target-username: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>"
    put-repositories-workspace-repo-slug-default-reviewers-target-username: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>"
    get-repositories-workspace-repo-slug-deploy-keys: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record, owner: record, repository: record>>"
    post-repositories-workspace-repo-slug-deploy-keys: "record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    get-repositories-workspace-repo-slug-deploy-keys-key-id: "record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    put-repositories-workspace-repo-slug-deploy-keys-key-id: "record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    get-deployments-for-repository: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, environment: record, release: record, state: record, uuid: string>>"
    get-deployment-for-repository: "record<type: string, environment: record<type: string, name: string, uuid: string>, release: record<type: string, commit: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: record>, created_on: string, name: string, url: string, uuid: string>, state: record<type: string>, uuid: string>"
    get-deployment-variables: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>"
    create-deployment-variable: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    update-deployment-variable: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-repositories-workspace-repo-slug-diffstat-spec: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<lines_added: int, lines_removed: int, new: record, old: record, status: string, type: string>>"
    get-repositories-workspace-repo-slug-effective-branching-model: "record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>>"
    get-repositories-workspace-repo-slug-effective-default-reviewers: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>>"
    get-environments-for-repository: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, name: string, uuid: string>>"
    create-environment: "record<type: string, name: string, uuid: string>"
    get-environment-for-repository: "record<type: string, name: string, uuid: string>"
    get-repositories-workspace-repo-slug-filehistory-commit-path: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<attributes: string, commit: record, escaped_path: string, path: string, type: string>>"
    get-repositories-workspace-repo-slug-forks: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>"
    post-repositories-workspace-repo-slug-forks: "record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>"
    get-repositories-workspace-repo-slug-hooks: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>>"
    post-repositories-workspace-repo-slug-hooks: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    get-repositories-workspace-repo-slug-hooks-uid: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    put-repositories-workspace-repo-slug-hooks-uid: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    get-repositories-workspace-repo-slug-issues: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, assignee: record, component: record, content: record, created_on: string, edited_on: string, id: int, kind: string, links: record, milestone: record, priority: string, reporter: record, repository: record, state: string, title: string, updated_on: string, version: record, votes: int>>"
    post-repositories-workspace-repo-slug-issues: "record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>"
    get-repositories-workspace-repo-slug-issues-export-repo-name-issues-task-id-zip: "record<count: int, pct: float, phase: string, status: string, total: int, type: string>"
    get-repositories-workspace-repo-slug-issues-import: "record<count: int, pct: float, phase: string, status: string, total: int, type: string>"
    post-repositories-workspace-repo-slug-issues-import: "record<count: int, pct: float, phase: string, status: string, total: int, type: string>"
    delete-repositories-workspace-repo-slug-issues-issue-id: "record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>"
    get-repositories-workspace-repo-slug-issues-issue-id: "record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>"
    put-repositories-workspace-repo-slug-issues-issue-id: "record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>"
    get-repositories-workspace-repo-slug-issues-issue-id-attachments: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, name: string>>"
    get-repositories-workspace-repo-slug-issues-issue-id-changes: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<changes: record, created_on: string, issue: record, links: record, message: record, name: string, type: string, user: record>>"
    post-repositories-workspace-repo-slug-issues-issue-id-changes: "record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-issues-issue-id-changes-change-id: "record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-issues-issue-id-comments: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, issue: record>>"
    get-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>>"
    put-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>>"
    delete-repositories-workspace-repo-slug-issues-issue-id-vote: "record<error: record<data: record, detail: string, message: string>, type: string>"
    get-repositories-workspace-repo-slug-issues-issue-id-vote: "record<error: record<data: record, detail: string, message: string>, type: string>"
    put-repositories-workspace-repo-slug-issues-issue-id-vote: "record<error: record<data: record, detail: string, message: string>, type: string>"
    delete-repositories-workspace-repo-slug-issues-issue-id-watch: "record<error: record<data: record, detail: string, message: string>, type: string>"
    get-repositories-workspace-repo-slug-issues-issue-id-watch: "record<error: record<data: record, detail: string, message: string>, type: string>"
    put-repositories-workspace-repo-slug-issues-issue-id-watch: "record<error: record<data: record, detail: string, message: string>, type: string>"
    get-repositories-workspace-repo-slug-merge-base-revspec: "record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    get-repositories-workspace-repo-slug-milestones: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>"
    get-repositories-workspace-repo-slug-milestones-milestone-id: "record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>"
    get-repositories-workspace-repo-slug-override-settings: "record<override_settings: record, type: string>"
    get-repositories-workspace-repo-slug-permissions-config-groups: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<group: record, links: record, permission: string, repository: record, type: string>>"
    get-repositories-workspace-repo-slug-permissions-config-groups-group-slug: "record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string>"
    put-repositories-workspace-repo-slug-permissions-config-groups-group-slug: "record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string>"
    get-repositories-workspace-repo-slug-permissions-config-users: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, permission: string, repository: record, type: string, user: record>>"
    get-repositories-workspace-repo-slug-permissions-config-users-selected-user-id: "record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, repositories: record, self: record>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>>"
    put-repositories-workspace-repo-slug-permissions-config-users-selected-user-id: "record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, repositories: record, self: record>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>>"
    get-repository-pipeline-caches: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, file_size_bytes: int, key_hash: string, name: string, path: string, pipeline_uuid: string, step_uuid: string, uuid: string>>"
    get-repository-pipeline-cache-content-uri: "record<uri: string>"
    get-pipelines-for-repository: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record, repository: record, state: record, target: record, trigger: record, uuid: string>>"
    create-pipeline-for-repository: "record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string>"
    get-pipeline-for-repository: "record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string>"
    get-pipeline-steps-for-repository: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, completed_on: string, image: record, script_commands: list, setup_commands: list, started_on: string, state: record, uuid: string>>"
    get-pipeline-step-for-repository: "record<type: string, completed_on: string, image: record<email: string, name: string, password: string, username: string>, script_commands: table<command: string, name: string>, setup_commands: table<command: string, name: string>, started_on: string, state: record<type: string>, uuid: string>"
    get-repository-pipeline-config: "record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    update-repository-pipeline-config: "record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>"
    update-repository-build-number: "record<type: string, next: int>"
    get-repository-pipeline-schedules: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record, target: record, updated_on: string, uuid: string>>"
    create-repository-pipeline-schedule: "record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>"
    get-repository-pipeline-schedule: "record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>"
    update-repository-pipeline-schedule: "record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>"
    get-repository-pipeline-schedule-executions: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string>>"
    get-repository-pipeline-ssh-key-pair: "record<type: string, private_key: string, public_key: string>"
    update-repository-pipeline-key-pair: "record<type: string, private_key: string, public_key: string>"
    get-repository-pipeline-known-hosts: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, hostname: string, public_key: record, uuid: string>>"
    create-repository-pipeline-known-host: "record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>"
    get-repository-pipeline-known-host: "record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>"
    update-repository-pipeline-known-host: "record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>"
    get-repository-pipeline-variables: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>"
    create-repository-pipeline-variable: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-repository-pipeline-variable: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    update-repository-pipeline-variable: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-repository-hosted-property-value: "record<_attributes: list<string>>"
    get-repositories-workspace-repo-slug-pullrequests: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>"
    post-repositories-workspace-repo-slug-pullrequests: "record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>"
    get-repositories-workspace-repo-slug-pullrequests-pull-request-id: "record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>"
    put-repositories-workspace-repo-slug-pullrequests-pull-request-id: "record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>"
    post-repositories-workspace-repo-slug-pullrequests-pull-request-id-approve: "record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, pullrequest: record>>"
    post-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>"
    get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>"
    put-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id: "record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>"
    post-repositories-workspace-repo-slug-pullrequests-pull-request-id-decline: "record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>"
    post-repositories-workspace-repo-slug-pullrequests-pull-request-id-merge: "record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>"
    post-repositories-workspace-repo-slug-pullrequests-pull-request-id-request-changes: "record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-repositories-workspace-repo-slug-pullrequests-pull-request-id-statuses: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>>"
    get-pull-request-hosted-property-value: "record<_attributes: list<string>>"
    get-repositories-workspace-repo-slug-refs: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string>>"
    get-repositories-workspace-repo-slug-refs-branches: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>>"
    post-repositories-workspace-repo-slug-refs-branches: "record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>>"
    get-repositories-workspace-repo-slug-refs-branches-name: "record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>>"
    get-repositories-workspace-repo-slug-refs-tags: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, date: string, message: string, tagger: record>>"
    post-repositories-workspace-repo-slug-refs-tags: "record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>>"
    get-repositories-workspace-repo-slug-refs-tags-name: "record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>>"
    get-repositories-workspace-repo-slug-src: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>>"
    get-repositories-workspace-repo-slug-src-commit-path: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>>"
    get-repositories-workspace-repo-slug-versions: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>"
    get-repositories-workspace-repo-slug-versions-version-id: "record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>"
    get-repositories-workspace-repo-slug-watchers: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    get-snippets: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>>"
    post-snippets: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    get-snippets-workspace: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>>"
    post-snippets-workspace: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    get-snippets-workspace-encoded-id: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    put-snippets-workspace-encoded-id: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    get-snippets-workspace-encoded-id-comments: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, snippet: record>>"
    post-snippets-workspace-encoded-id-comments: "record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>"
    get-snippets-workspace-encoded-id-comments-comment-id: "record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>"
    put-snippets-workspace-encoded-id-comments-comment-id: "record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>"
    get-snippets-workspace-encoded-id-commits: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, links: record, snippet: record>>"
    get-snippets-workspace-encoded-id-commits-revision: "record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, links: record<diff: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>"
    get-snippets-workspace-encoded-id-watchers: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>"
    get-snippets-workspace-encoded-id-node-id: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    put-snippets-workspace-encoded-id-node-id: "record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>"
    get-pipeline-variables-for-team: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>"
    create-pipeline-variable-for-team: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-pipeline-variable-for-team: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    update-pipeline-variable-for-team: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    search-team: "record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>"
    get-user: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>"
    get-user-emails: "record<error: record<data: record, detail: string, message: string>, type: string>"
    get-user-emails-email: "record<error: record<data: record, detail: string, message: string>, type: string>"
    get-user-permissions-repositories: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>"
    get-user-permissions-workspaces: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>"
    get-users-selected-user: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>"
    get-pipeline-variables-for-user: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>"
    create-pipeline-variable-for-user: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-pipeline-variable-for-user: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    update-pipeline-variable-for-user: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    retrieve-user-hosted-property-value: "record<_attributes: list<string>>"
    search-account: "record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>"
    get-users-selected-user-ssh-keys: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record, uuid: string, owner: record>>"
    post-users-selected-user-ssh-keys: "record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-users-selected-user-ssh-keys-key-id: "record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    put-users-selected-user-ssh-keys-key-id: "record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>"
    get-workspaces: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>"
    get-workspaces-workspace: "record<type: string, created_on: string, is_private: bool, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, members: record<href: string, name: string>, owners: record<href: string, name: string>, projects: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>, snippets: record<href: string, name: string>>, name: string, slug: string, updated_on: string, uuid: string>"
    get-workspaces-workspace-hooks: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>>"
    post-workspaces-workspace-hooks: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    get-workspaces-workspace-hooks-uid: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    put-workspaces-workspace-hooks-uid: "record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>"
    get-workspaces-workspace-members: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>"
    get-workspaces-workspace-members-member: "record<type: string, links: record<self: record<href: string, name: string>>, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, workspace: record<type: string, created_on: string, is_private: bool, links: record<avatar: record, html: record, members: record, owners: record, projects: record, repositories: record, self: record, snippets: record>, name: string, slug: string, updated_on: string, uuid: string>>"
    get-workspaces-workspace-permissions: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>"
    get-workspaces-workspace-permissions-repositories: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>"
    get-workspaces-workspace-permissions-repositories-repo-slug: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>"
    get-pipeline-variables-for-workspace: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>"
    create-pipeline-variable-for-workspace: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-pipeline-variable-for-workspace: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    update-pipeline-variable-for-workspace: "record<type: string, key: string, secured: bool, uuid: string, value: string>"
    get-workspaces-workspace-projects: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>>"
    post-workspaces-workspace-projects: "record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>"
    get-workspaces-workspace-projects-project-key: "record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>"
    put-workspaces-workspace-projects-project-key: "record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>"
    get-workspaces-workspace-projects-project-key-branching-model: "record<type: string, branch_types: table<kind: string, prefix: string>, development: record<name: string, use_mainbranch: bool>, production: record<name: string, use_mainbranch: bool>>"
    get-workspaces-workspace-projects-project-key-branching-model-settings: "record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>"
    put-workspaces-workspace-projects-project-key-branching-model-settings: "record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>"
    get-workspaces-workspace-projects-project-key-default-reviewers: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>>"
    get-workspaces-workspace-projects-project-key-default-reviewers-selected-user: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>"
    put-workspaces-workspace-projects-project-key-default-reviewers-selected-user: "record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>"
    get-workspaces-workspace-projects-project-key-deploy-keys: "record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, created_by: record, key: string, label: string, last_used: string, links: record, project: record>>"
    post-workspaces-workspace-projects-project-key-deploy-keys: "record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>>"
    get-workspaces-workspace-projects-project-key-deploy-keys-key-id: "record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>>"
    search-workspace: "record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-addon" "put-addon" "get-addon-linkers" "get-addon-linkers-linker-key" "delete-addon-linkers-linker-key-values" "get-addon-linkers-linker-key-values" "post-addon-linkers-linker-key-values" "put-addon-linkers-linker-key-values" "delete-addon-linkers-linker-key-values-value-id" "get-addon-linkers-linker-key-values-value-id" "get-hook-events" "get-hook-events-subject-type" "get-pullrequests-selected-user" "get-repositories" "get-repositories-workspace" "delete-repositories-workspace-repo-slug" "get-repositories-workspace-repo-slug" "post-repositories-workspace-repo-slug" "put-repositories-workspace-repo-slug" "get-repositories-workspace-repo-slug-branch-restrictions" "post-repositories-workspace-repo-slug-branch-restrictions" "delete-repositories-workspace-repo-slug-branch-restrictions-id" "get-repositories-workspace-repo-slug-branch-restrictions-id" "put-repositories-workspace-repo-slug-branch-restrictions-id" "get-repositories-workspace-repo-slug-branching-model" "get-repositories-workspace-repo-slug-branching-model-settings" "put-repositories-workspace-repo-slug-branching-model-settings" "get-repositories-workspace-repo-slug-commit-commit" "delete-repositories-workspace-repo-slug-commit-commit-approve" "post-repositories-workspace-repo-slug-commit-commit-approve" "get-repositories-workspace-repo-slug-commit-commit-comments" "post-repositories-workspace-repo-slug-commit-commit-comments" "delete-repositories-workspace-repo-slug-commit-commit-comments-comment-id" "get-repositories-workspace-repo-slug-commit-commit-comments-comment-id" "put-repositories-workspace-repo-slug-commit-commit-comments-comment-id" "delete-commit-hosted-property-value" "get-commit-hosted-property-value" "update-commit-hosted-property-value" "get-pullrequests-for-commit" "get-reports-for-commit" "delete-report" "get-report" "create-or-update-report" "get-annotations-for-report" "bulk-create-or-update-annotations" "delete-annotation" "get-annotation" "create-or-update-annotation" "get-repositories-workspace-repo-slug-commit-commit-statuses" "post-repositories-workspace-repo-slug-commit-commit-statuses-build" "get-repositories-workspace-repo-slug-commit-commit-statuses-build-key" "put-repositories-workspace-repo-slug-commit-commit-statuses-build-key" "get-repositories-workspace-repo-slug-commits" "post-repositories-workspace-repo-slug-commits" "get-repositories-workspace-repo-slug-commits-revision" "post-repositories-workspace-repo-slug-commits-revision" "get-repositories-workspace-repo-slug-components" "get-repositories-workspace-repo-slug-components-component-id" "get-repositories-workspace-repo-slug-default-reviewers" "delete-repositories-workspace-repo-slug-default-reviewers-target-username" "get-repositories-workspace-repo-slug-default-reviewers-target-username" "put-repositories-workspace-repo-slug-default-reviewers-target-username" "get-repositories-workspace-repo-slug-deploy-keys" "post-repositories-workspace-repo-slug-deploy-keys" "delete-repositories-workspace-repo-slug-deploy-keys-key-id" "get-repositories-workspace-repo-slug-deploy-keys-key-id" "put-repositories-workspace-repo-slug-deploy-keys-key-id" "get-deployments-for-repository" "get-deployment-for-repository" "get-deployment-variables" "create-deployment-variable" "delete-deployment-variable" "update-deployment-variable" "get-repositories-workspace-repo-slug-diff-spec" "get-repositories-workspace-repo-slug-diffstat-spec" "get-repositories-workspace-repo-slug-downloads" "post-repositories-workspace-repo-slug-downloads" "delete-repositories-workspace-repo-slug-downloads-filename" "get-repositories-workspace-repo-slug-downloads-filename" "get-repositories-workspace-repo-slug-effective-branching-model" "get-repositories-workspace-repo-slug-effective-default-reviewers" "get-environments-for-repository" "create-environment" "delete-environment-for-repository" "get-environment-for-repository" "update-environment-for-repository" "get-repositories-workspace-repo-slug-filehistory-commit-path" "get-repositories-workspace-repo-slug-forks" "post-repositories-workspace-repo-slug-forks" "get-repositories-workspace-repo-slug-hooks" "post-repositories-workspace-repo-slug-hooks" "delete-repositories-workspace-repo-slug-hooks-uid" "get-repositories-workspace-repo-slug-hooks-uid" "put-repositories-workspace-repo-slug-hooks-uid" "get-repositories-workspace-repo-slug-issues" "post-repositories-workspace-repo-slug-issues" "post-repositories-workspace-repo-slug-issues-export" "get-repositories-workspace-repo-slug-issues-export-repo-name-issues-task-id-zip" "get-repositories-workspace-repo-slug-issues-import" "post-repositories-workspace-repo-slug-issues-import" "delete-repositories-workspace-repo-slug-issues-issue-id" "get-repositories-workspace-repo-slug-issues-issue-id" "put-repositories-workspace-repo-slug-issues-issue-id" "get-repositories-workspace-repo-slug-issues-issue-id-attachments" "post-repositories-workspace-repo-slug-issues-issue-id-attachments" "delete-repositories-workspace-repo-slug-issues-issue-id-attachments-path" "get-repositories-workspace-repo-slug-issues-issue-id-attachments-path" "get-repositories-workspace-repo-slug-issues-issue-id-changes" "post-repositories-workspace-repo-slug-issues-issue-id-changes" "get-repositories-workspace-repo-slug-issues-issue-id-changes-change-id" "get-repositories-workspace-repo-slug-issues-issue-id-comments" "post-repositories-workspace-repo-slug-issues-issue-id-comments" "delete-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" "get-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" "put-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" "delete-repositories-workspace-repo-slug-issues-issue-id-vote" "get-repositories-workspace-repo-slug-issues-issue-id-vote" "put-repositories-workspace-repo-slug-issues-issue-id-vote" "delete-repositories-workspace-repo-slug-issues-issue-id-watch" "get-repositories-workspace-repo-slug-issues-issue-id-watch" "put-repositories-workspace-repo-slug-issues-issue-id-watch" "get-repositories-workspace-repo-slug-merge-base-revspec" "get-repositories-workspace-repo-slug-milestones" "get-repositories-workspace-repo-slug-milestones-milestone-id" "get-repositories-workspace-repo-slug-override-settings" "put-repositories-workspace-repo-slug-override-settings" "get-repositories-workspace-repo-slug-patch-spec" "get-repositories-workspace-repo-slug-permissions-config-groups" "delete-repositories-workspace-repo-slug-permissions-config-groups-group-slug" "get-repositories-workspace-repo-slug-permissions-config-groups-group-slug" "put-repositories-workspace-repo-slug-permissions-config-groups-group-slug" "get-repositories-workspace-repo-slug-permissions-config-users" "delete-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" "get-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" "put-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" "delete-repository-pipeline-caches" "get-repository-pipeline-caches" "delete-repository-pipeline-cache" "get-repository-pipeline-cache-content-uri" "get-pipelines-for-repository" "create-pipeline-for-repository" "get-pipeline-for-repository" "get-pipeline-steps-for-repository" "get-pipeline-step-for-repository" "get-pipeline-step-log-for-repository" "get-pipeline-container-log" "get-pipeline-test-reports" "get-pipeline-test-report-test-cases" "get-pipeline-test-report-test-case-reasons" "stop-pipeline" "get-repository-pipeline-config" "update-repository-pipeline-config" "update-repository-build-number" "get-repository-pipeline-schedules" "create-repository-pipeline-schedule" "delete-repository-pipeline-schedule" "get-repository-pipeline-schedule" "update-repository-pipeline-schedule" "get-repository-pipeline-schedule-executions" "delete-repository-pipeline-key-pair" "get-repository-pipeline-ssh-key-pair" "update-repository-pipeline-key-pair" "get-repository-pipeline-known-hosts" "create-repository-pipeline-known-host" "delete-repository-pipeline-known-host" "get-repository-pipeline-known-host" "update-repository-pipeline-known-host" "get-repository-pipeline-variables" "create-repository-pipeline-variable" "delete-repository-pipeline-variable" "get-repository-pipeline-variable" "update-repository-pipeline-variable" "delete-repository-hosted-property-value" "get-repository-hosted-property-value" "update-repository-hosted-property-value" "get-repositories-workspace-repo-slug-pullrequests" "post-repositories-workspace-repo-slug-pullrequests" "get-repositories-workspace-repo-slug-pullrequests-activity" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id" "put-repositories-workspace-repo-slug-pullrequests-pull-request-id" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-activity" "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-approve" "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-approve" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments" "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments" "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" "put-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-commits" "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-decline" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-diff" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-diffstat" "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-merge" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-merge-task-status-task-id" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-patch" "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-request-changes" "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-request-changes" "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-statuses" "delete-pull-request-hosted-property-value" "get-pull-request-hosted-property-value" "update-pull-request-hosted-property-value" "get-repositories-workspace-repo-slug-refs" "get-repositories-workspace-repo-slug-refs-branches" "post-repositories-workspace-repo-slug-refs-branches" "delete-repositories-workspace-repo-slug-refs-branches-name" "get-repositories-workspace-repo-slug-refs-branches-name" "get-repositories-workspace-repo-slug-refs-tags" "post-repositories-workspace-repo-slug-refs-tags" "delete-repositories-workspace-repo-slug-refs-tags-name" "get-repositories-workspace-repo-slug-refs-tags-name" "get-repositories-workspace-repo-slug-src" "post-repositories-workspace-repo-slug-src" "get-repositories-workspace-repo-slug-src-commit-path" "get-repositories-workspace-repo-slug-versions" "get-repositories-workspace-repo-slug-versions-version-id" "get-repositories-workspace-repo-slug-watchers" "get-snippets" "post-snippets" "get-snippets-workspace" "post-snippets-workspace" "delete-snippets-workspace-encoded-id" "get-snippets-workspace-encoded-id" "put-snippets-workspace-encoded-id" "get-snippets-workspace-encoded-id-comments" "post-snippets-workspace-encoded-id-comments" "delete-snippets-workspace-encoded-id-comments-comment-id" "get-snippets-workspace-encoded-id-comments-comment-id" "put-snippets-workspace-encoded-id-comments-comment-id" "get-snippets-workspace-encoded-id-commits" "get-snippets-workspace-encoded-id-commits-revision" "get-snippets-workspace-encoded-id-files-path" "delete-snippets-workspace-encoded-id-watch" "get-snippets-workspace-encoded-id-watch" "put-snippets-workspace-encoded-id-watch" "get-snippets-workspace-encoded-id-watchers" "delete-snippets-workspace-encoded-id-node-id" "get-snippets-workspace-encoded-id-node-id" "put-snippets-workspace-encoded-id-node-id" "get-snippets-workspace-encoded-id-node-id-files-path" "get-snippets-workspace-encoded-id-revision-diff" "get-snippets-workspace-encoded-id-revision-patch" "get-pipeline-variables-for-team" "create-pipeline-variable-for-team" "delete-pipeline-variable-for-team" "get-pipeline-variable-for-team" "update-pipeline-variable-for-team" "search-team" "get-user" "get-user-emails" "get-user-emails-email" "get-user-permissions-repositories" "get-user-permissions-workspaces" "get-users-selected-user" "get-pipeline-variables-for-user" "create-pipeline-variable-for-user" "delete-pipeline-variable-for-user" "get-pipeline-variable-for-user" "update-pipeline-variable-for-user" "delete-user-hosted-property-value" "retrieve-user-hosted-property-value" "update-user-hosted-property-value" "search-account" "get-users-selected-user-ssh-keys" "post-users-selected-user-ssh-keys" "delete-users-selected-user-ssh-keys-key-id" "get-users-selected-user-ssh-keys-key-id" "put-users-selected-user-ssh-keys-key-id" "get-workspaces" "get-workspaces-workspace" "get-workspaces-workspace-hooks" "post-workspaces-workspace-hooks" "delete-workspaces-workspace-hooks-uid" "get-workspaces-workspace-hooks-uid" "put-workspaces-workspace-hooks-uid" "get-workspaces-workspace-members" "get-workspaces-workspace-members-member" "get-workspaces-workspace-permissions" "get-workspaces-workspace-permissions-repositories" "get-workspaces-workspace-permissions-repositories-repo-slug" "get-oidc-configuration" "get-oidc-keys" "get-pipeline-variables-for-workspace" "create-pipeline-variable-for-workspace" "delete-pipeline-variable-for-workspace" "get-pipeline-variable-for-workspace" "update-pipeline-variable-for-workspace" "get-workspaces-workspace-projects" "post-workspaces-workspace-projects" "delete-workspaces-workspace-projects-project-key" "get-workspaces-workspace-projects-project-key" "put-workspaces-workspace-projects-project-key" "get-workspaces-workspace-projects-project-key-branching-model" "get-workspaces-workspace-projects-project-key-branching-model-settings" "put-workspaces-workspace-projects-project-key-branching-model-settings" "get-workspaces-workspace-projects-project-key-default-reviewers" "delete-workspaces-workspace-projects-project-key-default-reviewers-selected-user" "get-workspaces-workspace-projects-project-key-default-reviewers-selected-user" "put-workspaces-workspace-projects-project-key-default-reviewers-selected-user" "get-workspaces-workspace-projects-project-key-deploy-keys" "post-workspaces-workspace-projects-project-key-deploy-keys" "delete-workspaces-workspace-projects-project-key-deploy-keys-key-id" "get-workspaces-workspace-projects-project-key-deploy-keys-key-id" "search-workspace" "commands"] | sort) } | get name | first)
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

# Delete an app
#
# DELETE /addon
export def "delete-addon" [
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
    path: "/addon"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an installed app
#
# PUT /addon
export def "put-addon" [
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
    method: put
    path: "/addon"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List linkers for an app
#
# GET /addon/linkers
export def "get-addon-linkers" [
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
    path: "/addon/linkers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a linker for an app
#
# GET /addon/linkers/{linker_key}
export def "get-addon-linkers-linker-key" [
  linker_key: string
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
    path: "/addon/linkers/{linker_key}"
    path_params: [{name: linker_key, var: linker_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linker_key: $linker_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all linker values
#
# DELETE /addon/linkers/{linker_key}/values
export def "delete-addon-linkers-linker-key-values" [
  linker_key: string
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
    path: "/addon/linkers/{linker_key}/values"
    path_params: [{name: linker_key, var: linker_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    linker_key: $linker_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List linker values for a linker
#
# GET /addon/linkers/{linker_key}/values
export def "get-addon-linkers-linker-key-values" [
  linker_key: string
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
    path: "/addon/linkers/{linker_key}/values"
    path_params: [{name: linker_key, var: linker_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linker_key: $linker_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a linker value
#
# POST /addon/linkers/{linker_key}/values
export def "post-addon-linkers-linker-key-values" [
  linker_key: string
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
    method: post
    path: "/addon/linkers/{linker_key}/values"
    path_params: [{name: linker_key, var: linker_key}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    linker_key: $linker_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a linker value
#
# PUT /addon/linkers/{linker_key}/values
export def "put-addon-linkers-linker-key-values" [
  linker_key: string
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
    method: put
    path: "/addon/linkers/{linker_key}/values"
    path_params: [{name: linker_key, var: linker_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    linker_key: $linker_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a linker value
#
# DELETE /addon/linkers/{linker_key}/values/{value_id}
export def "delete-addon-linkers-linker-key-values-value-id" [
  linker_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/addon/linkers/{linker_key}/values/{value_id}"
    path_params: [{name: linker_key, var: linker_key}, {name: value_id, var: value_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    linker_key: $linker_key, value_id: $value_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a linker value
#
# GET /addon/linkers/{linker_key}/values/{value_id}
export def "get-addon-linkers-linker-key-values-value-id" [
  linker_key: string
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
]: nothing -> any {
  http-request {
    method: get
    path: "/addon/linkers/{linker_key}/values/{value_id}"
    path_params: [{name: linker_key, var: linker_key}, {name: value_id, var: value_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    linker_key: $linker_key, value_id: $value_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook resource
#
# GET /hook_events
# Returns: record<repository: record<events: record<href: string, name: string>>, workspace: record<events: record<href: string, name: string>>>
export def "get-hook-events" [
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
    path: "/hook_events"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List subscribable webhook types
#
# GET /hook_events/{subject_type}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<category: string, description: string, event: string, label: string>>
export def "get-hook-events-subject-type" [
  subject_type: string@subject-type-completer
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
    path: "/hook_events/{subject_type}"
    path_params: [{name: subject_type, var: subject_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_type: $subject_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pull requests for a user
#
# GET /pullrequests/{selected_user}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>
export def "get-pullrequests-selected-user" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/pullrequests/{selected_user}"
    path_params: [{name: selected_user, var: selected_user}]
    query: [{name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List public repositories
#
# GET /repositories
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Filter the results to include only repositories created on or after this [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) timestamp. Example: `YYYY-MM-DDTHH:mm:ss.sssZ`
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). `role` parameter must also be specified.
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories"
    query: [{name: after, var: after}, {name: role, var: role}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    after: $after, role: $role, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repositories in a workspace
#
# GET /repositories/{workspace}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}"
    path_params: [{name: workspace, var: workspace}]
    query: [{name: role, var: role}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, role: $role, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a repository
#
# DELETE /repositories/{workspace}/{repo_slug}
export def "delete-repositories-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-to: string # If a repository has been moved to a new location, use this parameter to show users a friendly message in the Bitbucket UI that the repository has moved to a new location. However, a GET to this endpoint will still return a 404.
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: redirect_to, var: redirect_to}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, redirect_to: $redirect_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a repository
#
# GET /repositories/{workspace}/{repo_slug}
# Returns: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>
export def "get-repositories-workspace-repo-slug" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a repository
#
# POST /repositories/{workspace}/{repo_slug}
# Returns: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>
export def "post-repositories-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: record # A ref object, representing a branch or tag in a repository. — shape: {links?: record, name?: string, target?: record, type: string, default_merge_strategy?: string, merge_strategies?: list<string>}
  --name: string
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
  --project: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, has_publicly_visible_repos?: bool, is_private?: bool, key?: string, links?: record, name?: string, owner?: record, updated_on?: string, uuid?: string}
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: fork_policy, var: fork_policy}, {name: full_name, var: full_name}, {name: has_issues, var: has_issues}, {name: has_wiki, var: has_wiki}, {name: is_private, var: is_private}, {name: language, var: language}, {name: links, var: links}, {name: mainbranch, var: mainbranch}, {name: name, var: name}, {name: owner, var: owner}, {name: parent, var: parent}, {name: project, var: project}, {name: scm, var: scm}, {name: size, var: size}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, created_on: $created_on, description: $description, fork_policy: $fork_policy, full_name: $full_name, has_issues: $has_issues, has_wiki: $has_wiki, is_private: $is_private, language: $language, links: $links, mainbranch: $mainbranch, name: $name, owner: $owner, parent: $parent, project: $project, scm: $scm, size: $size, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a repository
#
# PUT /repositories/{workspace}/{repo_slug}
# Returns: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>
export def "put-repositories-workspace-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: record # A ref object, representing a branch or tag in a repository. — shape: {links?: record, name?: string, target?: record, type: string, default_merge_strategy?: string, merge_strategies?: list<string>}
  --name: string
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
  --project: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, has_publicly_visible_repos?: bool, is_private?: bool, key?: string, links?: record, name?: string, owner?: record, updated_on?: string, uuid?: string}
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: fork_policy, var: fork_policy}, {name: full_name, var: full_name}, {name: has_issues, var: has_issues}, {name: has_wiki, var: has_wiki}, {name: is_private, var: is_private}, {name: language, var: language}, {name: links, var: links}, {name: mainbranch, var: mainbranch}, {name: name, var: name}, {name: owner, var: owner}, {name: parent, var: parent}, {name: project, var: project}, {name: scm, var: scm}, {name: size, var: size}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, created_on: $created_on, description: $description, fork_policy: $fork_policy, full_name: $full_name, has_issues: $has_issues, has_wiki: $has_wiki, is_private: $is_private, language: $language, links: $links, mainbranch: $mainbranch, name: $name, owner: $owner, parent: $parent, project: $project, scm: $scm, size: $size, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List branch restrictions
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, groups: list, users: list>>
export def "get-repositories-workspace-repo-slug-branch-restrictions" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Branch restrictions of this type
  --pattern: string # Branch restrictions applied to branches of this pattern
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/branch-restrictions"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: kind, var: kind}, {name: pattern, var: pattern}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, kind: $kind, pattern: $pattern
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a branch restriction rule
#
# POST /repositories/{workspace}/{repo_slug}/branch-restrictions
# Returns: record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-branch-restrictions" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --groups: list # item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: record, slug?: string, workspace?: record}
  --users: list # item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/branch-restrictions"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: groups, var: groups}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, groups: $groups, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a branch restriction rule
#
# DELETE /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
export def "delete-repositories-workspace-repo-slug-branch-restrictions-id" [
  workspace: string
  repo_slug: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a branch restriction rule
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
# Returns: record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-branch-restrictions-id" [
  workspace: string
  repo_slug: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a branch restriction rule
#
# PUT /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
# Returns: record<type: string, groups: table<type: string, full_slug: string, links: record, name: string, owner: record, slug: string, workspace: record>, users: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
export def "put-repositories-workspace-repo-slug-branch-restrictions-id" [
  workspace: string
  repo_slug: string
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
  type: string
  --groups: list # item shape: {type: string, full_slug?: string, links?: record, name?: string, owner?: record, slug?: string, workspace?: record}
  --users: list # item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/branch-restrictions/{id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: groups, var: groups}, {name: users, var: users}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, id: $id, type: $type, groups: $groups, users: $users
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model
# Returns: record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>>
export def "get-repositories-workspace-repo-slug-branching-model" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/branching-model"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the branching model config for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model/settings
# Returns: record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>
export def "get-repositories-workspace-repo-slug-branching-model-settings" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/branching-model/settings"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the branching model config for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/branching-model/settings
# Returns: record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>
export def "put-repositories-workspace-repo-slug-branching-model-settings" [
  workspace: string
  repo_slug: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/branching-model/settings"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}
# Returns: record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-commit-commit" [
  workspace: string
  repo_slug: string
  commit: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unapprove a commit
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
export def "delete-repositories-workspace-repo-slug-commit-commit-approve" [
  workspace: string
  repo_slug: string
  commit: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/approve"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
# Returns: record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-commit-commit-approve" [
  workspace: string
  repo_slug: string
  commit: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/approve"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a commit's comments
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, commit: record>>
export def "get-repositories-workspace-repo-slug-commit-commit-comments" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create comment for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
export def "post-repositories-workspace-repo-slug-commit-commit-comments" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --body-commit: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, author?: record, date?: string, hash?: string, message?: string, parents?: list, summary?: record, participants?: list, repository?: record} (spec name: commit)
]: any -> any {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: commit, var: body_commit}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, body_commit: $body_commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a commit comment
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "delete-repositories-workspace-repo-slug-commit-commit-comments-comment-id" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a commit comment
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, commit: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>>
export def "get-repositories-workspace-repo-slug-commit-commit-comments-comment-id" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a commit comment
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "put-repositories-workspace-repo-slug-commit-commit-comments-comment-id" [
  workspace: string
  repo_slug: string
  commit: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --body-commit: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, author?: record, date?: string, hash?: string, message?: string, parents?: list, summary?: record, participants?: list, repository?: record} (spec name: commit)
]: any -> any {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: commit, var: body_commit}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, comment_id: $comment_id, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, body_commit: $body_commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a commit application property
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: deleteCommitHostedPropertyValue
export def "delete-commit-hosted-property-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a commit application property
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# Returns: record<_attributes: list<string>>
# operationId: getCommitHostedPropertyValue
export def "get-commit-hosted-property-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a commit application property
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: updateCommitHostedPropertyValue
export def "update-commit-hosted-property-value" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: _attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, app_key: $app_key, property_name: $property_name, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pull requests that contain a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>
# operationId: getPullrequestsForCommit
export def "get-pullrequests-for-commit" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page to retrieve (format: int32, default: 1)
  --pagelen: int # How many pull requests to retrieve per page (format: int32, default: 30)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    query: [{name: page, var: page}, {name: pagelen, var: pagelen}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, page: $page, pagelen: $pagelen
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reports
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, data: list, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>>
# operationId: getReportsForCommit
export def "get-reports-for-commit" [
  workspace: string
  repo_slug: string
  commit: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a report
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: deleteReport
export def "delete-report" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a report
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# Returns: record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>
# operationId: getReport
export def "get-report" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a report
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# Returns: record<type: string, created_on: string, data: table<title: string, type: string, value: record>, details: string, external_id: string, link: string, logo_url: string, remote_link_enabled: bool, report_type: string, reporter: string, result: string, title: string, updated_on: string, uuid: string>
# operationId: createOrUpdateReport
export def "create-or-update-report" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --data: list # An array of data fields to display information on the report. Maximum 10. — item shape: {title?: string, type?: "BOOLEAN"|"DATE"|"DURATION"|"LINK"|"NUMBER"|"PERCENTAGE"|"TEXT", value?: record}
  --details: string # A string to describe the purpose of the report.
  --external-id: string # ID of the report provided by the report creator. It can be used to identify the report as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the report creator for updating or deleting this specific report. Needs to be unique.
  --link: string # A URL linking to the results of the report in an external tool. (format: uri)
  --logo-url: string # A URL to the report logo. If none is provided, the default insights logo will be used. (format: uri)
  --remote-link-enabled: oneof<nothing, bool> # If enabled, a remote link is created in Jira for the issue associated with the commit the report belongs to.
  --report-type: string@report-type-completer # The type of the report.
  --reporter: string # A string to describe the tool or company who created the report.
  --result: string@result-completer # The state of the report. May be set to PENDING and later updated.
  --title: string # The title of the report.
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
  --uuid: string # The UUID that can be used to identify the report.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: data, var: data}, {name: details, var: details}, {name: external_id, var: external_id}, {name: link, var: link}, {name: logo_url, var: logo_url}, {name: remote_link_enabled, var: remote_link_enabled}, {name: report_type, var: report_type}, {name: reporter, var: reporter}, {name: result, var: result}, {name: title, var: title}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id, type: $type, created_on: $created_on, data: $data, details: $details, external_id: $external_id, link: $link, logo_url: $logo_url, remote_link_enabled: $remote_link_enabled, report_type: $report_type, reporter: $reporter, result: $result, title: $title, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List annotations
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>>
# operationId: getAnnotationsForReport
export def "get-annotations-for-report" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk create or update annotations
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# Returns: table<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>
# operationId: bulkCreateOrUpdateAnnotations
export def "bulk-create-or-update-annotations" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
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
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an annotation
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: deleteAnnotation
export def "delete-annotation" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}, {name: annotationId, var: annotation_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id, annotation_id: $annotation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an annotation
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# Returns: record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>
# operationId: getAnnotation
export def "get-annotation" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}, {name: annotationId, var: annotation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id, annotation_id: $annotation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update an annotation
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# Returns: record<type: string, annotation_type: string, created_on: string, details: string, external_id: string, line: int, link: string, path: string, result: string, severity: string, summary: string, updated_on: string, uuid: string>
# operationId: createOrUpdateAnnotation
export def "create-or-update-annotation" [
  workspace: string
  repo_slug: string
  commit: string
  report_id: string
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --annotation-type: string@annotation-type-completer # The type of the report.
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --details: string # The details to show to users when clicking on the annotation.
  --external-id: string # ID of the annotation provided by the annotation creator. It can be used to identify the annotation as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the annotation creator for updating or deleting this specific annotation. Needs to be unique.
  --line: int # The line number that the annotation should belong to. If no line number is provided, then it will default to 0 and in a pull request it will appear at the top of the file specified by the path field.
  --link: string # A URL linking to the annotation in an external tool. (format: uri)
  --path: string # The path of the file on which this annotation should be placed. This is the path of the file relative to the git repository. If no path is provided, then it will appear in the overview modal on all pull requests where the tip of the branch is the given commit, regardless of which files were modified.
  --result: string@result-completer-1 # The state of the report. May be set to PENDING and later updated.
  --severity: string@severity-completer # The severity of the annotation.
  --summary: string # The message to display to users.
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
  --uuid: string # The UUID that can be used to identify the annotation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: reportId, var: report_id}, {name: annotationId, var: annotation_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: annotation_type, var: annotation_type}, {name: created_on, var: created_on}, {name: details, var: details}, {name: external_id, var: external_id}, {name: line, var: line}, {name: link, var: link}, {name: path, var: path}, {name: result, var: result}, {name: severity, var: severity}, {name: summary, var: summary}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, report_id: $report_id, annotation_id: $annotation_id, type: $type, annotation_type: $annotation_type, created_on: $created_on, details: $details, external_id: $external_id, line: $line, link: $link, path: $path, result: $result, severity: $severity, summary: $summary, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commit statuses for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-commit-commit-statuses" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a build status for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build
# Returns: record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>
export def "post-repositories-workspace-repo-slug-commit-commit-statuses-build" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --key: string # An identifier for the status that's unique to its type (current "build" is the only supported type) and the vendor, e.g. BB-DEPLOY
  --links: record # shape: {commit?: record, self?: record}
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --refname: string # The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --state: string@state-completer-1 # Provides some indication of the status of this commit
  --updated-on: string # format: date-time
  --url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  --uuid: string # The commit status' id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: key, var: key}, {name: links, var: links}, {name: name, var: name}, {name: refname, var: refname}, {name: state, var: state}, {name: updated_on, var: updated_on}, {name: url, var: url}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, type: $type, created_on: $created_on, description: $description, key: $key, links: $links, name: $name, refname: $refname, state: $state, updated_on: $updated_on, url: $url, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a build status for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
# Returns: record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>
export def "get-repositories-workspace-repo-slug-commit-commit-statuses-build-key" [
  workspace: string
  repo_slug: string
  commit: string
  key: string
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
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a build status for a commit
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
# Returns: record<type: string, created_on: string, description: string, key: string, links: record<commit: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>
export def "put-repositories-workspace-repo-slug-commit-commit-statuses-build-key" [
  workspace: string
  repo_slug: string
  commit: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --body-key: string # An identifier for the status that's unique to its type (current "build" is the only supported type) and the vendor, e.g. BB-DEPLOY (spec name: key)
  --links: record # shape: {commit?: record, self?: record}
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --refname: string # The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --state: string@state-completer-1 # Provides some indication of the status of this commit
  --updated-on: string # format: date-time
  --url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  --uuid: string # The commit status' id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: key, var: key}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: key, var: body_key}, {name: links, var: links}, {name: name, var: name}, {name: refname, var: refname}, {name: state, var: state}, {name: updated_on, var: updated_on}, {name: url, var: url}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, key: $key, type: $type, created_on: $created_on, description: $description, body_key: $body_key, links: $links, name: $name, refname: $refname, state: $state, updated_on: $updated_on, url: $url, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits
#
# GET /repositories/{workspace}/{repo_slug}/commits
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>
export def "get-repositories-workspace-repo-slug-commits" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/commits"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits with include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>
export def "post-repositories-workspace-repo-slug-commits" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/commits"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits for revision
#
# GET /repositories/{workspace}/{repo_slug}/commits/{revision}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>
export def "get-repositories-workspace-repo-slug-commits-revision" [
  workspace: string
  repo_slug: string
  revision: string
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
    path: "/repositories/{workspace}/{repo_slug}/commits/{revision}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: revision, var: revision}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits for revision using include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits/{revision}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>>
export def "post-repositories-workspace-repo-slug-commits-revision" [
  workspace: string
  repo_slug: string
  revision: string
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
    path: "/repositories/{workspace}/{repo_slug}/commits/{revision}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: revision, var: revision}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List components
#
# GET /repositories/{workspace}/{repo_slug}/components
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>
export def "get-repositories-workspace-repo-slug-components" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/components"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a component for issues
#
# GET /repositories/{workspace}/{repo_slug}/components/{component_id}
# Returns: record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>
export def "get-repositories-workspace-repo-slug-components-component-id" [
  workspace: string
  repo_slug: string
  component_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/components/{component_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: component_id, var: component_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, component_id: $component_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-default-reviewers" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/default-reviewers"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from the default reviewers
#
# DELETE /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "delete-repositories-workspace-repo-slug-default-reviewers-target-username" [
  workspace: string
  repo_slug: string
  target_username: string
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
    path: "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: target_username, var: target_username}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, target_username: $target_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a default reviewer
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>
export def "get-repositories-workspace-repo-slug-default-reviewers-target-username" [
  workspace: string
  repo_slug: string
  target_username: string
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
    path: "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: target_username, var: target_username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, target_username: $target_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to the default reviewers
#
# PUT /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>
export def "put-repositories-workspace-repo-slug-default-reviewers-target-username" [
  workspace: string
  repo_slug: string
  target_username: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: target_username, var: target_username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, target_username: $target_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repository deploy keys
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record, owner: record, repository: record>>
export def "get-repositories-workspace-repo-slug-deploy-keys" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/deploy-keys"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a repository deploy key
#
# POST /repositories/{workspace}/{repo_slug}/deploy-keys
# Returns: record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-deploy-keys" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/deploy-keys"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a repository deploy key
#
# DELETE /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "delete-repositories-workspace-repo-slug-deploy-keys-key-id" [
  workspace: string
  repo_slug: string
  key_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a repository deploy key
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
# Returns: record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-deploy-keys-key-id" [
  workspace: string
  repo_slug: string
  key_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a repository deploy key
#
# PUT /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
# Returns: record<type: string, added_on: string, comment: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
export def "put-repositories-workspace-repo-slug-deploy-keys-key-id" [
  workspace: string
  repo_slug: string
  key_id: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List deployments
#
# GET /repositories/{workspace}/{repo_slug}/deployments/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, environment: record, release: record, state: record, uuid: string>>
# operationId: getDeploymentsForRepository
export def "get-deployments-for-repository" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/deployments/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a deployment
#
# GET /repositories/{workspace}/{repo_slug}/deployments/{deployment_uuid}
# Returns: record<type: string, environment: record<type: string, name: string, uuid: string>, release: record<type: string, commit: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: record>, created_on: string, name: string, url: string, uuid: string>, state: record<type: string>, uuid: string>
# operationId: getDeploymentForRepository
export def "get-deployment-for-repository" [
  workspace: string
  repo_slug: string
  deployment_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/deployments/{deployment_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: deployment_uuid, var: deployment_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, deployment_uuid: $deployment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables for an environment
#
# GET /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>
# operationId: getDeploymentVariables
export def "get-deployment-variables" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable for an environment
#
# POST /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: createDeploymentVariable
export def "create-deployment-variable" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable for an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# operationId: deleteDeploymentVariable
export def "delete-deployment-variable" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable for an environment
#
# PUT /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: updateDeploymentVariable
export def "update-deployment-variable" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}, {name: variable_uuid, var: variable_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid, variable_uuid: $variable_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare two commits
#
# GET /repositories/{workspace}/{repo_slug}/diff/{spec}
export def "get-repositories-workspace-repo-slug-diff-spec" [
  workspace: string
  repo_slug: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: int # Generate diffs with lines of context instead of the usual three.
  --path: string # Limit the diff to a particular file (this parameter can be repeated for multiple paths).
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace.
  --binary: oneof<nothing, bool> # Generate diffs that include binary files, true if omitted.
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --merge: oneof<nothing, bool> # This parameter is deprecated and will be removed at the end of 2022. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time. If true, the source commit is merged into the destination commit, and then a diff from the destination to the merge result is returned. If false, a simple 'two dot' diff between the source and destination is returned. True if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.
]: nothing -> any {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/diff/{spec}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: spec, var: spec}]
    query: [{name: context, var: context}, {name: path, var: path}, {name: ignore_whitespace, var: ignore_whitespace}, {name: binary, var: binary}, {name: renames, var: renames}, {name: merge, var: merge}, {name: topic, var: topic}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, spec: $spec, context: $context, path: $path, ignore_whitespace: $ignore_whitespace, binary: $binary, renames: $renames, merge: $merge, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare two commit diff stats
#
# GET /repositories/{workspace}/{repo_slug}/diffstat/{spec}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<lines_added: int, lines_removed: int, new: record, old: record, status: string, type: string>>
export def "get-repositories-workspace-repo-slug-diffstat-spec" [
  workspace: string
  repo_slug: string
  spec: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace
  --merge: oneof<nothing, bool> # This parameter is deprecated and will be removed at the end of 2022. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time. If true, the source commit is merged into the destination commit, and then a diffstat from the destination to the merge result is returned. If false, a simple 'two dot' diffstat between the source and destination is returned. True if omitted.
  --path: string # Limit the diffstat to a particular file (this parameter can be repeated for multiple paths).
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/diffstat/{spec}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: spec, var: spec}]
    query: [{name: ignore_whitespace, var: ignore_whitespace}, {name: merge, var: merge}, {name: path, var: path}, {name: renames, var: renames}, {name: topic, var: topic}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, spec: $spec, ignore_whitespace: $ignore_whitespace, merge: $merge, path: $path, renames: $renames, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List download artifacts
#
# GET /repositories/{workspace}/{repo_slug}/downloads
export def "get-repositories-workspace-repo-slug-downloads" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/downloads"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a download artifact
#
# POST /repositories/{workspace}/{repo_slug}/downloads
export def "post-repositories-workspace-repo-slug-downloads" [
  workspace: string
  repo_slug: string
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
    method: post
    path: "/repositories/{workspace}/{repo_slug}/downloads"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a download artifact
#
# DELETE /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "delete-repositories-workspace-repo-slug-downloads-filename" [
  workspace: string
  repo_slug: string
  filename: string
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
    path: "/repositories/{workspace}/{repo_slug}/downloads/{filename}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: filename, var: filename}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a download artifact link
#
# GET /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "get-repositories-workspace-repo-slug-downloads-filename" [
  workspace: string
  repo_slug: string
  filename: string
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
    path: "/repositories/{workspace}/{repo_slug}/downloads/{filename}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: filename, var: filename}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the effective, or currently applied, branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/effective-branching-model
# Returns: record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>, production: record<branch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, use_mainbranch: bool>>
export def "get-repositories-workspace-repo-slug-effective-branching-model" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/effective-branching-model"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List effective default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/effective-default-reviewers
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>>
export def "get-repositories-workspace-repo-slug-effective-default-reviewers" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/effective-default-reviewers"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environments
#
# GET /repositories/{workspace}/{repo_slug}/environments/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, name: string, uuid: string>>
# operationId: getEnvironmentsForRepository
export def "get-environments-for-repository" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/environments/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments/
# Returns: record<type: string, name: string, uuid: string>
# operationId: createEnvironment
export def "create-environment" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --name: string # The name of the environment.
  --uuid: string # The UUID identifying the environment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/environments/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: name, var: name}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, name: $name, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# operationId: deleteEnvironmentForRepository
export def "delete-environment-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an environment
#
# GET /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# Returns: record<type: string, name: string, uuid: string>
# operationId: getEnvironmentForRepository
export def "get-environment-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}/changes/
# operationId: updateEnvironmentForRepository
export def "update-environment-for-repository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
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
    method: post
    path: "/repositories/{workspace}/{repo_slug}/environments/{environment_uuid}/changes/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: environment_uuid, var: environment_uuid}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, environment_uuid: $environment_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits that modified a file
#
# GET /repositories/{workspace}/{repo_slug}/filehistory/{commit}/{path}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<attributes: string, commit: record, escaped_path: string, path: string, type: string>>
export def "get-repositories-workspace-repo-slug-filehistory-commit-path" [
  workspace: string
  repo_slug: string
  commit: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --renames: string # When `true`, Bitbucket will follow the history of the file across renames (this is the default behavior). This can be turned off by specifying `false`.
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/filehistory/{commit}/{path}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: path, var: path}]
    query: [{name: renames, var: renames}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, path: $path, renames: $renames, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repository forks
#
# GET /repositories/{workspace}/{repo_slug}/forks
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-forks" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository. * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/forks"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: role, var: role}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, role: $role, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fork a repository
#
# POST /repositories/{workspace}/{repo_slug}/forks
# Returns: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record<href: string, name: string>, clone: list<record>, commits: record<href: string, name: string>, downloads: record<href: string, name: string>, forks: record<href: string, name: string>, hooks: record<href: string, name: string>, html: record<href: string, name: string>, pullrequests: record<href: string, name: string>, self: record<href: string, name: string>, watchers: record<href: string, name: string>>, mainbranch: record<links: record<commits: record, html: record, self: record>, name: string, target: record<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, participants: list, repository: any>, type: string, default_merge_strategy: string, merge_strategies: list<string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>
export def "post-repositories-workspace-repo-slug-forks" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --fork-policy: string@fork-policy-completer # Controls the rules for forking this repository. * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot be made public later) * **no_forks**: deny all forking
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --has-issues: oneof<nothing, bool>
  --has-wiki: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --language: string
  --links: record # shape: {avatar?: record, clone?: list, commits?: record, downloads?: record, forks?: record, hooks?: record, html?: record, pullrequests?: record, self?: record, watchers?: record}
  --mainbranch: record # A ref object, representing a branch or tag in a repository. — shape: {links?: record, name?: string, target?: record, type: string, default_merge_strategy?: string, merge_strategies?: list<string>}
  --name: string
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
  --project: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, has_publicly_visible_repos?: bool, is_private?: bool, key?: string, links?: record, name?: string, owner?: record, updated_on?: string, uuid?: string}
  --scm: string@scm-completer
  --size: int
  --updated-on: string # format: date-time
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/forks"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: fork_policy, var: fork_policy}, {name: full_name, var: full_name}, {name: has_issues, var: has_issues}, {name: has_wiki, var: has_wiki}, {name: is_private, var: is_private}, {name: language, var: language}, {name: links, var: links}, {name: mainbranch, var: mainbranch}, {name: name, var: name}, {name: owner, var: owner}, {name: parent, var: parent}, {name: project, var: project}, {name: scm, var: scm}, {name: size, var: size}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, created_on: $created_on, description: $description, fork_policy: $fork_policy, full_name: $full_name, has_issues: $has_issues, has_wiki: $has_wiki, is_private: $is_private, language: $language, links: $links, mainbranch: $mainbranch, name: $name, owner: $owner, parent: $parent, project: $project, scm: $scm, size: $size, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhooks for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-hooks" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/hooks"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook for a repository
#
# POST /repositories/{workspace}/{repo_slug}/hooks
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "post-repositories-workspace-repo-slug-hooks" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/hooks"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "delete-repositories-workspace-repo-slug-hooks-uid" [
  workspace: string
  repo_slug: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks/{uid}
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "get-repositories-workspace-repo-slug-hooks-uid" [
  workspace: string
  repo_slug: string
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
    method: get
    path: "/repositories/{workspace}/{repo_slug}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/hooks/{uid}
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "put-repositories-workspace-repo-slug-hooks-uid" [
  workspace: string
  repo_slug: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List issues
#
# GET /repositories/{workspace}/{repo_slug}/issues
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, assignee: record, component: record, content: record, created_on: string, edited_on: string, id: int, kind: string, links: record, milestone: record, priority: string, reporter: record, repository: record, state: string, title: string, updated_on: string, version: record, votes: int>>
export def "get-repositories-workspace-repo-slug-issues" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues
# Returns: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>
export def "post-repositories-workspace-repo-slug-issues" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --assignee: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --component: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, id?: int, links?: record, name?: string}
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --edited-on: string # format: date-time
  --id: int
  --kind: string@kind-completer
  --links: record # shape: {attachments?: record, comments?: record, html?: record, self?: record, vote?: record, watch?: record}
  --milestone: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, id?: int, links?: record, name?: string}
  --priority: string@priority-completer
  --reporter: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --repository: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
  --state: string@state-completer-2
  --title: string
  --updated-on: string # format: date-time
  --version: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, id?: int, links?: record, name?: string}
  --votes: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/issues"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: assignee, var: assignee}, {name: component, var: component}, {name: content, var: content}, {name: created_on, var: created_on}, {name: edited_on, var: edited_on}, {name: id, var: id}, {name: kind, var: kind}, {name: links, var: links}, {name: milestone, var: milestone}, {name: priority, var: priority}, {name: reporter, var: reporter}, {name: repository, var: repository}, {name: state, var: state}, {name: title, var: title}, {name: updated_on, var: updated_on}, {name: version, var: version}, {name: votes, var: votes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, assignee: $assignee, component: $component, content: $content, created_on: $created_on, edited_on: $edited_on, id: $id, kind: $kind, links: $links, milestone: $milestone, priority: $priority, reporter: $reporter, repository: $repository, state: $state, title: $title, updated_on: $updated_on, version: $version, votes: $votes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/export
export def "post-repositories-workspace-repo-slug-issues-export" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-attachments: oneof<nothing, bool>
  --project-key: string
  --project-name: string
  --send-email: oneof<nothing, bool>
  type: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/issues/export"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: include_attachments, var: include_attachments}, {name: project_key, var: project_key}, {name: project_name, var: project_name}, {name: send_email, var: send_email}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, include_attachments: $include_attachments, project_key: $project_key, project_name: $project_name, send_email: $send_email, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check issue export status
#
# GET /repositories/{workspace}/{repo_slug}/issues/export/{repo_name}-issues-{task_id}.zip
# Returns: record<count: int, pct: float, phase: string, status: string, total: int, type: string>
export def "get-repositories-workspace-repo-slug-issues-export-repo-name-issues-task-id-zip" [
  workspace: string
  repo_slug: string
  repo_name: string
  task_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/export/{repo_name}-issues-{task_id}.zip"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: repo_name, var: repo_name}, {name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, repo_name: $repo_name, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check issue import status
#
# GET /repositories/{workspace}/{repo_slug}/issues/import
# Returns: record<count: int, pct: float, phase: string, status: string, total: int, type: string>
export def "get-repositories-workspace-repo-slug-issues-import" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/import"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/import
# Returns: record<count: int, pct: float, phase: string, status: string, total: int, type: string>
export def "post-repositories-workspace-repo-slug-issues-import" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/import"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# Returns: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>
export def "delete-repositories-workspace-repo-slug-issues-issue-id" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# Returns: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>
export def "get-repositories-workspace-repo-slug-issues-issue-id" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# Returns: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, component: record<type: string, id: int, links: record<self: record>, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record<href: string, name: string>, comments: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>, vote: record<href: string, name: string>, watch: record<href: string, name: string>>, milestone: record<type: string, id: int, links: record<self: record>, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record<self: record>, name: string>, votes: int>
export def "put-repositories-workspace-repo-slug-issues-issue-id" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, name: string>>
export def "get-repositories-workspace-repo-slug-issues-issue-id-attachments" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload an attachment to an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
export def "post-repositories-workspace-repo-slug-issues-issue-id-attachments" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    method: post
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attachment for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
export def "delete-repositories-workspace-repo-slug-issues-issue-id-attachments-path" [
  workspace: string
  repo_slug: string
  issue_id: string
  path: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get attachment for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
export def "get-repositories-workspace-repo-slug-issues-issue-id-attachments-path" [
  workspace: string
  repo_slug: string
  issue_id: string
  path: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List changes on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<changes: record, created_on: string, issue: record, links: record, message: record, name: string, type: string, user: record>>
export def "get-repositories-workspace-repo-slug-issues-issue-id-changes" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the state of an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
# Returns: record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-issues-issue-id-changes" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --changes: record # shape: {assignee?: record, component?: record, content?: record, kind?: record, milestone?: record, priority?: record, state?: record, title?: record, version?: record}
  --created-on: string # format: date-time
  --issue: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, assignee?: record, component?: record, content?: record, created_on?: string, edited_on?: string, id?: int, kind?: "bug"|"enhancement"|"proposal"|"task", links?: record, milestone?: record, priority?: "trivial"|"minor"|"major"|"critical"|"blocker", reporter?: record, repository?: record, state?: "new"|"open"|"resolved"|"on hold"|"invalid"|"duplicate"|"wontfix"|"closed", title?: string, updated_on?: string, version?: record, votes?: int}
  --links: record # shape: {issue?: record, self?: record}
  --message: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --name: string
  type: string
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: changes, var: changes}, {name: created_on, var: created_on}, {name: issue, var: issue}, {name: links, var: links}, {name: message, var: message}, {name: name, var: name}, {name: type, var: type}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, changes: $changes, created_on: $created_on, issue: $issue, links: $links, message: $message, name: $name, type: $type, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get issue change object
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes/{change_id}
# Returns: record<changes: record<assignee: record<new: string, old: string>, component: record<new: string, old: string>, content: record<new: string, old: string>, kind: record<new: string, old: string>, milestone: record<new: string, old: string>, priority: record<new: string, old: string>, state: record<new: string, old: string>, title: record<new: string, old: string>, version: record<new: string, old: string>>, created_on: string, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>, links: record<issue: record<href: string, name: string>, self: record<href: string, name: string>>, message: record<html: string, markup: string, raw: string>, name: string, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-issues-issue-id-changes-change-id" [
  workspace: string
  repo_slug: string
  issue_id: string
  change_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes/{change_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: change_id, var: change_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, change_id: $change_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List comments on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, issue: record>>
export def "get-repositories-workspace-repo-slug-issues-issue-id-comments" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment on an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
export def "post-repositories-workspace-repo-slug-issues-issue-id-comments" [
  workspace: string
  repo_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --issue: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, assignee?: record, component?: record, content?: record, created_on?: string, edited_on?: string, id?: int, kind?: "bug"|"enhancement"|"proposal"|"task", links?: record, milestone?: record, priority?: "trivial"|"minor"|"major"|"critical"|"blocker", reporter?: record, repository?: record, state?: "new"|"open"|"resolved"|"on hold"|"invalid"|"duplicate"|"wontfix"|"closed", title?: string, updated_on?: string, version?: record, votes?: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: issue, var: issue}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, issue: $issue
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment on an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
export def "delete-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>>
export def "get-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment on an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, issue: record<type: string, assignee: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, component: record<type: string, id: int, links: record, name: string>, content: record<html: string, markup: string, raw: string>, created_on: string, edited_on: string, id: int, kind: string, links: record<attachments: record, comments: record, html: record, self: record, vote: record, watch: record>, milestone: record<type: string, id: int, links: record, name: string>, priority: string, reporter: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>, state: string, title: string, updated_on: string, version: record<type: string, id: int, links: record, name: string>, votes: int>>
export def "put-repositories-workspace-repo-slug-issues-issue-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  issue_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --issue: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, assignee?: record, component?: record, content?: record, created_on?: string, edited_on?: string, id?: int, kind?: "bug"|"enhancement"|"proposal"|"task", links?: record, milestone?: record, priority?: "trivial"|"minor"|"major"|"critical"|"blocker", reporter?: record, repository?: record, state?: "new"|"open"|"resolved"|"on hold"|"invalid"|"duplicate"|"wontfix"|"closed", title?: string, updated_on?: string, version?: record, votes?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: issue, var: issue}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id, comment_id: $comment_id, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, issue: $issue
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove vote for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "delete-repositories-workspace-repo-slug-issues-issue-id-vote" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if current user voted for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "get-repositories-workspace-repo-slug-issues-issue-id-vote" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Vote for an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "put-repositories-workspace-repo-slug-issues-issue-id-vote" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "delete-repositories-workspace-repo-slug-issues-issue-id-watch" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if current user is watching a issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "get-repositories-workspace-repo-slug-issues-issue-id-watch" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "put-repositories-workspace-repo-slug-issues-issue-id-watch" [
  workspace: string
  repo_slug: string
  issue_id: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the common ancestor between two commits
#
# GET /repositories/{workspace}/{repo_slug}/merge-base/{revspec}
# Returns: record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: any, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-merge-base-revspec" [
  workspace: string
  repo_slug: string
  revspec: string
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
    path: "/repositories/{workspace}/{repo_slug}/merge-base/{revspec}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: revspec, var: revspec}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, revspec: $revspec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List milestones
#
# GET /repositories/{workspace}/{repo_slug}/milestones
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>
export def "get-repositories-workspace-repo-slug-milestones" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/milestones"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a milestone
#
# GET /repositories/{workspace}/{repo_slug}/milestones/{milestone_id}
# Returns: record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>
export def "get-repositories-workspace-repo-slug-milestones-milestone-id" [
  workspace: string
  repo_slug: string
  milestone_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/milestones/{milestone_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: milestone_id, var: milestone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, milestone_id: $milestone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the inheritance state for repository settings
#
# GET /repositories/{workspace}/{repo_slug}/override-settings
# Returns: record<override_settings: record, type: string>
export def "get-repositories-workspace-repo-slug-override-settings" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/override-settings"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the inheritance state for repository settings
#
# PUT /repositories/{workspace}/{repo_slug}/override-settings
export def "put-repositories-workspace-repo-slug-override-settings" [
  workspace: string
  repo_slug: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/override-settings"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a patch for two commits
#
# GET /repositories/{workspace}/{repo_slug}/patch/{spec}
export def "get-repositories-workspace-repo-slug-patch-spec" [
  workspace: string
  repo_slug: string
  spec: string
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
    path: "/repositories/{workspace}/{repo_slug}/patch/{spec}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: spec, var: spec}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List explicit group permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<group: record, links: record, permission: string, repository: record, type: string>>
export def "get-repositories-workspace-repo-slug-permissions-config-groups" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/groups"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an explicit group permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "delete-repositories-workspace-repo-slug-permissions-config-groups-group-slug" [
  workspace: string
  repo_slug: string
  group_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: group_slug, var: group_slug}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, group_slug: $group_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an explicit group permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
# Returns: record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string>
export def "get-repositories-workspace-repo-slug-permissions-config-groups-group-slug" [
  workspace: string
  repo_slug: string
  group_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: group_slug, var: group_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, group_slug: $group_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an explicit group permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
# Returns: record<group: record<type: string, full_slug: string, links: record<html: record, self: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, slug: string, workspace: record<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>, links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string>
export def "put-repositories-workspace-repo-slug-permissions-config-groups-group-slug" [
  workspace: string
  repo_slug: string
  group_slug: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: group_slug, var: group_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, group_slug: $group_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List explicit user permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, permission: string, repository: record, type: string, user: record>>
export def "get-repositories-workspace-repo-slug-permissions-config-users" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/users"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an explicit user permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "delete-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" [
  workspace: string
  repo_slug: string
  selected_user_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: selected_user_id, var: selected_user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, selected_user_id: $selected_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an explicit user permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
# Returns: record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, repositories: record, self: record>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>>
export def "get-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" [
  workspace: string
  repo_slug: string
  selected_user_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: selected_user_id, var: selected_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, selected_user_id: $selected_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an explicit user permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
# Returns: record<links: record<self: record<href: string, name: string>>, permission: string, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, type: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, repositories: record, self: record>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>>
export def "put-repositories-workspace-repo-slug-permissions-config-users-selected-user-id" [
  workspace: string
  repo_slug: string
  selected_user_id: string
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
    method: put
    path: "/repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: selected_user_id, var: selected_user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, selected_user_id: $selected_user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete caches
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches
# operationId: deleteRepositoryPipelineCaches
export def "delete-repository-pipeline-caches" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The cache name. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}/pipelines-config/caches"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List caches
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, file_size_bytes: int, key_hash: string, name: string, path: string, pipeline_uuid: string, step_uuid: string, uuid: string>>
# operationId: getRepositoryPipelineCaches
export def "get-repository-pipeline-caches" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a cache
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}
# operationId: deleteRepositoryPipelineCache
export def "delete-repository-pipeline-cache" [
  workspace: string
  repo_slug: string
  cache_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: cache_uuid, var: cache_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, cache_uuid: $cache_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get cache content URI
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}/content-uri
# Returns: record<uri: string>
# operationId: getRepositoryPipelineCacheContentURI
export def "get-repository-pipeline-cache-content-uri" [
  workspace: string
  repo_slug: string
  cache_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}/content-uri"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: cache_uuid, var: cache_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, cache_uuid: $cache_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pipelines
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record, repository: record, state: record, target: record, trigger: record, uuid: string>>
# operationId: getPipelinesForRepository
export def "get-pipelines-for-repository" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines/
# Returns: record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string>
# operationId: createPipelineForRepository
export def "create-pipeline-for-repository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --build-number: int # The build number of the pipeline.
  --build-seconds-used: int # The number of build seconds used by this pipeline.
  --completed-on: string # The timestamp when the Pipeline was completed. This is not set if the pipeline is still in progress. (format: date-time)
  --created-on: string # The timestamp when the pipeline was created. (format: date-time)
  --creator: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --repository: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
  --state: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string}
  --target: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string}
  --trigger: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string}
  --uuid: string # The UUID identifying the pipeline.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pipelines/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: build_number, var: build_number}, {name: build_seconds_used, var: build_seconds_used}, {name: completed_on, var: completed_on}, {name: created_on, var: created_on}, {name: creator, var: creator}, {name: repository, var: repository}, {name: state, var: state}, {name: target, var: target}, {name: trigger, var: trigger}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, build_number: $build_number, build_seconds_used: $build_seconds_used, completed_on: $completed_on, created_on: $created_on, creator: $creator, repository: $repository, state: $state, target: $target, trigger: $trigger, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}
# Returns: record<type: string, build_number: int, build_seconds_used: int, completed_on: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>, state: record<type: string>, target: record<type: string>, trigger: record<type: string>, uuid: string>
# operationId: getPipelineForRepository
export def "get-pipeline-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List steps for a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, completed_on: string, image: record, script_commands: list, setup_commands: list, started_on: string, state: record, uuid: string>>
# operationId: getPipelineStepsForRepository
export def "get-pipeline-steps-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a step of a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}
# Returns: record<type: string, completed_on: string, image: record<email: string, name: string, password: string, username: string>, script_commands: table<command: string, name: string>, setup_commands: table<command: string, name: string>, started_on: string, state: record<type: string>, uuid: string>
# operationId: getPipelineStepForRepository
export def "get-pipeline-step-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get log file for a step
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/log
# operationId: getPipelineStepLogForRepository
export def "get-pipeline-step-log-for-repository" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/log"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the logs for the build container or a service container for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/logs/{log_uuid}
# operationId: getPipelineContainerLog
export def "get-pipeline-container-log" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  log_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/logs/{log_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}, {name: log_uuid, var: log_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid, log_uuid: $log_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a summary of test reports for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports
# operationId: getPipelineTestReports
export def "get-pipeline-test-reports" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get test cases for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases
# operationId: getPipelineTestReportTestCases
export def "get-pipeline-test-report-test-cases" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get test case reasons (output) for a given test case in a step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases/{test_case_uuid}/test_case_reasons
# operationId: getPipelineTestReportTestCaseReasons
export def "get-pipeline-test-report-test-case-reasons" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  test_case_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases/{test_case_uuid}/test_case_reasons"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}, {name: step_uuid, var: step_uuid}, {name: test_case_uuid, var: test_case_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid, step_uuid: $step_uuid, test_case_uuid: $test_case_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/stopPipeline
# operationId: stopPipeline
export def "stop-pipeline" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
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
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/stopPipeline"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pipeline_uuid, var: pipeline_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pipeline_uuid: $pipeline_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get configuration
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config
# Returns: record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
# operationId: getRepositoryPipelineConfig
export def "get-repository-pipeline-config" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update configuration
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config
# Returns: record<type: string, enabled: bool, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record<avatar: record, clone: list, commits: record, downloads: record, forks: record, hooks: record, html: record, pullrequests: record, self: record, watchers: record>, mainbranch: record<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, parent: any, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>, scm: string, size: int, updated_on: string, uuid: string>>
# operationId: updateRepositoryPipelineConfig
export def "update-repository-pipeline-config" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --enabled: oneof<nothing, bool> # Whether Pipelines is enabled for the repository.
  --repository: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, description?: string, fork_policy?: "allow_forks"|"no_public_forks"|"no_forks", full_name?: string, has_issues?: bool, has_wiki?: bool, is_private?: bool, language?: string, links?: record, mainbranch?: record, name?: string, owner?: record, parent?: record, project?: record, scm?: "git", size?: int, updated_on?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: enabled, var: enabled}, {name: repository, var: repository}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, enabled: $enabled, repository: $repository
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the next build number
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/build_number
# Returns: record<type: string, next: int>
# operationId: updateRepositoryBuildNumber
export def "update-repository-build-number" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --next: int # The next number that will be used as build number.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/build_number"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: next, var: next}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, next: $next
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schedules
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record, target: record, updated_on: string, uuid: string>>
# operationId: getRepositoryPipelineSchedules
export def "get-repository-pipeline-schedules" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a schedule
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/
# Returns: record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>
# operationId: createRepositoryPipelineSchedule
export def "create-repository-pipeline-schedule" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the schedule was created. (format: date-time)
  --cron-pattern: string # The cron expression that the schedule applies.
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
  --selector: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: "branches"|"tags"|"bookmarks"|"default"|"custom", pattern?: string}
  --target: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string}
  --updated-on: string # The timestamp when the schedule was updated. (format: date-time)
  --uuid: string # The UUID identifying the schedule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: cron_pattern, var: cron_pattern}, {name: enabled, var: enabled}, {name: selector, var: selector}, {name: target, var: target}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, created_on: $created_on, cron_pattern: $cron_pattern, enabled: $enabled, selector: $selector, target: $target, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a schedule
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: deleteRepositoryPipelineSchedule
export def "delete-repository-pipeline-schedule" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: schedule_uuid, var: schedule_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, schedule_uuid: $schedule_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# Returns: record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>
# operationId: getRepositoryPipelineSchedule
export def "get-repository-pipeline-schedule" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: schedule_uuid, var: schedule_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, schedule_uuid: $schedule_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a schedule
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# Returns: record<type: string, created_on: string, cron_pattern: string, enabled: bool, selector: record<type: string, pattern: string>, target: record<type: string>, updated_on: string, uuid: string>
# operationId: updateRepositoryPipelineSchedule
export def "update-repository-pipeline-schedule" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # The timestamp when the schedule was created. (format: date-time)
  --cron-pattern: string # The cron expression that the schedule applies.
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
  --selector: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: "branches"|"tags"|"bookmarks"|"default"|"custom", pattern?: string}
  --target: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string}
  --updated-on: string # The timestamp when the schedule was updated. (format: date-time)
  --uuid: string # The UUID identifying the schedule.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: schedule_uuid, var: schedule_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: cron_pattern, var: cron_pattern}, {name: enabled, var: enabled}, {name: selector, var: selector}, {name: target, var: target}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, schedule_uuid: $schedule_uuid, type: $type, created_on: $created_on, cron_pattern: $cron_pattern, enabled: $enabled, selector: $selector, target: $target, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List executions of a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}/executions/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string>>
# operationId: getRepositoryPipelineScheduleExecutions
export def "get-repository-pipeline-schedule-executions" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}/executions/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: schedule_uuid, var: schedule_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, schedule_uuid: $schedule_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete SSH key pair
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: deleteRepositoryPipelineKeyPair
export def "delete-repository-pipeline-key-pair" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SSH key pair
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# Returns: record<type: string, private_key: string, public_key: string>
# operationId: getRepositoryPipelineSshKeyPair
export def "get-repository-pipeline-ssh-key-pair" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SSH key pair
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# Returns: record<type: string, private_key: string, public_key: string>
# operationId: updateRepositoryPipelineKeyPair
export def "update-repository-pipeline-key-pair" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --private-key: string # The SSH private key. This value will be empty when retrieving the SSH key pair.
  --public-key: string # The SSH public key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: private_key, var: private_key}, {name: public_key, var: public_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, private_key: $private_key, public_key: $public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List known hosts
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, hostname: string, public_key: record, uuid: string>>
# operationId: getRepositoryPipelineKnownHosts
export def "get-repository-pipeline-known-hosts" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a known host
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/
# Returns: record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>
# operationId: createRepositoryPipelineKnownHost
export def "create-repository-pipeline-known-host" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --hostname: string # The hostname of the known host.
  --public-key: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, key?: string, key_type?: string, md5_fingerprint?: string, sha256_fingerprint?: string}
  --uuid: string # The UUID identifying the known host.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: hostname, var: hostname}, {name: public_key, var: public_key}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, hostname: $hostname, public_key: $public_key, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a known host
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: deleteRepositoryPipelineKnownHost
export def "delete-repository-pipeline-known-host" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: known_host_uuid, var: known_host_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, known_host_uuid: $known_host_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a known host
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# Returns: record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>
# operationId: getRepositoryPipelineKnownHost
export def "get-repository-pipeline-known-host" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: known_host_uuid, var: known_host_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, known_host_uuid: $known_host_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a known host
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# Returns: record<type: string, hostname: string, public_key: record<type: string, key: string, key_type: string, md5_fingerprint: string, sha256_fingerprint: string>, uuid: string>
# operationId: updateRepositoryPipelineKnownHost
export def "update-repository-pipeline-known-host" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --hostname: string # The hostname of the known host.
  --public-key: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, key?: string, key_type?: string, md5_fingerprint?: string, sha256_fingerprint?: string}
  --uuid: string # The UUID identifying the known host.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: known_host_uuid, var: known_host_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: hostname, var: hostname}, {name: public_key, var: public_key}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, known_host_uuid: $known_host_uuid, type: $type, hostname: $hostname, public_key: $public_key, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables/
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>
# operationId: getRepositoryPipelineVariables
export def "get-repository-pipeline-variables" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable for a repository
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/variables/
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: createRepositoryPipelineVariable
export def "create-repository-pipeline-variable" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: deleteRepositoryPipelineVariable
export def "delete-repository-pipeline-variable" [
  workspace: string
  repo_slug: string
  variable_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variable for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: getRepositoryPipelineVariable
export def "get-repository-pipeline-variable" [
  workspace: string
  repo_slug: string
  variable_uuid: string
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
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: updateRepositoryPipelineVariable
export def "update-repository-pipeline-variable" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: variable_uuid, var: variable_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, variable_uuid: $variable_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a repository application property
#
# DELETE /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: deleteRepositoryHostedPropertyValue
export def "delete-repository-hosted-property-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a repository application property
#
# GET /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# Returns: record<_attributes: list<string>>
# operationId: getRepositoryHostedPropertyValue
export def "get-repository-hosted-property-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a repository application property
#
# PUT /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: updateRepositoryHostedPropertyValue
export def "update-repository-hosted-property-value" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: _attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, app_key: $app_key, property_name: $property_name, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pull requests
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, close_source_branch: bool, closed_by: record, comment_count: int, created_on: string, destination: record, id: int, links: record, merge_commit: record, participants: list, reason: string, rendered: record, reviewers: list, source: record, state: string, summary: record, task_count: int, title: string, updated_on: string>>
export def "get-repositories-workspace-repo-slug-pullrequests" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/pullrequests"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests
# Returns: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>
export def "post-repositories-workspace-repo-slug-pullrequests" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --author: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --comment-count: int # The number of comments for a specific pull request.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --destination: record # shape: {branch?: record, commit?: record, repository?: record}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --links: record # shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
  --merge-commit: record # shape: {hash?: string}
  --participants: list # The list of users that are collaborating on this pull request. Collaborators are user that: * are added to the pull request as a reviewer (part of the reviewers list) * are not explicit reviewers, but have commented on the pull request * are not explicit reviewers, but have approved the pull request Each user is wrapped in an object that indicates the user's role and whether they have approved the pull request. For performance reasons, the API only returns this list when an API requests a pull request by id. — item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested", user?: record}
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {description?: record, reason?: record, title?: record}
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --source: record # shape: {branch?: record, commit?: record, repository?: record}
  --state: string@state-completer # The pull request's current status.
  --summary: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --task-count: int # The number of open tasks for a specific pull request.
  --title: string # Title of the pull request.
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pullrequests"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: author, var: author}, {name: close_source_branch, var: close_source_branch}, {name: closed_by, var: closed_by}, {name: comment_count, var: comment_count}, {name: created_on, var: created_on}, {name: destination, var: destination}, {name: id, var: id}, {name: links, var: links}, {name: merge_commit, var: merge_commit}, {name: participants, var: participants}, {name: reason, var: reason}, {name: rendered, var: rendered}, {name: reviewers, var: reviewers}, {name: source, var: source}, {name: state, var: state}, {name: summary, var: summary}, {name: task_count, var: task_count}, {name: title, var: title}, {name: updated_on, var: updated_on}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, type: $type, author: $author, close_source_branch: $close_source_branch, closed_by: $closed_by, comment_count: $comment_count, created_on: $created_on, destination: $destination, id: $id, links: $links, merge_commit: $merge_commit, participants: $participants, reason: $reason, rendered: $rendered, reviewers: $reviewers, source: $source, state: $state, summary: $summary, task_count: $task_count, title: $title, updated_on: $updated_on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/activity
export def "get-repositories-workspace-repo-slug-pullrequests-activity" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/activity"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
# Returns: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
# Returns: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>
export def "put-repositories-workspace-repo-slug-pullrequests-pull-request-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --author: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --comment-count: int # The number of comments for a specific pull request.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --destination: record # shape: {branch?: record, commit?: record, repository?: record}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --links: record # shape: {activity?: record, approve?: record, comments?: record, commits?: record, decline?: record, diff?: record, diffstat?: record, html?: record, merge?: record, self?: record}
  --merge-commit: record # shape: {hash?: string}
  --participants: list # The list of users that are collaborating on this pull request. Collaborators are user that: * are added to the pull request as a reviewer (part of the reviewers list) * are not explicit reviewers, but have commented on the pull request * are not explicit reviewers, but have approved the pull request Each user is wrapped in an object that indicates the user's role and whether they have approved the pull request. For performance reasons, the API only returns this list when an API requests a pull request by id. — item shape: {type: string, approved?: bool, participated_on?: string, role?: "PARTICIPANT"|"REVIEWER", state?: "approved"|"changes_requested", user?: record}
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {description?: record, reason?: record, title?: record}
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --source: record # shape: {branch?: record, commit?: record, repository?: record}
  --state: string@state-completer # The pull request's current status.
  --summary: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --task-count: int # The number of open tasks for a specific pull request.
  --title: string # Title of the pull request.
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: author, var: author}, {name: close_source_branch, var: close_source_branch}, {name: closed_by, var: closed_by}, {name: comment_count, var: comment_count}, {name: created_on, var: created_on}, {name: destination, var: destination}, {name: id, var: id}, {name: links, var: links}, {name: merge_commit, var: merge_commit}, {name: participants, var: participants}, {name: reason, var: reason}, {name: rendered, var: rendered}, {name: reviewers, var: reviewers}, {name: source, var: source}, {name: state, var: state}, {name: summary, var: summary}, {name: task_count, var: task_count}, {name: title, var: title}, {name: updated_on, var: updated_on}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, type: $type, author: $author, close_source_branch: $close_source_branch, closed_by: $closed_by, comment_count: $comment_count, created_on: $created_on, destination: $destination, id: $id, links: $links, merge_commit: $merge_commit, participants: $participants, reason: $reason, rendered: $rendered, reviewers: $reviewers, source: $source, state: $state, summary: $summary, task_count: $task_count, title: $title, updated_on: $updated_on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-activity" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unapprove a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
export def "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-approve" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
# Returns: record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-approve" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List comments on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, content: record, created_on: string, deleted: bool, id: int, inline: record, links: record, parent: record, updated_on: string, user: record, pullrequest: record>>
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment on a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>
export def "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --pullrequest: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, author?: record, close_source_branch?: bool, closed_by?: record, comment_count?: int, created_on?: string, destination?: record, id?: int, links?: record, merge_commit?: record, participants?: list, reason?: string, rendered?: record, reviewers?: list, source?: record, state?: "OPEN"|"MERGED"|"DECLINED"|"SUPERSEDED", summary?: record, task_count?: int, title?: string, updated_on?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: pullrequest, var: pullrequest}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, pullrequest: $pullrequest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment on a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment on a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
# Returns: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, parent: record<type: string, content: record<html: string, markup: string, raw: string>, created_on: string, deleted: bool, id: int, inline: record<from: int, path: string, to: int>, links: record<code: record, html: record, self: record>, parent: any, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, updated_on: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, pullrequest: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record, commit: record, repository: record>, id: int, links: record<activity: record, approve: record, comments: record, commits: record, decline: record, diff: record, diffstat: record, html: record, merge: record, self: record>, merge_commit: record<hash: string>, participants: list<record>, reason: string, rendered: record<description: record, reason: record, title: record>, reviewers: list<record>, source: record<branch: record, commit: record, repository: record>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>>
export def "put-repositories-workspace-repo-slug-pullrequests-pull-request-id-comments-comment-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --content: record # shape: {html?: string, markup?: "markdown"|"creole"|"plaintext", raw?: string}
  --created-on: string # format: date-time
  --deleted: oneof<nothing, bool>
  --id: int
  --inline: record # shape: {from?: int, path: string, to?: int}
  --links: record # shape: {code?: record, html?: record, self?: record}
  --parent: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, content?: record, created_on?: string, deleted?: bool, id?: int, inline?: record, links?: record, parent?: record, updated_on?: string, user?: record}
  --updated-on: string # format: date-time
  --user: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --pullrequest: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, author?: record, close_source_branch?: bool, closed_by?: record, comment_count?: int, created_on?: string, destination?: record, id?: int, links?: record, merge_commit?: record, participants?: list, reason?: string, rendered?: record, reviewers?: list, source?: record, state?: "OPEN"|"MERGED"|"DECLINED"|"SUPERSEDED", summary?: record, task_count?: int, title?: string, updated_on?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: content, var: content}, {name: created_on, var: created_on}, {name: deleted, var: deleted}, {name: id, var: id}, {name: inline, var: inline}, {name: links, var: links}, {name: parent, var: parent}, {name: updated_on, var: updated_on}, {name: user, var: user}, {name: pullrequest, var: pullrequest}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, comment_id: $comment_id, type: $type, content: $content, created_on: $created_on, deleted: $deleted, id: $id, inline: $inline, links: $links, parent: $parent, updated_on: $updated_on, user: $user, pullrequest: $pullrequest
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commits on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-commits" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decline a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline
# Returns: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>
export def "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-decline" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List changes in a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-diff" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the diff stat for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-diffstat" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge
# Returns: record<type: string, author: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, close_source_branch: bool, closed_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, comment_count: int, created_on: string, destination: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, id: int, links: record<activity: record<href: string, name: string>, approve: record<href: string, name: string>, comments: record<href: string, name: string>, commits: record<href: string, name: string>, decline: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, html: record<href: string, name: string>, merge: record<href: string, name: string>, self: record<href: string, name: string>>, merge_commit: record<hash: string>, participants: table<type: string, approved: bool, participated_on: string, role: string, state: string, user: record>, reason: string, rendered: record<description: record<html: string, markup: string, raw: string>, reason: record<html: string, markup: string, raw: string>, title: record<html: string, markup: string, raw: string>>, reviewers: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, source: record<branch: record<default_merge_strategy: string, merge_strategies: list, name: string>, commit: record<hash: string>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, state: string, summary: record<html: string, markup: string, raw: string>, task_count: int, title: string, updated_on: string>
export def "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-merge" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # Default value is false. When set to true, runs merge asynchronously and immediately returns a 202 with polling link to the task-status API in the Location header. When set to false, runs merge and waits for it to complete, returning 200 when it succeeds. If the duration of the merge exceeds a timeout threshold, the API returns a 202 with polling link to the task-status API in the Location header.
  --close-source-branch: oneof<nothing, bool> # Whether the source branch should be deleted. If this is not provided, we fallback to the value used when the pull request was created, which defaults to False
  --merge-strategy: string@merge-strategy-completer # The merge strategy that will be used to merge the pull request. (default: merge_commit)
  --message: string # The commit message that will be used on the resulting commit.
  type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    query: [{name: async, var: async}]
    body: {content_type: "application/json", kind: json, fields: [{name: close_source_branch, var: close_source_branch}, {name: merge_strategy, var: merge_strategy}, {name: message, var: message}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, async: $async, close_source_branch: $close_source_branch, merge_strategy: $merge_strategy, message: $message, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the merge task status for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-merge-task-status-task-id" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  task_id: string
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}, {name: task_id, var: task_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the patch for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-patch" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove change request for a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
export def "delete-repositories-workspace-repo-slug-pullrequests-pull-request-id-request-changes" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request changes for a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
# Returns: record<type: string, approved: bool, participated_on: string, role: string, state: string, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "post-repositories-workspace-repo-slug-pullrequests-pull-request-id-request-changes" [
  workspace: string
  repo_slug: string
  pull_request_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List commit statuses for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/statuses
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, key: string, links: record, name: string, refname: string, state: string, updated_on: string, url: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-pullrequests-pull-request-id-statuses" [
  workspace: string
  repo_slug: string
  pull_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/statuses"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pull_request_id, var: pull_request_id}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pull_request_id: $pull_request_id, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a pull request application property
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: deletePullRequestHostedPropertyValue
export def "delete-pull-request-hosted-property-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pullrequest_id, var: pullrequest_id}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pullrequest_id: $pullrequest_id, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a pull request application property
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# Returns: record<_attributes: list<string>>
# operationId: getPullRequestHostedPropertyValue
export def "get-pull-request-hosted-property-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
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
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pullrequest_id, var: pullrequest_id}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pullrequest_id: $pullrequest_id, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a pull request application property
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: updatePullRequestHostedPropertyValue
export def "update-pull-request-hosted-property-value" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: pullrequest_id, var: pullrequest_id}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: _attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, pullrequest_id: $pullrequest_id, app_key: $app_key, property_name: $property_name, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List branches and tags
#
# GET /repositories/{workspace}/{repo_slug}/refs
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string>>
export def "get-repositories-workspace-repo-slug-refs" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for refs in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/refs"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List open branches
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, default_merge_strategy: string, merge_strategies: list>>
export def "get-repositories-workspace-repo-slug-refs-branches" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for branches in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['branch1', 'branch2', 'branch10'] instead of ['branch1', 'branch10', 'branch2'].
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/refs/branches"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a branch
#
# POST /repositories/{workspace}/{repo_slug}/refs/branches
# Returns: record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>>
export def "post-repositories-workspace-repo-slug-refs-branches" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/refs/branches"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a branch
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/branches/{name}
export def "delete-repositories-workspace-repo-slug-refs-branches-name" [
  workspace: string
  repo_slug: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}/refs/branches/{name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a branch
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches/{name}
# Returns: record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: any, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, default_merge_strategy: string, merge_strategies: list<string>>
export def "get-repositories-workspace-repo-slug-refs-branches-name" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/refs/branches/{name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<links: record, name: string, target: record, type: string, date: string, message: string, tagger: record>>
export def "get-repositories-workspace-repo-slug-refs-tags" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for tags in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/refs/tags"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a tag
#
# POST /repositories/{workspace}/{repo_slug}/refs/tags
# Returns: record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>>
export def "post-repositories-workspace-repo-slug-refs-tags" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --links: record # shape: {commits?: record, html?: record, self?: record}
  --name: string # The name of the ref.
  --target: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, author?: record, date?: string, hash?: string, message?: string, parents?: list, summary?: record, participants?: list, repository?: record}
  type: string
  --date: string # The date that the tag was created, if available (format: date-time)
  --message: string # The message associated with the tag, if available.
  --tagger: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, raw?: string, user?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/refs/tags"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    body: {content_type: "application/json", kind: json, fields: [{name: links, var: links}, {name: name, var: name}, {name: target, var: target}, {name: type, var: type}, {name: date, var: date}, {name: message, var: message}, {name: tagger, var: tagger}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, links: $links, name: $name, target: $target, type: $type, date: $date, message: $message, tagger: $tagger
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/tags/{name}
export def "delete-repositories-workspace-repo-slug-refs-tags-name" [
  workspace: string
  repo_slug: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/repositories/{workspace}/{repo_slug}/refs/tags/{name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tag
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags/{name}
# Returns: record<links: record<commits: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, name: string, target: record<type: string, author: record<type: string, raw: string, user: record>, date: string, hash: string, message: string, parents: list<record>, summary: record<html: string, markup: string, raw: string>, participants: list<record>, repository: record<type: string, created_on: string, description: string, fork_policy: string, full_name: string, has_issues: bool, has_wiki: bool, is_private: bool, language: string, links: record, mainbranch: record, name: string, owner: record, parent: any, project: record, scm: string, size: int, updated_on: string, uuid: string>>, type: string, date: string, message: string, tagger: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>>
export def "get-repositories-workspace-repo-slug-refs-tags-name" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/refs/tags/{name}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the root directory of the main branch
#
# GET /repositories/{workspace}/{repo_slug}/src
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>>
export def "get-repositories-workspace-repo-slug-src" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # Instead of returning the file's contents, return the (json) meta data for it.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/src"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a commit by uploading a file
#
# POST /repositories/{workspace}/{repo_slug}/src
export def "post-repositories-workspace-repo-slug-src" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # The commit message. When omitted, Bitbucket uses a canned string.
  --author: string # The raw string to be used as the new commit's author. This string follows the format `Erik van Zijst <evzijst@atlassian.com>`. When omitted, Bitbucket uses the authenticated user's full/display name and primary email address. Commits cannot be created anonymously.
  --parents: string # A comma-separated list of SHA1s of the commits that should be the parents of the newly created commit. When omitted, the new commit will inherit from and become a child of the main branch's tip/HEAD commit. When more than one SHA1 is provided, the first SHA1 identifies the commit from which the content will be inherited.".
  --files: string # Optional field that declares the files that the request is manipulating. When adding a new file to a repo, or when overwriting an existing file, the client can just upload the full contents of the file in a normal form field and the use of this `files` meta data field is redundant. However, when the `files` field contains a file path that does not have a corresponding, identically-named form field, then Bitbucket interprets that as the client wanting to replace the named file with the null set and the file is deleted instead. Paths in the repo that are referenced in neither files nor an individual file field, remain unchanged and carry over from the parent to the new commit. This API does not support renaming as an explicit feature. To rename a file, simply delete it and recreate it under the new name in the same commit.
  --branch: string # The name of the branch that the new commit should be created on. When omitted, the commit will be created on top of the main branch and will become the main branch's new head. When a branch name is provided that already exists in the repo, then the commit will be created on top of that branch. In this case, *if* a parent SHA1 was also provided, then it is asserted that the parent is the branch's tip/HEAD at the time the request is made. When this is not the case, a 409 is returned. When a new branch name is specified (that does not already exist in the repo), and no parent SHA1s are provided, then the new commit will inherit from the current main branch's tip/HEAD commit, but not advance the main branch. The new commit will be the new branch. When the request *also* specifies a parent SHA1, then the new commit and branch are created directly on top of the parent commit, regardless of the state of the main branch. When a branch name is not specified, but a parent SHA1 is provided, then Bitbucket asserts that it represents the main branch's current HEAD/tip, or a 409 is returned. When a branch name is not specified and the repo is empty, the new commit will become the repo's root commit and will be on the main branch. When a branch name is specified and the repo is empty, the new commit will become the repo's root commit and also define the repo's main branch going forward. This API cannot be used to create additional root commits in non-empty repos. The branch field cannot be repeated. As a side effect, this API can be used to create a new branch without modifying any files, by specifying a new branch name in this field, together with `parents`, but omitting the `files` fields, while not sending any files. This will create a new commit and branch with the same contents as the first parent. The diff of this commit against its first parent will be empty.
]: nothing -> any {
  http-request {
    method: post
    path: "/repositories/{workspace}/{repo_slug}/src"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: message, var: message}, {name: author, var: author}, {name: parents, var: parents}, {name: files, var: files}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, message: $message, author: $author, parents: $parents, files: $files, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file or directory contents
#
# GET /repositories/{workspace}/{repo_slug}/src/{commit}/{path}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<commit: record, path: string, type: string>>
export def "get-repositories-workspace-repo-slug-src-commit-path" [
  workspace: string
  repo_slug: string
  commit: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # If 'meta' is provided, returns the (json) meta data for the contents of the file. If 'rendered' is provided, returns the contents of a non-binary file in HTML-formatted rendered markup. Since Git does not generally track what text encoding scheme is used, this endpoint attempts to detect the most appropriate character encoding. While usually correct, determining the character encoding can be ambiguous which in exceptional cases can lead to misinterpretation of the characters. As such, the raw element in the response object should not be treated as equivalent to the file's actual contents.
  --q: string # Optional filter expression as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Optional sorting parameter as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
  --max-depth: int # If provided, returns the contents of the repository and its subdirectories recursively until the specified max_depth of nested directories. When omitted, this defaults to 1.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/repositories/{workspace}/{repo_slug}/src/{commit}/{path}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: commit, var: commit}, {name: path, var: path}]
    query: [{name: format, var: format}, {name: q, var: q}, {name: sort, var: sort}, {name: max_depth, var: max_depth}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, commit: $commit, path: $path, format: $format, q: $q, sort: $sort, max_depth: $max_depth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List defined versions for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, id: int, links: record, name: string>>
export def "get-repositories-workspace-repo-slug-versions" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/versions"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a defined version for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions/{version_id}
# Returns: record<type: string, id: int, links: record<self: record<href: string, name: string>>, name: string>
export def "get-repositories-workspace-repo-slug-versions-version-id" [
  workspace: string
  repo_slug: string
  version_id: int
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
    path: "/repositories/{workspace}/{repo_slug}/versions/{version_id}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}, {name: version_id, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repositories watchers
#
# GET /repositories/{workspace}/{repo_slug}/watchers
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
export def "get-repositories-workspace-repo-slug-watchers" [
  workspace: string
  repo_slug: string
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
    path: "/repositories/{workspace}/{repo_slug}/watchers"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List snippets
#
# GET /snippets
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>>
export def "get-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/snippets"
    query: [{name: role, var: role}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a snippet
#
# POST /snippets
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "post-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --creator: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --id: int
  --is-private: oneof<nothing, bool>
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --title: string
  --updated-on: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/snippets"
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: creator, var: creator}, {name: id, var: id}, {name: is_private, var: is_private}, {name: owner, var: owner}, {name: scm, var: scm}, {name: title, var: title}, {name: updated_on, var: updated_on}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    type: $type, created_on: $created_on, creator: $creator, id: $id, is_private: $is_private, owner: $owner, scm: $scm, title: $title, updated_on: $updated_on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List snippets in a workspace
#
# GET /snippets/{workspace}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, creator: record, id: int, is_private: bool, owner: record, scm: string, title: string, updated_on: string>>
export def "get-snippets-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/snippets/{workspace}"
    path_params: [{name: workspace, var: workspace}]
    query: [{name: role, var: role}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, role: $role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a snippet for a workspace
#
# POST /snippets/{workspace}
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "post-snippets-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --creator: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --id: int
  --is-private: oneof<nothing, bool>
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --title: string
  --updated-on: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/snippets/{workspace}"
    path_params: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: creator, var: creator}, {name: id, var: id}, {name: is_private, var: is_private}, {name: owner, var: owner}, {name: scm, var: scm}, {name: title, var: title}, {name: updated_on, var: updated_on}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, type: $type, created_on: $created_on, creator: $creator, id: $id, is_private: $is_private, owner: $owner, scm: $scm, title: $title, updated_on: $updated_on
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}
export def "delete-snippets-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a snippet
#
# GET /snippets/{workspace}/{encoded_id}
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "get-snippets-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/snippets/{workspace}/{encoded_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json", "multipart/form-data", "multipart/related"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a snippet
#
# PUT /snippets/{workspace}/{encoded_id}
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "put-snippets-workspace-encoded-id" [
  workspace: string
  encoded_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/snippets/{workspace}/{encoded_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json", "multipart/form-data", "multipart/related"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List comments on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, snippet: record>>
export def "get-snippets-workspace-encoded-id-comments" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a comment on a snippet
#
# POST /snippets/{workspace}/{encoded_id}/comments
# Returns: record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>
export def "post-snippets-workspace-encoded-id-comments" [
  workspace: string
  encoded_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --links: record # shape: {html?: record, self?: record}
  --snippet: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, creator?: record, id?: int, is_private?: bool, owner?: record, scm?: "git", title?: string, updated_on?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/snippets/{workspace}/{encoded_id}/comments"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: links, var: links}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, type: $type, links: $links, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment on a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/comments/{comment_id}
export def "delete-snippets-workspace-encoded-id-comments-comment-id" [
  workspace: string
  encoded_id: string
  comment_id: int
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
    path: "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments/{comment_id}
# Returns: record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>
export def "get-snippets-workspace-encoded-id-comments-comment-id" [
  workspace: string
  encoded_id: string
  comment_id: int
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
    path: "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: comment_id, var: comment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, comment_id: $comment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment on a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/comments/{comment_id}
# Returns: record<type: string, links: record<html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>
export def "put-snippets-workspace-encoded-id-comments-comment-id" [
  workspace: string
  encoded_id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --links: record # shape: {html?: record, self?: record}
  --snippet: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, creator?: record, id?: int, is_private?: bool, owner?: record, scm?: "git", title?: string, updated_on?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/snippets/{workspace}/{encoded_id}/comments/{comment_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: comment_id, var: comment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: links, var: links}, {name: snippet, var: snippet}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, comment_id: $comment_id, type: $type, links: $links, snippet: $snippet
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List snippet changes
#
# GET /snippets/{workspace}/{encoded_id}/commits
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record, links: record, snippet: record>>
export def "get-snippets-workspace-encoded-id-commits" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/commits"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a previous snippet change
#
# GET /snippets/{workspace}/{encoded_id}/commits/{revision}
# Returns: record<type: string, author: record<type: string, raw: string, user: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>, date: string, hash: string, message: string, parents: table<type: string, author: record, date: string, hash: string, message: string, parents: list, summary: record>, summary: record<html: string, markup: string, raw: string>, links: record<diff: record<href: string, name: string>, html: record<href: string, name: string>, self: record<href: string, name: string>>, snippet: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, scm: string, title: string, updated_on: string>>
export def "get-snippets-workspace-encoded-id-commits-revision" [
  workspace: string
  encoded_id: string
  revision: string
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
    path: "/snippets/{workspace}/{encoded_id}/commits/{revision}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: revision, var: revision}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a snippet's raw file at HEAD
#
# GET /snippets/{workspace}/{encoded_id}/files/{path}
export def "get-snippets-workspace-encoded-id-files-path" [
  workspace: string
  encoded_id: string
  path: string
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
    path: "/snippets/{workspace}/{encoded_id}/files/{path}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/watch
export def "delete-snippets-workspace-encoded-id-watch" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if the current user is watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watch
export def "get-snippets-workspace-encoded-id-watch" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watch a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/watch
export def "put-snippets-workspace-encoded-id-watch" [
  workspace: string
  encoded_id: string
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
    method: put
    path: "/snippets/{workspace}/{encoded_id}/watch"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watchers
# DEPRECATED
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>>
@deprecated
export def "get-snippets-workspace-encoded-id-watchers" [
  workspace: string
  encoded_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/watchers"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a previous revision of a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/{node_id}
export def "delete-snippets-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
    path: "/snippets/{workspace}/{encoded_id}/{node_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: node_id, var: node_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a previous revision of a snippet
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "get-snippets-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/snippets/{workspace}/{encoded_id}/{node_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: node_id, var: node_id}]
    accept: ["application/json", "multipart/form-data", "multipart/related"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a previous revision of a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/{node_id}
# Returns: record<type: string, created_on: string, creator: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, id: int, is_private: bool, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, scm: string, title: string, updated_on: string>
export def "put-snippets-workspace-encoded-id-node-id" [
  workspace: string
  encoded_id: string
  node_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/snippets/{workspace}/{encoded_id}/{node_id}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: node_id, var: node_id}]
    accept: ["application/json", "multipart/form-data", "multipart/related"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, node_id: $node_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a snippet's raw file
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}/files/{path}
export def "get-snippets-workspace-encoded-id-node-id-files-path" [
  workspace: string
  encoded_id: string
  node_id: string
  path: string
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
    path: "/snippets/{workspace}/{encoded_id}/{node_id}/files/{path}"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: node_id, var: node_id}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, node_id: $node_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get snippet changes between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/diff
export def "get-snippets-workspace-encoded-id-revision-diff" [
  workspace: string
  encoded_id: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # When used, only one the diff of the specified file will be returned.
]: nothing -> any {
  http-request {
    method: get
    path: "/snippets/{workspace}/{encoded_id}/{revision}/diff"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: revision, var: revision}]
    query: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, revision: $revision, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get snippet patch between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/patch
export def "get-snippets-workspace-encoded-id-revision-patch" [
  workspace: string
  encoded_id: string
  revision: string
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
    path: "/snippets/{workspace}/{encoded_id}/{revision}/patch"
    path_params: [{name: workspace, var: workspace}, {name: encoded_id, var: encoded_id}, {name: revision, var: revision}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, encoded_id: $encoded_id, revision: $revision
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables for an account
#
# GET /teams/{username}/pipelines_config/variables/
# DEPRECATED
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>
# operationId: getPipelineVariablesForTeam
@deprecated
export def "get-pipeline-variables-for-team" [
  username: string
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
    path: "/teams/{username}/pipelines_config/variables/"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable for a user
#
# POST /teams/{username}/pipelines_config/variables/
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: createPipelineVariableForTeam
@deprecated
export def "create-pipeline-variable-for-team" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{username}/pipelines_config/variables/"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable for a team
#
# DELETE /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForTeam
@deprecated
export def "delete-pipeline-variable-for-team" [
  username: string
  variable_uuid: string
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
    path: "/teams/{username}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: username, var: username}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    username: $username, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variable for a team
#
# GET /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: getPipelineVariableForTeam
@deprecated
export def "get-pipeline-variable-for-team" [
  username: string
  variable_uuid: string
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
    path: "/teams/{username}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: username, var: username}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable for a team
#
# PUT /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: updatePipelineVariableForTeam
@deprecated
export def "update-pipeline-variable-for-team" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/teams/{username}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: username, var: username}, {name: variable_uuid, var: variable_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, variable_uuid: $variable_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for code in a team's repositories
#
# GET /teams/{username}/search/code
# Returns: record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>
# operationId: searchTeam
export def "search-team" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query (required)
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{username}/search/code"
    path_params: [{name: username, var: username}]
    query: [{name: search_query, var: search_query, required: true}, {name: page, var: page}, {name: pagelen, var: pagelen}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, search_query: $search_query, page: $page, pagelen: $pagelen
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get current user
#
# GET /user
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>
export def "get-user" [
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
    path: "/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List email addresses for current user
#
# GET /user/emails
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "get-user-emails" [
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
    path: "/user/emails"
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an email address for current user
#
# GET /user/emails/{email}
# Returns: record<error: record<data: record, detail: string, message: string>, type: string>
export def "get-user-emails-email" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/emails/{email}"
    path_params: [{name: email, var: email}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repository permissions for a user
#
# GET /user/permissions/repositories
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>
export def "get-user-permissions-repositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/permissions/repositories"
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List workspaces for the current user
#
# GET /user/permissions/workspaces
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>
export def "get-user-permissions-workspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/permissions/workspaces"
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{selected_user}
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>>, username: string, uuid: string>
export def "get-users-selected-user" [
  selected_user: string
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
    path: "/users/{selected_user}"
    path_params: [{name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables for a user
#
# GET /users/{selected_user}/pipelines_config/variables/
# DEPRECATED
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>
# operationId: getPipelineVariablesForUser
@deprecated
export def "get-pipeline-variables-for-user" [
  selected_user: string
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
    path: "/users/{selected_user}/pipelines_config/variables/"
    path_params: [{name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable for a user
#
# POST /users/{selected_user}/pipelines_config/variables/
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: createPipelineVariableForUser
@deprecated
export def "create-pipeline-variable-for-user" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{selected_user}/pipelines_config/variables/"
    path_params: [{name: selected_user, var: selected_user}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    selected_user: $selected_user, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable for a user
#
# DELETE /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForUser
@deprecated
export def "delete-pipeline-variable-for-user" [
  selected_user: string
  variable_uuid: string
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
    path: "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: selected_user, var: selected_user}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    selected_user: $selected_user, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a variable for a user
#
# GET /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: getPipelineVariableForUser
@deprecated
export def "get-pipeline-variable-for-user" [
  selected_user: string
  variable_uuid: string
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
    path: "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: selected_user, var: selected_user}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a variable for a user
#
# PUT /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: updatePipelineVariableForUser
@deprecated
export def "update-pipeline-variable-for-user" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{selected_user}/pipelines_config/variables/{variable_uuid}"
    path_params: [{name: selected_user, var: selected_user}, {name: variable_uuid, var: variable_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, variable_uuid: $variable_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user application property
#
# DELETE /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: deleteUserHostedPropertyValue
export def "delete-user-hosted-property-value" [
  selected_user: string
  app_key: string
  property_name: string
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
    path: "/users/{selected_user}/properties/{app_key}/{property_name}"
    path_params: [{name: selected_user, var: selected_user}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    selected_user: $selected_user, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user application property
#
# GET /users/{selected_user}/properties/{app_key}/{property_name}
# Returns: record<_attributes: list<string>>
# operationId: retrieveUserHostedPropertyValue
export def "retrieve-user-hosted-property-value" [
  selected_user: string
  app_key: string
  property_name: string
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
    path: "/users/{selected_user}/properties/{app_key}/{property_name}"
    path_params: [{name: selected_user, var: selected_user}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, app_key: $app_key, property_name: $property_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user application property
#
# PUT /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: updateUserHostedPropertyValue
export def "update-user-hosted-property-value" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list<string>
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{selected_user}/properties/{app_key}/{property_name}"
    path_params: [{name: selected_user, var: selected_user}, {name: app_key, var: app_key}, {name: property_name, var: property_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: _attributes, var: attributes}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    selected_user: $selected_user, app_key: $app_key, property_name: $property_name, attributes: $attributes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for code in a user's repositories
#
# GET /users/{selected_user}/search/code
# Returns: record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>
# operationId: searchAccount
export def "search-account" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query (required)
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{selected_user}/search/code"
    path_params: [{name: selected_user, var: selected_user}]
    query: [{name: search_query, var: search_query, required: true}, {name: page, var: page}, {name: pagelen, var: pagelen}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, search_query: $search_query, page: $page, pagelen: $pagelen
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List SSH keys
#
# GET /users/{selected_user}/ssh-keys
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record, uuid: string, owner: record>>
export def "get-users-selected-user-ssh-keys" [
  selected_user: string
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
    path: "/users/{selected_user}/ssh-keys"
    path_params: [{name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new SSH key
#
# POST /users/{selected_user}/ssh-keys
# Returns: record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "post-users-selected-user-ssh-keys" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --comment: string # The comment parsed from the SSH key (if present)
  --created-on: string # format: date-time
  --key: string # The SSH public key value in OpenSSH format.
  --label: string # The user-defined label for the SSH key
  --last-used: string # format: date-time
  --links: record # shape: {self?: record}
  --uuid: string # The SSH key's immutable ID.
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{selected_user}/ssh-keys"
    path_params: [{name: selected_user, var: selected_user}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: comment, var: comment}, {name: created_on, var: created_on}, {name: key, var: key}, {name: label, var: label}, {name: last_used, var: last_used}, {name: links, var: links}, {name: uuid, var: uuid}, {name: owner, var: owner}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    selected_user: $selected_user, type: $type, comment: $comment, created_on: $created_on, key: $key, label: $label, last_used: $last_used, links: $links, uuid: $uuid, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a SSH key
#
# DELETE /users/{selected_user}/ssh-keys/{key_id}
export def "delete-users-selected-user-ssh-keys-key-id" [
  selected_user: string
  key_id: string
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
    path: "/users/{selected_user}/ssh-keys/{key_id}"
    path_params: [{name: selected_user, var: selected_user}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    selected_user: $selected_user, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a SSH key
#
# GET /users/{selected_user}/ssh-keys/{key_id}
# Returns: record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "get-users-selected-user-ssh-keys-key-id" [
  selected_user: string
  key_id: string
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
    path: "/users/{selected_user}/ssh-keys/{key_id}"
    path_params: [{name: selected_user, var: selected_user}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a SSH key
#
# PUT /users/{selected_user}/ssh-keys/{key_id}
# Returns: record<type: string, comment: string, created_on: string, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, uuid: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>>
export def "put-users-selected-user-ssh-keys-key-id" [
  selected_user: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --comment: string # The comment parsed from the SSH key (if present)
  --created-on: string # format: date-time
  --key: string # The SSH public key value in OpenSSH format.
  --label: string # The user-defined label for the SSH key
  --last-used: string # format: date-time
  --links: record # shape: {self?: record}
  --uuid: string # The SSH key's immutable ID.
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/{selected_user}/ssh-keys/{key_id}"
    path_params: [{name: selected_user, var: selected_user}, {name: key_id, var: key_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: comment, var: comment}, {name: created_on, var: created_on}, {name: key, var: key}, {name: label, var: label}, {name: last_used, var: last_used}, {name: links, var: links}, {name: uuid, var: uuid}, {name: owner, var: owner}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    selected_user: $selected_user, key_id: $key_id, type: $type, comment: $comment, created_on: $created_on, key: $key, label: $label, last_used: $last_used, links: $links, uuid: $uuid, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List workspaces for user
#
# GET /workspaces
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, is_private: bool, links: record, name: string, slug: string, updated_on: string, uuid: string>>
export def "get-workspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer-2 # Filters the workspaces based on the authenticated user's role on each workspace. * **member**: returns a list of all the workspaces which the caller is a member of at least one workspace group or repository * **collaborator**: returns a list of workspaces which the caller has write access to at least one repository in the workspace * **owner**: returns a list of workspaces which the caller has administrator access
  --q: string # Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --sort: string # Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces"
    query: [{name: role, var: role}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role: $role, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workspace
#
# GET /workspaces/{workspace}
# Returns: record<type: string, created_on: string, is_private: bool, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, members: record<href: string, name: string>, owners: record<href: string, name: string>, projects: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>, snippets: record<href: string, name: string>>, name: string, slug: string, updated_on: string, uuid: string>
export def "get-workspaces-workspace" [
  workspace: string
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
    path: "/workspaces/{workspace}"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List webhooks for a workspace
#
# GET /workspaces/{workspace}/hooks
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, active: bool, created_at: string, description: string, events: list, subject: record, subject_type: string, url: string, uuid: string>>
export def "get-workspaces-workspace-hooks" [
  workspace: string
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
    path: "/workspaces/{workspace}/hooks"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a webhook for a workspace
#
# POST /workspaces/{workspace}/hooks
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "post-workspaces-workspace-hooks" [
  workspace: string
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
    path: "/workspaces/{workspace}/hooks"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook for a workspace
#
# DELETE /workspaces/{workspace}/hooks/{uid}
export def "delete-workspaces-workspace-hooks-uid" [
  workspace: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/workspaces/{workspace}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook for a workspace
#
# GET /workspaces/{workspace}/hooks/{uid}
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "get-workspaces-workspace-hooks-uid" [
  workspace: string
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
    method: get
    path: "/workspaces/{workspace}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook for a workspace
#
# PUT /workspaces/{workspace}/hooks/{uid}
# Returns: record<type: string, active: bool, created_at: string, description: string, events: list<string>, subject: record<type: string>, subject_type: string, url: string, uuid: string>
export def "put-workspaces-workspace-hooks-uid" [
  workspace: string
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
    method: put
    path: "/workspaces/{workspace}/hooks/{uid}"
    path_params: [{name: workspace, var: workspace}, {name: uid, var: uid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users in a workspace
#
# GET /workspaces/{workspace}/members
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>
export def "get-workspaces-workspace-members" [
  workspace: string
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
    path: "/workspaces/{workspace}/members"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user membership for a workspace
#
# GET /workspaces/{workspace}/members/{member}
# Returns: record<type: string, links: record<self: record<href: string, name: string>>, user: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, workspace: record<type: string, created_on: string, is_private: bool, links: record<avatar: record, html: record, members: record, owners: record, projects: record, repositories: record, self: record, snippets: record>, name: string, slug: string, updated_on: string, uuid: string>>
export def "get-workspaces-workspace-members-member" [
  workspace: string
  member: string
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
    path: "/workspaces/{workspace}/members/{member}"
    path_params: [{name: workspace, var: workspace}, {name: member, var: member}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, member: $member
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List user permissions in a workspace
#
# GET /workspaces/{workspace}/permissions
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, links: record, user: record, workspace: record>>
export def "get-workspaces-workspace-permissions" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace}/permissions"
    path_params: [{name: workspace, var: workspace}]
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>
export def "get-workspaces-workspace-permissions-repositories" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace}/permissions/repositories"
    path_params: [{name: workspace, var: workspace}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories/{repo_slug}
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<permission: string, repository: record, type: string, user: record>>
export def "get-workspaces-workspace-permissions-repositories-repo-slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --sort: string # Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace}/permissions/repositories/{repo_slug}"
    path_params: [{name: workspace, var: workspace}, {name: repo_slug, var: repo_slug}]
    query: [{name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, repo_slug: $repo_slug, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get OpenID configuration for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/.well-known/openid-configuration
# operationId: getOIDCConfiguration
export def "get-oidc-configuration" [
  workspace: string
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
    path: "/workspaces/{workspace}/pipelines-config/identity/oidc/.well-known/openid-configuration"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get keys for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/keys.json
# operationId: getOIDCKeys
export def "get-oidc-keys" [
  workspace: string
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
    path: "/workspaces/{workspace}/pipelines-config/identity/oidc/keys.json"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List variables for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, key: string, secured: bool, uuid: string, value: string>>
# operationId: getPipelineVariablesForWorkspace
export def "get-pipeline-variables-for-workspace" [
  workspace: string
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
    path: "/workspaces/{workspace}/pipelines-config/variables"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a variable for a workspace
#
# POST /workspaces/{workspace}/pipelines-config/variables
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: createPipelineVariableForWorkspace
export def "create-pipeline-variable-for-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace}/pipelines-config/variables"
    path_params: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a variable for a workspace
#
# DELETE /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: deletePipelineVariableForWorkspace
export def "delete-pipeline-variable-for-workspace" [
  workspace: string
  variable_uuid: string
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
    path: "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get variable for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: getPipelineVariableForWorkspace
export def "get-pipeline-variable-for-workspace" [
  workspace: string
  variable_uuid: string
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
    path: "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: variable_uuid, var: variable_uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, variable_uuid: $variable_uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update variable for a workspace
#
# PUT /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# Returns: record<type: string, key: string, secured: bool, uuid: string, value: string>
# operationId: updatePipelineVariableForWorkspace
export def "update-pipeline-variable-for-workspace" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --key: string # The unique name of the variable.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
  --uuid: string # The UUID identifying the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/workspaces/{workspace}/pipelines-config/variables/{variable_uuid}"
    path_params: [{name: workspace, var: workspace}, {name: variable_uuid, var: variable_uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: key, var: key}, {name: secured, var: secured}, {name: uuid, var: uuid}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, variable_uuid: $variable_uuid, type: $type, key: $key, secured: $secured, uuid: $uuid, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List projects in a workspace
#
# GET /workspaces/{workspace}/projects
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record, name: string, owner: record, updated_on: string, uuid: string>>
export def "get-workspaces-workspace-projects" [
  workspace: string
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
    path: "/workspaces/{workspace}/projects"
    path_params: [{name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project in a workspace
#
# POST /workspaces/{workspace}/projects
# Returns: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>
export def "post-workspaces-workspace-projects" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --has-publicly-visible-repos: oneof<nothing, bool> # Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
  --is-private: oneof<nothing, bool> # Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --key: string # The project's key.
  --links: record # shape: {avatar?: record, html?: record}
  --name: string # The name of the project.
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --updated-on: string # format: date-time
  --uuid: string # The project's immutable id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace}/projects"
    path_params: [{name: workspace, var: workspace}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: has_publicly_visible_repos, var: has_publicly_visible_repos}, {name: is_private, var: is_private}, {name: key, var: key}, {name: links, var: links}, {name: name, var: name}, {name: owner, var: owner}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace: $workspace, type: $type, created_on: $created_on, description: $description, has_publicly_visible_repos: $has_publicly_visible_repos, is_private: $is_private, key: $key, links: $links, name: $name, owner: $owner, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project for a workspace
#
# DELETE /workspaces/{workspace}/projects/{project_key}
export def "delete-workspaces-workspace-projects-project-key" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project for a workspace
#
# GET /workspaces/{workspace}/projects/{project_key}
# Returns: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>
export def "get-workspaces-workspace-projects-project-key" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project for a workspace
#
# PUT /workspaces/{workspace}/projects/{project_key}
# Returns: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record<avatar: record, html: record, members: record, projects: record, repositories: record, self: record>, username: string, uuid: string>, updated_on: string, uuid: string>
export def "put-workspaces-workspace-projects-project-key" [
  workspace: string
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  --created-on: string # format: date-time
  --description: string
  --has-publicly-visible-repos: oneof<nothing, bool> # Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
  --is-private: oneof<nothing, bool> # Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --key: string # The project's key.
  --links: record # shape: {avatar?: record, html?: record}
  --name: string # The name of the project.
  --owner: record # Base type for most resource objects. It defines the common `type` element that identifies an object's type. It also identifies the element as Swagger's `discriminator`. — shape: {type: string, created_on?: string, display_name?: string, links?: record, username?: string, uuid?: string}
  --updated-on: string # format: date-time
  --uuid: string # The project's immutable id.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/workspaces/{workspace}/projects/{project_key}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: created_on, var: created_on}, {name: description, var: description}, {name: has_publicly_visible_repos, var: has_publicly_visible_repos}, {name: is_private, var: is_private}, {name: key, var: key}, {name: links, var: links}, {name: name, var: name}, {name: owner, var: owner}, {name: updated_on, var: updated_on}, {name: uuid, var: uuid}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, type: $type, created_on: $created_on, description: $description, has_publicly_visible_repos: $has_publicly_visible_repos, is_private: $is_private, key: $key, links: $links, name: $name, owner: $owner, updated_on: $updated_on, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the branching model for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model
# Returns: record<type: string, branch_types: table<kind: string, prefix: string>, development: record<name: string, use_mainbranch: bool>, production: record<name: string, use_mainbranch: bool>>
export def "get-workspaces-workspace-projects-project-key-branching-model" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/branching-model"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the branching model config for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model/settings
# Returns: record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>
export def "get-workspaces-workspace-projects-project-key-branching-model-settings" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/branching-model/settings"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the branching model config for a project
#
# PUT /workspaces/{workspace}/projects/{project_key}/branching-model/settings
# Returns: record<type: string, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, links: record<self: record<href: string, name: string>>, production: record<enabled: bool, is_valid: bool, name: string, use_mainbranch: bool>>
export def "put-workspaces-workspace-projects-project-key-branching-model-settings" [
  workspace: string
  project_key: string
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
    method: put
    path: "/workspaces/{workspace}/projects/{project_key}/branching-model/settings"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the default reviewers in a project
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<reviewer_type: string, type: string, user: record>>
export def "get-workspaces-workspace-projects-project-key-default-reviewers" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/default-reviewers"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove the specific user from the project's default reviewers
#
# DELETE /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "delete-workspaces-workspace-projects-project-key-default-reviewers-selected-user" [
  workspace: string
  project_key: string
  selected_user: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}, {name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a default reviewer
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>
export def "get-workspaces-workspace-projects-project-key-default-reviewers-selected-user" [
  workspace: string
  project_key: string
  selected_user: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}, {name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add the specific user as a default reviewer for the project
#
# PUT /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
# Returns: record<type: string, created_on: string, display_name: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>, self: record<href: string, name: string>>, username: string, uuid: string, account_id: string, account_status: string, has_2fa_enabled: bool, is_staff: bool, nickname: string, website: string>
export def "put-workspaces-workspace-projects-project-key-default-reviewers-selected-user" [
  workspace: string
  project_key: string
  selected_user: string
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
    method: put
    path: "/workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}, {name: selected_user, var: selected_user}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, selected_user: $selected_user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List project deploy keys
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys
# Returns: record<next: string, page: int, pagelen: int, previous: string, size: int, values: table<type: string, added_on: string, comment: string, created_by: record, key: string, label: string, last_used: string, links: record, project: record>>
export def "get-workspaces-workspace-projects-project-key-deploy-keys" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/deploy-keys"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project deploy key
#
# POST /workspaces/{workspace}/projects/{project_key}/deploy-keys
# Returns: record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>>
export def "post-workspaces-workspace-projects-project-key-deploy-keys" [
  workspace: string
  project_key: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/deploy-keys"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a deploy key from a project
#
# DELETE /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
export def "delete-workspaces-workspace-projects-project-key-deploy-keys-key-id" [
  workspace: string
  project_key: string
  key_id: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project deploy key
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
# Returns: record<type: string, added_on: string, comment: string, created_by: record<type: string, created_on: string, display_name: string, links: record<avatar: record>, username: string, uuid: string>, key: string, label: string, last_used: string, links: record<self: record<href: string, name: string>>, project: record<type: string, created_on: string, description: string, has_publicly_visible_repos: bool, is_private: bool, key: string, links: record<avatar: record, html: record>, name: string, owner: record<type: string, created_on: string, display_name: string, links: record, username: string, uuid: string>, updated_on: string, uuid: string>>
export def "get-workspaces-workspace-projects-project-key-deploy-keys-key-id" [
  workspace: string
  project_key: string
  key_id: string
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
    path: "/workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}"
    path_params: [{name: workspace, var: workspace}, {name: project_key, var: project_key}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, project_key: $project_key, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for code in a workspace
#
# GET /workspaces/{workspace}/search/code
# Returns: record<next: string, page: int, pagelen: int, previous: string, query_substituted: bool, size: int, values: table<content_match_count: int, content_matches: list, file: record, path_matches: list, type: string>>
# operationId: searchWorkspace
export def "search-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-query: string # The search query (required)
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace}/search/code"
    path_params: [{name: workspace, var: workspace}]
    query: [{name: search_query, var: search_query, required: true}, {name: page, var: page}, {name: pagelen, var: pagelen}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, search_query: $search_query, page: $page, pagelen: $pagelen
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
