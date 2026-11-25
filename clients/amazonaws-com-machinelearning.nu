# Auto-generated client for Amazon Machine Learning v2014-12-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/machinelearning/2014-12-12/openapi.json
# Auth: --token flag or $env.AMAZON_MACHINE_LEARNING_TOKEN

const CLIENT = {
  base_url: "http://machinelearning.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_MACHINE_LEARNING_TOKEN"
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

def base-url-completer [] { ["http://machinelearning.us-east-1.amazonaws.com" "http://machinelearning.us-east-2.amazonaws.com" "http://machinelearning.us-west-1.amazonaws.com" "http://machinelearning.us-west-2.amazonaws.com" "http://machinelearning.us-gov-west-1.amazonaws.com" "http://machinelearning.us-gov-east-1.amazonaws.com" "http://machinelearning.ca-central-1.amazonaws.com" "http://machinelearning.eu-north-1.amazonaws.com" "http://machinelearning.eu-west-1.amazonaws.com" "http://machinelearning.eu-west-2.amazonaws.com" "http://machinelearning.eu-west-3.amazonaws.com" "http://machinelearning.eu-central-1.amazonaws.com" "http://machinelearning.eu-south-1.amazonaws.com" "http://machinelearning.af-south-1.amazonaws.com" "http://machinelearning.ap-northeast-1.amazonaws.com" "http://machinelearning.ap-northeast-2.amazonaws.com" "http://machinelearning.ap-northeast-3.amazonaws.com" "http://machinelearning.ap-southeast-1.amazonaws.com" "http://machinelearning.ap-southeast-2.amazonaws.com" "http://machinelearning.ap-east-1.amazonaws.com" "http://machinelearning.ap-south-1.amazonaws.com" "http://machinelearning.sa-east-1.amazonaws.com" "http://machinelearning.me-south-1.amazonaws.com" "https://machinelearning.us-east-1.amazonaws.com" "https://machinelearning.us-east-2.amazonaws.com" "https://machinelearning.us-west-1.amazonaws.com" "https://machinelearning.us-west-2.amazonaws.com" "https://machinelearning.us-gov-west-1.amazonaws.com" "https://machinelearning.us-gov-east-1.amazonaws.com" "https://machinelearning.ca-central-1.amazonaws.com" "https://machinelearning.eu-north-1.amazonaws.com" "https://machinelearning.eu-west-1.amazonaws.com" "https://machinelearning.eu-west-2.amazonaws.com" "https://machinelearning.eu-west-3.amazonaws.com" "https://machinelearning.eu-central-1.amazonaws.com" "https://machinelearning.eu-south-1.amazonaws.com" "https://machinelearning.af-south-1.amazonaws.com" "https://machinelearning.ap-northeast-1.amazonaws.com" "https://machinelearning.ap-northeast-2.amazonaws.com" "https://machinelearning.ap-northeast-3.amazonaws.com" "https://machinelearning.ap-southeast-1.amazonaws.com" "https://machinelearning.ap-southeast-2.amazonaws.com" "https://machinelearning.ap-east-1.amazonaws.com" "https://machinelearning.ap-south-1.amazonaws.com" "https://machinelearning.sa-east-1.amazonaws.com" "https://machinelearning.me-south-1.amazonaws.com" "http://machinelearning.cn-north-1.amazonaws.com.cn" "http://machinelearning.cn-northwest-1.amazonaws.com.cn" "https://machinelearning.cn-north-1.amazonaws.com.cn" "https://machinelearning.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["BatchPrediction" "DataSource" "Evaluation" "MLModel"] }
def x-amz-target-completer [] { ["AmazonML_20141212.AddTags"] }
def x-amz-target-completer-1 [] { ["AmazonML_20141212.CreateBatchPrediction"] }
def x-amz-target-completer-2 [] { ["AmazonML_20141212.CreateDataSourceFromRDS"] }
def x-amz-target-completer-3 [] { ["AmazonML_20141212.CreateDataSourceFromRedshift"] }
def x-amz-target-completer-4 [] { ["AmazonML_20141212.CreateDataSourceFromS3"] }
def x-amz-target-completer-5 [] { ["AmazonML_20141212.CreateEvaluation"] }
def ml-model-type-completer [] { ["BINARY" "MULTICLASS" "REGRESSION"] }
def x-amz-target-completer-6 [] { ["AmazonML_20141212.CreateMLModel"] }
def x-amz-target-completer-7 [] { ["AmazonML_20141212.CreateRealtimeEndpoint"] }
def x-amz-target-completer-8 [] { ["AmazonML_20141212.DeleteBatchPrediction"] }
def x-amz-target-completer-9 [] { ["AmazonML_20141212.DeleteDataSource"] }
def x-amz-target-completer-10 [] { ["AmazonML_20141212.DeleteEvaluation"] }
def x-amz-target-completer-11 [] { ["AmazonML_20141212.DeleteMLModel"] }
def x-amz-target-completer-12 [] { ["AmazonML_20141212.DeleteRealtimeEndpoint"] }
def x-amz-target-completer-13 [] { ["AmazonML_20141212.DeleteTags"] }
def filter-variable-completer [] { ["CreatedAt" "DataSourceId" "DataURI" "IAMUser" "LastUpdatedAt" "MLModelId" "Name" "Status"] }
def sort-order-completer [] { ["asc" "dsc"] }
def x-amz-target-completer-14 [] { ["AmazonML_20141212.DescribeBatchPredictions"] }
def filter-variable-completer-1 [] { ["CreatedAt" "DataLocationS3" "IAMUser" "LastUpdatedAt" "Name" "Status"] }
def x-amz-target-completer-15 [] { ["AmazonML_20141212.DescribeDataSources"] }
def x-amz-target-completer-16 [] { ["AmazonML_20141212.DescribeEvaluations"] }
def filter-variable-completer-2 [] { ["Algorithm" "CreatedAt" "IAMUser" "LastUpdatedAt" "MLModelType" "Name" "RealtimeEndpointStatus" "Status" "TrainingDataSourceId" "TrainingDataURI"] }
def x-amz-target-completer-17 [] { ["AmazonML_20141212.DescribeMLModels"] }
def x-amz-target-completer-18 [] { ["AmazonML_20141212.DescribeTags"] }
def x-amz-target-completer-19 [] { ["AmazonML_20141212.GetBatchPrediction"] }
def x-amz-target-completer-20 [] { ["AmazonML_20141212.GetDataSource"] }
def x-amz-target-completer-21 [] { ["AmazonML_20141212.GetEvaluation"] }
def x-amz-target-completer-22 [] { ["AmazonML_20141212.GetMLModel"] }
def x-amz-target-completer-23 [] { ["AmazonML_20141212.Predict"] }
def x-amz-target-completer-24 [] { ["AmazonML_20141212.UpdateBatchPrediction"] }
def x-amz-target-completer-25 [] { ["AmazonML_20141212.UpdateDataSource"] }
def x-amz-target-completer-26 [] { ["AmazonML_20141212.UpdateEvaluation"] }
def x-amz-target-completer-27 [] { ["AmazonML_20141212.UpdateMLModel"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-tags: "record<ResourceId: string, ResourceType: string>"
    create-batch-prediction: "record<BatchPredictionId: string>"
    create-data-source-from-rds: "record<DataSourceId: string>"
    create-data-source-from-redshift: "record<DataSourceId: string>"
    create-data-source-from-s3: "record<DataSourceId: string>"
    create-evaluation: "record<EvaluationId: string>"
    create-ml-model: "record<MLModelId: string>"
    create-realtime-endpoint: "record<MLModelId: string, RealtimeEndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>>"
    delete-batch-prediction: "record<BatchPredictionId: string>"
    delete-data-source: "record<DataSourceId: string>"
    delete-evaluation: "record<EvaluationId: string>"
    delete-ml-model: "record<MLModelId: string>"
    delete-realtime-endpoint: "record<MLModelId: string, RealtimeEndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>>"
    delete-tags: "record<ResourceId: string, ResourceType: string>"
    describe-batch-predictions: "record<Results: table<BatchPredictionId: string, MLModelId: string, BatchPredictionDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, OutputUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, TotalRecordCount: int, InvalidRecordCount: int>, NextToken: string>"
    describe-data-sources: "record<Results: table<DataSourceId: string, DataLocationS3: string, DataRearrangement: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, DataSizeInBytes: int, NumberOfFiles: int, Name: string, Status: string, Message: string, RedshiftMetadata: record, RDSMetadata: record, RoleARN: string, ComputeStatistics: bool, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>"
    describe-evaluations: "record<Results: table<EvaluationId: string, MLModelId: string, EvaluationDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, PerformanceMetrics: record, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>"
    describe-ml-models: "record<Results: table<MLModelId: string, TrainingDataSourceId: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, SizeInBytes: int, EndpointInfo: record, TrainingParameters: record, InputDataLocationS3: string, Algorithm: string, MLModelType: string, ScoreThreshold: float, ScoreThresholdLastUpdatedAt: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>"
    describe-tags: "record<ResourceId: string, ResourceType: string, Tags: table<Key: string, Value: string>>"
    get-batch-prediction: "record<BatchPredictionId: string, MLModelId: string, BatchPredictionDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, OutputUri: string, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, TotalRecordCount: int, InvalidRecordCount: int>"
    get-data-source: "record<DataSourceId: string, DataLocationS3: string, DataRearrangement: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, DataSizeInBytes: int, NumberOfFiles: int, Name: string, Status: string, LogUri: string, Message: string, RedshiftMetadata: record<RedshiftDatabase: record<DatabaseName: string, ClusterIdentifier: string>, DatabaseUserName: string, SelectSqlQuery: string>, RDSMetadata: record<Database: record<InstanceIdentifier: string, DatabaseName: string>, DatabaseUserName: string, SelectSqlQuery: string, ResourceRole: string, ServiceRole: string, DataPipelineId: string>, RoleARN: string, ComputeStatistics: bool, ComputeTime: int, FinishedAt: string, StartedAt: string, DataSourceSchema: string>"
    get-evaluation: "record<EvaluationId: string, MLModelId: string, EvaluationDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, PerformanceMetrics: record<Properties: record>, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>"
    get-ml-model: "record<MLModelId: string, TrainingDataSourceId: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, SizeInBytes: int, EndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>, TrainingParameters: record, InputDataLocationS3: string, MLModelType: string, ScoreThreshold: float, ScoreThresholdLastUpdatedAt: string, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, Recipe: string, Schema: string>"
    predict: "record<Prediction: record<predictedLabel: string, predictedValue: float, predictedScores: record, details: record>>"
    update-batch-prediction: "record<BatchPredictionId: string>"
    update-data-source: "record<DataSourceId: string>"
    update-evaluation: "record<EvaluationId: string>"
    update-ml-model: "record<MLModelId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags" "create-batch-prediction" "create-data-source-from-rds" "create-data-source-from-redshift" "create-data-source-from-s3" "create-evaluation" "create-ml-model" "create-realtime-endpoint" "delete-batch-prediction" "delete-data-source" "delete-evaluation" "delete-ml-model" "delete-realtime-endpoint" "delete-tags" "describe-batch-predictions" "describe-data-sources" "describe-evaluations" "describe-ml-models" "describe-tags" "get-batch-prediction" "get-data-source" "get-evaluation" "get-ml-model" "predict" "update-batch-prediction" "update-data-source" "update-evaluation" "update-ml-model" "commands"] | sort) } | get name | first)
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

# Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, AddTags updates the tag's value.
#
# POST /
# Returns: record<ResourceId: string, ResourceType: string>
# operationId: AddTags
export def "add-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  tags: list # The key-value pairs to use to create tags. If you specify a key without specifying a value, Amazon ML creates a tag with the specified key and a value of null. — item shape: {Key?: string, Value?: string}
  resource_id: string # The ID of the ML object to tag. For example, exampleModelId.
  resource_type: string@resource-type-completer # The type of the ML object to tag.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.AddTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}, {name: ResourceId, var: resource_id}, {name: ResourceType, var: resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tags: $tags, resource_id: $resource_id, resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a DataSource. This operation creates a new BatchPrediction, and uses an MLModel and the data files referenced by the DataSource as information sources. CreateBatchPrediction is an asynchronous operation. In response to CreateBatchPrediction, Amazon Machine Learning (Amazon ML) immediately returns and sets the BatchPrediction status to PENDING. After the BatchPrediction completes, Amazon ML sets the status to COMPLETED. You can poll for status updates by using the GetBatchPrediction operation and checking the Status parameter of the result. After the COMPLETED status appears, the results are available in the location specified by the OutputUri parameter.
#
# POST /
# Returns: record<BatchPredictionId: string>
# operationId: CreateBatchPrediction
export def "create-batch-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  batch_prediction_id: string # A user-supplied ID that uniquely identifies the BatchPrediction.
  --batch-prediction-name: string # A user-supplied name or description of the Amazon ML resource.
  ml_model_id: string # The ID of the MLModel that will generate predictions for the group of observations.
  batch_prediction_data_source_id: string # The ID of the DataSource that points to the group of observations to predict.
  output_uri: string # A reference to a file or bucket on Amazon Simple Storage Service (Amazon S3).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateBatchPrediction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchPredictionId, var: batch_prediction_id}, {name: BatchPredictionName, var: batch_prediction_name}, {name: MLModelId, var: ml_model_id}, {name: BatchPredictionDataSourceId, var: batch_prediction_data_source_id}, {name: OutputUri, var: output_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_prediction_id: $batch_prediction_id, batch_prediction_name: $batch_prediction_name, ml_model_id: $ml_model_id, batch_prediction_data_source_id: $batch_prediction_data_source_id, output_uri: $output_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a DataSource object from an Amazon Relational Database Service (http://aws.amazon.com/rds/) (Amazon RDS). A DataSource references data that can be used to perform CreateMLModel, CreateEvaluation, or CreateBatchPrediction operations. CreateDataSourceFromRDS is an asynchronous operation. In response to CreateDataSourceFromRDS, Amazon Machine Learning (Amazon ML) immediately returns and sets the DataSource status to PENDING. After the DataSource is created and ready for use, Amazon ML sets the Status parameter to COMPLETED. DataSource in the COMPLETED or PENDING state can be used only to perform >CreateMLModel>, CreateEvaluation, or CreateBatchPrediction operations. If Amazon ML cannot accept the input source, it sets the Status parameter to FAILED and includes an error message in the Message attribute of the GetDataSource operation response.
#
# POST /
# Returns: record<DataSourceId: string>
# operationId: CreateDataSourceFromRDS
export def "create-data-source-from-rds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  data_source_id: string # A user-supplied ID that uniquely identifies the DataSource. Typically, an Amazon Resource Number (ARN) becomes the ID for a DataSource.
  --data-source-name: string # A user-supplied name or description of the Amazon ML resource.
  rds_data: record # The data specification of an Amazon Relational Database Service (Amazon RDS) DataSource. — shape: {DatabaseInformation: record, SelectSqlQuery: string, DatabaseCredentials: record, S3StagingLocation: string, DataRearrangement?: string, DataSchema?: string, DataSchemaUri?: string, ResourceRole: string, ServiceRole: string, SubnetId: string, SecurityGroupIds: list<string>}
  role_arn: string # The Amazon Resource Name (ARN) of an AWS IAM Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/roles-toplevel.html#roles-about-termsandconcepts), such as the following: arn:aws:iam::account:role/rolename.
  --compute-statistics: oneof<nothing, bool> # The compute statistics for a DataSource. The statistics are generated from the observation data referenced by a DataSource. Amazon ML uses the statistics internally during MLModel training. This parameter must be set to true if the DataSource needs to be used for MLModel training.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateDataSourceFromRDS"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: DataSourceName, var: data_source_name}, {name: RDSData, var: rds_data}, {name: RoleARN, var: role_arn}, {name: ComputeStatistics, var: compute_statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id, data_source_name: $data_source_name, rds_data: $rds_data, role_arn: $role_arn, compute_statistics: $compute_statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a DataSource from a database hosted on an Amazon Redshift cluster. A DataSource references data that can be used to perform either CreateMLModel, CreateEvaluation, or CreateBatchPrediction operations. CreateDataSourceFromRedshift is an asynchronous operation. In response to CreateDataSourceFromRedshift, Amazon Machine Learning (Amazon ML) immediately returns and sets the DataSource status to PENDING. After the DataSource is created and ready for use, Amazon ML sets the Status parameter to COMPLETED. DataSource in COMPLETED or PENDING states can be used to perform only CreateMLModel, CreateEvaluation, or CreateBatchPrediction operations. If Amazon ML can't accept the input source, it sets the Status parameter to FAILED and includes an error message in the Message attribute of the GetDataSource operation response. The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a SelectSqlQuery query. Amazon ML executes an Unload command in Amazon Redshift to transfer the result set of the SelectSqlQuery query to S3StagingLocation. After the DataSource has been created, it's ready for use in evaluations and batch predictions. If you plan to use the DataSource to train an MLModel, the DataSource also requires a recipe. A recipe describes how each input variable will be used in training an MLModel. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions. You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call GetDataSource for an existing datasource and copy the values to a CreateDataSource call. Change the settings that you want to change and make sure that all required fields have the appropriate values.
#
# POST /
# Returns: record<DataSourceId: string>
# operationId: CreateDataSourceFromRedshift
export def "create-data-source-from-redshift" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  data_source_id: string # A user-supplied ID that uniquely identifies the DataSource.
  --data-source-name: string # A user-supplied name or description of the Amazon ML resource.
  data_spec: record # Describes the data specification of an Amazon Redshift DataSource. — shape: {DatabaseInformation: record, SelectSqlQuery: string, DatabaseCredentials: record, S3StagingLocation: string, DataRearrangement?: string, DataSchema?: string, DataSchemaUri?: string}
  role_arn: string # The Amazon Resource Name (ARN) of an AWS IAM Role (https://docs.aws.amazon.com/IAM/latest/UserGuide/roles-toplevel.html#roles-about-termsandconcepts), such as the following: arn:aws:iam::account:role/rolename.
  --compute-statistics: oneof<nothing, bool> # The compute statistics for a DataSource. The statistics are generated from the observation data referenced by a DataSource. Amazon ML uses the statistics internally during MLModel training. This parameter must be set to true if the DataSource needs to be used for MLModel training.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateDataSourceFromRedshift"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: DataSourceName, var: data_source_name}, {name: DataSpec, var: data_spec}, {name: RoleARN, var: role_arn}, {name: ComputeStatistics, var: compute_statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id, data_source_name: $data_source_name, data_spec: $data_spec, role_arn: $role_arn, compute_statistics: $compute_statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a DataSource object. A DataSource references data that can be used to perform CreateMLModel, CreateEvaluation, or CreateBatchPrediction operations. CreateDataSourceFromS3 is an asynchronous operation. In response to CreateDataSourceFromS3, Amazon Machine Learning (Amazon ML) immediately returns and sets the DataSource status to PENDING. After the DataSource has been created and is ready for use, Amazon ML sets the Status parameter to COMPLETED. DataSource in the COMPLETED or PENDING state can be used to perform only CreateMLModel, CreateEvaluation or CreateBatchPrediction operations. If Amazon ML can't accept the input source, it sets the Status parameter to FAILED and includes an error message in the Message attribute of the GetDataSource operation response. The observation data used in a DataSource should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the DataSource. After the DataSource has been created, it's ready to use in evaluations and batch predictions. If you plan to use the DataSource to train an MLModel, the DataSource also needs a recipe. A recipe describes how each input variable will be used in training an MLModel. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.
#
# POST /
# Returns: record<DataSourceId: string>
# operationId: CreateDataSourceFromS3
export def "create-data-source-from-s3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  data_source_id: string # A user-supplied identifier that uniquely identifies the DataSource.
  --data-source-name: string # A user-supplied name or description of the Amazon ML resource.
  data_spec: record # Describes the data specification of a DataSource. — shape: {DataLocationS3: string, DataRearrangement?: string, DataSchema?: string, DataSchemaLocationS3?: string}
  --compute-statistics: oneof<nothing, bool> # The compute statistics for a DataSource. The statistics are generated from the observation data referenced by a DataSource. Amazon ML uses the statistics internally during MLModel training. This parameter must be set to true if the DataSource needs to be used for MLModel training.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateDataSourceFromS3"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: DataSourceName, var: data_source_name}, {name: DataSpec, var: data_spec}, {name: ComputeStatistics, var: compute_statistics}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id, data_source_name: $data_source_name, data_spec: $data_spec, compute_statistics: $compute_statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Evaluation of an MLModel. An MLModel is evaluated on a set of observations associated to a DataSource. Like a DataSource for an MLModel, the DataSource for an Evaluation contains values for the Target Variable. The Evaluation compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the MLModel functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding MLModelType: BINARY, REGRESSION or MULTICLASS. CreateEvaluation is an asynchronous operation. In response to CreateEvaluation, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to PENDING. After the Evaluation is created and ready for use, Amazon ML sets the status to COMPLETED. You can use the GetEvaluation operation to check progress of the evaluation during the creation operation.
#
# POST /
# Returns: record<EvaluationId: string>
# operationId: CreateEvaluation
export def "create-evaluation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  evaluation_id: string # A user-supplied ID that uniquely identifies the Evaluation.
  --evaluation-name: string # A user-supplied name or description of the Amazon ML resource.
  ml_model_id: string # The ID of the MLModel to evaluate. The schema used in creating the MLModel must match the schema of the DataSource used in the Evaluation.
  evaluation_data_source_id: string # The ID of the DataSource for the evaluation. The schema of the DataSource must match the schema used to create the MLModel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateEvaluation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EvaluationId, var: evaluation_id}, {name: EvaluationName, var: evaluation_name}, {name: MLModelId, var: ml_model_id}, {name: EvaluationDataSourceId, var: evaluation_data_source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, evaluation_id: $evaluation_id, evaluation_name: $evaluation_name, ml_model_id: $ml_model_id, evaluation_data_source_id: $evaluation_data_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new MLModel using the DataSource and the recipe as information sources. An MLModel is nearly immutable. Users can update only the MLModelName and the ScoreThreshold in an MLModel without creating a new MLModel. CreateMLModel is an asynchronous operation. In response to CreateMLModel, Amazon Machine Learning (Amazon ML) immediately returns and sets the MLModel status to PENDING. After the MLModel has been created and ready is for use, Amazon ML sets the status to COMPLETED. You can use the GetMLModel operation to check the progress of the MLModel during the creation operation. CreateMLModel requires a DataSource with computed statistics, which can be created by setting ComputeStatistics to true in CreateDataSourceFromRDS, CreateDataSourceFromS3, or CreateDataSourceFromRedshift operations.
#
# POST /
# Returns: record<MLModelId: string>
# operationId: CreateMLModel
export def "create-ml-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  ml_model_id: string # A user-supplied ID that uniquely identifies the MLModel.
  --ml-model-name: string # A user-supplied name or description of the Amazon ML resource.
  ml_model_type: string@ml-model-type-completer # The category of supervised learning that this MLModel will address. Choose from the following types: Choose REGRESSION if the MLModel will be used to predict a numeric value. Choose BINARY if the MLModel result has two possible values. Choose MULTICLASS if the MLModel result has a limited number of values. For more information, see the Amazon Machine Learning Developer Guide (https://docs.aws.amazon.com/machine-learning/latest/dg).
  --parameters: record # A list of the training parameters in the MLModel. The list is implemented as a map of key-value pairs. The following is the current set of training parameters: sgd.maxMLModelSizeInBytes - The maximum allowed size of the model. Depending on the input data, the size of the model might affect its performance. The value is an integer that ranges from 100000 to 2147483648. The default value is 33554432. sgd.maxPasses - The number of times that the training process traverses the observations to build the MLModel. The value is an integer that ranges from 1 to 10000. The default value is 10. sgd.shuffleType - Whether Amazon ML shuffles the training data. Shuffling the data improves a model's ability to find the optimal solution for a variety of data types. The valid values are auto and none. The default value is none. We strongly recommend that you shuffle your data. sgd.l1RegularizationAmount - The coefficient regularization L1 norm. It controls overfitting the data by penalizing large coefficients. This tends to drive coefficients to zero, resulting in a sparse feature set. If you use this parameter, start by specifying a small value, such as 1.0E-08. The value is a double that ranges from 0 to MAX_DOUBLE. The default is to not use L1 normalization. This parameter can't be used when L2 is specified. Use this parameter sparingly. sgd.l2RegularizationAmount - The coefficient regularization L2 norm. It controls overfitting the data by penalizing large coefficients. This tends to drive coefficients to small, nonzero values. If you use this parameter, start by specifying a small value, such as 1.0E-08. The value is a double that ranges from 0 to MAX_DOUBLE. The default is to not use L2 normalization. This parameter can't be used when L1 is specified. Use this parameter sparingly.
  training_data_source_id: string # The DataSource that points to the training data.
  --recipe: string # The data recipe for creating the MLModel. You must specify either the recipe or its URI. If you don't specify a recipe or its URI, Amazon ML creates a default.
  --recipe-uri: string # A reference to a file or bucket on Amazon Simple Storage Service (Amazon S3).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateMLModel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}, {name: MLModelName, var: ml_model_name}, {name: MLModelType, var: ml_model_type}, {name: Parameters, var: parameters}, {name: TrainingDataSourceId, var: training_data_source_id}, {name: Recipe, var: recipe}, {name: RecipeUri, var: recipe_uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id, ml_model_name: $ml_model_name, ml_model_type: $ml_model_type, parameters: $parameters, training_data_source_id: $training_data_source_id, recipe: $recipe, recipe_uri: $recipe_uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a real-time endpoint for the MLModel. The endpoint contains the URI of the MLModel; that is, the location to send real-time prediction requests for the specified MLModel.
#
# POST /
# Returns: record<MLModelId: string, RealtimeEndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>>
# operationId: CreateRealtimeEndpoint
export def "create-realtime-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  ml_model_id: string # The ID assigned to the MLModel during creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.CreateRealtimeEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the DELETED status to a BatchPrediction, rendering it unusable. After using the DeleteBatchPrediction operation, you can use the GetBatchPrediction operation to verify that the status of the BatchPrediction changed to DELETED. Caution: The result of the DeleteBatchPrediction operation is irreversible.
#
# POST /
# Returns: record<BatchPredictionId: string>
# operationId: DeleteBatchPrediction
export def "delete-batch-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  batch_prediction_id: string # A user-supplied ID that uniquely identifies the BatchPrediction.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteBatchPrediction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchPredictionId, var: batch_prediction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_prediction_id: $batch_prediction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the DELETED status to a DataSource, rendering it unusable. After using the DeleteDataSource operation, you can use the GetDataSource operation to verify that the status of the DataSource changed to DELETED. Caution: The results of the DeleteDataSource operation are irreversible.
#
# POST /
# Returns: record<DataSourceId: string>
# operationId: DeleteDataSource
export def "delete-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  data_source_id: string # A user-supplied ID that uniquely identifies the DataSource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the DELETED status to an Evaluation, rendering it unusable. After invoking the DeleteEvaluation operation, you can use the GetEvaluation operation to verify that the status of the Evaluation changed to DELETED. Caution: The results of the DeleteEvaluation operation are irreversible.
#
# POST /
# Returns: record<EvaluationId: string>
# operationId: DeleteEvaluation
export def "delete-evaluation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  evaluation_id: string # A user-supplied ID that uniquely identifies the Evaluation to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteEvaluation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EvaluationId, var: evaluation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, evaluation_id: $evaluation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns the DELETED status to an MLModel, rendering it unusable. After using the DeleteMLModel operation, you can use the GetMLModel operation to verify that the status of the MLModel changed to DELETED. Caution: The result of the DeleteMLModel operation is irreversible.
#
# POST /
# Returns: record<MLModelId: string>
# operationId: DeleteMLModel
export def "delete-ml-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  ml_model_id: string # A user-supplied ID that uniquely identifies the MLModel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteMLModel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a real time endpoint of an MLModel.
#
# POST /
# Returns: record<MLModelId: string, RealtimeEndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>>
# operationId: DeleteRealtimeEndpoint
export def "delete-realtime-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  ml_model_id: string # The ID assigned to the MLModel during creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteRealtimeEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags. If you specify a tag that doesn't exist, Amazon ML ignores it.
#
# POST /
# Returns: record<ResourceId: string, ResourceType: string>
# operationId: DeleteTags
export def "delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  tag_keys: list<string> # One or more tags to delete.
  resource_id: string # The ID of the tagged ML object. For example, exampleModelId.
  resource_type: string@resource-type-completer # The type of the tagged ML object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DeleteTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TagKeys, var: tag_keys}, {name: ResourceId, var: resource_id}, {name: ResourceType, var: resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, tag_keys: $tag_keys, resource_id: $resource_id, resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of BatchPrediction operations that match the search criteria in the request.
#
# POST /
# Returns: record<Results: table<BatchPredictionId: string, MLModelId: string, BatchPredictionDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, OutputUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, TotalRecordCount: int, InvalidRecordCount: int>, NextToken: string>
# operationId: DescribeBatchPredictions
export def "describe-batch-predictions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  --filter-variable: string@filter-variable-completer # A list of the variables to use in searching or filtering BatchPrediction. CreatedAt - Sets the search criteria to BatchPrediction creation date. Status - Sets the search criteria to BatchPrediction status. Name - Sets the search criteria to the contents of BatchPrediction Name. IAMUser - Sets the search criteria to the user account that invoked the BatchPrediction creation. MLModelId - Sets the search criteria to the MLModel used in the BatchPrediction. DataSourceId - Sets the search criteria to the DataSource used in the BatchPrediction. DataURI - Sets the search criteria to the data file(s) used in the BatchPrediction. The URL can identify either a file or an Amazon Simple Storage Service (Amazon S3) bucket or directory.
  --eq: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --gt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --lt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ge: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --le: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ne: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --prefix: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --sort-order: string@sort-order-completer # The sort order specified in a listing condition. Possible values include the following: asc - Present the information in ascending order (from A-Z). dsc - Present the information in descending order (from Z-A).
  --body-next-token: string # String type. (spec name: NextToken)
  --body-limit: int # The number of pages of information to include in the result. The range of acceptable values is 1 through 100. The default value is 100. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DescribeBatchPredictions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FilterVariable, var: filter_variable}, {name: EQ, var: eq}, {name: GT, var: gt}, {name: LT, var: lt}, {name: GE, var: ge}, {name: LE, var: le}, {name: NE, var: ne}, {name: Prefix, var: prefix}, {name: SortOrder, var: sort_order}, {name: NextToken, var: body_next_token}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_variable: $filter_variable, eq: $eq, gt: $gt, lt: $lt, ge: $ge, le: $le, ne: $ne, prefix: $prefix, sort_order: $sort_order, body_next_token: $body_next_token, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DataSource that match the search criteria in the request.
#
# POST /
# Returns: record<Results: table<DataSourceId: string, DataLocationS3: string, DataRearrangement: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, DataSizeInBytes: int, NumberOfFiles: int, Name: string, Status: string, Message: string, RedshiftMetadata: record, RDSMetadata: record, RoleARN: string, ComputeStatistics: bool, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>
# operationId: DescribeDataSources
export def "describe-data-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  --filter-variable: string@filter-variable-completer-1 # A list of the variables to use in searching or filtering DataSource. CreatedAt - Sets the search criteria to DataSource creation date. Status - Sets the search criteria to DataSource status. Name - Sets the search criteria to the contents of DataSource Name. DataUri - Sets the search criteria to the URI of data files used to create the DataSource. The URI can identify either a file or an Amazon Simple Storage Service (Amazon S3) bucket or directory. IAMUser - Sets the search criteria to the user account that invoked the DataSource creation. Note: The variable names should match the variable names in the DataSource.
  --eq: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --gt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --lt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ge: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --le: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ne: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --prefix: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --sort-order: string@sort-order-completer # The sort order specified in a listing condition. Possible values include the following: asc - Present the information in ascending order (from A-Z). dsc - Present the information in descending order (from Z-A).
  --body-next-token: string # String type. (spec name: NextToken)
  --body-limit: int # The maximum number of DataSource to include in the result. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DescribeDataSources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FilterVariable, var: filter_variable}, {name: EQ, var: eq}, {name: GT, var: gt}, {name: LT, var: lt}, {name: GE, var: ge}, {name: LE, var: le}, {name: NE, var: ne}, {name: Prefix, var: prefix}, {name: SortOrder, var: sort_order}, {name: NextToken, var: body_next_token}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_variable: $filter_variable, eq: $eq, gt: $gt, lt: $lt, ge: $ge, le: $le, ne: $ne, prefix: $prefix, sort_order: $sort_order, body_next_token: $body_next_token, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of DescribeEvaluations that match the search criteria in the request.
#
# POST /
# Returns: record<Results: table<EvaluationId: string, MLModelId: string, EvaluationDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, PerformanceMetrics: record, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>
# operationId: DescribeEvaluations
export def "describe-evaluations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  --filter-variable: string@filter-variable-completer # A list of the variables to use in searching or filtering Evaluation. CreatedAt - Sets the search criteria to Evaluation creation date. Status - Sets the search criteria to Evaluation status. Name - Sets the search criteria to the contents of Evaluation Name. IAMUser - Sets the search criteria to the user account that invoked an evaluation. MLModelId - Sets the search criteria to the Predictor that was evaluated. DataSourceId - Sets the search criteria to the DataSource used in evaluation. DataUri - Sets the search criteria to the data file(s) used in evaluation. The URL can identify either a file or an Amazon Simple Storage Service (Amazon S3) bucket or directory.
  --eq: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --gt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --lt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ge: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --le: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ne: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --prefix: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --sort-order: string@sort-order-completer # The sort order specified in a listing condition. Possible values include the following: asc - Present the information in ascending order (from A-Z). dsc - Present the information in descending order (from Z-A).
  --body-next-token: string # String type. (spec name: NextToken)
  --body-limit: int # The maximum number of Evaluation to include in the result. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DescribeEvaluations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FilterVariable, var: filter_variable}, {name: EQ, var: eq}, {name: GT, var: gt}, {name: LT, var: lt}, {name: GE, var: ge}, {name: LE, var: le}, {name: NE, var: ne}, {name: Prefix, var: prefix}, {name: SortOrder, var: sort_order}, {name: NextToken, var: body_next_token}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_variable: $filter_variable, eq: $eq, gt: $gt, lt: $lt, ge: $ge, le: $le, ne: $ne, prefix: $prefix, sort_order: $sort_order, body_next_token: $body_next_token, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of MLModel that match the search criteria in the request.
#
# POST /
# Returns: record<Results: table<MLModelId: string, TrainingDataSourceId: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, SizeInBytes: int, EndpointInfo: record, TrainingParameters: record, InputDataLocationS3: string, Algorithm: string, MLModelType: string, ScoreThreshold: float, ScoreThresholdLastUpdatedAt: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>, NextToken: string>
# operationId: DescribeMLModels
export def "describe-ml-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --filter-variable: string@filter-variable-completer-2 # Use one of the following variables to filter a list of MLModel: CreatedAt - Sets the search criteria to MLModel creation date. Status - Sets the search criteria to MLModel status. Name - Sets the search criteria to the contents of MLModel Name. IAMUser - Sets the search criteria to the user account that invoked the MLModel creation. TrainingDataSourceId - Sets the search criteria to the DataSource used to train one or more MLModel. RealtimeEndpointStatus - Sets the search criteria to the MLModel real-time endpoint status. MLModelType - Sets the search criteria to MLModel type: binary, regression, or multi-class. Algorithm - Sets the search criteria to the algorithm that the MLModel uses. TrainingDataURI - Sets the search criteria to the data file(s) used in training a MLModel. The URL can identify either a file or an Amazon Simple Storage Service (Amazon S3) bucket or directory.
  --eq: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --gt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --lt: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ge: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --le: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --ne: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --prefix: string # The value specified in a filtering condition. The ComparatorValue becomes the reference value when matching or evaluating data values in filtering and searching functions.
  --sort-order: string@sort-order-completer # The sort order specified in a listing condition. Possible values include the following: asc - Present the information in ascending order (from A-Z). dsc - Present the information in descending order (from Z-A).
  --body-next-token: string # String type. (spec name: NextToken)
  --body-limit: int # The number of pages of information to include in the result. The range of acceptable values is 1 through 100. The default value is 100. (spec name: Limit)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Limit, var: limit}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DescribeMLModels"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FilterVariable, var: filter_variable}, {name: EQ, var: eq}, {name: GT, var: gt}, {name: LT, var: lt}, {name: GE, var: ge}, {name: LE, var: le}, {name: NE, var: ne}, {name: Prefix, var: prefix}, {name: SortOrder, var: sort_order}, {name: NextToken, var: body_next_token}, {name: Limit, var: body_limit}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter_variable: $filter_variable, eq: $eq, gt: $gt, lt: $lt, ge: $ge, le: $le, ne: $ne, prefix: $prefix, sort_order: $sort_order, body_next_token: $body_next_token, body_limit: $body_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more of the tags for your Amazon ML object.
#
# POST /
# Returns: record<ResourceId: string, ResourceType: string, Tags: table<Key: string, Value: string>>
# operationId: DescribeTags
export def "describe-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  resource_id: string # The ID of the ML object. For example, exampleModelId.
  resource_type: string@resource-type-completer # The type of the ML object.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.DescribeTags"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: ResourceType, var: resource_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, resource_type: $resource_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a BatchPrediction that includes detailed metadata, status, and data file information for a Batch Prediction request.
#
# POST /
# Returns: record<BatchPredictionId: string, MLModelId: string, BatchPredictionDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, OutputUri: string, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, TotalRecordCount: int, InvalidRecordCount: int>
# operationId: GetBatchPrediction
export def "get-batch-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  batch_prediction_id: string # An ID assigned to the BatchPrediction at creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.GetBatchPrediction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchPredictionId, var: batch_prediction_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_prediction_id: $batch_prediction_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a DataSource that includes metadata and data file information, as well as the current status of the DataSource. GetDataSource provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.
#
# POST /
# Returns: record<DataSourceId: string, DataLocationS3: string, DataRearrangement: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, DataSizeInBytes: int, NumberOfFiles: int, Name: string, Status: string, LogUri: string, Message: string, RedshiftMetadata: record<RedshiftDatabase: record<DatabaseName: string, ClusterIdentifier: string>, DatabaseUserName: string, SelectSqlQuery: string>, RDSMetadata: record<Database: record<InstanceIdentifier: string, DatabaseName: string>, DatabaseUserName: string, SelectSqlQuery: string, ResourceRole: string, ServiceRole: string, DataPipelineId: string>, RoleARN: string, ComputeStatistics: bool, ComputeTime: int, FinishedAt: string, StartedAt: string, DataSourceSchema: string>
# operationId: GetDataSource
export def "get-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  data_source_id: string # The ID assigned to the DataSource at creation.
  --verbose: oneof<nothing, bool> # Specifies whether a describe operation should return exhaustive or abbreviated information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.GetDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: Verbose, var: verbose}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id, verbose: $verbose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an Evaluation that includes metadata as well as the current status of the Evaluation.
#
# POST /
# Returns: record<EvaluationId: string, MLModelId: string, EvaluationDataSourceId: string, InputDataLocationS3: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, PerformanceMetrics: record<Properties: record>, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string>
# operationId: GetEvaluation
export def "get-evaluation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  evaluation_id: string # The ID of the Evaluation to retrieve. The evaluation of each MLModel is recorded and cataloged. The ID provides the means to access the information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.GetEvaluation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EvaluationId, var: evaluation_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, evaluation_id: $evaluation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an MLModel that includes detailed metadata, data source information, and the current status of the MLModel. GetMLModel provides results in normal or verbose format.
#
# POST /
# Returns: record<MLModelId: string, TrainingDataSourceId: string, CreatedByIamUser: string, CreatedAt: string, LastUpdatedAt: string, Name: string, Status: string, SizeInBytes: int, EndpointInfo: record<PeakRequestsPerSecond: int, CreatedAt: string, EndpointUrl: string, EndpointStatus: string>, TrainingParameters: record, InputDataLocationS3: string, MLModelType: string, ScoreThreshold: float, ScoreThresholdLastUpdatedAt: string, LogUri: string, Message: string, ComputeTime: int, FinishedAt: string, StartedAt: string, Recipe: string, Schema: string>
# operationId: GetMLModel
export def "get-ml-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  ml_model_id: string # The ID assigned to the MLModel at creation.
  --verbose: oneof<nothing, bool> # Specifies whether a describe operation should return exhaustive or abbreviated information.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.GetMLModel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}, {name: Verbose, var: verbose}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id, verbose: $verbose
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a prediction for the observation using the specified ML Model. Note: Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.
#
# POST /
# Returns: record<Prediction: record<predictedLabel: string, predictedValue: float, predictedScores: record, details: record>>
# operationId: Predict
export def "predict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  ml_model_id: string # A unique identifier of the MLModel.
  record: record # A map of variable name-value pairs that represent an observation.
  predict_endpoint: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.Predict"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}, {name: Record, var: record}, {name: PredictEndpoint, var: predict_endpoint}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id, record: $record, predict_endpoint: $predict_endpoint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the BatchPredictionName of a BatchPrediction. You can use the GetBatchPrediction operation to view the contents of the updated data element.
#
# POST /
# Returns: record<BatchPredictionId: string>
# operationId: UpdateBatchPrediction
export def "update-batch-prediction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  batch_prediction_id: string # The ID assigned to the BatchPrediction during creation.
  batch_prediction_name: string # A user-supplied name or description of the Amazon ML resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.UpdateBatchPrediction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchPredictionId, var: batch_prediction_id}, {name: BatchPredictionName, var: batch_prediction_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, batch_prediction_id: $batch_prediction_id, batch_prediction_name: $batch_prediction_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the DataSourceName of a DataSource. You can use the GetDataSource operation to view the contents of the updated data element.
#
# POST /
# Returns: record<DataSourceId: string>
# operationId: UpdateDataSource
export def "update-data-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  data_source_id: string # The ID assigned to the DataSource during creation.
  data_source_name: string # A user-supplied name or description of the Amazon ML resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.UpdateDataSource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: DataSourceName, var: data_source_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data_source_id: $data_source_id, data_source_name: $data_source_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the EvaluationName of an Evaluation. You can use the GetEvaluation operation to view the contents of the updated data element.
#
# POST /
# Returns: record<EvaluationId: string>
# operationId: UpdateEvaluation
export def "update-evaluation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  evaluation_id: string # The ID assigned to the Evaluation during creation.
  evaluation_name: string # A user-supplied name or description of the Amazon ML resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.UpdateEvaluation"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EvaluationId, var: evaluation_id}, {name: EvaluationName, var: evaluation_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, evaluation_id: $evaluation_id, evaluation_name: $evaluation_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the MLModelName and the ScoreThreshold of an MLModel. You can use the GetMLModel operation to view the contents of the updated data element.
#
# POST /
# Returns: record<MLModelId: string>
# operationId: UpdateMLModel
export def "update-ml-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  ml_model_id: string # The ID assigned to the MLModel during creation.
  --ml-model-name: string # A user-supplied name or description of the Amazon ML resource.
  --score-threshold: float # The ScoreThreshold used in binary classification MLModel that marks the boundary between a positive prediction and a negative prediction. Output values greater than or equal to the ScoreThreshold receive a positive result from the MLModel, such as true. Output values less than the ScoreThreshold receive a negative response from the MLModel, such as false. (format: float)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonML_20141212.UpdateMLModel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MLModelId, var: ml_model_id}, {name: MLModelName, var: ml_model_name}, {name: ScoreThreshold, var: score_threshold}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, ml_model_id: $ml_model_id, ml_model_name: $ml_model_name, score_threshold: $score_threshold
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
