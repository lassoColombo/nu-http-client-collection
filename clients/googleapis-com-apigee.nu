# Auto-generated client for Apigee API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/apigee/v1/openapi.json
# Auth: --token flag or $env.APIGEE_API_TOKEN

const CLIENT = {
  base_url: "https://apigee.googleapis.com"
  token_env_var: "APIGEE_API_TOKEN"
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

def base-url-completer [] { ["https://apigee.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def billing-type-completer [] { ["BILLING_TYPE_UNSPECIFIED" "EVALUATION" "PAYG" "SUBSCRIPTION"] }
def runtime-type-completer [] { ["CLOUD" "HYBRID" "RUNTIME_TYPE_UNSPECIFIED"] }
def type-completer [] { ["TYPE_INTERNAL" "TYPE_PAID" "TYPE_TRIAL" "TYPE_UNSPECIFIED"] }
def retention-completer [] { ["DELETION_RETENTION_UNSPECIFIED" "MINIMUM"] }
def format-completer [] { ["BASIC" "FULL" "INGRESS_CONFIG_VIEW_UNSPECIFIED"] }
def timestamp-order-completer [] { ["ASCENDING" "DESCENDING" "ORDER_UNSPECIFIED"] }
def window-size-completer [] { ["DAY" "HOUR" "MINUTE" "MONTH" "WINDOW_SIZE_UNSPECIFIED"] }
def quota-counter-scope-completer [] { ["OPERATION" "PROXY" "QUOTA_COUNTER_SCOPE_UNSPECIFIED"] }
def type-completer-1 [] { ["BOOLEAN" "DATETIME" "FLOAT" "INTEGER" "STRING" "TYPE_UNSPECIFIED"] }
def peering-cidr-range-completer [] { ["CIDR_RANGE_UNSPECIFIED" "SLASH_16" "SLASH_17" "SLASH_18" "SLASH_19" "SLASH_20" "SLASH_22" "SLASH_23"] }
def state-completer [] { ["DRAFT" "PUBLISHED" "STATE_UNSPECIFIED"] }
def billing-period-completer [] { ["BILLING_PERIOD_UNSPECIFIED" "MONTHLY" "WEEKLY"] }
def consumption-pricing-type-completer [] { ["BANDED" "CONSUMPTION_PRICING_TYPE_UNSPECIFIED" "FIXED_PER_UNIT" "STAIRSTEP" "TIERED"] }
def payment-funding-model-completer [] { ["PAYMENT_FUNDING_MODEL_UNSPECIFIED" "POSTPAID" "PREPAID"] }
def revenue-share-type-completer [] { ["FIXED" "REVENUE_SHARE_TYPE_UNSPECIFIED" "VOLUME_BANDED"] }
def protocol-completer [] { ["GRPC" "HTTP" "PROTOCOL_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    apigee-organizations-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-instances-report-status: "record"
    apigee-organizations-sites-apicategories-delete: "record<errorCode: string, message: string, requestId: string, status: string>"
    apigee-organizations-sites-apicategories-get: "record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>"
    apigee-organizations-sites-apicategories-patch: "record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>"
    apigee-organizations-sharedflows-revisions-update-shared-flow-revision: "record<configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, lastModifiedAt: string, name: string, policies: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, type: string>"
    apigee-organizations-reports-update: "record<chartType: string, comments: list<string>, createdAt: string, dimensions: list<string>, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: table<function: string, name: string>, name: string, offset: string, organization: string, properties: table<property: string, value: list>, sortByCols: list<string>, sortOrder: string, tags: list<string>, timeUnit: string, toTime: string, topk: string>"
    apigee-organizations-developers-apps-attributes: "record<attribute: table<name: string, value: string>>"
    apigee-organizations-environments-keystores-aliases-get-certificate: "record<contentType: string, data: string, extensions: list<record>>"
    apigee-organizations-environments-keystores-aliases-csr: "record<contentType: string, data: string, extensions: list<record>>"
    apigee-organizations-environments-apis-revisions-debugsessions-delete-data: "record"
    apigee-organizations-environments-sharedflows-revisions-undeploy: "record"
    apigee-organizations-environments-sharedflows-revisions-get-deployments: "record<apiProxy: string, deployStartTime: string, environment: string, errors: table<code: int, details: list, message: string>, instances: table<deployedRevisions: list, deployedRoutes: list, instance: string>, pods: table<appVersion: string, deploymentStatus: string, deploymentStatusTime: string, deploymentTime: string, podName: string, podStatus: string, podStatusTime: string, statusCode: string, statusCodeDetails: string>, revision: string, routeConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, serviceAccount: string, state: string>"
    apigee-organizations-environments-sharedflows-revisions-deploy: "record<apiProxy: string, deployStartTime: string, environment: string, errors: table<code: int, details: list, message: string>, instances: table<deployedRevisions: list, deployedRoutes: list, instance: string>, pods: table<appVersion: string, deploymentStatus: string, deploymentStatusTime: string, deploymentTime: string, podName: string, podStatus: string, podStatusTime: string, statusCode: string, statusCodeDetails: string>, revision: string, routeConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, serviceAccount: string, state: string>"
    apigee-organizations-environments-apis-revisions-deployments-generate-deploy-change-report: "record<routingChanges: table<description: string, environmentGroup: string, fromDeployment: record, shouldSequenceRollout: bool, toDeployment: record>, routingConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, validationErrors: record<violations: list<record>>>"
    apigee-organizations-environments-apis-revisions-deployments-generate-undeploy-change-report: "record<routingChanges: table<description: string, environmentGroup: string, fromDeployment: record, shouldSequenceRollout: bool, toDeployment: record>, routingConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, validationErrors: record<violations: list<record>>>"
    apigee-organizations-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    apigee-organizations-instances-nat-addresses-activate: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-developers-balance-adjust: "record<wallets: table<balance: record, lastCreditTime: string>>"
    apigee-organizations-developers-balance-credit: "record<wallets: table<balance: record, lastCreditTime: string>>"
    apigee-organizations-developers-subscriptions-expire: "record<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>"
    apigee-organizations-environments-archive-deployments-generate-download-url: "record<downloadUri: string>"
    apigee-organizations-get-project-mapping: "record<location: string, organization: string, projectId: string, projectIds: list<string>>"
    apigee-organizations-get-sync-authorization: "record<etag: string, identities: list<string>>"
    apigee-organizations-security-profiles-list-revisions: "record<nextPageToken: string, securityProfiles: table<displayName: string, environments: list, maxScore: int, minScore: int, name: string, revisionCreateTime: string, revisionId: string, revisionPublishTime: string, revisionUpdateTime: string, scoringConfigs: list>>"
    apigee-organizations-set-sync-authorization: "record<etag: string, identities: list<string>>"
    apigee-organizations-environments-security-stats-query-tabular-stats: "record<columns: list<string>, nextPageToken: string, values: list<list<any>>>"
    apigee-organizations-environments-security-stats-query-time-series-stats: "record<columns: list<string>, nextPageToken: string, values: table<dimensions: record, points: list>>"
    apigee-organizations-set-addons: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-list: "record<organizations: table<location: string, organization: string, projectId: string, projectIds: list>>"
    apigee-organizations-environments-keystores-aliases-create: "record<alias: string, certsInfo: record<certInfo: list<record>>, type: string>"
    apigee-organizations-analytics-datastores-list: "record<datastores: table<createTime: string, datastoreConfig: record, displayName: string, lastUpdateTime: string, org: string, self: string, targetType: string>>"
    apigee-organizations-analytics-datastores-create: "record<createTime: string, datastoreConfig: record<bucketName: string, datasetName: string, path: string, projectId: string, tablePrefix: string>, displayName: string, lastUpdateTime: string, org: string, self: string, targetType: string>"
    apigee-organizations-analytics-datastores-test: "record<error: string, state: string>"
    apigee-organizations-environments-analytics-exports-list: "record<exports: table<created: string, datastoreName: string, description: string, error: string, executionTime: string, name: string, self: string, state: string, updated: string>>"
    apigee-organizations-environments-analytics-exports-create: "record<created: string, datastoreName: string, description: string, error: string, executionTime: string, name: string, self: string, state: string, updated: string>"
    apigee-organizations-sites-apicategories-list: "record<data: table<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>"
    apigee-organizations-sites-apicategories-create: "record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>"
    apigee-organizations-apiproducts-list: "record<apiProduct: table<apiResources: list, approvalType: string, attributes: list, createdAt: string, description: string, displayName: string, environments: list, graphqlOperationGroup: record, lastModifiedAt: string, name: string, operationGroup: record, proxies: list, quota: string, quotaCounterScope: string, quotaInterval: string, quotaTimeUnit: string, scopes: list>>"
    apigee-organizations-apiproducts-create: "record<apiResources: list<string>, approvalType: string, attributes: table<name: string, value: string>, createdAt: string, description: string, displayName: string, environments: list<string>, graphqlOperationGroup: record<operationConfigType: string, operationConfigs: list<record>>, lastModifiedAt: string, name: string, operationGroup: record<operationConfigType: string, operationConfigs: list<record>>, proxies: list<string>, quota: string, quotaCounterScope: string, quotaInterval: string, quotaTimeUnit: string, scopes: list<string>>"
    apigee-organizations-apis-list: "record<proxies: table<apiProxyType: string, labels: record, latestRevisionId: string, metaData: record, name: string, readOnly: bool, revision: list>>"
    apigee-organizations-apis-create: "record<archive: string, basepaths: list<string>, configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, integrationEndpoints: list<string>, lastModifiedAt: string, name: string, policies: list<string>, proxies: list<string>, proxyEndpoints: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, spec: string, targetEndpoints: list<string>, targetServers: list<string>, targets: list<string>, teams: list<string>, type: string>"
    apigee-organizations-developers-apps-list: "record<app: table<apiProducts: list, appFamily: string, appId: string, attributes: list, callbackUrl: string, createdAt: string, credentials: list, developerId: string, keyExpiresIn: string, lastModifiedAt: string, name: string, scopes: list, status: string>>"
    apigee-organizations-developers-apps-create: "record<apiProducts: list<string>, appFamily: string, appId: string, attributes: table<name: string, value: string>, callbackUrl: string, createdAt: string, credentials: table<apiProducts: list, attributes: list, consumerKey: string, consumerSecret: string, expiresAt: string, issuedAt: string, scopes: list, status: string>, developerId: string, keyExpiresIn: string, lastModifiedAt: string, name: string, scopes: list<string>, status: string>"
    apigee-organizations-environments-archive-deployments-list: "record<archiveDeployments: table<createdAt: string, gcsUri: string, labels: record, name: string, operation: string, updatedAt: string>, nextPageToken: string>"
    apigee-organizations-environments-archive-deployments-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-environments-archive-deployments-generate-upload-url: "record<uploadUri: string>"
    apigee-organizations-instances-attachments-list: "record<attachments: table<createdAt: string, environment: string, name: string>, nextPageToken: string>"
    apigee-organizations-instances-attachments-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-developers-attributes-list: "record<attribute: table<name: string, value: string>>"
    apigee-organizations-developers-attributes: "record<attribute: table<name: string, value: string>>"
    apigee-organizations-instances-canaryevaluations-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-datacollectors-list: "record<dataCollectors: table<createdAt: string, description: string, lastModifiedAt: string, name: string, type: string>, nextPageToken: string>"
    apigee-organizations-datacollectors-create: "record<createdAt: string, description: string, lastModifiedAt: string, name: string, type: string>"
    apigee-organizations-environments-apis-revisions-debugsessions-list: "record<nextPageToken: string, sessions: table<id: string, timestampMs: string>>"
    apigee-organizations-environments-apis-revisions-debugsessions-create: "record<count: int, createTime: string, filter: string, name: string, timeout: string, tracesize: int, validity: int>"
    apigee-organizations-sharedflows-revisions-deployments-list: "record<deployments: table<apiProxy: string, deployStartTime: string, environment: string, errors: list, instances: list, pods: list, revision: string, routeConflicts: list, serviceAccount: string, state: string>>"
    apigee-organizations-developers-list: "record<developer: table<accessType: string, appFamily: string, apps: list, attributes: list, companies: list, createdAt: string, developerId: string, email: string, firstName: string, lastModifiedAt: string, lastName: string, organizationName: string, status: string, userName: string>>"
    apigee-organizations-developers-create: "record<accessType: string, appFamily: string, apps: list<string>, attributes: table<name: string, value: string>, companies: list<string>, createdAt: string, developerId: string, email: string, firstName: string, lastModifiedAt: string, lastName: string, organizationName: string, status: string, userName: string>"
    apigee-organizations-endpoint-attachments-list: "record<endpointAttachments: table<connectionState: string, host: string, location: string, name: string, serviceAttachment: string, state: string>, nextPageToken: string>"
    apigee-organizations-endpoint-attachments-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-keyvaluemaps-entries-list: "record<keyValueEntries: table<name: string, value: string>, nextPageToken: string>"
    apigee-organizations-keyvaluemaps-entries-create: "record<name: string, value: string>"
    apigee-organizations-envgroups-list: "record<environmentGroups: table<createdAt: string, hostnames: list, lastModifiedAt: string, name: string, state: string>, nextPageToken: string>"
    apigee-organizations-envgroups-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-security-profiles-environments-create: "record<attachTime: string, name: string, securityProfileRevisionId: string>"
    apigee-organizations-host-queries-list: "record<queries: table<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>"
    apigee-organizations-host-queries-create: "record<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, outputFormat: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>"
    apigee-organizations-host-security-reports-list: "record<nextPageToken: string, securityReports: table<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>"
    apigee-organizations-host-security-reports-create: "record<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, mimeType: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>"
    apigee-organizations-instances-list: "record<instances: table<consumerAcceptList: list, createdAt: string, description: string, diskEncryptionKeyName: string, displayName: string, host: string, ipRange: string, lastModifiedAt: string, location: string, name: string, peeringCidrRange: string, port: string, runtimeVersion: string, serviceAttachment: string, state: string>, nextPageToken: string>"
    apigee-organizations-instances-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-developers-apps-keys-create: "record<apiProducts: list<any>, attributes: table<name: string, value: string>, consumerKey: string, consumerSecret: string, expiresAt: string, expiresInSeconds: string, issuedAt: string, scopes: list<string>, status: string>"
    apigee-organizations-developers-apps-keys-create-create: "record<apiProducts: list<any>, attributes: table<name: string, value: string>, consumerKey: string, consumerSecret: string, expiresAt: string, expiresInSeconds: string, issuedAt: string, scopes: list<string>, status: string>"
    apigee-organizations-environments-keystores-create: "record<aliases: list<string>, name: string>"
    apigee-organizations-keyvaluemaps-create: "record<encrypted: bool, name: string>"
    apigee-organizations-instances-nat-addresses-list: "record<natAddresses: table<ipAddress: string, name: string, state: string>, nextPageToken: string>"
    apigee-organizations-instances-nat-addresses-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-environments-trace-config-overrides-list: "record<nextPageToken: string, traceConfigOverrides: table<apiProxy: string, name: string, samplingConfig: record>>"
    apigee-organizations-environments-trace-config-overrides-create: "record<apiProxy: string, name: string, samplingConfig: record<sampler: string, samplingRate: float>>"
    apigee-organizations-environments-queries-list: "record<queries: table<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>"
    apigee-organizations-environments-queries-create: "record<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, outputFormat: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>"
    apigee-organizations-apiproducts-rateplans-list: "record<nextStartKey: string, ratePlans: table<apiproduct: string, billingPeriod: string, consumptionPricingRates: list, consumptionPricingType: string, createdAt: string, currencyCode: string, description: string, displayName: string, endTime: string, fixedFeeFrequency: int, fixedRecurringFee: record, lastModifiedAt: string, name: string, paymentFundingModel: string, revenueShareRates: list, revenueShareType: string, setupFee: record, startTime: string, state: string>>"
    apigee-organizations-apiproducts-rateplans-create: "record<apiproduct: string, billingPeriod: string, consumptionPricingRates: table<end: string, fee: record, start: string>, consumptionPricingType: string, createdAt: string, currencyCode: string, description: string, displayName: string, endTime: string, fixedFeeFrequency: int, fixedRecurringFee: record<currencyCode: string, nanos: int, units: string>, lastModifiedAt: string, name: string, paymentFundingModel: string, revenueShareRates: table<end: string, sharePercentage: float, start: string>, revenueShareType: string, setupFee: record<currencyCode: string, nanos: int, units: string>, startTime: string, state: string>"
    apigee-organizations-environments-references-create: "record<description: string, name: string, refers: string, resourceType: string>"
    apigee-organizations-reports-list: "record<qualifier: table<chartType: string, comments: list, createdAt: string, dimensions: list, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: list, name: string, offset: string, organization: string, properties: list, sortByCols: list, sortOrder: string, tags: list, timeUnit: string, toTime: string, topk: string>>"
    apigee-organizations-reports-create: "record<chartType: string, comments: list<string>, createdAt: string, dimensions: list<string>, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: table<function: string, name: string>, name: string, offset: string, organization: string, properties: table<property: string, value: list>, sortByCols: list<string>, sortOrder: string, tags: list<string>, timeUnit: string, toTime: string, topk: string>"
    apigee-organizations-environments-resourcefiles-list: "record<resourceFile: table<name: string, type: string>>"
    apigee-organizations-environments-resourcefiles-create: "record<name: string, type: string>"
    apigee-organizations-environments-resourcefiles-list-environment-resources: "record<resourceFile: table<name: string, type: string>>"
    apigee-organizations-environments-resourcefiles-delete: "record<name: string, type: string>"
    apigee-organizations-environments-resourcefiles-get: "record<contentType: string, data: string, extensions: list<record>>"
    apigee-organizations-environments-resourcefiles-update: "record<name: string, type: string>"
    apigee-organizations-environments-security-incidents-list: "record<nextPageToken: string, securityIncidents: table<detectionTypes: list, displayName: string, firstDetectedTime: string, lastDetectedTime: string, name: string, riskLevel: string, trafficCount: string>>"
    apigee-organizations-security-profiles-list: "record<nextPageToken: string, securityProfiles: table<displayName: string, environments: list, maxScore: int, minScore: int, name: string, revisionCreateTime: string, revisionId: string, revisionPublishTime: string, revisionUpdateTime: string, scoringConfigs: list>>"
    apigee-organizations-environments-security-reports-list: "record<nextPageToken: string, securityReports: table<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>"
    apigee-organizations-environments-security-reports-create: "record<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, mimeType: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>"
    apigee-organizations-sharedflows-list: "record<sharedFlows: table<latestRevisionId: string, metaData: record, name: string, revision: list>>"
    apigee-organizations-sharedflows-create: "record<configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, lastModifiedAt: string, name: string, policies: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, type: string>"
    apigee-organizations-developers-subscriptions-list: "record<developerSubscriptions: table<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>, nextStartKey: string>"
    apigee-organizations-developers-subscriptions-create: "record<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>"
    apigee-organizations-environments-targetservers-create: "record<description: string, host: string, isEnabled: bool, name: string, port: int, protocol: string, sSLInfo: record<ciphers: list<string>, clientAuthEnabled: bool, commonName: record<value: string, wildcardMatch: bool>, enabled: bool, ignoreValidationErrors: bool, keyAlias: string, keyStore: string, protocols: list<string>, trustStore: string>>"
    apigee-organizations-environments-subscribe: "record<name: string>"
    apigee-organizations-environments-unsubscribe: "record"
    apigee-organizations-security-profiles-environments-compute-environment-scores: "record<nextPageToken: string, scores: table<component: record, subcomponents: list, timeRange: record>>"
    apigee-projects-provision-organization: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    apigee-organizations-environments-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    apigee-organizations-environments-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    apigee-organizations-environments-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["apigee-organizations-create" "apigee-organizations-instances-report-status" "apigee-organizations-sites-apicategories-delete" "apigee-organizations-sites-apicategories-get" "apigee-organizations-sites-apicategories-patch" "apigee-organizations-sharedflows-revisions-update-shared-flow-revision" "apigee-organizations-reports-update" "apigee-organizations-developers-apps-attributes" "apigee-organizations-environments-keystores-aliases-get-certificate" "apigee-organizations-environments-keystores-aliases-csr" "apigee-organizations-environments-apis-revisions-debugsessions-delete-data" "apigee-organizations-environments-sharedflows-revisions-undeploy" "apigee-organizations-environments-sharedflows-revisions-get-deployments" "apigee-organizations-environments-sharedflows-revisions-deploy" "apigee-organizations-environments-apis-revisions-deployments-generate-deploy-change-report" "apigee-organizations-environments-apis-revisions-deployments-generate-undeploy-change-report" "apigee-organizations-operations-list" "apigee-organizations-instances-nat-addresses-activate" "apigee-organizations-developers-balance-adjust" "apigee-organizations-developers-balance-credit" "apigee-organizations-developers-subscriptions-expire" "apigee-organizations-environments-archive-deployments-generate-download-url" "apigee-organizations-get-project-mapping" "apigee-organizations-get-sync-authorization" "apigee-organizations-security-profiles-list-revisions" "apigee-organizations-set-sync-authorization" "apigee-organizations-environments-security-stats-query-tabular-stats" "apigee-organizations-environments-security-stats-query-time-series-stats" "apigee-organizations-set-addons" "apigee-organizations-list" "apigee-organizations-environments-keystores-aliases-create" "apigee-organizations-analytics-datastores-list" "apigee-organizations-analytics-datastores-create" "apigee-organizations-analytics-datastores-test" "apigee-organizations-environments-analytics-exports-list" "apigee-organizations-environments-analytics-exports-create" "apigee-organizations-sites-apicategories-list" "apigee-organizations-sites-apicategories-create" "apigee-organizations-apiproducts-list" "apigee-organizations-apiproducts-create" "apigee-organizations-apis-list" "apigee-organizations-apis-create" "apigee-organizations-developers-apps-list" "apigee-organizations-developers-apps-create" "apigee-organizations-environments-archive-deployments-list" "apigee-organizations-environments-archive-deployments-create" "apigee-organizations-environments-archive-deployments-generate-upload-url" "apigee-organizations-instances-attachments-list" "apigee-organizations-instances-attachments-create" "apigee-organizations-developers-attributes-list" "apigee-organizations-developers-attributes" "apigee-organizations-instances-canaryevaluations-create" "apigee-organizations-datacollectors-list" "apigee-organizations-datacollectors-create" "apigee-organizations-environments-apis-revisions-debugsessions-list" "apigee-organizations-environments-apis-revisions-debugsessions-create" "apigee-organizations-sharedflows-revisions-deployments-list" "apigee-organizations-developers-list" "apigee-organizations-developers-create" "apigee-organizations-endpoint-attachments-list" "apigee-organizations-endpoint-attachments-create" "apigee-organizations-keyvaluemaps-entries-list" "apigee-organizations-keyvaluemaps-entries-create" "apigee-organizations-envgroups-list" "apigee-organizations-envgroups-create" "apigee-organizations-security-profiles-environments-create" "apigee-organizations-host-queries-list" "apigee-organizations-host-queries-create" "apigee-organizations-host-security-reports-list" "apigee-organizations-host-security-reports-create" "apigee-organizations-instances-list" "apigee-organizations-instances-create" "apigee-organizations-developers-apps-keys-create" "apigee-organizations-developers-apps-keys-create-create" "apigee-organizations-environments-keystores-create" "apigee-organizations-keyvaluemaps-create" "apigee-organizations-instances-nat-addresses-list" "apigee-organizations-instances-nat-addresses-create" "apigee-organizations-environments-trace-config-overrides-list" "apigee-organizations-environments-trace-config-overrides-create" "apigee-organizations-environments-queries-list" "apigee-organizations-environments-queries-create" "apigee-organizations-apiproducts-rateplans-list" "apigee-organizations-apiproducts-rateplans-create" "apigee-organizations-environments-references-create" "apigee-organizations-reports-list" "apigee-organizations-reports-create" "apigee-organizations-environments-resourcefiles-list" "apigee-organizations-environments-resourcefiles-create" "apigee-organizations-environments-resourcefiles-list-environment-resources" "apigee-organizations-environments-resourcefiles-delete" "apigee-organizations-environments-resourcefiles-get" "apigee-organizations-environments-resourcefiles-update" "apigee-organizations-environments-security-incidents-list" "apigee-organizations-security-profiles-list" "apigee-organizations-environments-security-reports-list" "apigee-organizations-environments-security-reports-create" "apigee-organizations-sharedflows-list" "apigee-organizations-sharedflows-create" "apigee-organizations-developers-subscriptions-list" "apigee-organizations-developers-subscriptions-create" "apigee-organizations-environments-targetservers-create" "apigee-organizations-environments-subscribe" "apigee-organizations-environments-unsubscribe" "apigee-organizations-security-profiles-environments-compute-environment-scores" "apigee-projects-provision-organization" "apigee-organizations-environments-get-iam-policy" "apigee-organizations-environments-set-iam-policy" "apigee-organizations-environments-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Creates an Apigee organization. See [Create an Apigee organization](https://cloud.google.com/apigee/docs/api-platform/get-started/create-org).
#
# POST /v1/organizations
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.create
export def "apigee-organizations-create" [
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
  --parent: string # Required. Name of the Google Cloud project in which to associate the Apigee organization. Pass the information as a query parameter using the following structure in your request: `projects/`
  --addons-config: record # Add-on configurations for the Apigee organization. — shape: {advancedApiOpsConfig?: record, apiSecurityConfig?: record, connectorsPlatformConfig?: record, integrationConfig?: record, monetizationConfig?: record}
  --analytics-region: string # Required. DEPRECATED: This field will be deprecated once Apigee supports DRZ. Primary Google Cloud region for analytics data storage. For valid values, see [Create an Apigee organization](https://cloud.google.com/apigee/docs/api-platform/get-started/create-org).
  --api-consumer-data-encryption-key-name: string # Cloud KMS key name used for encrypting API consumer data. Required for US/EU regions when [BillingType](#BillingType) is `SUBSCRIPTION`. When [BillingType](#BillingType) is `EVALUATION` or the region is not US/EU, a Google-Managed encryption key will be used. Format: `projects/*/locations/*/keyRings/*/cryptoKeys/*`
  --api-consumer-data-location: string # This field is needed only for customers with control plane in US or EU. Apigee stores some control plane data only in single region. This field determines which single region Apigee should use. For example: "us-west1" when control plane is in US or "europe-west2" when control plane is in EU.
  --attributes: list<string> # Not used by Apigee.
  --authorized-network: string # Compute Engine network used for Service Networking to be peered with Apigee runtime instances. See [Getting started with the Service Networking API](https://cloud.google.com/service-infrastructure/docs/service-networking/getting-started). Valid only when [RuntimeType](#RuntimeType) is set to `CLOUD`. The value must be set before the creation of a runtime instance and can be updated only when there are no runtime instances. For example: `default`. Apigee also supports shared VPC (that is, the host network project is not the same as the one that is peering with Apigee). See [Shared VPC overview](https://cloud.google.com/vpc/docs/shared-vpc). To use a shared VPC network, use the following format: `projects/{host-project-id}/{region}/networks/{network-name}`. For example: `projects/my-sharedvpc-host/global/networks/mynetwork` **Note:** Not supported for Apigee hybrid.
  --billing-type: string@billing-type-completer # Billing type of the Apigee organization. See [Apigee pricing](https://cloud.google.com/apigee/pricing).
  --control-plane-encryption-key-name: string # Cloud KMS key name used for encrypting control plane data that is stored in a multi region. Required when [BillingType](#BillingType) is `SUBSCRIPTION`. When [BillingType](#BillingType) is `EVALUATION`, a Google-Managed encryption key will be used. Format: `projects/*/locations/*/keyRings/*/cryptoKeys/*`
  --customer-name: string # Not used by Apigee.
  --description: string # Description of the Apigee organization.
  --display-name: string # Display name for the Apigee organization. Unused, but reserved for future use.
  --portal-disabled: oneof<nothing, bool> # Configuration for the Portals settings.
  --properties: record # Message for compatibility with legacy Edge specification for Java Properties object in JSON. — shape: {property?: list}
  --runtime-database-encryption-key-name: string # Cloud KMS key name used for encrypting the data that is stored and replicated across runtime instances. Update is not allowed after the organization is created. Required when [RuntimeType](#RuntimeType) is `CLOUD`. If not specified when [RuntimeType](#RuntimeType) is `TRIAL`, a Google-Managed encryption key will be used. For example: "projects/foo/locations/us/keyRings/bar/cryptoKeys/baz". **Note:** Not supported for Apigee hybrid.
  --runtime-type: string@runtime-type-completer # Required. Runtime type of the Apigee organization based on the Apigee subscription purchased.
  --type: string@type-completer # Not used by Apigee.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/organizations"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parent, var: parent}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonsConfig, var: addons_config}, {name: analyticsRegion, var: analytics_region}, {name: apiConsumerDataEncryptionKeyName, var: api_consumer_data_encryption_key_name}, {name: apiConsumerDataLocation, var: api_consumer_data_location}, {name: attributes, var: attributes}, {name: authorizedNetwork, var: authorized_network}, {name: billingType, var: billing_type}, {name: controlPlaneEncryptionKeyName, var: control_plane_encryption_key_name}, {name: customerName, var: customer_name}, {name: description, var: description}, {name: displayName, var: display_name}, {name: portalDisabled, var: portal_disabled}, {name: properties, var: properties}, {name: runtimeDatabaseEncryptionKeyName, var: runtime_database_encryption_key_name}, {name: runtimeType, var: runtime_type}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent: $parent, addons_config: $addons_config, analytics_region: $analytics_region, api_consumer_data_encryption_key_name: $api_consumer_data_encryption_key_name, api_consumer_data_location: $api_consumer_data_location, attributes: $attributes, authorized_network: $authorized_network, billing_type: $billing_type, control_plane_encryption_key_name: $control_plane_encryption_key_name, customer_name: $customer_name, description: $description, display_name: $display_name, portal_disabled: $portal_disabled, properties: $properties, runtime_database_encryption_key_name: $runtime_database_encryption_key_name, runtime_type: $runtime_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reports the latest status for a runtime instance.
#
# POST /v1/{instance}:reportStatus
# Returns: record
# operationId: apigee.organizations.instances.reportStatus
export def "apigee-organizations-instances-report-status" [
  instance: string
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
  --instance-uid: string # A unique ID for the instance which is guaranteed to be unique in case the user installs multiple hybrid runtimes with the same instance ID.
  --report-time: string # The time the report was generated in the runtime. Used to prevent an old status from overwriting a newer one. An instance should space out it's status reports so that clock skew does not play a factor. (format: google-datetime)
  --resources: list # Status for config resources — item shape: {resource?: string, revisions?: list, totalReplicas?: int, uid?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{instance}:reportStatus"
    path_params: [{name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: instanceUid, var: instance_uid}, {name: reportTime, var: report_time}, {name: resources, var: resources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, instance_uid: $instance_uid, report_time: $report_time, resources: $resources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a category from the portal.
#
# DELETE /v1/{name}
# Returns: record<errorCode: string, message: string, requestId: string, status: string>
# operationId: apigee.organizations.sites.apicategories.delete
export def "apigee-organizations-sites-apicategories-delete" [
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
  --retention: string@retention-completer # Optional. This setting is applicable only for organizations that are soft-deleted (i.e., BillingType is not EVALUATION). It controls how long Organization data will be retained after the initial delete operation completes. During this period, the Organization may be restored to its last known state. After this period, the Organization will no longer be able to be restored.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: retention, var: retention}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, retention: $retention
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a category on the portal.
#
# GET /v1/{name}
# Returns: record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>
# operationId: apigee.organizations.sites.apicategories.get
export def "apigee-organizations-sites-apicategories-get" [
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
  --format: string@format-completer # Specify `bundle` to export the contents of the shared flow bundle. Otherwise, the bundle metadata is returned.
  --envgroup-hostname: string # Required. Hostname for which the interactive query will be executed.
  --filter: string # Filter that enables you to drill-down on specific dimension values.
  --limit: string # Maximum number of result items to return. The default and maximum value that can be returned is 14400.
  --offset: string # Offset value. Use `offset` with `limit` to enable pagination of results. For example, to display results 11-20, set limit to `10` and offset to `10`.
  --realtime: oneof<nothing, bool> # No longer used by Apigee. Supported for backwards compatibility.
  --select: string # Required. Comma-separated list of metrics. For example: `sum(message_count),sum(error_count)`
  --sort: string # Flag that specifies whether the sort order should be ascending or descending. Valid values include `DESC` and `ASC`.
  --sortby: string # Comma-separated list of columns used to sort the final result.
  --time-range: string # Required. Time interval for the interactive query. Time range is specified in GMT as `start~end`. For example: `04/15/2017 00:00~05/15/2017 23:59`.
  --time-unit: string # Granularity of metrics returned. Valid values include: `second`, `minute`, `hour`, `day`, `week`, or `month`.
  --topk: string # Top number of results to return. For example, to return the top 5 results, set `topk=5`.
  --ts-ascending: oneof<nothing, bool> # Flag that specifies whether to list timestamps in ascending (`true`) or descending (`false`) order. Apigee recommends that you set this value to `true` if you are using `sortby` with `sort=DESC`.
  --tzo: string # Timezone offset value.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: format, var: format}, {name: envgroupHostname, var: envgroup_hostname}, {name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: realtime, var: realtime}, {name: select, var: select}, {name: sort, var: sort}, {name: sortby, var: sortby}, {name: timeRange, var: time_range}, {name: timeUnit, var: time_unit}, {name: topk, var: topk}, {name: tsAscending, var: ts_ascending}, {name: tzo, var: tzo}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, format: $format, envgroup_hostname: $envgroup_hostname, filter: $filter, limit: $limit, offset: $offset, realtime: $realtime, select: $select, sort: $sort, sortby: $sortby, time_range: $time_range, time_unit: $time_unit, topk: $topk, ts_ascending: $ts_ascending, tzo: $tzo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a category on the portal.
#
# PATCH /v1/{name}
# Returns: record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>
# operationId: apigee.organizations.sites.apicategories.patch
export def "apigee-organizations-sites-apicategories-patch" [
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
  --update-mask: string # List of fields to be updated.
  --id: string # ID of the category (a UUID).
  --body-name: string # Name of the category. (spec name: name)
  --site-id: string # Name of the portal.
  --update-time: string # Time the category was last modified in milliseconds since epoch. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: body_name}, {name: siteId, var: site_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, id: $id, body_name: $body_name, site_id: $site_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a shared flow revision. This operation is only allowed on revisions which have never been deployed. After deployment a revision becomes immutable, even if it becomes undeployed. The payload is a ZIP-formatted shared flow. Content type must be either multipart/form-data or application/octet-stream.
#
# POST /v1/{name}
# Returns: record<configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, lastModifiedAt: string, name: string, policies: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, type: string>
# operationId: apigee.organizations.sharedflows.revisions.updateSharedFlowRevision
export def "apigee-organizations-sharedflows-revisions-update-shared-flow-revision" [
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
  --validate: oneof<nothing, bool> # Ignored. All uploads are validated regardless of the value of this field. It is kept for compatibility with existing APIs. Must be `true` or `false` if provided.
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validate, var: validate}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate: $validate, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom report definition
#
# PUT /v1/{name}
# Returns: record<chartType: string, comments: list<string>, createdAt: string, dimensions: list<string>, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: table<function: string, name: string>, name: string, offset: string, organization: string, properties: table<property: string, value: list>, sortByCols: list<string>, sortOrder: string, tags: list<string>, timeUnit: string, toTime: string, topk: string>
# operationId: apigee.organizations.reports.update
export def "apigee-organizations-reports-update" [
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
  --ignore-expiry-validation: oneof<nothing, bool> # Required. Flag that specifies whether to ignore expiry validation. If set to `true`, no expiry validation will be performed.
  --ignore-newline-validation: oneof<nothing, bool> # Flag that specifies whether to ignore newline validation. If set to `true`, no error is thrown when the file contains a certificate chain with no newline between each certificate. Defaults to `false`.
  --chart-type: string # This field contains the chart type for the report
  --comments: list<string> # Legacy field: not used. This field contains a list of comments associated with custom report
  --dimensions: list<string> # This contains the list of dimensions for the report
  --display-name: string # This is the display name for the report
  --filter: string # This field contains the filter expression
  --from-time: string # Legacy field: not used. Contains the from time for the report
  --limit: string # Legacy field: not used This field contains the limit for the result retrieved
  --metrics: list # Required. This contains the list of metrics — item shape: {function?: string, name?: string}
  --body-name: string # Required. Unique identifier for the report T his is a legacy field used to encode custom report unique id (spec name: name)
  --offset: string # Legacy field: not used. This field contains the offset for the data
  --properties: list # This field contains report properties such as ui metadata etc. — item shape: {property?: string, value?: list}
  --sort-by-cols: list<string> # Legacy field: not used much. Contains the list of sort by columns
  --sort-order: string # Legacy field: not used much. Contains the sort order for the sort columns
  --tags: list<string> # Legacy field: not used. This field contains a list of tags associated with custom report
  --time-unit: string # This field contains the time unit of aggregation for the report
  --to-time: string # Legacy field: not used. Contains the end time for the report
  --topk: string # Legacy field: not used. This field contains the top k parameter value for restricting the result
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: ignoreExpiryValidation, var: ignore_expiry_validation}, {name: ignoreNewlineValidation, var: ignore_newline_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: chartType, var: chart_type}, {name: comments, var: comments}, {name: dimensions, var: dimensions}, {name: displayName, var: display_name}, {name: filter, var: filter}, {name: fromTime, var: from_time}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: name, var: body_name}, {name: offset, var: offset}, {name: properties, var: properties}, {name: sortByCols, var: sort_by_cols}, {name: sortOrder, var: sort_order}, {name: tags, var: tags}, {name: timeUnit, var: time_unit}, {name: toTime, var: to_time}, {name: topk, var: topk}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, ignore_expiry_validation: $ignore_expiry_validation, ignore_newline_validation: $ignore_newline_validation, chart_type: $chart_type, comments: $comments, dimensions: $dimensions, display_name: $display_name, filter: $filter, from_time: $from_time, limit: $limit, metrics: $metrics, body_name: $body_name, offset: $offset, properties: $properties, sort_by_cols: $sort_by_cols, sort_order: $sort_order, tags: $tags, time_unit: $time_unit, to_time: $to_time, topk: $topk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates attributes for a developer app. This API replaces the current attributes with those specified in the request.
#
# POST /v1/{name}/attributes
# Returns: record<attribute: table<name: string, value: string>>
# operationId: apigee.organizations.developers.apps.attributes
export def "apigee-organizations-developers-apps-attributes" [
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
  --attribute: list # List of attributes. — item shape: {name?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}/attributes"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribute: $attribute
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the certificate from an alias in PEM-encoded form.
#
# GET /v1/{name}/certificate
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: apigee.organizations.environments.keystores.aliases.getCertificate
export def "apigee-organizations-environments-keystores-aliases-get-certificate" [
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
    path: "/v1/{name}/certificate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a PKCS #10 Certificate Signing Request for the private key in an alias.
#
# GET /v1/{name}/csr
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: apigee.organizations.environments.keystores.aliases.csr
export def "apigee-organizations-environments-keystores-aliases-csr" [
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
    path: "/v1/{name}/csr"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the data from a debug session. This does not cancel the debug session or prevent further data from being collected if the session is still active in runtime pods.
#
# DELETE /v1/{name}/data
# Returns: record
# operationId: apigee.organizations.environments.apis.revisions.debugsessions.deleteData
export def "apigee-organizations-environments-apis-revisions-debugsessions-delete-data" [
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
    path: "/v1/{name}/data"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undeploys a shared flow revision from an environment. For a request path `organizations/{org}/environments/{env}/sharedflows/{sf}/revisions/{rev}/deployments`, two permissions are required: * `apigee.deployments.delete` on the resource `organizations/{org}/environments/{env}` * `apigee.sharedflowrevisions.undeploy` on the resource `organizations/{org}/sharedflows/{sf}/revisions/{rev}`
#
# DELETE /v1/{name}/deployments
# Returns: record
# operationId: apigee.organizations.environments.sharedflows.revisions.undeploy
export def "apigee-organizations-environments-sharedflows-revisions-undeploy" [
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
  --sequenced-rollout: oneof<nothing, bool> # Flag that specifies whether to enable sequenced rollout. If set to `true`, the environment group routing rules corresponding to this deployment will be removed before removing the deployment from the runtime. This is likely to be a rare use case; it is only needed when the intended effect of undeploying this proxy is to cause the traffic it currently handles to be rerouted to some other existing proxy in the environment group. The [GenerateUndeployChangeReport API](GenerateUndeployChangeReport) may be used to examine routing changes before issuing the undeployment request, and its response will indicate if a sequenced rollout is recommended for the undeployment.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{name}/deployments"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: sequencedRollout, var: sequenced_rollout}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, sequenced_rollout: $sequenced_rollout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the deployment of a shared flow revision and actual state reported by runtime pods.
#
# GET /v1/{name}/deployments
# Returns: record<apiProxy: string, deployStartTime: string, environment: string, errors: table<code: int, details: list, message: string>, instances: table<deployedRevisions: list, deployedRoutes: list, instance: string>, pods: table<appVersion: string, deploymentStatus: string, deploymentStatusTime: string, deploymentTime: string, podName: string, podStatus: string, podStatusTime: string, statusCode: string, statusCodeDetails: string>, revision: string, routeConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, serviceAccount: string, state: string>
# operationId: apigee.organizations.environments.sharedflows.revisions.getDeployments
export def "apigee-organizations-environments-sharedflows-revisions-get-deployments" [
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
    path: "/v1/{name}/deployments"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploys a revision of a shared flow. If another revision of the same shared flow is currently deployed, set the `override` parameter to `true` to have this revision replace the currently deployed revision. You cannot use a shared flow until it has been deployed to an environment. For a request path `organizations/{org}/environments/{env}/sharedflows/{sf}/revisions/{rev}/deployments`, two permissions are required: * `apigee.deployments.create` on the resource `organizations/{org}/environments/{env}` * `apigee.sharedflowrevisions.deploy` on the resource `organizations/{org}/sharedflows/{sf}/revisions/{rev}`
#
# POST /v1/{name}/deployments
# Returns: record<apiProxy: string, deployStartTime: string, environment: string, errors: table<code: int, details: list, message: string>, instances: table<deployedRevisions: list, deployedRoutes: list, instance: string>, pods: table<appVersion: string, deploymentStatus: string, deploymentStatusTime: string, deploymentTime: string, podName: string, podStatus: string, podStatusTime: string, statusCode: string, statusCodeDetails: string>, revision: string, routeConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, serviceAccount: string, state: string>
# operationId: apigee.organizations.environments.sharedflows.revisions.deploy
export def "apigee-organizations-environments-sharedflows-revisions-deploy" [
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
  --override: oneof<nothing, bool> # Flag that specifies whether the new deployment replaces other deployed revisions of the shared flow in the environment. Set `override` to `true` to replace other deployed revisions. By default, `override` is `false` and the deployment is rejected if other revisions of the shared flow are deployed in the environment.
  --service-account: string # Google Cloud IAM service account. The service account represents the identity of the deployed proxy, and determines what permissions it has. The format must be `{ACCOUNT_ID}@{PROJECT}.iam.gserviceaccount.com`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/{name}/deployments"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: override, var: override}, {name: serviceAccount, var: service_account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, override: $override, service_account: $service_account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a report for a dry run analysis of a DeployApiProxy request without committing the deployment. In addition to the standard validations performed when adding deployments, additional analysis will be done to detect possible traffic routing changes that would result from this deployment being created. Any potential routing conflicts or unsafe changes will be reported in the response. This routing analysis is not performed for a non-dry-run DeployApiProxy request. For a request path `organizations/{org}/environments/{env}/apis/{api}/revisions/{rev}/deployments:generateDeployChangeReport`, two permissions are required: * `apigee.deployments.create` on the resource `organizations/{org}/environments/{env}` * `apigee.proxyrevisions.deploy` on the resource `organizations/{org}/apis/{api}/revisions/{rev}`
#
# POST /v1/{name}/deployments:generateDeployChangeReport
# Returns: record<routingChanges: table<description: string, environmentGroup: string, fromDeployment: record, shouldSequenceRollout: bool, toDeployment: record>, routingConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, validationErrors: record<violations: list<record>>>
# operationId: apigee.organizations.environments.apis.revisions.deployments.generateDeployChangeReport
export def "apigee-organizations-environments-apis-revisions-deployments-generate-deploy-change-report" [
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
  --override: oneof<nothing, bool> # Flag that specifies whether to force the deployment of the new revision over the currently deployed revision by overriding conflict checks.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v1/{name}/deployments:generateDeployChangeReport"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: override, var: override}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, override: $override
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a report for a dry run analysis of an UndeployApiProxy request without committing the undeploy. In addition to the standard validations performed when removing deployments, additional analysis will be done to detect possible traffic routing changes that would result from this deployment being removed. Any potential routing conflicts or unsafe changes will be reported in the response. This routing analysis is not performed for a non-dry-run UndeployApiProxy request. For a request path `organizations/{org}/environments/{env}/apis/{api}/revisions/{rev}/deployments:generateUndeployChangeReport`, two permissions are required: * `apigee.deployments.delete` on the resource `organizations/{org}/environments/{env}` * `apigee.proxyrevisions.undeploy` on the resource `organizations/{org}/apis/{api}/revisions/{rev}`
#
# POST /v1/{name}/deployments:generateUndeployChangeReport
# Returns: record<routingChanges: table<description: string, environmentGroup: string, fromDeployment: record, shouldSequenceRollout: bool, toDeployment: record>, routingConflicts: table<conflictingDeployment: record, description: string, environmentGroup: string>, validationErrors: record<violations: list<record>>>
# operationId: apigee.organizations.environments.apis.revisions.deployments.generateUndeployChangeReport
export def "apigee-organizations-environments-apis-revisions-deployments-generate-undeploy-change-report" [
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
    path: "/v1/{name}/deployments:generateUndeployChangeReport"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1/{name}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: apigee.organizations.operations.list
export def "apigee-organizations-operations-list" [
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
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}/operations"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activates the NAT address. The Apigee instance can now use this for Internet egress traffic. **Note:** Not supported for Apigee hybrid.
#
# POST /v1/{name}:activate
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.instances.natAddresses.activate
export def "apigee-organizations-instances-nat-addresses-activate" [
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
    path: "/v1/{name}:activate"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adjust the prepaid balance for the developer. This API will be used in scenarios where the developer has been under-charged or over-charged.
#
# POST /v1/{name}:adjust
# Returns: record<wallets: table<balance: record, lastCreditTime: string>>
# operationId: apigee.organizations.developers.balance.adjust
export def "apigee-organizations-developers-balance-adjust" [
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
  --adjustment: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:adjust"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adjustment, var: adjustment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, adjustment: $adjustment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Credits the account balance for the developer.
#
# POST /v1/{name}:credit
# Returns: record<wallets: table<balance: record, lastCreditTime: string>>
# operationId: apigee.organizations.developers.balance.credit
export def "apigee-organizations-developers-balance-credit" [
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
  --transaction-amount: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
  --transaction-id: string # Each transaction_id uniquely identifies a credit balance request. If multiple requests are received with the same transaction_id, only one of them will be considered.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:credit"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: transactionAmount, var: transaction_amount}, {name: transactionId, var: transaction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, transaction_amount: $transaction_amount, transaction_id: $transaction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expires an API product subscription immediately.
#
# POST /v1/{name}:expire
# Returns: record<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>
# operationId: apigee.organizations.developers.subscriptions.expire
export def "apigee-organizations-developers-subscriptions-expire" [
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
    path: "/v1/{name}:expire"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a signed URL for downloading the original zip file used to create an Archive Deployment. The URL is only valid for a limited period and should be used within minutes after generation. Each call returns a new upload URL.
#
# POST /v1/{name}:generateDownloadUrl
# Returns: record<downloadUri: string>
# operationId: apigee.organizations.environments.archiveDeployments.generateDownloadUrl
export def "apigee-organizations-environments-archive-deployments-generate-download-url" [
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
    path: "/v1/{name}:generateDownloadUrl"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the project ID and region for an Apigee organization.
#
# GET /v1/{name}:getProjectMapping
# Returns: record<location: string, organization: string, projectId: string, projectIds: list<string>>
# operationId: apigee.organizations.getProjectMapping
export def "apigee-organizations-get-project-mapping" [
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
    path: "/v1/{name}:getProjectMapping"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the service accounts with the permissions required to allow the Synchronizer to download environment data from the control plane. An ETag is returned in the response to `getSyncAuthorization`. Pass that ETag when calling [setSyncAuthorization](setSyncAuthorization) to ensure that you are updating the correct version. If you don't pass the ETag in the call to `setSyncAuthorization`, then the existing authorization is overwritten indiscriminately. For more information, see [Configure the Synchronizer](https://cloud.google.com/apigee/docs/hybrid/latest/synchronizer-access). **Note**: Available to Apigee hybrid only.
#
# POST /v1/{name}:getSyncAuthorization
# Returns: record<etag: string, identities: list<string>>
# operationId: apigee.organizations.getSyncAuthorization
export def "apigee-organizations-get-sync-authorization" [
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
    path: "/v1/{name}:getSyncAuthorization"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSecurityProfileRevisions lists all the revisions of the security profile.
#
# GET /v1/{name}:listRevisions
# Returns: record<nextPageToken: string, securityProfiles: table<displayName: string, environments: list, maxScore: int, minScore: int, name: string, revisionCreateTime: string, revisionId: string, revisionPublishTime: string, revisionUpdateTime: string, scoringConfigs: list>>
# operationId: apigee.organizations.securityProfiles.listRevisions
export def "apigee-organizations-security-profiles-list-revisions" [
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
  --page-size: int # The maximum number of profile revisions to return. The service may return fewer than this value. If unspecified, at most 50 revisions will be returned.
  --page-token: string # A page token, received from a previous `ListSecurityProfileRevisions` call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}:listRevisions"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the permissions required to allow the Synchronizer to download environment data from the control plane. You must call this API to enable proper functioning of hybrid. Pass the ETag when calling `setSyncAuthorization` to ensure that you are updating the correct version. To get an ETag, call [getSyncAuthorization](getSyncAuthorization). If you don't pass the ETag in the call to `setSyncAuthorization`, then the existing authorization is overwritten indiscriminately. For more information, see [Configure the Synchronizer](https://cloud.google.com/apigee/docs/hybrid/latest/synchronizer-access). **Note**: Available to Apigee hybrid only.
#
# POST /v1/{name}:setSyncAuthorization
# Returns: record<etag: string, identities: list<string>>
# operationId: apigee.organizations.setSyncAuthorization
export def "apigee-organizations-set-sync-authorization" [
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
  --etag: string # Entity tag (ETag) used for optimistic concurrency control as a way to help prevent simultaneous updates from overwriting each other. For example, when you call [getSyncAuthorization](organizations/getSyncAuthorization) an ETag is returned in the response. Pass that ETag when calling the [setSyncAuthorization](organizations/setSyncAuthorization) to ensure that you are updating the correct version. If you don't pass the ETag in the call to `setSyncAuthorization`, then the existing authorization is overwritten indiscriminately. **Note**: We strongly recommend that you use the ETag in the read-modify-write cycle to avoid race conditions. (format: byte)
  --identities: list<string> # Required. Array of service accounts to grant access to control plane resources, each specified using the following format: `serviceAccount:` service-account-name. The service-account-name is formatted like an email address. For example: `my-synchronizer-manager-service_account@my_project_id.iam.gserviceaccount.com` You might specify multiple service accounts, for example, if you have multiple environments and wish to assign a unique service account to each one. The service accounts must have **Apigee Synchronizer Manager** role. See also [Create service accounts](https://cloud.google.com/apigee/docs/hybrid/latest/sa-about#create-the-service-accounts).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{name}:setSyncAuthorization"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: identities, var: identities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, identities: $identities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve security statistics as tabular rows.
#
# POST /v1/{orgenv}/securityStats:queryTabularStats
# Returns: record<columns: list<string>, nextPageToken: string, values: list<list<any>>>
# operationId: apigee.organizations.environments.securityStats.queryTabularStats
export def "apigee-organizations-environments-security-stats-query-tabular-stats" [
  orgenv: string
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
  --dimensions: list<string> # Required. List of dimension names to group the aggregations by.
  --filter: string # Filter further on specific dimension values. Follows the same grammar as custom report's filter expressions. Example, apiproxy eq 'foobar'. https://cloud.google.com/apigee/docs/api-platform/analytics/analytics-reference#filters
  --metrics: list # Required. List of metrics and their aggregations. — item shape: {aggregation?: "AGGREGATION_FUNCTION_UNSPECIFIED"|"AVG"|"SUM"|"MIN"|"MAX"|"COUNT_DISTINCT", name?: string, order?: "ORDER_UNSPECIFIED"|"ASCENDING"|"DESCENDING"}
  --page-size: int # Page size represents the number of rows. (format: int32)
  --page-token: string # Identifies a sequence of rows.
  --time-range: record # Represents a time interval, encoded as a Timestamp start (inclusive) and a Timestamp end (exclusive). The start must be less than or equal to the end. When the start equals the end, the interval is empty (matches no time). When both start and end are unspecified, the interval matches any time. — shape: {endTime?: string, startTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{orgenv}/securityStats:queryTabularStats"
    path_params: [{name: orgenv, var: orgenv}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dimensions, var: dimensions}, {name: filter, var: filter}, {name: metrics, var: metrics}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgenv: $orgenv, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dimensions: $dimensions, filter: $filter, metrics: $metrics, page_size: $page_size, page_token: $page_token, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve security statistics as a collection of time series.
#
# POST /v1/{orgenv}/securityStats:queryTimeSeriesStats
# Returns: record<columns: list<string>, nextPageToken: string, values: table<dimensions: record, points: list>>
# operationId: apigee.organizations.environments.securityStats.queryTimeSeriesStats
export def "apigee-organizations-environments-security-stats-query-time-series-stats" [
  orgenv: string
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
  --dimensions: list<string> # List of dimension names to group the aggregations by. If no dimensions are passed, a single trend line representing the requested metric aggregations grouped by environment is returned.
  --filter: string # Filter further on specific dimension values. Follows the same grammar as custom report's filter expressions. Example, apiproxy eq 'foobar'. https://cloud.google.com/apigee/docs/api-platform/analytics/analytics-reference#filters
  --metrics: list # Required. List of metrics and their aggregations. — item shape: {aggregation?: "AGGREGATION_FUNCTION_UNSPECIFIED"|"AVG"|"SUM"|"MIN"|"MAX"|"COUNT_DISTINCT", name?: string, order?: "ORDER_UNSPECIFIED"|"ASCENDING"|"DESCENDING"}
  --page-size: int # Page size represents the number of time series sequences, one per unique set of dimensions and their values. (format: int32)
  --page-token: string # Page token stands for a specific collection of time series sequences.
  --time-range: record # Represents a time interval, encoded as a Timestamp start (inclusive) and a Timestamp end (exclusive). The start must be less than or equal to the end. When the start equals the end, the interval is empty (matches no time). When both start and end are unspecified, the interval matches any time. — shape: {endTime?: string, startTime?: string}
  --timestamp-order: string@timestamp-order-completer # Order the sequences in increasing or decreasing order of timestamps. Default is descending order of timestamps (latest first).
  --window-size: string@window-size-completer # Time buckets to group the stats by.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{orgenv}/securityStats:queryTimeSeriesStats"
    path_params: [{name: orgenv, var: orgenv}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: dimensions, var: dimensions}, {name: filter, var: filter}, {name: metrics, var: metrics}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: timeRange, var: time_range}, {name: timestampOrder, var: timestamp_order}, {name: windowSize, var: window_size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    orgenv: $orgenv, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dimensions: $dimensions, filter: $filter, metrics: $metrics, page_size: $page_size, page_token: $page_token, time_range: $time_range, timestamp_order: $timestamp_order, window_size: $window_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures the add-ons for the Apigee organization. The existing add-on configuration will be fully replaced.
#
# POST /v1/{org}:setAddons
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.setAddons
export def "apigee-organizations-set-addons" [
  org: string
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
  --addons-config: record # Add-on configurations for the Apigee organization. — shape: {advancedApiOpsConfig?: record, apiSecurityConfig?: record, connectorsPlatformConfig?: record, integrationConfig?: record, monetizationConfig?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{org}:setAddons"
    path_params: [{name: org, var: org}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonsConfig, var: addons_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    org: $org, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addons_config: $addons_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Apigee organizations and associated Google Cloud projects that you have permission to access. See [Understanding organizations](https://cloud.google.com/apigee/docs/api-platform/fundamentals/organization-structure).
#
# GET /v1/{parent}
# Returns: record<organizations: table<location: string, organization: string, projectId: string, projectIds: list>>
# operationId: apigee.organizations.list
export def "apigee-organizations-list" [
  parent: string
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
    path: "/v1/{parent}"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an alias from a key/certificate pair. The structure of the request is controlled by the `format` query parameter: - `keycertfile` - Separate PEM-encoded key and certificate files are uploaded. Set `Content-Type: multipart/form-data` and include the `keyFile`, `certFile`, and `password` (if keys are encrypted) fields in the request body. If uploading to a truststore, omit `keyFile`. - `pkcs12` - A PKCS12 file is uploaded. Set `Content-Type: multipart/form-data`, provide the file in the `file` field, and include the `password` field if the file is encrypted in the request body. - `selfsignedcert` - A new private key and certificate are generated. Set `Content-Type: application/json` and include CertificateGenerationSpec in the request body.
#
# POST /v1/{parent}/aliases
# Returns: record<alias: string, certsInfo: record<certInfo: list<record>>, type: string>
# operationId: apigee.organizations.environments.keystores.aliases.create
export def "apigee-organizations-environments-keystores-aliases-create" [
  parent: string
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
  --password: string # DEPRECATED: For improved security, specify the password in the request body instead of using the query parameter. To specify the password in the request body, set `Content-type: multipart/form-data` part with name `password`. Password for the private key file, if required.
  --alias: string # Alias for the key/certificate pair. Values must match the regular expression `[\w\s-.]{1,255}`. This must be provided for all formats except `selfsignedcert`; self-signed certs may specify the alias in either this parameter or the JSON body.
  --format: string # Required. Format of the data. Valid values include: `selfsignedcert`, `keycertfile`, or `pkcs12`
  --ignore-expiry-validation: oneof<nothing, bool> # Flag that specifies whether to ignore expiry validation. If set to `true`, no expiry validation will be performed.
  --ignore-newline-validation: oneof<nothing, bool> # Flag that specifies whether to ignore newline validation. If set to `true`, no error is thrown when the file contains a certificate chain with no newline between each certificate. Defaults to `false`.
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/aliases"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: _password, var: password}, {name: alias, var: alias}, {name: format, var: format}, {name: ignoreExpiryValidation, var: ignore_expiry_validation}, {name: ignoreNewlineValidation, var: ignore_newline_validation}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, password: $password, alias: $alias, format: $format, ignore_expiry_validation: $ignore_expiry_validation, ignore_newline_validation: $ignore_newline_validation, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Datastores
#
# GET /v1/{parent}/analytics/datastores
# Returns: record<datastores: table<createTime: string, datastoreConfig: record, displayName: string, lastUpdateTime: string, org: string, self: string, targetType: string>>
# operationId: apigee.organizations.analytics.datastores.list
export def "apigee-organizations-analytics-datastores-list" [
  parent: string
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
  --target-type: string # Optional. TargetType is used to fetch all Datastores that match the type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/analytics/datastores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: targetType, var: target_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Datastore for an org
#
# POST /v1/{parent}/analytics/datastores
# Returns: record<createTime: string, datastoreConfig: record<bucketName: string, datasetName: string, path: string, projectId: string, tablePrefix: string>, displayName: string, lastUpdateTime: string, org: string, self: string, targetType: string>
# operationId: apigee.organizations.analytics.datastores.create
export def "apigee-organizations-analytics-datastores-create" [
  parent: string
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
  --datastore-config: record # Configuration detail for datastore — shape: {bucketName?: string, datasetName?: string, path?: string, projectId?: string, tablePrefix?: string}
  --display-name: string # Required. Display name in UI
  --target-type: string # Destination storage type. Supported types `gcs` or `bigquery`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/analytics/datastores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: datastoreConfig, var: datastore_config}, {name: displayName, var: display_name}, {name: targetType, var: target_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, datastore_config: $datastore_config, display_name: $display_name, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test if Datastore configuration is correct. This includes checking if credentials provided by customer have required permissions in target destination storage
#
# POST /v1/{parent}/analytics/datastores:test
# Returns: record<error: string, state: string>
# operationId: apigee.organizations.analytics.datastores.test
export def "apigee-organizations-analytics-datastores-test" [
  parent: string
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
  --datastore-config: record # Configuration detail for datastore — shape: {bucketName?: string, datasetName?: string, path?: string, projectId?: string, tablePrefix?: string}
  --display-name: string # Required. Display name in UI
  --target-type: string # Destination storage type. Supported types `gcs` or `bigquery`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/analytics/datastores:test"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: datastoreConfig, var: datastore_config}, {name: displayName, var: display_name}, {name: targetType, var: target_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, datastore_config: $datastore_config, display_name: $display_name, target_type: $target_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the details and status of all analytics export jobs belonging to the parent organization and environment.
#
# GET /v1/{parent}/analytics/exports
# Returns: record<exports: table<created: string, datastoreName: string, description: string, error: string, executionTime: string, name: string, self: string, state: string, updated: string>>
# operationId: apigee.organizations.environments.analytics.exports.list
export def "apigee-organizations-environments-analytics-exports-list" [
  parent: string
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
    path: "/v1/{parent}/analytics/exports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a data export job to be processed in the background. If the request is successful, the API returns a 201 status, a URI that can be used to retrieve the status of the export job, and the `state` value of "enqueued".
#
# POST /v1/{parent}/analytics/exports
# Returns: record<created: string, datastoreName: string, description: string, error: string, executionTime: string, name: string, self: string, state: string, updated: string>
# operationId: apigee.organizations.environments.analytics.exports.create
export def "apigee-organizations-environments-analytics-exports-create" [
  parent: string
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
  --csv-delimiter: string # Optional. Delimiter used in the CSV file, if `outputFormat` is set to `csv`. Defaults to the `,` (comma) character. Supported delimiter characters include comma (`,`), pipe (`|`), and tab (`\t`).
  --datastore-name: string # Required. Name of the preconfigured datastore.
  --date-range: record # Date range of the data to export. — shape: {end?: string, start?: string}
  --description: string # Optional. Description of the export job.
  --name: string # Required. Display name of the export job.
  --output-format: string # Optional. Output format of the export. Valid values include: `csv` or `json`. Defaults to `json`. Note: Configure the delimiter for CSV output using the `csvDelimiter` property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/analytics/exports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: csvDelimiter, var: csv_delimiter}, {name: datastoreName, var: datastore_name}, {name: dateRange, var: date_range}, {name: description, var: description}, {name: name, var: name}, {name: outputFormat, var: output_format}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, csv_delimiter: $csv_delimiter, datastore_name: $datastore_name, date_range: $date_range, description: $description, name: $name, output_format: $output_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the categories on the portal.
#
# GET /v1/{parent}/apicategories
# Returns: record<data: table<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>
# operationId: apigee.organizations.sites.apicategories.list
export def "apigee-organizations-sites-apicategories-list" [
  parent: string
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
    path: "/v1/{parent}/apicategories"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new category on the portal.
#
# POST /v1/{parent}/apicategories
# Returns: record<data: record<id: string, name: string, siteId: string, updateTime: string>, errorCode: string, message: string, requestId: string, status: string>
# operationId: apigee.organizations.sites.apicategories.create
export def "apigee-organizations-sites-apicategories-create" [
  parent: string
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
  --id: string # ID of the category (a UUID).
  --name: string # Name of the category.
  --site-id: string # Name of the portal.
  --update-time: string # Time the category was last modified in milliseconds since epoch. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/apicategories"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: siteId, var: site_id}, {name: updateTime, var: update_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, id: $id, name: $name, site_id: $site_id, update_time: $update_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all API product names for an organization. Filter the list by passing an `attributename` and `attibutevalue`. The maximum number of API products returned is 1000. You can paginate the list of API products returned using the `startKey` and `count` query parameters.
#
# GET /v1/{parent}/apiproducts
# Returns: record<apiProduct: table<apiResources: list, approvalType: string, attributes: list, createdAt: string, description: string, displayName: string, environments: list, graphqlOperationGroup: record, lastModifiedAt: string, name: string, operationGroup: record, proxies: list, quota: string, quotaCounterScope: string, quotaInterval: string, quotaTimeUnit: string, scopes: list>>
# operationId: apigee.organizations.apiproducts.list
export def "apigee-organizations-apiproducts-list" [
  parent: string
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
  --attributename: string # Name of the attribute used to filter the search.
  --attributevalue: string # Value of the attribute used to filter the search.
  --count: string # Enter the number of API products you want returned in the API call. The limit is 1000.
  --expand: oneof<nothing, bool> # Flag that specifies whether to expand the results. Set to `true` to get expanded details about each API.
  --start-key: string # Gets a list of API products starting with a specific API product in the list. For example, if you're returning 50 API products at a time (using the `count` query parameter), you can view products 50-99 by entering the name of the 50th API product in the first API (without using `startKey`). Product name is case sensitive.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/apiproducts"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: attributename, var: attributename}, {name: attributevalue, var: attributevalue}, {name: count, var: count}, {name: expand, var: expand}, {name: startKey, var: start_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attributename: $attributename, attributevalue: $attributevalue, count: $count, expand: $expand, start_key: $start_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an API product in an organization. You create API products after you have proxied backend services using API proxies. An API product is a collection of API resources combined with quota settings and metadata that you can use to deliver customized and productized API bundles to your developer community. This metadata can include: - Scope - Environments - API proxies - Extensible profile API products enable you repackage APIs on the fly, without having to do any additional coding or configuration. Apigee recommends that you start with a simple API product including only required elements. You then provision credentials to apps to enable them to start testing your APIs. After you have authentication and authorization working against a simple API product, you can iterate to create finer-grained API products, defining different sets of API resources for each API product. **WARNING:** - If you don't specify an API proxy in the request body, *any* app associated with the product can make calls to *any* API in your entire organization. - If you don't specify an environment in the request body, the product allows access to all environments. For more information, see What is an API product?
#
# POST /v1/{parent}/apiproducts
# Returns: record<apiResources: list<string>, approvalType: string, attributes: table<name: string, value: string>, createdAt: string, description: string, displayName: string, environments: list<string>, graphqlOperationGroup: record<operationConfigType: string, operationConfigs: list<record>>, lastModifiedAt: string, name: string, operationGroup: record<operationConfigType: string, operationConfigs: list<record>>, proxies: list<string>, quota: string, quotaCounterScope: string, quotaInterval: string, quotaTimeUnit: string, scopes: list<string>>
# operationId: apigee.organizations.apiproducts.create
export def "apigee-organizations-apiproducts-create" [
  parent: string
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
  --api-resources: list<string> # Comma-separated list of API resources to be bundled in the API product. By default, the resource paths are mapped from the `proxy.pathsuffix` variable. The proxy path suffix is defined as the URI fragment following the ProxyEndpoint base path. For example, if the `apiResources` element is defined to be `/forecastrss` and the base path defined for the API proxy is `/weather`, then only requests to `/weather/forecastrss` are permitted by the API product. You can select a specific path, or you can select all subpaths with the following wildcard: - `/**`: Indicates that all sub-URIs are included. - `/*` : Indicates that only URIs one level down are included. By default, / supports the same resources as /** as well as the base path defined by the API proxy. For example, if the base path of the API proxy is `/v1/weatherapikey`, then the API product supports requests to `/v1/weatherapikey` and to any sub-URIs, such as `/v1/weatherapikey/forecastrss`, `/v1/weatherapikey/region/CA`, and so on. For more information, see Managing API products.
  --approval-type: string # Flag that specifies how API keys are approved to access the APIs defined by the API product. If set to `manual`, the consumer key is generated and returned in "pending" state. In this case, the API keys won't work until they have been explicitly approved. If set to `auto`, the consumer key is generated and returned in "approved" state and can be used immediately. **Note:** Typically, `auto` is used to provide access to free or trial API products that provide limited quota or capabilities.
  --attributes: list # Array of attributes that may be used to extend the default API product profile with customer-specific metadata. You can specify a maximum of 18 attributes. Use this property to specify the access level of the API product as either `public`, `private`, or `internal`. Only products marked `public` are available to developers in the Apigee developer portal. For example, you can set a product to `internal` while it is in development and then change access to `public` when it is ready to release on the portal. API products marked as `private` do not appear on the portal, but can be accessed by external developers. — item shape: {name?: string, value?: string}
  --created-at: string # Response only. Creation time of this environment as milliseconds since epoch. (format: int64)
  --description: string # Description of the API product. Include key information about the API product that is not captured by other fields.
  --display-name: string # Name displayed in the UI or developer portal to developers registering for API access.
  --environments: list<string> # Comma-separated list of environment names to which the API product is bound. Requests to environments that are not listed are rejected. By specifying one or more environments, you can bind the resources listed in the API product to a specific environment, preventing developers from accessing those resources through API proxies deployed in another environment. This setting is used, for example, to prevent resources associated with API proxies in `prod` from being accessed by API proxies deployed in `test`.
  --graphql-operation-group: record # List of graphQL operation configuration details associated with Apigee API proxies or remote services. Remote services are non-Apigee proxies, such as Istio-Envoy. — shape: {operationConfigType?: string, operationConfigs?: list}
  --last-modified-at: string # Response only. Modified time of this environment as milliseconds since epoch. (format: int64)
  --name: string # Internal name of the API product. Characters you can use in the name are restricted to: `A-Z0-9._\-$ %`. **Note:** The internal name cannot be edited when updating the API product.
  --operation-group: record # List of operation configuration details associated with Apigee API proxies or remote services. Remote services are non-Apigee proxies, such as Istio-Envoy. — shape: {operationConfigType?: string, operationConfigs?: list}
  --proxies: list<string> # Comma-separated list of API proxy names to which this API product is bound. By specifying API proxies, you can associate resources in the API product with specific API proxies, preventing developers from accessing those resources through other API proxies. Apigee rejects requests to API proxies that are not listed. **Note:** The API proxy names must already exist in the specified environment as they will be validated upon creation.
  --quota: string # Number of request messages permitted per app by this API product for the specified `quotaInterval` and `quotaTimeUnit`. For example, a `quota` of 50, for a `quotaInterval` of 12 and a `quotaTimeUnit` of hours means 50 requests are allowed every 12 hours.
  --quota-counter-scope: string@quota-counter-scope-completer # Scope of the quota decides how the quota counter gets applied and evaluate for quota violation. If the Scope is set as PROXY, then all the operations defined for the APIproduct that are associated with the same proxy will share the same quota counter set at the APIproduct level, making it a global counter at a proxy level. If the Scope is set as OPERATION, then each operations get the counter set at the API product dedicated, making it a local counter. Note that, the QuotaCounterScope applies only when an operation does not have dedicated quota set for itself.
  --quota-interval: string # Time interval over which the number of request messages is calculated.
  --quota-time-unit: string # Time unit defined for the `quotaInterval`. Valid values include `minute`, `hour`, `day`, or `month`.
  --scopes: list<string> # Comma-separated list of OAuth scopes that are validated at runtime. Apigee validates that the scopes in any access token presented match the scopes defined in the OAuth policy associated with the API product.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/apiproducts"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiResources, var: api_resources}, {name: approvalType, var: approval_type}, {name: attributes, var: attributes}, {name: createdAt, var: created_at}, {name: description, var: description}, {name: displayName, var: display_name}, {name: environments, var: environments}, {name: graphqlOperationGroup, var: graphql_operation_group}, {name: lastModifiedAt, var: last_modified_at}, {name: name, var: name}, {name: operationGroup, var: operation_group}, {name: proxies, var: proxies}, {name: quota, var: quota}, {name: quotaCounterScope, var: quota_counter_scope}, {name: quotaInterval, var: quota_interval}, {name: quotaTimeUnit, var: quota_time_unit}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_resources: $api_resources, approval_type: $approval_type, attributes: $attributes, created_at: $created_at, description: $description, display_name: $display_name, environments: $environments, graphql_operation_group: $graphql_operation_group, last_modified_at: $last_modified_at, name: $name, operation_group: $operation_group, proxies: $proxies, quota: $quota, quota_counter_scope: $quota_counter_scope, quota_interval: $quota_interval, quota_time_unit: $quota_time_unit, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the names of all API proxies in an organization. The names returned correspond to the names defined in the configuration files for each API proxy.
#
# GET /v1/{parent}/apis
# Returns: record<proxies: table<apiProxyType: string, labels: record, latestRevisionId: string, metaData: record, name: string, readOnly: bool, revision: list>>
# operationId: apigee.organizations.apis.list
export def "apigee-organizations-apis-list" [
  parent: string
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
  --include-meta-data: oneof<nothing, bool> # Flag that specifies whether to include API proxy metadata in the response.
  --include-revisions: oneof<nothing, bool> # Flag that specifies whether to include a list of revisions in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/apis"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeMetaData, var: include_meta_data}, {name: includeRevisions, var: include_revisions}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_meta_data: $include_meta_data, include_revisions: $include_revisions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an API proxy. The API proxy created will not be accessible at runtime until it is deployed to an environment. Create a new API proxy by setting the `name` query parameter to the name of the API proxy. Import an API proxy configuration bundle stored in zip format on your local machine to your organization by doing the following: * Set the `name` query parameter to the name of the API proxy. * Set the `action` query parameter to `import`. * Set the `Content-Type` header to `multipart/form-data`. * Pass as a file the name of API proxy configuration bundle stored in zip format on your local machine using the `file` form field. **Note**: To validate the API proxy configuration bundle only without importing it, set the `action` query parameter to `validate`. When importing an API proxy configuration bundle, if the API proxy does not exist, it will be created. If the API proxy exists, then a new revision is created. Invalid API proxy configurations are rejected, and a list of validation errors is returned to the client.
#
# POST /v1/{parent}/apis
# Returns: record<archive: string, basepaths: list<string>, configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, integrationEndpoints: list<string>, lastModifiedAt: string, name: string, policies: list<string>, proxies: list<string>, proxyEndpoints: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, spec: string, targetEndpoints: list<string>, targetServers: list<string>, targets: list<string>, teams: list<string>, type: string>
# operationId: apigee.organizations.apis.create
export def "apigee-organizations-apis-create" [
  parent: string
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
  --action: string # Action to perform when importing an API proxy configuration bundle. Set this parameter to one of the following values: * `import` to import the API proxy configuration bundle. * `validate` to validate the API proxy configuration bundle without importing it.
  --name: string # Name of the API proxy. Restrict the characters used to: A-Za-z0-9._-
  --validate: oneof<nothing, bool> # Ignored. All uploads are validated regardless of the value of this field. Maintained for compatibility with Apigee Edge API.
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/apis"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: action, var: action}, {name: name, var: name}, {name: validate, var: validate}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, name: $name, validate: $validate, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all apps created by a developer in an Apigee organization. Optionally, you can request an expanded view of the developer apps. A maximum of 100 developer apps are returned per API call. You can paginate the list of deveoper apps returned using the `startKey` and `count` query parameters.
#
# GET /v1/{parent}/apps
# Returns: record<app: table<apiProducts: list, appFamily: string, appId: string, attributes: list, callbackUrl: string, createdAt: string, credentials: list, developerId: string, keyExpiresIn: string, lastModifiedAt: string, name: string, scopes: list, status: string>>
# operationId: apigee.organizations.developers.apps.list
export def "apigee-organizations-developers-apps-list" [
  parent: string
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
  --count: string # Number of developer apps to return in the API call. Use with the `startKey` parameter to provide more targeted filtering. The limit is 1000.
  --expand: oneof<nothing, bool> # Optional. Specifies whether to expand the results. Set to `true` to expand the results. This query parameter is not valid if you use the `count` or `startKey` query parameters.
  --shallow-expand: oneof<nothing, bool> # Optional. Specifies whether to expand the results in shallow mode. Set to `true` to expand the results in shallow mode.
  --start-key: string # **Note**: Must be used in conjunction with the `count` parameter. Name of the developer app from which to start displaying the list of developer apps. For example, if you're returning 50 developer apps at a time (using the `count` query parameter), you can view developer apps 50-99 by entering the name of the 50th developer app. The developer app name is case sensitive.
  --include-cred: oneof<nothing, bool> # Optional. Flag that specifies whether to include credentials in the response.
  --key-status: string # Optional. Key status of the app. Valid values include `approved` or `revoked`. Defaults to `approved`.
  --rows: string # Optional. Maximum number of app IDs to return. Defaults to 10000.
  --status: string # Optional. Filter by the status of the app. Valid values are `approved` or `revoked`. Defaults to `approved`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/apps"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: count, var: count}, {name: expand, var: expand}, {name: shallowExpand, var: shallow_expand}, {name: startKey, var: start_key}, {name: includeCred, var: include_cred}, {name: keyStatus, var: key_status}, {name: rows, var: rows}, {name: status, var: status}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, count: $count, expand: $expand, shallow_expand: $shallow_expand, start_key: $start_key, include_cred: $include_cred, key_status: $key_status, rows: $rows, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an app associated with a developer. This API associates the developer app with the specified API product and auto-generates an API key for the app to use in calls to API proxies inside that API product. The `name` is the unique ID of the app that you can use in API calls. The `DisplayName` (set as an attribute) appears in the UI. If you don't set the `DisplayName` attribute, the `name` appears in the UI.
#
# POST /v1/{parent}/apps
# Returns: record<apiProducts: list<string>, appFamily: string, appId: string, attributes: table<name: string, value: string>, callbackUrl: string, createdAt: string, credentials: table<apiProducts: list, attributes: list, consumerKey: string, consumerSecret: string, expiresAt: string, issuedAt: string, scopes: list, status: string>, developerId: string, keyExpiresIn: string, lastModifiedAt: string, name: string, scopes: list<string>, status: string>
# operationId: apigee.organizations.developers.apps.create
export def "apigee-organizations-developers-apps-create" [
  parent: string
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
  --api-products: list<string> # List of API products associated with the developer app.
  --app-family: string # Developer app family.
  --app-id: string # ID of the developer app.
  --attributes: list # List of attributes for the developer app. — item shape: {name?: string, value?: string}
  --callback-url: string # Callback URL used by OAuth 2.0 authorization servers to communicate authorization codes back to developer apps.
  --developer-id: string # ID of the developer.
  --key-expires-in: string # Expiration time, in milliseconds, for the consumer key that is generated for the developer app. If not set or left to the default value of `-1`, the API key never expires. The expiration time can't be updated after it is set. (format: int64)
  --name: string # Name of the developer app.
  --scopes: list<string> # Scopes to apply to the developer app. The specified scopes must already exist for the API product that you associate with the developer app.
  --status: string # Status of the credential. Valid values include `approved` or `revoked`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/apps"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiProducts, var: api_products}, {name: appFamily, var: app_family}, {name: appId, var: app_id}, {name: attributes, var: attributes}, {name: callbackUrl, var: callback_url}, {name: developerId, var: developer_id}, {name: keyExpiresIn, var: key_expires_in}, {name: name, var: name}, {name: scopes, var: scopes}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_products: $api_products, app_family: $app_family, app_id: $app_id, attributes: $attributes, callback_url: $callback_url, developer_id: $developer_id, key_expires_in: $key_expires_in, name: $name, scopes: $scopes, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the ArchiveDeployments in the specified Environment.
#
# GET /v1/{parent}/archiveDeployments
# Returns: record<archiveDeployments: table<createdAt: string, gcsUri: string, labels: record, name: string, operation: string, updatedAt: string>, nextPageToken: string>
# operationId: apigee.organizations.environments.archiveDeployments.list
export def "apigee-organizations-environments-archive-deployments-list" [
  parent: string
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
  --filter: string # Optional. An optional query used to return a subset of Archive Deployments using the semantics defined in https://google.aip.dev/160.
  --page-size: int # Optional. Maximum number of Archive Deployments to return. If unspecified, at most 25 deployments will be returned.
  --page-token: string # Optional. Page token, returned from a previous ListArchiveDeployments call, that you can use to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/archiveDeployments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ArchiveDeployment.
#
# POST /v1/{parent}/archiveDeployments
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.environments.archiveDeployments.create
export def "apigee-organizations-environments-archive-deployments-create" [
  parent: string
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
  --gcs-uri: string # Input only. The Google Cloud Storage signed URL returned from GenerateUploadUrl and used to upload the Archive zip file.
  --labels: record # User-supplied key-value pairs used to organize ArchiveDeployments. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: \p{Ll}\p{Lo}{0,62} Label values must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes, and must conform to the following PCRE regular expression: [\p{Ll}\p{Lo}\p{N}_-]{0,63} No more than 64 labels can be associated with a given store.
  --name: string # Name of the Archive Deployment in the following format: `organizations/{org}/environments/{env}/archiveDeployments/{id}`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/archiveDeployments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: gcsUri, var: gcs_uri}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, gcs_uri: $gcs_uri, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a signed URL for uploading an Archive zip file to Google Cloud Storage. Once the upload is complete, the signed URL should be passed to CreateArchiveDeployment. When uploading to the generated signed URL, please follow these restrictions: * Source file type should be a zip file. * Source file size should not exceed 1GB limit. * No credentials should be attached - the signed URLs provide access to the target bucket using internal service identity; if credentials were attached, the identity from the credentials would be used, but that identity does not have permissions to upload files to the URL. When making a HTTP PUT request, these two headers need to be specified: * `content-type: application/zip` * `x-goog-content-length-range: 0,1073741824` And this header SHOULD NOT be specified: * `Authorization: Bearer YOUR_TOKEN`
#
# POST /v1/{parent}/archiveDeployments:generateUploadUrl
# Returns: record<uploadUri: string>
# operationId: apigee.organizations.environments.archiveDeployments.generateUploadUrl
export def "apigee-organizations-environments-archive-deployments-generate-upload-url" [
  parent: string
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
    path: "/v1/{parent}/archiveDeployments:generateUploadUrl"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all attachments to an instance. **Note:** Not supported for Apigee hybrid.
#
# GET /v1/{parent}/attachments
# Returns: record<attachments: table<createdAt: string, environment: string, name: string>, nextPageToken: string>
# operationId: apigee.organizations.instances.attachments.list
export def "apigee-organizations-instances-attachments-list" [
  parent: string
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
  --page-size: int # Maximum number of instance attachments to return. Defaults to 25.
  --page-token: string # Page token, returned by a previous ListInstanceAttachments call, that you can use to retrieve the next page of content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/attachments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new attachment of an environment to an instance. **Note:** Not supported for Apigee hybrid.
#
# POST /v1/{parent}/attachments
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.instances.attachments.create
export def "apigee-organizations-instances-attachments-create" [
  parent: string
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
  --environment: string # ID of the attached environment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/attachments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: environment, var: environment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, environment: $environment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all developer attributes.
#
# GET /v1/{parent}/attributes
# Returns: record<attribute: table<name: string, value: string>>
# operationId: apigee.organizations.developers.attributes.list
export def "apigee-organizations-developers-attributes-list" [
  parent: string
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
    path: "/v1/{parent}/attributes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates developer attributes. This API replaces the existing attributes with those specified in the request. Add new attributes, and include or exclude any existing attributes that you want to retain or remove, respectively. The custom attribute limit is 18. **Note**: OAuth access tokens and Key Management Service (KMS) entities (apps, developers, and API products) are cached for 180 seconds (default). Any custom attributes associated with these entities are cached for at least 180 seconds after the entity is accessed at runtime. Therefore, an `ExpiresIn` element on the OAuthV2 policy won't be able to expire an access token in less than 180 seconds.
#
# POST /v1/{parent}/attributes
# Returns: record<attribute: table<name: string, value: string>>
# operationId: apigee.organizations.developers.attributes
export def "apigee-organizations-developers-attributes" [
  parent: string
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
  --attribute: list # List of attributes. — item shape: {name?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/attributes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: attribute, var: attribute}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, attribute: $attribute
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new canary evaluation for an organization.
#
# POST /v1/{parent}/canaryevaluations
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.instances.canaryevaluations.create
export def "apigee-organizations-instances-canaryevaluations-create" [
  parent: string
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
  --control: string # Required. The stable version that is serving requests.
  --end-time: string # Required. End time for the evaluation's analysis. (format: google-datetime)
  --metric-labels: record # Labels that can be used to filter Apigee metrics. — shape: {env?: string, instance_id?: string, location?: string}
  --start-time: string # Required. Start time for the canary evaluation's analysis. (format: google-datetime)
  --treatment: string # Required. The newer version that is serving requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/canaryevaluations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: control, var: control}, {name: endTime, var: end_time}, {name: metricLabels, var: metric_labels}, {name: startTime, var: start_time}, {name: treatment, var: treatment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, control: $control, end_time: $end_time, metric_labels: $metric_labels, start_time: $start_time, treatment: $treatment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all data collectors.
#
# GET /v1/{parent}/datacollectors
# Returns: record<dataCollectors: table<createdAt: string, description: string, lastModifiedAt: string, name: string, type: string>, nextPageToken: string>
# operationId: apigee.organizations.datacollectors.list
export def "apigee-organizations-datacollectors-list" [
  parent: string
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
  --page-size: int # Maximum number of data collectors to return. The page size defaults to 25.
  --page-token: string # Page token, returned from a previous ListDataCollectors call, that you can use to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/datacollectors"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new data collector.
#
# POST /v1/{parent}/datacollectors
# Returns: record<createdAt: string, description: string, lastModifiedAt: string, name: string, type: string>
# operationId: apigee.organizations.datacollectors.create
export def "apigee-organizations-datacollectors-create" [
  parent: string
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
  --data-collector-id: string # ID of the data collector. Overrides any ID in the data collector resource. Must be a string beginning with `dc_` that contains only letters, numbers, and underscores.
  --description: string # A description of the data collector.
  --name: string # ID of the data collector. Must begin with `dc_`.
  --type: string@type-completer-1 # Immutable. The type of data this data collector will collect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/datacollectors"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataCollectorId, var: data_collector_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_collector_id: $data_collector_id, description: $description, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists debug sessions that are currently active in the given API Proxy revision.
#
# GET /v1/{parent}/debugsessions
# Returns: record<nextPageToken: string, sessions: table<id: string, timestampMs: string>>
# operationId: apigee.organizations.environments.apis.revisions.debugsessions.list
export def "apigee-organizations-environments-apis-revisions-debugsessions-list" [
  parent: string
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
  --page-size: int # Maximum number of debug sessions to return. The page size defaults to 25.
  --page-token: string # Page token, returned from a previous ListDebugSessions call, that you can use to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/debugsessions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a debug session for a deployed API Proxy revision.
#
# POST /v1/{parent}/debugsessions
# Returns: record<count: int, createTime: string, filter: string, name: string, timeout: string, tracesize: int, validity: int>
# operationId: apigee.organizations.environments.apis.revisions.debugsessions.create
export def "apigee-organizations-environments-apis-revisions-debugsessions-create" [
  parent: string
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
  --timeout: string # Optional. The time in seconds after which this DebugSession should end. A timeout specified in DebugSession will overwrite this value.
  --count: int # Optional. The number of request to be traced. Min = 1, Max = 15, Default = 10. (format: int32)
  --filter: string # Optional. A conditional statement which is evaluated against the request message to determine if it should be traced. Syntax matches that of on API Proxy bundle flow Condition.
  --name: string # A unique ID for this DebugSession.
  --body-timeout: string # Optional. The time in seconds after which this DebugSession should end. This value will override the value in query param, if both are provided. (format: int64) (spec name: timeout)
  --tracesize: int # Optional. The maximum number of bytes captured from the response payload. Min = 0, Max = 5120, Default = 5120. (format: int32)
  --validity: int # Optional. The length of time, in seconds, that this debug session is valid, starting from when it's received in the control plane. Min = 1, Max = 15, Default = 10. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/debugsessions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: timeout, var: timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: filter, var: filter}, {name: name, var: name}, {name: timeout, var: body_timeout}, {name: tracesize, var: tracesize}, {name: validity, var: validity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, timeout: $timeout, count: $count, filter: $filter, name: $name, body_timeout: $body_timeout, tracesize: $tracesize, validity: $validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all deployments of a shared flow revision.
#
# GET /v1/{parent}/deployments
# Returns: record<deployments: table<apiProxy: string, deployStartTime: string, environment: string, errors: list, instances: list, pods: list, revision: string, routeConflicts: list, serviceAccount: string, state: string>>
# operationId: apigee.organizations.sharedflows.revisions.deployments.list
export def "apigee-organizations-sharedflows-revisions-deployments-list" [
  parent: string
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
  --shared-flows: oneof<nothing, bool> # Optional. Flag that specifies whether to return shared flow or API proxy deployments. Set to `true` to return shared flow deployments; set to `false` to return API proxy deployments. Defaults to `false`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/deployments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: sharedFlows, var: shared_flows}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, shared_flows: $shared_flows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all developers in an organization by email address. By default, the response does not include company developers. Set the `includeCompany` query parameter to `true` to include company developers. **Note**: A maximum of 1000 developers are returned in the response. You paginate the list of developers returned using the `startKey` and `count` query parameters.
#
# GET /v1/{parent}/developers
# Returns: record<developer: table<accessType: string, appFamily: string, apps: list, attributes: list, companies: list, createdAt: string, developerId: string, email: string, firstName: string, lastModifiedAt: string, lastName: string, organizationName: string, status: string, userName: string>>
# operationId: apigee.organizations.developers.list
export def "apigee-organizations-developers-list" [
  parent: string
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
  --app: string # Optional. List only Developers that are associated with the app. Note that start_key, count are not applicable for this filter criteria.
  --count: string # Optional. Number of developers to return in the API call. Use with the `startKey` parameter to provide more targeted filtering. The limit is 1000.
  --expand: oneof<nothing, bool> # Specifies whether to expand the results. Set to `true` to expand the results. This query parameter is not valid if you use the `count` or `startKey` query parameters.
  --ids: string # Optional. List of IDs to include, separated by commas.
  --include-company: oneof<nothing, bool> # Flag that specifies whether to include company details in the response.
  --start-key: string # **Note**: Must be used in conjunction with the `count` parameter. Email address of the developer from which to start displaying the list of developers. For example, if the an unfiltered list returns: ``` westley@example.com fezzik@example.com buttercup@example.com ``` and your `startKey` is `fezzik@example.com`, the list returned will be ``` fezzik@example.com buttercup@example.com ```
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/developers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: app, var: app}, {name: count, var: count}, {name: expand, var: expand}, {name: ids, var: ids}, {name: includeCompany, var: include_company}, {name: startKey, var: start_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, app: $app, count: $count, expand: $expand, ids: $ids, include_company: $include_company, start_key: $start_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a developer. Once created, the developer can register an app and obtain an API key. At creation time, a developer is set as `active`. To change the developer status, use the SetDeveloperStatus API.
#
# POST /v1/{parent}/developers
# Returns: record<accessType: string, appFamily: string, apps: list<string>, attributes: table<name: string, value: string>, companies: list<string>, createdAt: string, developerId: string, email: string, firstName: string, lastModifiedAt: string, lastName: string, organizationName: string, status: string, userName: string>
# operationId: apigee.organizations.developers.create
export def "apigee-organizations-developers-create" [
  parent: string
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
  --access-type: string # Access type.
  --app-family: string # Developer app family.
  --apps: list<string> # List of apps associated with the developer.
  --attributes: list # Optional. Developer attributes (name/value pairs). The custom attribute limit is 18. — item shape: {name?: string, value?: string}
  --companies: list<string> # List of companies associated with the developer.
  --developer-id: string # ID of the developer. **Note**: IDs are generated internally by Apigee and are not guaranteed to stay the same over time.
  --email: string # Required. Email address of the developer. This value is used to uniquely identify the developer in Apigee hybrid. Note that the email address has to be in lowercase only.
  --first-name: string # Required. First name of the developer.
  --last-name: string # Required. Last name of the developer.
  --user-name: string # Required. User name of the developer. Not used by Apigee hybrid.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/developers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessType, var: access_type}, {name: appFamily, var: app_family}, {name: apps, var: apps}, {name: attributes, var: attributes}, {name: companies, var: companies}, {name: developerId, var: developer_id}, {name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, access_type: $access_type, app_family: $app_family, apps: $apps, attributes: $attributes, companies: $companies, developer_id: $developer_id, email: $email, first_name: $first_name, last_name: $last_name, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the endpoint attachments in an organization.
#
# GET /v1/{parent}/endpointAttachments
# Returns: record<endpointAttachments: table<connectionState: string, host: string, location: string, name: string, serviceAttachment: string, state: string>, nextPageToken: string>
# operationId: apigee.organizations.endpointAttachments.list
export def "apigee-organizations-endpoint-attachments-list" [
  parent: string
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
  --page-size: int # Optional. Maximum number of endpoint attachments to return. If unspecified, at most 25 attachments will be returned.
  --page-token: string # Optional. Page token, returned from a previous `ListEndpointAttachments` call, that you can use to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/endpointAttachments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint attachment. **Note:** Not supported for Apigee hybrid.
#
# POST /v1/{parent}/endpointAttachments
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.endpointAttachments.create
export def "apigee-organizations-endpoint-attachments-create" [
  parent: string
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
  --endpoint-attachment-id: string # ID to use for the endpoint attachment. ID must start with a lowercase letter followed by up to 31 lowercase letters, numbers, or hyphens, and cannot end with a hyphen. The minimum length is 2.
  --location: string # Required. Location of the endpoint attachment.
  --name: string # Name of the endpoint attachment. Use the following structure in your request: `organizations/{org}/endpointAttachments/{endpoint_attachment}`
  --service-attachment: string # Format: projects/*/regions/*/serviceAttachments/*
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/endpointAttachments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endpointAttachmentId, var: endpoint_attachment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: name, var: name}, {name: serviceAttachment, var: service_attachment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, endpoint_attachment_id: $endpoint_attachment_id, location: $location, name: $name, service_attachment: $service_attachment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists key value entries for key values maps scoped to an organization, environment, or API proxy. **Note**: Supported for Apigee hybrid 1.8.x and higher.
#
# GET /v1/{parent}/entries
# Returns: record<keyValueEntries: table<name: string, value: string>, nextPageToken: string>
# operationId: apigee.organizations.keyvaluemaps.entries.list
export def "apigee-organizations-keyvaluemaps-entries-list" [
  parent: string
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
  --page-size: int # Optional. Maximum number of key value entries to return. If unspecified, at most 100 entries will be returned.
  --page-token: string # Optional. Page token. If provides, must be a valid key value entry returned from a previous call that can be used to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/entries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates key value entries in a key value map scoped to an organization, environment, or API proxy. **Note**: Supported for Apigee hybrid 1.8.x and higher.
#
# POST /v1/{parent}/entries
# Returns: record<name: string, value: string>
# operationId: apigee.organizations.keyvaluemaps.entries.create
export def "apigee-organizations-keyvaluemaps-entries-create" [
  parent: string
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
  --name: string # Resource URI that can be used to identify the scope of the key value map entries.
  --value: string # Required. Data or payload that is being retrieved and associated with the unique key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/entries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all environment groups.
#
# GET /v1/{parent}/envgroups
# Returns: record<environmentGroups: table<createdAt: string, hostnames: list, lastModifiedAt: string, name: string, state: string>, nextPageToken: string>
# operationId: apigee.organizations.envgroups.list
export def "apigee-organizations-envgroups-list" [
  parent: string
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
  --page-size: int # Maximum number of environment groups to return. The page size defaults to 25.
  --page-token: string # Page token, returned from a previous ListEnvironmentGroups call, that you can use to retrieve the next page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/envgroups"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new environment group.
#
# POST /v1/{parent}/envgroups
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.envgroups.create
export def "apigee-organizations-envgroups-create" [
  parent: string
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
  --name: string # ID of the environment group. Overrides any ID in the environment_group resource.
  --hostnames: list<string> # Required. Host names for this environment group.
  --body-name: string # ID of the environment group. (spec name: name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/envgroups"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: hostnames, var: hostnames}, {name: name, var: body_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, hostnames: $hostnames, body_name: $body_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CreateSecurityProfileEnvironmentAssociation creates profile environment association i.e. attaches environment to security profile.
#
# POST /v1/{parent}/environments
# Returns: record<attachTime: string, name: string, securityProfileRevisionId: string>
# operationId: apigee.organizations.securityProfiles.environments.create
export def "apigee-organizations-security-profiles-environments-create" [
  parent: string
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
  --name: string # Optional. Name of the environment.
  --body-name: string # Immutable. Name of the profile-environment association resource. Format: organizations/{org}/securityProfiles/{profile}/environments/{env} (spec name: name)
  --security-profile-revision-id: string # Revision ID of the security profile. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/environments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: body_name}, {name: securityProfileRevisionId, var: security_profile_revision_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, body_name: $body_name, security_profile_revision_id: $security_profile_revision_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of Asynchronous Queries at host level.
#
# GET /v1/{parent}/hostQueries
# Returns: record<queries: table<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>
# operationId: apigee.organizations.hostQueries.list
export def "apigee-organizations-host-queries-list" [
  parent: string
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
  --dataset: string # Filter response list by dataset. Example: `api`, `mint`
  --envgroup-hostname: string # Required. Filter response list by hostname.
  --from: string # Filter response list by returning asynchronous queries that created after this date time. Time must be in ISO date-time format like '2011-12-03T10:15:30Z'.
  --incl-queries-without-report: string # Flag to include asynchronous queries that don't have a report denifition.
  --status: string # Filter response list by asynchronous query status.
  --submitted-by: string # Filter response list by user who submitted queries.
  --to: string # Filter response list by returning asynchronous queries that created before this date time. Time must be in ISO date-time format like '2011-12-03T10:16:30Z'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/hostQueries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataset, var: dataset}, {name: envgroupHostname, var: envgroup_hostname}, {name: from, var: from}, {name: inclQueriesWithoutReport, var: incl_queries_without_report}, {name: status, var: status}, {name: submittedBy, var: submitted_by}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dataset: $dataset, envgroup_hostname: $envgroup_hostname, from: $from, incl_queries_without_report: $incl_queries_without_report, status: $status, submitted_by: $submitted_by, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a query at host level to be processed in the background. If the submission of the query succeeds, the API returns a 201 status and an ID that refer to the query. In addition to the HTTP status 201, the `state` of "enqueued" means that the request succeeded.
#
# POST /v1/{parent}/hostQueries
# Returns: record<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, outputFormat: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>
# operationId: apigee.organizations.hostQueries.create
export def "apigee-organizations-host-queries-create" [
  parent: string
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
  --csv-delimiter: string # Delimiter used in the CSV file, if `outputFormat` is set to `csv`. Defaults to the `,` (comma) character. Supported delimiter characters include comma (`,`), pipe (`|`), and tab (`\t`).
  --dimensions: list<string> # A list of dimensions. https://docs.apigee.com/api-platform/analytics/analytics-reference#dimensions
  --envgroup-hostname: string # Hostname needs to be specified if query intends to run at host level. This field is only allowed when query is submitted by CreateHostAsyncQuery where analytics data will be grouped by organization and hostname.
  --filter: string # Boolean expression that can be used to filter data. Filter expressions can be combined using AND/OR terms and should be fully parenthesized to avoid ambiguity. See Analytics metrics, dimensions, and filters reference https://docs.apigee.com/api-platform/analytics/analytics-reference for more information on the fields available to filter on. For more information on the tokens that you use to build filter expressions, see Filter expression syntax. https://docs.apigee.com/api-platform/analytics/asynch-reports-api#filter-expression-syntax
  --group-by-time-unit: string # Time unit used to group the result set. Valid values include: second, minute, hour, day, week, or month. If a query includes groupByTimeUnit, then the result is an aggregation based on the specified time unit and the resultant timestamp does not include milliseconds precision. If a query omits groupByTimeUnit, then the resultant timestamp includes milliseconds precision.
  --limit: int # Maximum number of rows that can be returned in the result. (format: int32)
  --metrics: list # A list of Metrics. — item shape: {alias?: string, function?: string, name?: string, operator?: string, value?: string}
  --name: string # Asynchronous Query Name.
  --output-format: string # Valid values include: `csv` or `json`. Defaults to `json`. Note: Configure the delimiter for CSV output using the csvDelimiter property.
  --report-definition-id: string # Asynchronous Report ID.
  --time-range: any # Required. Time range for the query. Can use the following predefined strings to specify the time range: `last60minutes` `last24hours` `last7days` Or, specify the timeRange as a structure describing start and end timestamps in the ISO format: yyyy-mm-ddThh:mm:ssZ. Example: "timeRange": { "start": "2018-07-29T00:13:00Z", "end": "2018-08-01T00:18:00Z" }
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/hostQueries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: csvDelimiter, var: csv_delimiter}, {name: dimensions, var: dimensions}, {name: envgroupHostname, var: envgroup_hostname}, {name: filter, var: filter}, {name: groupByTimeUnit, var: group_by_time_unit}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: name, var: name}, {name: outputFormat, var: output_format}, {name: reportDefinitionId, var: report_definition_id}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, csv_delimiter: $csv_delimiter, dimensions: $dimensions, envgroup_hostname: $envgroup_hostname, filter: $filter, group_by_time_unit: $group_by_time_unit, limit: $limit, metrics: $metrics, name: $name, output_format: $output_format, report_definition_id: $report_definition_id, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of Security Reports at host level.
#
# GET /v1/{parent}/hostSecurityReports
# Returns: record<nextPageToken: string, securityReports: table<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>
# operationId: apigee.organizations.hostSecurityReports.list
export def "apigee-organizations-host-security-reports-list" [
  parent: string
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
  --dataset: string # Filter response list by dataset. Example: `api`, `mint`
  --envgroup-hostname: string # Required. Filter response list by hostname.
  --from: string # Filter response list by returning security reports that created after this date time. Time must be in ISO date-time format like '2011-12-03T10:15:30Z'.
  --page-size: int # The maximum number of security report to return in the list response.
  --page-token: string # Token returned from the previous list response to fetch the next page.
  --status: string # Filter response list by security report status.
  --submitted-by: string # Filter response list by user who submitted queries.
  --to: string # Filter response list by returning security reports that created before this date time. Time must be in ISO date-time format like '2011-12-03T10:16:30Z'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/hostSecurityReports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataset, var: dataset}, {name: envgroupHostname, var: envgroup_hostname}, {name: from, var: from}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: status, var: status}, {name: submittedBy, var: submitted_by}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dataset: $dataset, envgroup_hostname: $envgroup_hostname, from: $from, page_size: $page_size, page_token: $page_token, status: $status, submitted_by: $submitted_by, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a query at host level to be processed in the background. If the submission of the query succeeds, the API returns a 201 status and an ID that refer to the query. In addition to the HTTP status 201, the `state` of "enqueued" means that the request succeeded.
#
# POST /v1/{parent}/hostSecurityReports
# Returns: record<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, mimeType: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>
# operationId: apigee.organizations.hostSecurityReports.create
export def "apigee-organizations-host-security-reports-create" [
  parent: string
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
  --csv-delimiter: string # Delimiter used in the CSV file, if `outputFormat` is set to `csv`. Defaults to the `,` (comma) character. Supported delimiter characters include comma (`,`), pipe (`|`), and tab (`\t`).
  --dimensions: list<string> # A list of dimensions. https://docs.apigee.com/api-platform/analytics/analytics-reference#dimensions
  --display-name: string # Security Report display name which users can specify.
  --envgroup-hostname: string # Hostname needs to be specified if query intends to run at host level. This field is only allowed when query is submitted by CreateHostSecurityReport where analytics data will be grouped by organization and hostname.
  --filter: string # Boolean expression that can be used to filter data. Filter expressions can be combined using AND/OR terms and should be fully parenthesized to avoid ambiguity. See Analytics metrics, dimensions, and filters reference https://docs.apigee.com/api-platform/analytics/analytics-reference for more information on the fields available to filter on. For more information on the tokens that you use to build filter expressions, see Filter expression syntax. https://docs.apigee.com/api-platform/analytics/asynch-reports-api#filter-expression-syntax
  --group-by-time-unit: string # Time unit used to group the result set. Valid values include: second, minute, hour, day, week, or month. If a query includes groupByTimeUnit, then the result is an aggregation based on the specified time unit and the resultant timestamp does not include milliseconds precision. If a query omits groupByTimeUnit, then the resultant timestamp includes milliseconds precision.
  --limit: int # Maximum number of rows that can be returned in the result. (format: int32)
  --metrics: list # A list of Metrics. — item shape: {aggregationFunction?: string, alias?: string, name?: string, operator?: string, value?: string}
  --mime-type: string # Valid values include: `csv` or `json`. Defaults to `json`. Note: Configure the delimiter for CSV output using the csvDelimiter property.
  --report-definition-id: string # Report Definition ID.
  --time-range: any # Required. Time range for the query. Can use the following predefined strings to specify the time range: `last60minutes` `last24hours` `last7days` Or, specify the timeRange as a structure describing start and end timestamps in the ISO format: yyyy-mm-ddThh:mm:ssZ. Example: "timeRange": { "start": "2018-07-29T00:13:00Z", "end": "2018-08-01T00:18:00Z" }
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/hostSecurityReports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: csvDelimiter, var: csv_delimiter}, {name: dimensions, var: dimensions}, {name: displayName, var: display_name}, {name: envgroupHostname, var: envgroup_hostname}, {name: filter, var: filter}, {name: groupByTimeUnit, var: group_by_time_unit}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: mimeType, var: mime_type}, {name: reportDefinitionId, var: report_definition_id}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, csv_delimiter: $csv_delimiter, dimensions: $dimensions, display_name: $display_name, envgroup_hostname: $envgroup_hostname, filter: $filter, group_by_time_unit: $group_by_time_unit, limit: $limit, metrics: $metrics, mime_type: $mime_type, report_definition_id: $report_definition_id, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Apigee runtime instances for the organization. **Note:** Not supported for Apigee hybrid.
#
# GET /v1/{parent}/instances
# Returns: record<instances: table<consumerAcceptList: list, createdAt: string, description: string, diskEncryptionKeyName: string, displayName: string, host: string, ipRange: string, lastModifiedAt: string, location: string, name: string, peeringCidrRange: string, port: string, runtimeVersion: string, serviceAttachment: string, state: string>, nextPageToken: string>
# operationId: apigee.organizations.instances.list
export def "apigee-organizations-instances-list" [
  parent: string
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
  --page-size: int # Maximum number of instances to return. Defaults to 25.
  --page-token: string # Page token, returned from a previous ListInstances call, that you can use to retrieve the next page of content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/instances"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Apigee runtime instance. The instance is accessible from the authorized network configured on the organization. **Note:** Not supported for Apigee hybrid.
#
# POST /v1/{parent}/instances
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.instances.create
export def "apigee-organizations-instances-create" [
  parent: string
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
  --consumer-accept-list: list<string> # Optional. Customer accept list represents the list of projects (id/number) on customer side that can privately connect to the service attachment. It is an optional field which the customers can provide during the instance creation. By default, the customer project associated with the Apigee organization will be included to the list.
  --description: string # Optional. Description of the instance.
  --disk-encryption-key-name: string # Customer Managed Encryption Key (CMEK) used for disk and volume encryption. Required for Apigee paid subscriptions only. Use the following format: `projects/([^/]+)/locations/([^/]+)/keyRings/([^/]+)/cryptoKeys/([^/]+)`
  --display-name: string # Optional. Display name for the instance.
  --ip-range: string # Optional. Comma-separated list of CIDR blocks of length 22 and/or 28 used to create the Apigee instance. Providing CIDR ranges is optional. You can provide just /22 or /28 or both (or neither). Ranges you provide should be freely available as part of a larger named range you have allocated to the Service Networking peering. If this parameter is not provided, Apigee automatically requests an available /22 and /28 CIDR block from Service Networking. Use the /22 CIDR block for configuring your firewall needs to allow traffic from Apigee. Input formats: `a.b.c.d/22` or `e.f.g.h/28` or `a.b.c.d/22,e.f.g.h/28`
  --location: string # Required. Compute Engine location where the instance resides.
  --name: string # Required. Resource ID of the instance. Values must match the regular expression `^a-z{0,30}[a-z\d]$`.
  --peering-cidr-range: string@peering-cidr-range-completer # Optional. Size of the CIDR block range that will be reserved by the instance. PAID organizations support `SLASH_16` to `SLASH_20` and defaults to `SLASH_16`. Evaluation organizations support only `SLASH_23`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/instances"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: consumerAcceptList, var: consumer_accept_list}, {name: description, var: description}, {name: diskEncryptionKeyName, var: disk_encryption_key_name}, {name: displayName, var: display_name}, {name: ipRange, var: ip_range}, {name: location, var: location}, {name: name, var: name}, {name: peeringCidrRange, var: peering_cidr_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, consumer_accept_list: $consumer_accept_list, description: $description, disk_encryption_key_name: $disk_encryption_key_name, display_name: $display_name, ip_range: $ip_range, location: $location, name: $name, peering_cidr_range: $peering_cidr_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom consumer key and secret for a developer app. This is particularly useful if you want to migrate existing consumer keys and secrets to Apigee from another system. Consumer keys and secrets can contain letters, numbers, underscores, and hyphens. No other special characters are allowed. To avoid service disruptions, a consumer key and secret should not exceed 2 KBs each. **Note**: When creating the consumer key and secret, an association to API products will not be made. Therefore, you should not specify the associated API products in your request. Instead, use the UpdateDeveloperAppKey API to make the association after the consumer key and secret are created. If a consumer key and secret already exist, you can keep them or delete them using the DeleteDeveloperAppKey API.
#
# POST /v1/{parent}/keys
# Returns: record<apiProducts: list<any>, attributes: table<name: string, value: string>, consumerKey: string, consumerSecret: string, expiresAt: string, expiresInSeconds: string, issuedAt: string, scopes: list<string>, status: string>
# operationId: apigee.organizations.developers.apps.keys.create
export def "apigee-organizations-developers-apps-keys-create" [
  parent: string
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
  --api-products: list # List of API products for which the credential can be used. **Note**: Do not specify the list of API products when creating a consumer key and secret for a developer app. Instead, use the UpdateDeveloperAppKey API to make the association after the consumer key and secret are created.
  --attributes: list # List of attributes associated with the credential. — item shape: {name?: string, value?: string}
  --consumer-key: string # Consumer key.
  --consumer-secret: string # Secret key.
  --expires-at: string # Time the developer app expires in milliseconds since epoch. (format: int64)
  --expires-in-seconds: string # Input only. Expiration time, in seconds, for the consumer key. If not set or left to the default value of `-1`, the API key never expires. The expiration time can't be updated after it is set. (format: int64)
  --issued-at: string # Time the developer app was created in milliseconds since epoch. (format: int64)
  --scopes: list<string> # Scopes to apply to the app. The specified scope names must already be defined for the API product that you associate with the app.
  --status: string # Status of the credential. Valid values include `approved` or `revoked`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/keys"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiProducts, var: api_products}, {name: attributes, var: attributes}, {name: consumerKey, var: consumer_key}, {name: consumerSecret, var: consumer_secret}, {name: expiresAt, var: expires_at}, {name: expiresInSeconds, var: expires_in_seconds}, {name: issuedAt, var: issued_at}, {name: scopes, var: scopes}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_products: $api_products, attributes: $attributes, consumer_key: $consumer_key, consumer_secret: $consumer_secret, expires_at: $expires_at, expires_in_seconds: $expires_in_seconds, issued_at: $issued_at, scopes: $scopes, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a custom consumer key and secret for a developer app. This is particularly useful if you want to migrate existing consumer keys and secrets to Apigee from another system. Consumer keys and secrets can contain letters, numbers, underscores, and hyphens. No other special characters are allowed. To avoid service disruptions, a consumer key and secret should not exceed 2 KBs each. **Note**: When creating the consumer key and secret, an association to API products will not be made. Therefore, you should not specify the associated API products in your request. Instead, use the UpdateDeveloperAppKey API to make the association after the consumer key and secret are created. If a consumer key and secret already exist, you can keep them or delete them using the DeleteDeveloperAppKey API.
#
# POST /v1/{parent}/keys/create
# Returns: record<apiProducts: list<any>, attributes: table<name: string, value: string>, consumerKey: string, consumerSecret: string, expiresAt: string, expiresInSeconds: string, issuedAt: string, scopes: list<string>, status: string>
# operationId: apigee.organizations.developers.apps.keys.create.create
export def "apigee-organizations-developers-apps-keys-create-create" [
  parent: string
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
  --api-products: list # List of API products for which the credential can be used. **Note**: Do not specify the list of API products when creating a consumer key and secret for a developer app. Instead, use the UpdateDeveloperAppKey API to make the association after the consumer key and secret are created.
  --attributes: list # List of attributes associated with the credential. — item shape: {name?: string, value?: string}
  --consumer-key: string # Consumer key.
  --consumer-secret: string # Secret key.
  --expires-at: string # Time the developer app expires in milliseconds since epoch. (format: int64)
  --expires-in-seconds: string # Input only. Expiration time, in seconds, for the consumer key. If not set or left to the default value of `-1`, the API key never expires. The expiration time can't be updated after it is set. (format: int64)
  --issued-at: string # Time the developer app was created in milliseconds since epoch. (format: int64)
  --scopes: list<string> # Scopes to apply to the app. The specified scope names must already be defined for the API product that you associate with the app.
  --status: string # Status of the credential. Valid values include `approved` or `revoked`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/keys/create"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiProducts, var: api_products}, {name: attributes, var: attributes}, {name: consumerKey, var: consumer_key}, {name: consumerSecret, var: consumer_secret}, {name: expiresAt, var: expires_at}, {name: expiresInSeconds, var: expires_in_seconds}, {name: issuedAt, var: issued_at}, {name: scopes, var: scopes}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_products: $api_products, attributes: $attributes, consumer_key: $consumer_key, consumer_secret: $consumer_secret, expires_at: $expires_at, expires_in_seconds: $expires_in_seconds, issued_at: $issued_at, scopes: $scopes, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a keystore or truststore. - Keystore: Contains certificates and their associated keys. - Truststore: Contains trusted certificates used to validate a server's certificate. These certificates are typically self-signed certificates or certificates that are not signed by a trusted CA.
#
# POST /v1/{parent}/keystores
# Returns: record<aliases: list<string>, name: string>
# operationId: apigee.organizations.environments.keystores.create
export def "apigee-organizations-environments-keystores-create" [
  parent: string
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
  --name: string # Optional. Name of the keystore. Overrides the value in Keystore.
  --body-name: string # Required. Resource ID for this keystore. Values must match the regular expression `[\w[:space:].-]{1,255}`. (spec name: name)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/keystores"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: body_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, body_name: $body_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a key value map in an organization.
#
# POST /v1/{parent}/keyvaluemaps
# Returns: record<encrypted: bool, name: string>
# operationId: apigee.organizations.keyvaluemaps.create
export def "apigee-organizations-keyvaluemaps-create" [
  parent: string
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
  --encrypted: oneof<nothing, bool> # Required. Flag that specifies whether entry values will be encrypted. This field is retained for backward compatibility and the value of encrypted will always be `true`. Apigee X and hybrid do not support unencrypted key value maps.
  --name: string # Required. ID of the key value map.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/keyvaluemaps"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: encrypted, var: encrypted}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, encrypted: $encrypted, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the NAT addresses for an Apigee instance. **Note:** Not supported for Apigee hybrid.
#
# GET /v1/{parent}/natAddresses
# Returns: record<natAddresses: table<ipAddress: string, name: string, state: string>, nextPageToken: string>
# operationId: apigee.organizations.instances.natAddresses.list
export def "apigee-organizations-instances-nat-addresses-list" [
  parent: string
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
  --page-size: int # Maximum number of natAddresses to return. Defaults to 25.
  --page-token: string # Page token, returned from a previous ListNatAddresses call, that you can use to retrieve the next page of content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/natAddresses"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a NAT address. The address is created in the RESERVED state and a static external IP address will be provisioned. At this time, the instance will not use this IP address for Internet egress traffic. The address can be activated for use once any required firewall IP whitelisting has been completed. **Note:** Not supported for Apigee hybrid.
#
# POST /v1/{parent}/natAddresses
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.organizations.instances.natAddresses.create
export def "apigee-organizations-instances-nat-addresses-create" [
  parent: string
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
  --name: string # Required. Resource ID of the NAT address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/natAddresses"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the distributed trace configuration overrides in an environment.
#
# GET /v1/{parent}/overrides
# Returns: record<nextPageToken: string, traceConfigOverrides: table<apiProxy: string, name: string, samplingConfig: record>>
# operationId: apigee.organizations.environments.traceConfig.overrides.list
export def "apigee-organizations-environments-trace-config-overrides-list" [
  parent: string
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
  --page-size: int # Maximum number of trace configuration overrides to return. If not specified, the maximum number returned is 25. The maximum number cannot exceed 100.
  --page-token: string # A page token, returned from a previous `ListTraceConfigOverrides` call. Token value that can be used to retrieve the subsequent page. When paginating, all other parameters provided to `ListTraceConfigOverrides` must match those specified in the call to obtain the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/overrides"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a trace configuration override. The response contains a system-generated UUID, that can be used to view, update, or delete the configuration override. Use the List API to view the existing trace configuration overrides.
#
# POST /v1/{parent}/overrides
# Returns: record<apiProxy: string, name: string, samplingConfig: record<sampler: string, samplingRate: float>>
# operationId: apigee.organizations.environments.traceConfig.overrides.create
export def "apigee-organizations-environments-trace-config-overrides-create" [
  parent: string
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
  --api-proxy: string # ID of the API proxy that will have its trace configuration overridden.
  --name: string # ID of the trace configuration override specified as a system-generated UUID.
  --sampling-config: record # TraceSamplingConfig represents the detail settings of distributed tracing. Only the fields that are defined in the distributed trace configuration can be overridden using the distribute trace configuration override APIs. — shape: {sampler?: "SAMPLER_UNSPECIFIED"|"OFF"|"PROBABILITY", samplingRate?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/overrides"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiProxy, var: api_proxy}, {name: name, var: name}, {name: samplingConfig, var: sampling_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, api_proxy: $api_proxy, name: $name, sampling_config: $sampling_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of Asynchronous Queries
#
# GET /v1/{parent}/queries
# Returns: record<queries: table<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>
# operationId: apigee.organizations.environments.queries.list
export def "apigee-organizations-environments-queries-list" [
  parent: string
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
  --dataset: string # Filter response list by dataset. Example: `api`, `mint`
  --from: string # Filter response list by returning asynchronous queries that created after this date time. Time must be in ISO date-time format like '2011-12-03T10:15:30Z'.
  --incl-queries-without-report: string # Flag to include asynchronous queries that don't have a report denifition.
  --status: string # Filter response list by asynchronous query status.
  --submitted-by: string # Filter response list by user who submitted queries.
  --to: string # Filter response list by returning asynchronous queries that created before this date time. Time must be in ISO date-time format like '2011-12-03T10:16:30Z'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/queries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataset, var: dataset}, {name: from, var: from}, {name: inclQueriesWithoutReport, var: incl_queries_without_report}, {name: status, var: status}, {name: submittedBy, var: submitted_by}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dataset: $dataset, from: $from, incl_queries_without_report: $incl_queries_without_report, status: $status, submitted_by: $submitted_by, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a query to be processed in the background. If the submission of the query succeeds, the API returns a 201 status and an ID that refer to the query. In addition to the HTTP status 201, the `state` of "enqueued" means that the request succeeded.
#
# POST /v1/{parent}/queries
# Returns: record<created: string, envgroupHostname: string, error: string, executionTime: string, name: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, outputFormat: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>
# operationId: apigee.organizations.environments.queries.create
export def "apigee-organizations-environments-queries-create" [
  parent: string
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
  --csv-delimiter: string # Delimiter used in the CSV file, if `outputFormat` is set to `csv`. Defaults to the `,` (comma) character. Supported delimiter characters include comma (`,`), pipe (`|`), and tab (`\t`).
  --dimensions: list<string> # A list of dimensions. https://docs.apigee.com/api-platform/analytics/analytics-reference#dimensions
  --envgroup-hostname: string # Hostname needs to be specified if query intends to run at host level. This field is only allowed when query is submitted by CreateHostAsyncQuery where analytics data will be grouped by organization and hostname.
  --filter: string # Boolean expression that can be used to filter data. Filter expressions can be combined using AND/OR terms and should be fully parenthesized to avoid ambiguity. See Analytics metrics, dimensions, and filters reference https://docs.apigee.com/api-platform/analytics/analytics-reference for more information on the fields available to filter on. For more information on the tokens that you use to build filter expressions, see Filter expression syntax. https://docs.apigee.com/api-platform/analytics/asynch-reports-api#filter-expression-syntax
  --group-by-time-unit: string # Time unit used to group the result set. Valid values include: second, minute, hour, day, week, or month. If a query includes groupByTimeUnit, then the result is an aggregation based on the specified time unit and the resultant timestamp does not include milliseconds precision. If a query omits groupByTimeUnit, then the resultant timestamp includes milliseconds precision.
  --limit: int # Maximum number of rows that can be returned in the result. (format: int32)
  --metrics: list # A list of Metrics. — item shape: {alias?: string, function?: string, name?: string, operator?: string, value?: string}
  --name: string # Asynchronous Query Name.
  --output-format: string # Valid values include: `csv` or `json`. Defaults to `json`. Note: Configure the delimiter for CSV output using the csvDelimiter property.
  --report-definition-id: string # Asynchronous Report ID.
  --time-range: any # Required. Time range for the query. Can use the following predefined strings to specify the time range: `last60minutes` `last24hours` `last7days` Or, specify the timeRange as a structure describing start and end timestamps in the ISO format: yyyy-mm-ddThh:mm:ssZ. Example: "timeRange": { "start": "2018-07-29T00:13:00Z", "end": "2018-08-01T00:18:00Z" }
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/queries"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: csvDelimiter, var: csv_delimiter}, {name: dimensions, var: dimensions}, {name: envgroupHostname, var: envgroup_hostname}, {name: filter, var: filter}, {name: groupByTimeUnit, var: group_by_time_unit}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: name, var: name}, {name: outputFormat, var: output_format}, {name: reportDefinitionId, var: report_definition_id}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, csv_delimiter: $csv_delimiter, dimensions: $dimensions, envgroup_hostname: $envgroup_hostname, filter: $filter, group_by_time_unit: $group_by_time_unit, limit: $limit, metrics: $metrics, name: $name, output_format: $output_format, report_definition_id: $report_definition_id, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the rate plans for an API product.
#
# GET /v1/{parent}/rateplans
# Returns: record<nextStartKey: string, ratePlans: table<apiproduct: string, billingPeriod: string, consumptionPricingRates: list, consumptionPricingType: string, createdAt: string, currencyCode: string, description: string, displayName: string, endTime: string, fixedFeeFrequency: int, fixedRecurringFee: record, lastModifiedAt: string, name: string, paymentFundingModel: string, revenueShareRates: list, revenueShareType: string, setupFee: record, startTime: string, state: string>>
# operationId: apigee.organizations.apiproducts.rateplans.list
export def "apigee-organizations-apiproducts-rateplans-list" [
  parent: string
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
  --count: int # Number of rate plans to return in the API call. Use with the `startKey` parameter to provide more targeted filtering. The maximum limit is 1000. Defaults to 100.
  --expand: oneof<nothing, bool> # Flag that specifies whether to expand the results. Set to `true` to get expanded details about each API. Defaults to `false`.
  --order-by: string # Name of the attribute used for sorting. Valid values include: * `name`: Name of the rate plan. * `state`: State of the rate plan (`DRAFT`, `PUBLISHED`). * `startTime`: Time when the rate plan becomes active. * `endTime`: Time when the rate plan expires. **Note**: Not supported by Apigee at this time.
  --start-key: string # Name of the rate plan from which to start displaying the list of rate plans. If omitted, the list starts from the first item. For example, to view the rate plans from 51-150, set the value of `startKey` to the name of the 51st rate plan and set the value of `count` to 100.
  --state: string@state-completer # State of the rate plans (`DRAFT`, `PUBLISHED`) that you want to display.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/rateplans"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: count, var: count}, {name: expand, var: expand}, {name: orderBy, var: order_by}, {name: startKey, var: start_key}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, count: $count, expand: $expand, order_by: $order_by, start_key: $start_key, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a rate plan that is associated with an API product in an organization. Using rate plans, API product owners can monetize their API products by configuring one or more of the following: - Billing frequency - Initial setup fees for using an API product - Payment funding model (postpaid only) - Fixed recurring or consumption-based charges for using an API product - Revenue sharing with developer partners An API product can have multiple rate plans associated with it but *only one* rate plan can be active at any point of time. **Note: From the developer's perspective, they purchase API products not rate plans.
#
# POST /v1/{parent}/rateplans
# Returns: record<apiproduct: string, billingPeriod: string, consumptionPricingRates: table<end: string, fee: record, start: string>, consumptionPricingType: string, createdAt: string, currencyCode: string, description: string, displayName: string, endTime: string, fixedFeeFrequency: int, fixedRecurringFee: record<currencyCode: string, nanos: int, units: string>, lastModifiedAt: string, name: string, paymentFundingModel: string, revenueShareRates: table<end: string, sharePercentage: float, start: string>, revenueShareType: string, setupFee: record<currencyCode: string, nanos: int, units: string>, startTime: string, state: string>
# operationId: apigee.organizations.apiproducts.rateplans.create
export def "apigee-organizations-apiproducts-rateplans-create" [
  parent: string
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
  --apiproduct: string # Name of the API product that the rate plan is associated with.
  --billing-period: string@billing-period-completer # Frequency at which the customer will be billed.
  --consumption-pricing-rates: list # API call volume ranges and the fees charged when the total number of API calls is within a given range. The method used to calculate the final fee depends on the selected pricing model. For example, if the pricing model is `STAIRSTEP` and the ranges are defined as follows: ``` { "start": 1, "end": 100, "fee": 75 }, { "start": 101, "end": 200, "fee": 100 }, } ``` Then the following fees would be charged based on the total number of API calls (assuming the currency selected is `USD`): * 1 call costs $75 * 50 calls cost $75 * 150 calls cost $100 The number of API calls cannot exceed 200. — item shape: {end?: string, fee?: record, start?: string}
  --consumption-pricing-type: string@consumption-pricing-type-completer # Pricing model used for consumption-based charges.
  --currency-code: string # Currency to be used for billing. Consists of a three-letter code as defined by the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) standard.
  --description: string # Description of the rate plan.
  --display-name: string # Display name of the rate plan.
  --end-time: string # Time when the rate plan will expire in milliseconds since epoch. Set to 0 or `null` to indicate that the rate plan should never expire. (format: int64)
  --fixed-fee-frequency: int # Frequency at which the fixed fee is charged. (format: int32)
  --fixed-recurring-fee: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
  --payment-funding-model: string@payment-funding-model-completer # DEPRECATED: This field is no longer supported and will eventually be removed when Apigee Hybrid 1.5/1.6 is no longer supported. Instead, use the `billingType` field inside `DeveloperMonetizationConfig` resource. Flag that specifies the billing account type, prepaid or postpaid.
  --revenue-share-rates: list # Details of the revenue sharing model. — item shape: {end?: string, sharePercentage?: float, start?: string}
  --revenue-share-type: string@revenue-share-type-completer # Method used to calculate the revenue that is shared with developers.
  --setup-fee: record # Represents an amount of money with its currency type. — shape: {currencyCode?: string, nanos?: int, units?: string}
  --start-time: string # Time when the rate plan becomes active in milliseconds since epoch. (format: int64)
  --state: string@state-completer # Current state of the rate plan (draft or published).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/rateplans"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiproduct, var: apiproduct}, {name: billingPeriod, var: billing_period}, {name: consumptionPricingRates, var: consumption_pricing_rates}, {name: consumptionPricingType, var: consumption_pricing_type}, {name: currencyCode, var: currency_code}, {name: description, var: description}, {name: displayName, var: display_name}, {name: endTime, var: end_time}, {name: fixedFeeFrequency, var: fixed_fee_frequency}, {name: fixedRecurringFee, var: fixed_recurring_fee}, {name: paymentFundingModel, var: payment_funding_model}, {name: revenueShareRates, var: revenue_share_rates}, {name: revenueShareType, var: revenue_share_type}, {name: setupFee, var: setup_fee}, {name: startTime, var: start_time}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, apiproduct: $apiproduct, billing_period: $billing_period, consumption_pricing_rates: $consumption_pricing_rates, consumption_pricing_type: $consumption_pricing_type, currency_code: $currency_code, description: $description, display_name: $display_name, end_time: $end_time, fixed_fee_frequency: $fixed_fee_frequency, fixed_recurring_fee: $fixed_recurring_fee, payment_funding_model: $payment_funding_model, revenue_share_rates: $revenue_share_rates, revenue_share_type: $revenue_share_type, setup_fee: $setup_fee, start_time: $start_time, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Reference in the specified environment.
#
# POST /v1/{parent}/references
# Returns: record<description: string, name: string, refers: string, resourceType: string>
# operationId: apigee.organizations.environments.references.create
export def "apigee-organizations-environments-references-create" [
  parent: string
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
  --description: string # Optional. A human-readable description of this reference.
  --name: string # Required. The resource id of this reference. Values must match the regular expression [\w\s\-.]+.
  --refers: string # Required. The id of the resource to which this reference refers. Must be the id of a resource that exists in the parent environment and is of the given resource_type.
  --resource-type: string # The type of resource referred to by this reference. Valid values are 'KeyStore' or 'TrustStore'.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/references"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: refers, var: refers}, {name: resourceType, var: resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, name: $name, refers: $refers, resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of Custom Reports
#
# GET /v1/{parent}/reports
# Returns: record<qualifier: table<chartType: string, comments: list, createdAt: string, dimensions: list, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: list, name: string, offset: string, organization: string, properties: list, sortByCols: list, sortOrder: string, tags: list, timeUnit: string, toTime: string, topk: string>>
# operationId: apigee.organizations.reports.list
export def "apigee-organizations-reports-list" [
  parent: string
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
  --expand: oneof<nothing, bool> # Set to 'true' to get expanded details about each custom report.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/reports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: expand, var: expand}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Custom Report for an Organization. A Custom Report provides Apigee Customers to create custom dashboards in addition to the standard dashboards which are provided. The Custom Report in its simplest form contains specifications about metrics, dimensions and filters. It is important to note that the custom report by itself does not provide an executable entity. The Edge UI converts the custom report definition into an analytics query and displays the result in a chart.
#
# POST /v1/{parent}/reports
# Returns: record<chartType: string, comments: list<string>, createdAt: string, dimensions: list<string>, displayName: string, environment: string, filter: string, fromTime: string, lastModifiedAt: string, lastViewedAt: string, limit: string, metrics: table<function: string, name: string>, name: string, offset: string, organization: string, properties: table<property: string, value: list>, sortByCols: list<string>, sortOrder: string, tags: list<string>, timeUnit: string, toTime: string, topk: string>
# operationId: apigee.organizations.reports.create
export def "apigee-organizations-reports-create" [
  parent: string
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
  --chart-type: string # This field contains the chart type for the report
  --comments: list<string> # Legacy field: not used. This field contains a list of comments associated with custom report
  --dimensions: list<string> # This contains the list of dimensions for the report
  --display-name: string # This is the display name for the report
  --filter: string # This field contains the filter expression
  --from-time: string # Legacy field: not used. Contains the from time for the report
  --limit: string # Legacy field: not used This field contains the limit for the result retrieved
  --metrics: list # Required. This contains the list of metrics — item shape: {function?: string, name?: string}
  --name: string # Required. Unique identifier for the report T his is a legacy field used to encode custom report unique id
  --offset: string # Legacy field: not used. This field contains the offset for the data
  --properties: list # This field contains report properties such as ui metadata etc. — item shape: {property?: string, value?: list}
  --sort-by-cols: list<string> # Legacy field: not used much. Contains the list of sort by columns
  --sort-order: string # Legacy field: not used much. Contains the sort order for the sort columns
  --tags: list<string> # Legacy field: not used. This field contains a list of tags associated with custom report
  --time-unit: string # This field contains the time unit of aggregation for the report
  --to-time: string # Legacy field: not used. Contains the end time for the report
  --topk: string # Legacy field: not used. This field contains the top k parameter value for restricting the result
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/reports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: chartType, var: chart_type}, {name: comments, var: comments}, {name: dimensions, var: dimensions}, {name: displayName, var: display_name}, {name: filter, var: filter}, {name: fromTime, var: from_time}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: name, var: name}, {name: offset, var: offset}, {name: properties, var: properties}, {name: sortByCols, var: sort_by_cols}, {name: sortOrder, var: sort_order}, {name: tags, var: tags}, {name: timeUnit, var: time_unit}, {name: toTime, var: to_time}, {name: topk, var: topk}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, chart_type: $chart_type, comments: $comments, dimensions: $dimensions, display_name: $display_name, filter: $filter, from_time: $from_time, limit: $limit, metrics: $metrics, name: $name, offset: $offset, properties: $properties, sort_by_cols: $sort_by_cols, sort_order: $sort_order, tags: $tags, time_unit: $time_unit, to_time: $to_time, topk: $topk
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all resource files, optionally filtering by type. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# GET /v1/{parent}/resourcefiles
# Returns: record<resourceFile: table<name: string, type: string>>
# operationId: apigee.organizations.environments.resourcefiles.list
export def "apigee-organizations-environments-resourcefiles-list" [
  parent: string
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
  --type: string # Optional. Type of resource files to list. {{ resource_file_type }}
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/resourcefiles"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a resource file. Specify the `Content-Type` as `application/octet-stream` or `multipart/form-data`. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# POST /v1/{parent}/resourcefiles
# Returns: record<name: string, type: string>
# operationId: apigee.organizations.environments.resourcefiles.create
export def "apigee-organizations-environments-resourcefiles-create" [
  parent: string
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
  --name: string # Required. Name of the resource file. Must match the regular expression: [a-zA-Z0-9:/\\!@#$%^&{}\[\]()+\-=,.~'` ]{1,255}
  --type: string # Required. Resource file type. {{ resource_file_type }}
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/resourcefiles"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}, {name: type, var: type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, type: $type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all resource files, optionally filtering by type. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# GET /v1/{parent}/resourcefiles/{type}
# Returns: record<resourceFile: table<name: string, type: string>>
# operationId: apigee.organizations.environments.resourcefiles.listEnvironmentResources
export def "apigee-organizations-environments-resourcefiles-list-environment-resources" [
  parent: string
  type: string
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
    path: "/v1/{parent}/resourcefiles/{type}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource file. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# DELETE /v1/{parent}/resourcefiles/{type}/{name}
# Returns: record<name: string, type: string>
# operationId: apigee.organizations.environments.resourcefiles.delete
export def "apigee-organizations-environments-resourcefiles-delete" [
  parent: string
  type: string
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
    path: "/v1/{parent}/resourcefiles/{type}/{name}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}, {name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the contents of a resource file. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# GET /v1/{parent}/resourcefiles/{type}/{name}
# Returns: record<contentType: string, data: string, extensions: list<record>>
# operationId: apigee.organizations.environments.resourcefiles.get
export def "apigee-organizations-environments-resourcefiles-get" [
  parent: string
  type: string
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
    path: "/v1/{parent}/resourcefiles/{type}/{name}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}, {name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a resource file. Specify the `Content-Type` as `application/octet-stream` or `multipart/form-data`. For more information about resource files, see [Resource files](https://cloud.google.com/apigee/docs/api-platform/develop/resource-files).
#
# PUT /v1/{parent}/resourcefiles/{type}/{name}
# Returns: record<name: string, type: string>
# operationId: apigee.organizations.environments.resourcefiles.update
export def "apigee-organizations-environments-resourcefiles-update" [
  parent: string
  type: string
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
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{parent}/resourcefiles/{type}/{name}"
    path_params: [{name: parent, var: parent}, {name: type, var: type}, {name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, type: $type, name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSecurityIncidents lists all the security incident associated with the environment.
#
# GET /v1/{parent}/securityIncidents
# Returns: record<nextPageToken: string, securityIncidents: table<detectionTypes: list, displayName: string, firstDetectedTime: string, lastDetectedTime: string, name: string, riskLevel: string, trafficCount: string>>
# operationId: apigee.organizations.environments.securityIncidents.list
export def "apigee-organizations-environments-security-incidents-list" [
  parent: string
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
  --filter: string # The filter expression to be used to get the list of security incidents, where filtering can be done on API Proxies. Example: filter = "api_proxy = /", "first_detected_time >", "last_detected_time <"
  --page-size: int # The maximum number of incidents to return. The service may return fewer than this value. If unspecified, at most 50 incidents will be returned.
  --page-token: string # A page token, received from a previous `ListSecurityIncident` call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/securityIncidents"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ListSecurityProfiles lists all the security profiles associated with the org including attached and unattached profiles.
#
# GET /v1/{parent}/securityProfiles
# Returns: record<nextPageToken: string, securityProfiles: table<displayName: string, environments: list, maxScore: int, minScore: int, name: string, revisionCreateTime: string, revisionId: string, revisionPublishTime: string, revisionUpdateTime: string, scoringConfigs: list>>
# operationId: apigee.organizations.securityProfiles.list
export def "apigee-organizations-security-profiles-list" [
  parent: string
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
  --page-size: int # The maximum number of profiles to return. The service may return fewer than this value. If unspecified, at most 50 profiles will be returned.
  --page-token: string # A page token, received from a previous `ListSecurityProfiles` call. Provide this to retrieve the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/securityProfiles"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of Security Reports
#
# GET /v1/{parent}/securityReports
# Returns: record<nextPageToken: string, securityReports: table<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record, reportDefinitionId: string, result: record, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>>
# operationId: apigee.organizations.environments.securityReports.list
export def "apigee-organizations-environments-security-reports-list" [
  parent: string
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
  --dataset: string # Filter response list by dataset. Example: `api`, `mint`
  --from: string # Filter response list by returning security reports that created after this date time. Time must be in ISO date-time format like '2011-12-03T10:15:30Z'.
  --page-size: int # The maximum number of security report to return in the list response.
  --page-token: string # Token returned from the previous list response to fetch the next page.
  --status: string # Filter response list by security reports status.
  --submitted-by: string # Filter response list by user who submitted queries.
  --to: string # Filter response list by returning security reports that created before this date time. Time must be in ISO date-time format like '2011-12-03T10:16:30Z'.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/securityReports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataset, var: dataset}, {name: from, var: from}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: status, var: status}, {name: submittedBy, var: submitted_by}, {name: to, var: to}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, dataset: $dataset, from: $from, page_size: $page_size, page_token: $page_token, status: $status, submitted_by: $submitted_by, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a report request to be processed in the background. If the submission succeeds, the API returns a 200 status and an ID that refer to the report request. In addition to the HTTP status 200, the `state` of "enqueued" means that the request succeeded.
#
# POST /v1/{parent}/securityReports
# Returns: record<created: string, displayName: string, envgroupHostname: string, error: string, executionTime: string, queryParams: record<dimensions: list<string>, endTimestamp: string, metrics: list<string>, mimeType: string, startTimestamp: string, timeUnit: string>, reportDefinitionId: string, result: record<expires: string, self: string>, resultFileSize: string, resultRows: string, self: string, state: string, updated: string>
# operationId: apigee.organizations.environments.securityReports.create
export def "apigee-organizations-environments-security-reports-create" [
  parent: string
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
  --csv-delimiter: string # Delimiter used in the CSV file, if `outputFormat` is set to `csv`. Defaults to the `,` (comma) character. Supported delimiter characters include comma (`,`), pipe (`|`), and tab (`\t`).
  --dimensions: list<string> # A list of dimensions. https://docs.apigee.com/api-platform/analytics/analytics-reference#dimensions
  --display-name: string # Security Report display name which users can specify.
  --envgroup-hostname: string # Hostname needs to be specified if query intends to run at host level. This field is only allowed when query is submitted by CreateHostSecurityReport where analytics data will be grouped by organization and hostname.
  --filter: string # Boolean expression that can be used to filter data. Filter expressions can be combined using AND/OR terms and should be fully parenthesized to avoid ambiguity. See Analytics metrics, dimensions, and filters reference https://docs.apigee.com/api-platform/analytics/analytics-reference for more information on the fields available to filter on. For more information on the tokens that you use to build filter expressions, see Filter expression syntax. https://docs.apigee.com/api-platform/analytics/asynch-reports-api#filter-expression-syntax
  --group-by-time-unit: string # Time unit used to group the result set. Valid values include: second, minute, hour, day, week, or month. If a query includes groupByTimeUnit, then the result is an aggregation based on the specified time unit and the resultant timestamp does not include milliseconds precision. If a query omits groupByTimeUnit, then the resultant timestamp includes milliseconds precision.
  --limit: int # Maximum number of rows that can be returned in the result. (format: int32)
  --metrics: list # A list of Metrics. — item shape: {aggregationFunction?: string, alias?: string, name?: string, operator?: string, value?: string}
  --mime-type: string # Valid values include: `csv` or `json`. Defaults to `json`. Note: Configure the delimiter for CSV output using the csvDelimiter property.
  --report-definition-id: string # Report Definition ID.
  --time-range: any # Required. Time range for the query. Can use the following predefined strings to specify the time range: `last60minutes` `last24hours` `last7days` Or, specify the timeRange as a structure describing start and end timestamps in the ISO format: yyyy-mm-ddThh:mm:ssZ. Example: "timeRange": { "start": "2018-07-29T00:13:00Z", "end": "2018-08-01T00:18:00Z" }
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/securityReports"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: csvDelimiter, var: csv_delimiter}, {name: dimensions, var: dimensions}, {name: displayName, var: display_name}, {name: envgroupHostname, var: envgroup_hostname}, {name: filter, var: filter}, {name: groupByTimeUnit, var: group_by_time_unit}, {name: limit, var: limit}, {name: metrics, var: metrics}, {name: mimeType, var: mime_type}, {name: reportDefinitionId, var: report_definition_id}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, csv_delimiter: $csv_delimiter, dimensions: $dimensions, display_name: $display_name, envgroup_hostname: $envgroup_hostname, filter: $filter, group_by_time_unit: $group_by_time_unit, limit: $limit, metrics: $metrics, mime_type: $mime_type, report_definition_id: $report_definition_id, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all shared flows in the organization.
#
# GET /v1/{parent}/sharedflows
# Returns: record<sharedFlows: table<latestRevisionId: string, metaData: record, name: string, revision: list>>
# operationId: apigee.organizations.sharedflows.list
export def "apigee-organizations-sharedflows-list" [
  parent: string
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
  --include-meta-data: oneof<nothing, bool> # Indicates whether to include shared flow metadata in the response.
  --include-revisions: oneof<nothing, bool> # Indicates whether to include a list of revisions in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/sharedflows"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeMetaData, var: include_meta_data}, {name: includeRevisions, var: include_revisions}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_meta_data: $include_meta_data, include_revisions: $include_revisions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads a ZIP-formatted shared flow configuration bundle to an organization. If the shared flow already exists, this creates a new revision of it. If the shared flow does not exist, this creates it. Once imported, the shared flow revision must be deployed before it can be accessed at runtime. The size limit of a shared flow bundle is 15 MB.
#
# POST /v1/{parent}/sharedflows
# Returns: record<configurationVersion: record<majorVersion: int, minorVersion: int>, contextInfo: string, createdAt: string, description: string, displayName: string, entityMetaDataAsProperties: record, lastModifiedAt: string, name: string, policies: list<string>, resourceFiles: record<resourceFile: list<record>>, resources: list<string>, revision: string, sharedFlows: list<string>, type: string>
# operationId: apigee.organizations.sharedflows.create
export def "apigee-organizations-sharedflows-create" [
  parent: string
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
  --action: string # Required. Must be set to either `import` or `validate`.
  --name: string # Required. The name to give the shared flow
  --content-type: string # The HTTP Content-Type header value specifying the content type of the body.
  --data: string # The HTTP request/response body as raw binary. (format: byte)
  --extensions: list # Application specific response metadata. Must be set in the first response for streaming APIs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/sharedflows"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: action, var: action}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: contentType, var: content_type}, {name: data, var: data}, {name: extensions, var: extensions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, name: $name, content_type: $content_type, data: $data, extensions: $extensions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all API product subscriptions for a developer.
#
# GET /v1/{parent}/subscriptions
# Returns: record<developerSubscriptions: table<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>, nextStartKey: string>
# operationId: apigee.organizations.developers.subscriptions.list
export def "apigee-organizations-developers-subscriptions-list" [
  parent: string
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
  --count: int # Number of API product subscriptions to return in the API call. Use with `startKey` to provide more targeted filtering. Defaults to 100. The maximum limit is 1000.
  --start-key: string # Name of the API product subscription from which to start displaying the list of subscriptions. If omitted, the list starts from the first item. For example, to view the API product subscriptions from 51-150, set the value of `startKey` to the name of the 51st subscription and set the value of `count` to 100.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/subscriptions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: count, var: count}, {name: startKey, var: start_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, count: $count, start_key: $start_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a subscription to an API product.
#
# POST /v1/{parent}/subscriptions
# Returns: record<apiproduct: string, createdAt: string, endTime: string, lastModifiedAt: string, name: string, startTime: string>
# operationId: apigee.organizations.developers.subscriptions.create
export def "apigee-organizations-developers-subscriptions-create" [
  parent: string
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
  --apiproduct: string # Name of the API product for which the developer is purchasing a subscription.
  --end-time: string # Time when the API product subscription ends in milliseconds since epoch. (format: int64)
  --start-time: string # Time when the API product subscription starts in milliseconds since epoch. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/subscriptions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiproduct, var: apiproduct}, {name: endTime, var: end_time}, {name: startTime, var: start_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, apiproduct: $apiproduct, end_time: $end_time, start_time: $start_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a TargetServer in the specified environment.
#
# POST /v1/{parent}/targetservers
# Returns: record<description: string, host: string, isEnabled: bool, name: string, port: int, protocol: string, sSLInfo: record<ciphers: list<string>, clientAuthEnabled: bool, commonName: record<value: string, wildcardMatch: bool>, enabled: bool, ignoreValidationErrors: bool, keyAlias: string, keyStore: string, protocols: list<string>, trustStore: string>>
# operationId: apigee.organizations.environments.targetservers.create
export def "apigee-organizations-environments-targetservers-create" [
  parent: string
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
  --name: string # Optional. The ID to give the TargetServer. This will overwrite the value in TargetServer.
  --description: string # Optional. A human-readable description of this TargetServer.
  --host: string # Required. The host name this target connects to. Value must be a valid hostname as described by RFC-1123.
  --is-enabled: oneof<nothing, bool> # Optional. Enabling/disabling a TargetServer is useful when TargetServers are used in load balancing configurations, and one or more TargetServers need to taken out of rotation periodically. Defaults to true.
  --body-name: string # Required. The resource id of this target server. Values must match the regular expression (spec name: name)
  --port: int # Required. The port number this target connects to on the given host. Value must be between 1 and 65535, inclusive. (format: int32)
  --protocol: string@protocol-completer # Immutable. The protocol used by this TargetServer.
  --s-sl-info: record # TLS configuration information for virtual hosts and TargetServers. — shape: {ciphers?: list<string>, clientAuthEnabled?: bool, commonName?: record, enabled?: bool, ignoreValidationErrors?: bool, keyAlias?: string, keyStore?: string, protocols?: list<string>, trustStore?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/targetservers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: host, var: host}, {name: isEnabled, var: is_enabled}, {name: name, var: body_name}, {name: port, var: port}, {name: protocol, var: protocol}, {name: sSLInfo, var: s_sl_info}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, description: $description, host: $host, is_enabled: $is_enabled, body_name: $body_name, port: $port, protocol: $protocol, s_sl_info: $s_sl_info
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a subscription for the environment's Pub/Sub topic. The server will assign a random name for this subscription. The "name" and "push_config" must *not* be specified.
#
# POST /v1/{parent}:subscribe
# Returns: record<name: string>
# operationId: apigee.organizations.environments.subscribe
export def "apigee-organizations-environments-subscribe" [
  parent: string
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
    path: "/v1/{parent}:subscribe"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subscription for the environment's Pub/Sub topic.
#
# POST /v1/{parent}:unsubscribe
# Returns: record
# operationId: apigee.organizations.environments.unsubscribe
export def "apigee-organizations-environments-unsubscribe" [
  parent: string
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
  --name: string # Full name of the Pub/Sub subcription. Use the following structure in your request: `subscription "projects/foo/subscription/bar"`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}:unsubscribe"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# ComputeEnvironmentScores calculates scores for requested time range for the specified security profile and environment.
#
# POST /v1/{profileEnvironment}:computeEnvironmentScores
# Returns: record<nextPageToken: string, scores: table<component: record, subcomponents: list, timeRange: record>>
# operationId: apigee.organizations.securityProfiles.environments.computeEnvironmentScores
export def "apigee-organizations-security-profiles-environments-compute-environment-scores" [
  profile_environment: string
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
  --filters: list # Optional. Filters are used to filter scored components. Return all the components if no filter is mentioned. Example: [{ "scorePath": "/org@myorg/envgroup@myenvgroup/env@myenv/proxies/proxy@myproxy/source" }, { "scorePath": "/org@myorg/envgroup@myenvgroup/env@myenv/proxies/proxy@myproxy/target", }] This will return components with path: "/org@myorg/envgroup@myenvgroup/env@myenv/proxies/proxy@myproxy/source" OR "/org@myorg/envgroup@myenvgroup/env@myenv/proxies/proxy@myproxy/target" — item shape: {scorePath?: string}
  --page-size: int # Optional. The maximum number of subcomponents to be returned in a single page. The service may return fewer than this value. If unspecified, at most 100 subcomponents will be returned in a single page. (format: int32)
  --page-token: string # Optional. A token that can be sent as `page_token` to retrieve the next page. If this field is omitted, there are no subsequent pages.
  --time-range: record # Represents a time interval, encoded as a Timestamp start (inclusive) and a Timestamp end (exclusive). The start must be less than or equal to the end. When the start equals the end, the interval is empty (matches no time). When both start and end are unspecified, the interval matches any time. — shape: {endTime?: string, startTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{profileEnvironment}:computeEnvironmentScores"
    path_params: [{name: profileEnvironment, var: profile_environment}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: timeRange, var: time_range}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    profile_environment: $profile_environment, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filters: $filters, page_size: $page_size, page_token: $page_token, time_range: $time_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provisions a new Apigee organization with a functioning runtime. This is the standard way to create trial organizations for a free Apigee trial.
#
# POST /v1/{project}:provisionOrganization
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: apigee.projects.provisionOrganization
export def "apigee-projects-provision-organization" [
  project: string
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
  --analytics-region: string # Primary Cloud Platform region for analytics data storage. For valid values, see [Create an organization](https://cloud.google.com/apigee/docs/hybrid/latest/precog-provision). Defaults to `us-west1`.
  --authorized-network: string # Compute Engine network used for Service Networking to be peered with Apigee runtime instances. See [Getting started with the Service Networking API](https://cloud.google.com/service-infrastructure/docs/service-networking/getting-started). Apigee also supports shared VPC (that is, the host network project is not the same as the one that is peering with Apigee). See [Shared VPC overview](https://cloud.google.com/vpc/docs/shared-vpc). To use a shared VPC network, use the following format: `projects/{host-project-id}/{region}/networks/{network-name}`. For example: `projects/my-sharedvpc-host/global/networks/mynetwork`
  --runtime-location: string # Cloud Platform location for the runtime instance. Defaults to zone `us-west1-a`. If a region is provided, `EVAL` organizations will use the region for automatically selecting a zone for the runtime instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{project}:provisionOrganization"
    path_params: [{name: project, var: project}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: analyticsRegion, var: analytics_region}, {name: authorizedNetwork, var: authorized_network}, {name: runtimeLocation, var: runtime_location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project: $project, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, analytics_region: $analytics_region, authorized_network: $authorized_network, runtime_location: $runtime_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the IAM policy on an environment. For more information, see [Manage users, roles, and permissions using the API](https://cloud.google.com/apigee/docs/api-platform/system-administration/manage-users-roles). You must have the `apigee.environments.getIamPolicy` permission to call this API.
#
# GET /v1/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: apigee.organizations.environments.getIamPolicy
export def "apigee-organizations-environments-get-iam-policy" [
  resource: string
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
  --options-requested-policy-version: int # Optional. The maximum policy version that will be used to format the policy. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional role bindings must specify version 3. Policies with no conditional role bindings may specify any valid value or leave the field unset. The policy in the response might use the policy version that you specified, or it might use a lower policy version. For example, if you specify version 3, but the policy has no conditional role bindings, the response uses version 1. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: "options.requestedPolicyVersion", var: options_requested_policy_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, options_requested_policy_version: $options_requested_policy_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the IAM policy on an environment, if the policy already exists it will be replaced. For more information, see [Manage users, roles, and permissions using the API](https://cloud.google.com/apigee/docs/api-platform/system-administration/manage-users-roles). You must have the `apigee.environments.setIamPolicy` permission to call this API.
#
# POST /v1/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: apigee.organizations.environments.setIamPolicy
export def "apigee-organizations-environments-set-iam-policy" [
  resource: string
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, policy: $policy, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests the permissions of a user on an environment, and returns a subset of permissions that the user has on the environment. If the environment does not exist, an empty permission set is returned (a NOT_FOUND error is not returned).
#
# POST /v1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: apigee.organizations.environments.testIamPermissions
export def "apigee-organizations-environments-test-iam-permissions" [
  resource: string
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
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
