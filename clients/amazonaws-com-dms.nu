# Auto-generated client for AWS Database Migration Service v2016-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/dms/2016-01-01/openapi.json
# Auth: --token flag or $env.AWS_DATABASE_MIGRATION_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://dms.us-east-1.amazonaws.com"
  token_env_var: "AWS_DATABASE_MIGRATION_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://dms.us-east-1.amazonaws.com" "http://dms.us-east-2.amazonaws.com" "http://dms.us-west-1.amazonaws.com" "http://dms.us-west-2.amazonaws.com" "http://dms.us-gov-west-1.amazonaws.com" "http://dms.us-gov-east-1.amazonaws.com" "http://dms.ca-central-1.amazonaws.com" "http://dms.eu-north-1.amazonaws.com" "http://dms.eu-west-1.amazonaws.com" "http://dms.eu-west-2.amazonaws.com" "http://dms.eu-west-3.amazonaws.com" "http://dms.eu-central-1.amazonaws.com" "http://dms.eu-south-1.amazonaws.com" "http://dms.af-south-1.amazonaws.com" "http://dms.ap-northeast-1.amazonaws.com" "http://dms.ap-northeast-2.amazonaws.com" "http://dms.ap-northeast-3.amazonaws.com" "http://dms.ap-southeast-1.amazonaws.com" "http://dms.ap-southeast-2.amazonaws.com" "http://dms.ap-east-1.amazonaws.com" "http://dms.ap-south-1.amazonaws.com" "http://dms.sa-east-1.amazonaws.com" "http://dms.me-south-1.amazonaws.com" "https://dms.us-east-1.amazonaws.com" "https://dms.us-east-2.amazonaws.com" "https://dms.us-west-1.amazonaws.com" "https://dms.us-west-2.amazonaws.com" "https://dms.us-gov-west-1.amazonaws.com" "https://dms.us-gov-east-1.amazonaws.com" "https://dms.ca-central-1.amazonaws.com" "https://dms.eu-north-1.amazonaws.com" "https://dms.eu-west-1.amazonaws.com" "https://dms.eu-west-2.amazonaws.com" "https://dms.eu-west-3.amazonaws.com" "https://dms.eu-central-1.amazonaws.com" "https://dms.eu-south-1.amazonaws.com" "https://dms.af-south-1.amazonaws.com" "https://dms.ap-northeast-1.amazonaws.com" "https://dms.ap-northeast-2.amazonaws.com" "https://dms.ap-northeast-3.amazonaws.com" "https://dms.ap-southeast-1.amazonaws.com" "https://dms.ap-southeast-2.amazonaws.com" "https://dms.ap-east-1.amazonaws.com" "https://dms.ap-south-1.amazonaws.com" "https://dms.sa-east-1.amazonaws.com" "https://dms.me-south-1.amazonaws.com" "http://dms.cn-north-1.amazonaws.com.cn" "http://dms.cn-northwest-1.amazonaws.com.cn" "https://dms.cn-north-1.amazonaws.com.cn" "https://dms.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AmazonDMSv20160101.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["AmazonDMSv20160101.ApplyPendingMaintenanceAction"] }
def x-amz-target-completer-2 [] { ["AmazonDMSv20160101.BatchStartRecommendations"] }
def x-amz-target-completer-3 [] { ["AmazonDMSv20160101.CancelReplicationTaskAssessmentRun"] }
def endpoint-type-completer [] { ["source" "target"] }
def ssl-mode-completer [] { ["none" "require" "verify-ca" "verify-full"] }
def x-amz-target-completer-4 [] { ["AmazonDMSv20160101.CreateEndpoint"] }
def x-amz-target-completer-5 [] { ["AmazonDMSv20160101.CreateEventSubscription"] }
def x-amz-target-completer-6 [] { ["AmazonDMSv20160101.CreateFleetAdvisorCollector"] }
def x-amz-target-completer-7 [] { ["AmazonDMSv20160101.CreateReplicationInstance"] }
def x-amz-target-completer-8 [] { ["AmazonDMSv20160101.CreateReplicationSubnetGroup"] }
def migration-type-completer [] { ["cdc" "full-load" "full-load-and-cdc"] }
def x-amz-target-completer-9 [] { ["AmazonDMSv20160101.CreateReplicationTask"] }
def x-amz-target-completer-10 [] { ["AmazonDMSv20160101.DeleteCertificate"] }
def x-amz-target-completer-11 [] { ["AmazonDMSv20160101.DeleteConnection"] }
def x-amz-target-completer-12 [] { ["AmazonDMSv20160101.DeleteEndpoint"] }
def x-amz-target-completer-13 [] { ["AmazonDMSv20160101.DeleteEventSubscription"] }
def x-amz-target-completer-14 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorCollector"] }
def x-amz-target-completer-15 [] { ["AmazonDMSv20160101.DeleteFleetAdvisorDatabases"] }
def x-amz-target-completer-16 [] { ["AmazonDMSv20160101.DeleteReplicationInstance"] }
def x-amz-target-completer-17 [] { ["AmazonDMSv20160101.DeleteReplicationSubnetGroup"] }
def x-amz-target-completer-18 [] { ["AmazonDMSv20160101.DeleteReplicationTask"] }
def x-amz-target-completer-19 [] { ["AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun"] }
def x-amz-target-completer-20 [] { ["AmazonDMSv20160101.DescribeAccountAttributes"] }
def x-amz-target-completer-21 [] { ["AmazonDMSv20160101.DescribeApplicableIndividualAssessments"] }
def x-amz-target-completer-22 [] { ["AmazonDMSv20160101.DescribeCertificates"] }
def x-amz-target-completer-23 [] { ["AmazonDMSv20160101.DescribeConnections"] }
def x-amz-target-completer-24 [] { ["AmazonDMSv20160101.DescribeEndpointSettings"] }
def x-amz-target-completer-25 [] { ["AmazonDMSv20160101.DescribeEndpointTypes"] }
def x-amz-target-completer-26 [] { ["AmazonDMSv20160101.DescribeEndpoints"] }
def x-amz-target-completer-27 [] { ["AmazonDMSv20160101.DescribeEventCategories"] }
def x-amz-target-completer-28 [] { ["AmazonDMSv20160101.DescribeEventSubscriptions"] }
def source-type-completer [] { ["replication-instance"] }
def x-amz-target-completer-29 [] { ["AmazonDMSv20160101.DescribeEvents"] }
def x-amz-target-completer-30 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorCollectors"] }
def x-amz-target-completer-31 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorDatabases"] }
def x-amz-target-completer-32 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-33 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary"] }
def x-amz-target-completer-34 [] { ["AmazonDMSv20160101.DescribeFleetAdvisorSchemas"] }
def x-amz-target-completer-35 [] { ["AmazonDMSv20160101.DescribeOrderableReplicationInstances"] }
def x-amz-target-completer-36 [] { ["AmazonDMSv20160101.DescribePendingMaintenanceActions"] }
def x-amz-target-completer-37 [] { ["AmazonDMSv20160101.DescribeRecommendationLimitations"] }
def x-amz-target-completer-38 [] { ["AmazonDMSv20160101.DescribeRecommendations"] }
def x-amz-target-completer-39 [] { ["AmazonDMSv20160101.DescribeRefreshSchemasStatus"] }
def x-amz-target-completer-40 [] { ["AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"] }
def x-amz-target-completer-41 [] { ["AmazonDMSv20160101.DescribeReplicationInstances"] }
def x-amz-target-completer-42 [] { ["AmazonDMSv20160101.DescribeReplicationSubnetGroups"] }
def x-amz-target-completer-43 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"] }
def x-amz-target-completer-44 [] { ["AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns"] }
def x-amz-target-completer-45 [] { ["AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments"] }
def x-amz-target-completer-46 [] { ["AmazonDMSv20160101.DescribeReplicationTasks"] }
def x-amz-target-completer-47 [] { ["AmazonDMSv20160101.DescribeSchemas"] }
def x-amz-target-completer-48 [] { ["AmazonDMSv20160101.DescribeTableStatistics"] }
def x-amz-target-completer-49 [] { ["AmazonDMSv20160101.ImportCertificate"] }
def x-amz-target-completer-50 [] { ["AmazonDMSv20160101.ListTagsForResource"] }
def x-amz-target-completer-51 [] { ["AmazonDMSv20160101.ModifyEndpoint"] }
def x-amz-target-completer-52 [] { ["AmazonDMSv20160101.ModifyEventSubscription"] }
def x-amz-target-completer-53 [] { ["AmazonDMSv20160101.ModifyReplicationInstance"] }
def x-amz-target-completer-54 [] { ["AmazonDMSv20160101.ModifyReplicationSubnetGroup"] }
def x-amz-target-completer-55 [] { ["AmazonDMSv20160101.ModifyReplicationTask"] }
def x-amz-target-completer-56 [] { ["AmazonDMSv20160101.MoveReplicationTask"] }
def x-amz-target-completer-57 [] { ["AmazonDMSv20160101.RebootReplicationInstance"] }
def x-amz-target-completer-58 [] { ["AmazonDMSv20160101.RefreshSchemas"] }
def reload-option-completer [] { ["data-reload" "validate-only"] }
def x-amz-target-completer-59 [] { ["AmazonDMSv20160101.ReloadTables"] }
def x-amz-target-completer-60 [] { ["AmazonDMSv20160101.RemoveTagsFromResource"] }
def x-amz-target-completer-61 [] { ["AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis"] }
def x-amz-target-completer-62 [] { ["AmazonDMSv20160101.StartRecommendations"] }
def start-replication-task-type-completer [] { ["reload-target" "resume-processing" "start-replication"] }
def x-amz-target-completer-63 [] { ["AmazonDMSv20160101.StartReplicationTask"] }
def x-amz-target-completer-64 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessment"] }
def x-amz-target-completer-65 [] { ["AmazonDMSv20160101.StartReplicationTaskAssessmentRun"] }
def x-amz-target-completer-66 [] { ["AmazonDMSv20160101.StopReplicationTask"] }
def x-amz-target-completer-67 [] { ["AmazonDMSv20160101.TestConnection"] }
def x-amz-target-completer-68 [] { ["AmazonDMSv20160101.UpdateSubscriptionsToEventBridge"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-tags-to-resource: "record"
    apply-pending-maintenance-action: "record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: string, PendingMaintenanceActionDetails: list<record>>>"
    batch-start-recommendations: "record<ErrorEntries: table<DatabaseId: string, Message: string, Code: string>>"
    cancel-replication-task-assessment-run: "record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>"
    create-endpoint: "record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>"
    create-event-subscription: "record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>"
    create-fleet-advisor-collector: "record<CollectorReferencedId: string, CollectorName: string, Description: string, ServiceAccessRoleArn: string, S3BucketName: string>"
    create-replication-instance: "record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>"
    create-replication-subnet-group: "record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>"
    create-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    delete-certificate: "record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>"
    delete-connection: "record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>"
    delete-endpoint: "record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>"
    delete-event-subscription: "record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>"
    delete-fleet-advisor-databases: "record<DatabaseIds: list<string>>"
    delete-replication-instance: "record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>"
    delete-replication-subnet-group: "record"
    delete-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    delete-replication-task-assessment-run: "record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>"
    describe-account-attributes: "record<AccountQuotas: table<AccountQuotaName: string, Used: int, Max: int>, UniqueAccountIdentifier: string>"
    describe-applicable-individual-assessments: "record<IndividualAssessmentNames: list<string>, Marker: string>"
    describe-certificates: "record<Marker: string, Certificates: table<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>"
    describe-connections: "record<Marker: string, Connections: table<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>"
    describe-endpoint-settings: "record<Marker: string, EndpointSettings: table<Name: string, Type: string, EnumValues: list, Sensitive: bool, Units: string, Applicability: string, IntValueMin: int, IntValueMax: int, DefaultValue: string>>"
    describe-endpoint-types: "record<Marker: string, SupportedEndpointTypes: table<EngineName: string, SupportsCDC: bool, EndpointType: string, ReplicationInstanceEngineMinimumVersion: string, EngineDisplayName: string>>"
    describe-endpoints: "record<Marker: string, Endpoints: table<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record, S3Settings: record, DmsTransferSettings: record, MongoDbSettings: record, KinesisSettings: record, KafkaSettings: record, ElasticsearchSettings: record, NeptuneSettings: record, RedshiftSettings: record, PostgreSQLSettings: record, MySQLSettings: record, OracleSettings: record, SybaseSettings: record, MicrosoftSQLServerSettings: record, IBMDb2Settings: record, DocDbSettings: record, RedisSettings: record, GcpMySQLSettings: record>>"
    describe-event-categories: "record<EventCategoryGroupList: table<SourceType: string, EventCategories: list>>"
    describe-event-subscriptions: "record<Marker: string, EventSubscriptionsList: table<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list, EventCategoriesList: list, Enabled: bool>>"
    describe-events: "record<Marker: string, Events: table<SourceIdentifier: string, SourceType: string, Message: string, EventCategories: list, Date: string>>"
    describe-fleet-advisor-collectors: "record<Collectors: table<CollectorReferencedId: string, CollectorName: string, CollectorVersion: string, VersionStatus: string, Description: string, S3BucketName: string, ServiceAccessRoleArn: string, CollectorHealthCheck: record, LastDataReceived: string, RegisteredDate: string, CreatedDate: string, ModifiedDate: string, InventoryData: record>, NextToken: string>"
    describe-fleet-advisor-databases: "record<Databases: table<DatabaseId: string, DatabaseName: string, IpAddress: string, NumberOfSchemas: int, Server: record, SoftwareDetails: record, Collectors: list>, NextToken: string>"
    describe-fleet-advisor-lsa-analysis: "record<Analysis: table<LsaAnalysisId: string, Status: string>, NextToken: string>"
    describe-fleet-advisor-schema-object-summary: "record<FleetAdvisorSchemaObjects: table<SchemaId: string, ObjectType: string, NumberOfObjects: int, CodeLineCount: int, CodeSize: int>, NextToken: string>"
    describe-fleet-advisor-schemas: "record<FleetAdvisorSchemas: table<CodeLineCount: int, CodeSize: int, Complexity: string, Server: record, DatabaseInstance: record, SchemaId: string, SchemaName: string, OriginalSchema: record, Similarity: float>, NextToken: string>"
    describe-orderable-replication-instances: "record<OrderableReplicationInstances: table<EngineVersion: string, ReplicationInstanceClass: string, StorageType: string, MinAllocatedStorage: int, MaxAllocatedStorage: int, DefaultAllocatedStorage: int, IncludedAllocatedStorage: int, AvailabilityZones: list, ReleaseStatus: string>, Marker: string>"
    describe-pending-maintenance-actions: "record<PendingMaintenanceActions: table<ResourceIdentifier: string, PendingMaintenanceActionDetails: list>, Marker: string>"
    describe-recommendation-limitations: "record<NextToken: string, Limitations: table<DatabaseId: string, EngineName: string, Name: string, Description: string, Impact: string, Type: string>>"
    describe-recommendations: "record<NextToken: string, Recommendations: table<DatabaseId: string, EngineName: string, CreatedDate: string, Status: string, Preferred: bool, Settings: record, Data: record>>"
    describe-refresh-schemas-status: "record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>"
    describe-replication-instance-task-logs: "record<ReplicationInstanceArn: string, ReplicationInstanceTaskLogs: table<ReplicationTaskName: string, ReplicationTaskArn: string, ReplicationInstanceTaskLogSize: int>, Marker: string>"
    describe-replication-instances: "record<Marker: string, ReplicationInstances: table<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list, AvailabilityZone: string, ReplicationSubnetGroup: record, PreferredMaintenanceWindow: string, PendingModifiedValues: record, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list, ReplicationInstancePrivateIpAddresses: list, ReplicationInstanceIpv6Addresses: list, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>"
    describe-replication-subnet-groups: "record<Marker: string, ReplicationSubnetGroups: table<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>>"
    describe-replication-task-assessment-results: "record<Marker: string, BucketName: string, ReplicationTaskAssessmentResults: table<ReplicationTaskIdentifier: string, ReplicationTaskArn: string, ReplicationTaskLastAssessmentDate: string, AssessmentStatus: string, AssessmentResultsFile: string, AssessmentResults: string, S3ObjectUrl: string>>"
    describe-replication-task-assessment-runs: "record<Marker: string, ReplicationTaskAssessmentRuns: table<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>"
    describe-replication-task-individual-assessments: "record<Marker: string, ReplicationTaskIndividualAssessments: table<ReplicationTaskIndividualAssessmentArn: string, ReplicationTaskAssessmentRunArn: string, IndividualAssessmentName: string, Status: string, ReplicationTaskIndividualAssessmentStartDate: string>>"
    describe-replication-tasks: "record<Marker: string, ReplicationTasks: table<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record, TaskData: string, TargetReplicationInstanceArn: string>>"
    describe-schemas: "record<Marker: string, Schemas: list<string>>"
    describe-table-statistics: "record<ReplicationTaskArn: string, TableStatistics: table<SchemaName: string, TableName: string, Inserts: int, Deletes: int, Updates: int, Ddls: int, AppliedInserts: int, AppliedDeletes: int, AppliedUpdates: int, AppliedDdls: int, FullLoadRows: int, FullLoadCondtnlChkFailedRows: int, FullLoadErrorRows: int, FullLoadStartTime: string, FullLoadEndTime: string, FullLoadReloaded: bool, LastUpdateTime: string, TableState: string, ValidationPendingRecords: int, ValidationFailedRecords: int, ValidationSuspendedRecords: int, ValidationState: string, ValidationStateDetails: string>, Marker: string>"
    import-certificate: "record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>"
    list-tags-for-resource: "record<TagList: table<Key: string, Value: string, ResourceArn: string>>"
    modify-endpoint: "record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>"
    modify-event-subscription: "record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>"
    modify-replication-instance: "record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>"
    modify-replication-subnet-group: "record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>"
    modify-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    move-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    reboot-replication-instance: "record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>"
    refresh-schemas: "record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>"
    reload-tables: "record<ReplicationTaskArn: string>"
    remove-tags-from-resource: "record"
    run-fleet-advisor-lsa-analysis: "record<LsaAnalysisId: string, Status: string>"
    start-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    start-replication-task-assessment: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    start-replication-task-assessment-run: "record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>"
    stop-replication-task: "record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>"
    test-connection: "record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>"
    update-subscriptions-to-event-bridge: "record<Result: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-resource" "apply-pending-maintenance-action" "batch-start-recommendations" "cancel-replication-task-assessment-run" "create-endpoint" "create-event-subscription" "create-fleet-advisor-collector" "create-replication-instance" "create-replication-subnet-group" "create-replication-task" "delete-certificate" "delete-connection" "delete-endpoint" "delete-event-subscription" "delete-fleet-advisor-collector" "delete-fleet-advisor-databases" "delete-replication-instance" "delete-replication-subnet-group" "delete-replication-task" "delete-replication-task-assessment-run" "describe-account-attributes" "describe-applicable-individual-assessments" "describe-certificates" "describe-connections" "describe-endpoint-settings" "describe-endpoint-types" "describe-endpoints" "describe-event-categories" "describe-event-subscriptions" "describe-events" "describe-fleet-advisor-collectors" "describe-fleet-advisor-databases" "describe-fleet-advisor-lsa-analysis" "describe-fleet-advisor-schema-object-summary" "describe-fleet-advisor-schemas" "describe-orderable-replication-instances" "describe-pending-maintenance-actions" "describe-recommendation-limitations" "describe-recommendations" "describe-refresh-schemas-status" "describe-replication-instance-task-logs" "describe-replication-instances" "describe-replication-subnet-groups" "describe-replication-task-assessment-results" "describe-replication-task-assessment-runs" "describe-replication-task-individual-assessments" "describe-replication-tasks" "describe-schemas" "describe-table-statistics" "import-certificate" "list-tags-for-resource" "modify-endpoint" "modify-event-subscription" "modify-replication-instance" "modify-replication-subnet-group" "modify-replication-task" "move-replication-task" "reboot-replication-instance" "refresh-schemas" "reload-tables" "remove-tags-from-resource" "run-fleet-advisor-lsa-analysis" "start-recommendations" "start-replication-task" "start-replication-task-assessment" "start-replication-task-assessment-run" "stop-replication-task" "test-connection" "update-subscriptions-to-event-bridge" "commands"] | sort) } | get name | first)
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

# Adds metadata tags to an DMS resource, including replication instance, endpoint, subnet group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /
# Returns: record
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
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
  resource_arn: string # Identifies the DMS resource to which tags should be added. The value for this parameter is an Amazon Resource Name (ARN). For DMS, you can tag a replication instance, an endpoint, or a replication task.
  tags: list # One or more tags to be assigned to the resource. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.AddTagsToResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Applies a pending maintenance action to a resource (for example, to a replication instance).
#
# POST /
# Returns: record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: string, PendingMaintenanceActionDetails: list<record>>>
# operationId: ApplyPendingMaintenanceAction
export def "apply-pending-maintenance-action" [
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
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the DMS resource that the pending maintenance action applies to.
  apply_action: string # The pending maintenance action to apply to this resource. Valid values: os-upgrade, system-update, db-upgrade
  opt_in_type: string # A value that specifies the type of opt-in request, or undoes an opt-in request. You can't undo an opt-in request of type immediate. Valid values: immediate - Apply the maintenance action immediately. next-maintenance - Apply the maintenance action during the next maintenance window for the resource. undo-opt-in - Cancel any existing next-maintenance opt-in requests.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ApplyPendingMaintenanceAction"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: ApplyAction, var: apply_action}, {name: OptInType, var: opt_in_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, apply_action: $apply_action, opt_in_type: $opt_in_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the analysis of up to 20 source databases to recommend target engines for each source database. This is a batch version of StartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_StartRecommendations.html). The result of analysis of each source database is reported individually in the response. Because the batch request can result in a combination of successful and unsuccessful actions, you should check for batch errors even when the call returns an HTTP status code of 200.
#
# POST /
# Returns: record<ErrorEntries: table<DatabaseId: string, Message: string, Code: string>>
# operationId: BatchStartRecommendations
export def "batch-start-recommendations" [
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
  --data: list # Provides information about source databases to analyze. After this analysis, Fleet Advisor recommends target engines for each source database. — item shape: {DatabaseId: string, Settings: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.BatchStartRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a single premigration assessment run. This operation prevents any individual assessments from running if they haven't started running. It also attempts to cancel any individual assessments that are currently running.
#
# POST /
# Returns: record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>
# operationId: CancelReplicationTaskAssessmentRun
export def "cancel-replication-task-assessment-run" [
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
  replication_task_assessment_run_arn: string # Amazon Resource Name (ARN) of the premigration assessment run to be canceled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CancelReplicationTaskAssessmentRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskAssessmentRunArn, var: replication_task_assessment_run_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_assessment_run_arn: $replication_task_assessment_run_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an endpoint using the provided settings. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the CreateEndpoint API call. Specifying DatabaseName when you create a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /
# Returns: record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>
# operationId: CreateEndpoint
export def "create-endpoint" [
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
  endpoint_identifier: string # The database endpoint identifier. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen, or contain two consecutive hyphens.
  endpoint_type: string@endpoint-type-completer # The type of endpoint. Valid values are source and target.
  engine_name: string # The type of engine for the endpoint. Valid values, depending on the EndpointType value, include "mysql", "oracle", "postgres", "mariadb", "aurora", "aurora-postgresql", "opensearch", "redshift", "s3", "db2", "db2-zos", "azuredb", "sybase", "dynamodb", "mongodb", "kinesis", "kafka", "elasticsearch", "docdb", "sqlserver", "neptune", and "babelfish".
  --username: string # The user name to be used to log in to the endpoint database.
  --password: string # The password to be used to log in to the endpoint database. (format: password)
  --server-name: string # The name of the server where the endpoint database resides.
  --port: int # The port used by the endpoint database.
  --database-name: string # The name of the endpoint database. For a MySQL source or target endpoint, do not specify DatabaseName. To migrate to a specific database, use this setting and targetDbType.
  --extra-connection-attributes: string # Additional attributes associated with the connection. Each attribute is specified as a name-value pair associated by an equal sign (=). Multiple attributes are separated by a semicolon (;) with no additional white space. For information on the attributes available for connecting your source or target endpoint, see Working with DMS Endpoints (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Endpoints.html) in the Database Migration Service User Guide.
  --kms-key-id: string # An KMS key identifier that is used to encrypt the connection parameters for the endpoint. If you don't specify a value for the KmsKeyId parameter, then DMS uses your default encryption key. KMS creates the default encryption key for your Amazon Web Services account. Your Amazon Web Services account has a different default encryption key for each Amazon Web Services Region.
  --tags: list # One or more tags to be assigned to the endpoint. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --certificate-arn: string # The Amazon Resource Name (ARN) for the certificate.
  --ssl-mode: string@ssl-mode-completer # The Secure Sockets Layer (SSL) mode to use for the SSL connection. The default is none
  --service-access-role-arn: string # The Amazon Resource Name (ARN) for the service access role that you want to use to create the endpoint. The role must allow the iam:PassRole action.
  --external-table-definition: string # The external table definition.
  --dynamo-db-settings: record # Provides the Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to define an Amazon DynamoDB target endpoint. — shape: {ServiceAccessRoleArn: string}
  --s3-settings: record # Settings for exporting data to Amazon S3. — shape: {ServiceAccessRoleArn?: string, ExternalTableDefinition?: string, CsvRowDelimiter?: string, CsvDelimiter?: string, BucketFolder?: string, BucketName?: string, CompressionType?: "none"|"gzip", EncryptionMode?: "sse-s3"|"sse-kms", ServerSideEncryptionKmsKeyId?: string, DataFormat?: "csv"|"parquet", EncodingType?: "plain"|"plain-dictionary"|"rle-dictionary", DictPageSizeLimit?: int, RowGroupLength?: int, DataPageSize?: int, ParquetVersion?: "parquet-1-0"|"parquet-2-0", EnableStatistics?: bool, ... (25 more fields)}
  --dms-transfer-settings: record # The settings in JSON format for the DMS Transfer type source endpoint. — shape: {ServiceAccessRoleArn?: string, BucketName?: string}
  --mongo-db-settings: record # Provides information that defines a MongoDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, AuthType?: "no"|"password", AuthMechanism?: "default"|"mongodb_cr"|"scram_sha_1", NestingLevel?: "none"|"one", ExtractDocId?: string, DocsToInvestigate?: string, AuthSource?: string, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --kinesis-settings: record # Provides information that describes an Amazon Kinesis Data Stream endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {StreamArn?: string, MessageFormat?: "json"|"json-unformatted", ServiceAccessRoleArn?: string, IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, IncludeNullAndEmpty?: bool, NoHexPrefix?: bool}
  --kafka-settings: record # Provides information that describes an Apache Kafka endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {Broker?: string, Topic?: string, MessageFormat?: "json"|"json-unformatted", IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, MessageMaxBytes?: int, IncludeNullAndEmpty?: bool, SecurityProtocol?: "plaintext"|"ssl-authentication"|"ssl-encryption"|"sasl-ssl", SslClientCertificateArn?: string, SslClientKeyArn?: string, SslClientKeyPassword?: string, SslCaCertificateArn?: string, ... (4 more fields)}
  --elasticsearch-settings: record # Provides information that defines an OpenSearch endpoint. — shape: {ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage?: int, ErrorRetryDuration?: int, UseNewMappingType?: bool}
  --neptune-settings: record # Provides information that defines an Amazon Neptune endpoint. — shape: {ServiceAccessRoleArn?: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration?: int, MaxFileSize?: int, MaxRetryCount?: int, IamAuthEnabled?: bool}
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: bool, AfterConnectScript?: string, BucketFolder?: string, BucketName?: string, CaseSensitiveNames?: bool, CompUpdate?: bool, ConnectionTimeout?: int, DatabaseName?: string, DateFormat?: string, EmptyAsNull?: bool, EncryptionMode?: "sse-s3"|"sse-kms", ExplicitIds?: bool, FileTransferUploadStreams?: int, LoadTimeout?: int, MaxFileSize?: int, Password?: string, Port?: int, RemoveQuotes?: bool, ReplaceInvalidChars?: string, ReplaceChars?: string, ServerName?: string, ... (10 more fields)}
  --postgre-sql-settings: record # Provides information that defines a PostgreSQL endpoint. — shape: {AfterConnectScript?: string, CaptureDdls?: bool, MaxFileSize?: int, DatabaseName?: string, DdlArtifactsSchema?: string, ExecuteTimeout?: int, FailTasksOnLobTruncation?: bool, HeartbeatEnable?: bool, HeartbeatSchema?: string, HeartbeatFrequency?: int, Password?: string, Port?: int, ServerName?: string, Username?: string, SlotName?: string, PluginName?: "no-preference"|"test-decoding"|"pglogical", SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (1 more fields)}
  --my-sql-settings: record # Provides information that defines a MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --oracle-settings: record # Provides information that defines an Oracle endpoint. — shape: {AddSupplementalLogging?: bool, ArchivedLogDestId?: int, AdditionalArchivedLogDestId?: int, ExtraArchivedLogDestIds?: list<int>, AllowSelectNestedTables?: bool, ParallelAsmReadThreads?: int, ReadAheadBlocks?: int, AccessAlternateDirectly?: bool, UseAlternateFolderForOnline?: bool, OraclePathPrefix?: string, UsePathPrefix?: string, ReplacePathPrefix?: bool, EnableHomogenousTablespace?: bool, DirectPathNoLog?: bool, ArchivedLogsOnly?: bool, AsmPassword?: string, AsmServer?: string, AsmUser?: string, ... (24 more fields)}
  --sybase-settings: record # Provides information that defines a SAP ASE endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --microsoft-sql-server-settings: record # Provides information that defines a Microsoft SQL Server endpoint. — shape: {Port?: int, BcpPacketSize?: int, DatabaseName?: string, ControlTablesFileGroup?: string, Password?: string, QuerySingleAlwaysOnNode?: bool, ReadBackupOnly?: bool, SafeguardPolicy?: "rely-on-sql-server-replication-agent"|"exclusive-automatic-truncation"|"shared-automatic-truncation", ServerName?: string, Username?: string, UseBcpFullLoad?: bool, UseThirdPartyBackupDevice?: bool, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (2 more fields)}
  --ibm-db2-settings: record # Provides information that defines an IBM Db2 LUW endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, SetDataCaptureChanges?: bool, CurrentLsn?: string, MaxKBytesPerRead?: int, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
  --doc-db-settings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, NestingLevel?: "none"|"one", ExtractDocId?: bool, DocsToInvestigate?: int, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --redis-settings: record # Provides information that defines a Redis target endpoint. — shape: {ServerName: string, Port: int, SslSecurityProtocol?: "plaintext"|"ssl-encryption", AuthType?: "none"|"auth-role"|"auth-token", AuthUserName?: string, AuthPassword?: string, SslCaCertificateArn?: string}
  --gcp-my-sql-settings: record # Settings in JSON format for the source GCP MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointIdentifier, var: endpoint_identifier}, {name: EndpointType, var: endpoint_type}, {name: EngineName, var: engine_name}, {name: Username, var: username}, {name: Password, var: password}, {name: ServerName, var: server_name}, {name: Port, var: port}, {name: DatabaseName, var: database_name}, {name: ExtraConnectionAttributes, var: extra_connection_attributes}, {name: KmsKeyId, var: kms_key_id}, {name: Tags, var: tags}, {name: CertificateArn, var: certificate_arn}, {name: SslMode, var: ssl_mode}, {name: ServiceAccessRoleArn, var: service_access_role_arn}, {name: ExternalTableDefinition, var: external_table_definition}, {name: DynamoDbSettings, var: dynamo_db_settings}, {name: S3Settings, var: s3_settings}, {name: DmsTransferSettings, var: dms_transfer_settings}, {name: MongoDbSettings, var: mongo_db_settings}, {name: KinesisSettings, var: kinesis_settings}, {name: KafkaSettings, var: kafka_settings}, {name: ElasticsearchSettings, var: elasticsearch_settings}, {name: NeptuneSettings, var: neptune_settings}, {name: RedshiftSettings, var: redshift_settings}, {name: PostgreSQLSettings, var: postgre_sql_settings}, {name: MySQLSettings, var: my_sql_settings}, {name: OracleSettings, var: oracle_settings}, {name: SybaseSettings, var: sybase_settings}, {name: MicrosoftSQLServerSettings, var: microsoft_sql_server_settings}, {name: IBMDb2Settings, var: ibm_db2_settings}, {name: ResourceIdentifier, var: resource_identifier}, {name: DocDbSettings, var: doc_db_settings}, {name: RedisSettings, var: redis_settings}, {name: GcpMySQLSettings, var: gcp_my_sql_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_identifier: $endpoint_identifier, endpoint_type: $endpoint_type, engine_name: $engine_name, username: $username, password: $password, server_name: $server_name, port: $port, database_name: $database_name, extra_connection_attributes: $extra_connection_attributes, kms_key_id: $kms_key_id, tags: $tags, certificate_arn: $certificate_arn, ssl_mode: $ssl_mode, service_access_role_arn: $service_access_role_arn, external_table_definition: $external_table_definition, dynamo_db_settings: $dynamo_db_settings, s3_settings: $s3_settings, dms_transfer_settings: $dms_transfer_settings, mongo_db_settings: $mongo_db_settings, kinesis_settings: $kinesis_settings, kafka_settings: $kafka_settings, elasticsearch_settings: $elasticsearch_settings, neptune_settings: $neptune_settings, redshift_settings: $redshift_settings, postgre_sql_settings: $postgre_sql_settings, my_sql_settings: $my_sql_settings, oracle_settings: $oracle_settings, sybase_settings: $sybase_settings, microsoft_sql_server_settings: $microsoft_sql_server_settings, ibm_db2_settings: $ibm_db2_settings, resource_identifier: $resource_identifier, doc_db_settings: $doc_db_settings, redis_settings: $redis_settings, gcp_my_sql_settings: $gcp_my_sql_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an DMS event notification subscription. You can specify the type of source (SourceType) you want to be notified of, provide a list of DMS source IDs (SourceIds) that triggers the events, and provide a list of event categories (EventCategories) for events you want to be notified of. If you specify both the SourceType and SourceIds, such as SourceType = replication-instance and SourceIdentifier = my-replinstance, you will be notified of all the replication instance events for the specified source. If you specify a SourceType but don't specify a SourceIdentifier, you receive notice of the events for that source type for all your DMS sources. If you don't specify either SourceType nor SourceIdentifier, you will be notified of events generated from all DMS sources belonging to your customer account. For more information about DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>
# operationId: CreateEventSubscription
export def "create-event-subscription" [
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
  subscription_name: string # The name of the DMS event notification subscription. This name must be less than 255 characters.
  sns_topic_arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of DMS resource that generates the events. For example, if you want to be notified of events generated by a replication instance, you set this parameter to replication-instance. If this value isn't specified, all events are returned. Valid values: replication-instance | replication-task
  --event-categories: list<string> # A list of event categories for a source type that you want to subscribe to. For more information, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
  --source-ids: list<string> # A list of identifiers for which DMS provides notification events. If you don't specify a value, notifications are provided for all sources. If you specify multiple values, they must be of the same type. For example, if you specify a database instance ID, then all of the other values must be database instance IDs.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription, or set to false to create the subscription but not activate it.
  --tags: list # One or more tags to be assigned to the event subscription. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateEventSubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionName, var: subscription_name}, {name: SnsTopicArn, var: sns_topic_arn}, {name: SourceType, var: source_type}, {name: EventCategories, var: event_categories}, {name: SourceIds, var: source_ids}, {name: Enabled, var: enabled}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_name: $subscription_name, sns_topic_arn: $sns_topic_arn, source_type: $source_type, event_categories: $event_categories, source_ids: $source_ids, enabled: $enabled, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Fleet Advisor collector using the specified parameters.
#
# POST /
# Returns: record<CollectorReferencedId: string, CollectorName: string, Description: string, ServiceAccessRoleArn: string, S3BucketName: string>
# operationId: CreateFleetAdvisorCollector
export def "create-fleet-advisor-collector" [
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
  collector_name: string # The name of your Fleet Advisor collector (for example, sample-collector).
  --description: string # A summary description of your Fleet Advisor collector.
  service_access_role_arn: string # The IAM role that grants permissions to access the specified Amazon S3 bucket.
  s3_bucket_name: string # The Amazon S3 bucket that the Fleet Advisor collector uses to store inventory metadata.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateFleetAdvisorCollector"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CollectorName, var: collector_name}, {name: Description, var: description}, {name: ServiceAccessRoleArn, var: service_access_role_arn}, {name: S3BucketName, var: s3_bucket_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, collector_name: $collector_name, description: $description, service_access_role_arn: $service_access_role_arn, s3_bucket_name: $s3_bucket_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates the replication instance using the specified parameters. DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see Creating the IAM Roles to Use With the CLI and DMS API (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.APIRole). For information on the required permissions, see IAM Permissions Needed to Use DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html#CHAP_Security.IAMPermissions).
#
# POST /
# Returns: record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>
# operationId: CreateReplicationInstance
export def "create-replication-instance" [
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
  replication_instance_identifier: string # The replication instance identifier. This parameter is stored as a lowercase string. Constraints: Must contain 1-63 alphanumeric characters or hyphens. First character must be a letter. Can't end with a hyphen or contain two consecutive hyphens. Example: myrepinstance
  --allocated-storage: int # The amount of storage (in gigabytes) to be initially allocated for the replication instance.
  replication_instance_class: string # The compute and memory capacity of the replication instance as defined for the specified replication instance class. For example to specify the instance class dms.c4.large, set this parameter to "dms.c4.large". For more information on the settings and capacities for the available replication instance classes, see Selecting the right DMS replication instance for your migration (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReplicationInstance.html#CHAP_ReplicationInstance.InDepth).
  --vpc-security-group-ids: list<string> # Specifies the VPC security group to be used with the replication instance. The VPC security group must work with the VPC containing the replication instance.
  --availability-zone: string # The Availability Zone where the replication instance will be created. The default value is a random, system-chosen Availability Zone in the endpoint's Amazon Web Services Region, for example: us-east-1d
  --replication-subnet-group-identifier: string # A subnet group to associate with the replication instance.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi Default: A 30-minute window selected at random from an 8-hour block of time per Amazon Web Services Region, occurring on a random day of the week. Valid Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun Constraints: Minimum 30-minute window.
  --multi-az: oneof<nothing, bool> # Specifies whether the replication instance is a Multi-AZ deployment. You can't set the AvailabilityZone parameter if the Multi-AZ parameter is set to true.
  --engine-version: string # The engine version number of the replication instance. If an engine version number is not specified when a replication instance is created, the default is the latest engine version available.
  --auto-minor-version-upgrade: oneof<nothing, bool> # A value that indicates whether minor engine upgrades are applied automatically to the replication instance during the maintenance window. This parameter defaults to true. Default: true When AutoMinorVersionUpgrade is enabled, DMS uses the current default engine version when you create a replication instance. For example, if you set EngineVersion to a lower version number than the current default version, DMS uses the default version. If AutoMinorVersionUpgrade isn’t enabled when you create a replication instance, DMS uses the engine version specified by the EngineVersion parameter.
  --tags: list # One or more tags to be assigned to the replication instance. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --kms-key-id: string # An KMS key identifier that is used to encrypt the data on the replication instance. If you don't specify a value for the KmsKeyId parameter, then DMS uses your default encryption key. KMS creates the default encryption key for your Amazon Web Services account. Your Amazon Web Services account has a different default encryption key for each Amazon Web Services Region.
  --publicly-accessible: oneof<nothing, bool> # Specifies the accessibility options for the replication instance. A value of true represents an instance with a public IP address. A value of false represents an instance with a private IP address. The default value is true.
  --dns-name-servers: string # A list of custom DNS name servers supported for the replication instance to access your on-premise source or target database. This list overrides the default name servers supported by the replication instance. You can specify a comma-separated list of internet addresses for up to four on-premise DNS name servers. For example: "1.1.1.1,2.2.2.2,3.3.3.3,4.4.4.4"
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
  --network-type: string # The type of IP address protocol used by a replication instance, such as IPv4 only or Dual-stack that supports both IPv4 and IPv6 addressing. IPv6 only is not yet supported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateReplicationInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceIdentifier, var: replication_instance_identifier}, {name: AllocatedStorage, var: allocated_storage}, {name: ReplicationInstanceClass, var: replication_instance_class}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids}, {name: AvailabilityZone, var: availability_zone}, {name: ReplicationSubnetGroupIdentifier, var: replication_subnet_group_identifier}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: MultiAZ, var: multi_az}, {name: EngineVersion, var: engine_version}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: Tags, var: tags}, {name: KmsKeyId, var: kms_key_id}, {name: PubliclyAccessible, var: publicly_accessible}, {name: DnsNameServers, var: dns_name_servers}, {name: ResourceIdentifier, var: resource_identifier}, {name: NetworkType, var: network_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_identifier: $replication_instance_identifier, allocated_storage: $allocated_storage, replication_instance_class: $replication_instance_class, vpc_security_group_ids: $vpc_security_group_ids, availability_zone: $availability_zone, replication_subnet_group_identifier: $replication_subnet_group_identifier, preferred_maintenance_window: $preferred_maintenance_window, multi_az: $multi_az, engine_version: $engine_version, auto_minor_version_upgrade: $auto_minor_version_upgrade, tags: $tags, kms_key_id: $kms_key_id, publicly_accessible: $publicly_accessible, dns_name_servers: $dns_name_servers, resource_identifier: $resource_identifier, network_type: $network_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a replication subnet group given a list of the subnet IDs in a VPC. The VPC needs to have at least one subnet in at least two availability zones in the Amazon Web Services Region, otherwise the service will throw a ReplicationSubnetGroupDoesNotCoverEnoughAZs exception.
#
# POST /
# Returns: record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>
# operationId: CreateReplicationSubnetGroup
export def "create-replication-subnet-group" [
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
  replication_subnet_group_identifier: string # The name for the replication subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 alphanumeric characters, periods, spaces, underscores, or hyphens. Must not be "default". Example: mySubnetgroup
  replication_subnet_group_description: string # The description for the subnet group.
  subnet_ids: list<string> # One or more subnet IDs to be assigned to the subnet group.
  --tags: list # One or more tags to be assigned to the subnet group. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateReplicationSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationSubnetGroupIdentifier, var: replication_subnet_group_identifier}, {name: ReplicationSubnetGroupDescription, var: replication_subnet_group_description}, {name: SubnetIds, var: subnet_ids}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_subnet_group_identifier: $replication_subnet_group_identifier, replication_subnet_group_description: $replication_subnet_group_description, subnet_ids: $subnet_ids, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a replication task using the specified parameters.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: CreateReplicationTask
export def "create-replication-task" [
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
  replication_task_identifier: string # An identifier for the replication task. Constraints: Must contain 1-255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  source_endpoint_arn: string # An Amazon Resource Name (ARN) that uniquely identifies the source endpoint.
  target_endpoint_arn: string # An Amazon Resource Name (ARN) that uniquely identifies the target endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of a replication instance.
  migration_type: string@migration-type-completer # The migration type. Valid values: full-load | cdc | full-load-and-cdc
  table_mappings: string # The table mappings for the task, in JSON format. For more information, see Using Table Mapping to Specify Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.html) in the Database Migration Service User Guide.
  --replication-task-settings: string # Overall settings for the task, in JSON format. For more information, see Specifying Task Settings for Database Migration Service Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TaskSettings.html) in the Database Migration Service User Guide.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
  --tags: list # One or more tags to be assigned to the replication task. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
  --task-data: string # Supplemental information that the task requires to migrate the data for certain source and target endpoints. For more information, see Specifying Supplemental Data for Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.TaskData.html) in the Database Migration Service User Guide.
  --resource-identifier: string # A friendly name for the resource identifier at the end of the EndpointArn response parameter that is returned in the created Endpoint object. The value for this parameter can have up to 31 characters. It can contain only ASCII letters, digits, and hyphen ('-'). Also, it can't end with a hyphen or contain two consecutive hyphens, and can only begin with a letter, such as Example-App-ARN1. For example, this value might result in the EndpointArn value arn:aws:dms:eu-west-1:012345678901:rep:Example-App-ARN1. If you don't specify a ResourceIdentifier value, DMS generates a default identifier value for the end of EndpointArn.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.CreateReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskIdentifier, var: replication_task_identifier}, {name: SourceEndpointArn, var: source_endpoint_arn}, {name: TargetEndpointArn, var: target_endpoint_arn}, {name: ReplicationInstanceArn, var: replication_instance_arn}, {name: MigrationType, var: migration_type}, {name: TableMappings, var: table_mappings}, {name: ReplicationTaskSettings, var: replication_task_settings}, {name: CdcStartTime, var: cdc_start_time}, {name: CdcStartPosition, var: cdc_start_position}, {name: CdcStopPosition, var: cdc_stop_position}, {name: Tags, var: tags}, {name: TaskData, var: task_data}, {name: ResourceIdentifier, var: resource_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_identifier: $replication_task_identifier, source_endpoint_arn: $source_endpoint_arn, target_endpoint_arn: $target_endpoint_arn, replication_instance_arn: $replication_instance_arn, migration_type: $migration_type, table_mappings: $table_mappings, replication_task_settings: $replication_task_settings, cdc_start_time: $cdc_start_time, cdc_start_position: $cdc_start_position, cdc_stop_position: $cdc_stop_position, tags: $tags, task_data: $task_data, resource_identifier: $resource_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified certificate.
#
# POST /
# Returns: record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>
# operationId: DeleteCertificate
export def "delete-certificate" [
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
  certificate_arn: string # The Amazon Resource Name (ARN) of the certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CertificateArn, var: certificate_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, certificate_arn: $certificate_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the connection between a replication instance and an endpoint.
#
# POST /
# Returns: record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>
# operationId: DeleteConnection
export def "delete-connection" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}, {name: ReplicationInstanceArn, var: replication_instance_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn, replication_instance_arn: $replication_instance_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified endpoint. All tasks associated with the endpoint must be deleted before you can delete the endpoint.
#
# POST /
# Returns: record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>
# operationId: DeleteEndpoint
export def "delete-endpoint" [
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
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an DMS event subscription.
#
# POST /
# Returns: record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>
# operationId: DeleteEventSubscription
export def "delete-event-subscription" [
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
  subscription_name: string # The name of the DMS event notification subscription to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteEventSubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionName, var: subscription_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_name: $subscription_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Fleet Advisor collector.
#
# POST /
# operationId: DeleteFleetAdvisorCollector
export def "delete-fleet-advisor-collector" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  collector_referenced_id: string # The reference ID of the Fleet Advisor collector to delete.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteFleetAdvisorCollector"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CollectorReferencedId, var: collector_referenced_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, collector_referenced_id: $collector_referenced_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Fleet Advisor collector databases.
#
# POST /
# Returns: record<DatabaseIds: list<string>>
# operationId: DeleteFleetAdvisorDatabases
export def "delete-fleet-advisor-databases" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  database_ids: list<string> # The IDs of the Fleet Advisor collector databases to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteFleetAdvisorDatabases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatabaseIds, var: database_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, database_ids: $database_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified replication instance. You must delete any migration tasks that are associated with the replication instance before you can delete it.
#
# POST /
# Returns: record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>
# operationId: DeleteReplicationInstance
export def "delete-replication-instance" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteReplicationInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a subnet group.
#
# POST /
# Returns: record
# operationId: DeleteReplicationSubnetGroup
export def "delete-replication-subnet-group" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  replication_subnet_group_identifier: string # The subnet group name of the replication instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteReplicationSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationSubnetGroupIdentifier, var: replication_subnet_group_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_subnet_group_identifier: $replication_subnet_group_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified replication task.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: DeleteReplicationTask
export def "delete-replication-task" [
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
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the record of a single premigration assessment run. This operation removes all metadata that DMS maintains about this assessment run. However, the operation leaves untouched all information about this assessment run that is stored in your Amazon S3 bucket.
#
# POST /
# Returns: record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>
# operationId: DeleteReplicationTaskAssessmentRun
export def "delete-replication-task-assessment-run" [
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
  replication_task_assessment_run_arn: string # Amazon Resource Name (ARN) of the premigration assessment run to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DeleteReplicationTaskAssessmentRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskAssessmentRunArn, var: replication_task_assessment_run_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_assessment_run_arn: $replication_task_assessment_run_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the DMS attributes for a customer account. These attributes include DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region. This command does not take any parameters.
#
# POST /
# Returns: record<AccountQuotas: table<AccountQuotaName: string, Used: int, Max: int>, UniqueAccountIdentifier: string>
# operationId: DescribeAccountAttributes
export def "describe-account-attributes" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeAccountAttributes"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of individual assessments that you can specify for a new premigration assessment run, given one or more parameters. If you specify an existing migration task, this operation provides the default individual assessments you can specify for that task. Otherwise, the specified parameters model elements of a possible migration task on which to base a premigration assessment run. To use these migration task modeling parameters, you must specify an existing replication instance, a source database engine, a target database engine, and a migration type. This combination of parameters potentially limits the default individual assessments available for an assessment run created for a corresponding migration task. If you specify no parameters, this operation provides a list of all possible individual assessments that you can specify for an assessment run. If you specify any one of the task modeling parameters, you must specify all of them or the operation cannot provide a list of individual assessments. The only parameter that you can specify alone is for an existing migration task. The specified task definition then determines the default list of individual assessments that you can specify in an assessment run for the task.
#
# POST /
# Returns: record<IndividualAssessmentNames: list<string>, Marker: string>
# operationId: DescribeApplicableIndividualAssessments
export def "describe-applicable-individual-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --replication-task-arn: string # Amazon Resource Name (ARN) of a migration task on which you want to base the default list of individual assessments.
  --replication-instance-arn: string # ARN of a replication instance on which you want to base the default list of individual assessments.
  --source-engine-name: string # Name of a database engine that the specified replication instance supports as a source.
  --target-engine-name: string # Name of a database engine that the specified replication instance supports as a target.
  --migration-type: string@migration-type-completer # Name of the migration type that each provided individual assessment must support.
  --body-max-records: int # Maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # Optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeApplicableIndividualAssessments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: ReplicationInstanceArn, var: replication_instance_arn}, {name: SourceEngineName, var: source_engine_name}, {name: TargetEngineName, var: target_engine_name}, {name: MigrationType, var: migration_type}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, replication_instance_arn: $replication_instance_arn, source_engine_name: $source_engine_name, target_engine_name: $target_engine_name, migration_type: $migration_type, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a description of the certificate.
#
# POST /
# Returns: record<Marker: string, Certificates: table<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>
# operationId: DescribeCertificates
export def "describe-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --filters: list # Filters applied to the certificates described in the form of key-value pairs. Valid values are certificate-arn and certificate-id. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 10 (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeCertificates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
#
# POST /
# Returns: record<Marker: string, Connections: table<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>
# operationId: DescribeConnections
export def "describe-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --filters: list # The filters applied to the connection. Valid filter names: endpoint-arn | replication-instance-arn — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the possible endpoint settings available when you create an endpoint for a specific database engine.
#
# POST /
# Returns: record<Marker: string, EndpointSettings: table<Name: string, Type: string, EnumValues: list, Sensitive: bool, Units: string, Applicability: string, IntValueMin: int, IntValueMax: int, DefaultValue: string>>
# operationId: DescribeEndpointSettings
export def "describe-endpoint-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  engine_name: string # The databse engine used for your source or target endpoint.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEndpointSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EngineName, var: engine_name}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, engine_name: $engine_name, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the type of endpoints available.
#
# POST /
# Returns: record<Marker: string, SupportedEndpointTypes: table<EngineName: string, SupportsCDC: bool, EndpointType: string, ReplicationInstanceEngineMinimumVersion: string, EngineDisplayName: string>>
# operationId: DescribeEndpointTypes
export def "describe-endpoint-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  --filters: list # Filters applied to the endpoint types. Valid filter names: engine-name | endpoint-type — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEndpointTypes"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the endpoints for your account in the current region.
#
# POST /
# Returns: record<Marker: string, Endpoints: table<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record, S3Settings: record, DmsTransferSettings: record, MongoDbSettings: record, KinesisSettings: record, KafkaSettings: record, ElasticsearchSettings: record, NeptuneSettings: record, RedshiftSettings: record, PostgreSQLSettings: record, MySQLSettings: record, OracleSettings: record, SybaseSettings: record, MicrosoftSQLServerSettings: record, IBMDb2Settings: record, DocDbSettings: record, RedisSettings: record, GcpMySQLSettings: record>>
# operationId: DescribeEndpoints
export def "describe-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --filters: list # Filters applied to the endpoints. Valid filter names: endpoint-arn | endpoint-type | endpoint-id | engine-name — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEndpoints"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<EventCategoryGroupList: table<SourceType: string, EventCategories: list>>
# operationId: DescribeEventCategories
export def "describe-event-categories" [
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
  --source-type: string # The type of DMS resource that generates events. Valid values: replication-instance | replication-task
  --filters: list # Filters applied to the event categories. — item shape: {Name: string, Values: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEventCategories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceType, var: source_type}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_type: $source_type, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the event subscriptions for a customer account. The description of a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify SubscriptionName, this action lists the description for that subscription.
#
# POST /
# Returns: record<Marker: string, EventSubscriptionsList: table<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list, EventCategoriesList: list, Enabled: bool>>
# operationId: DescribeEventSubscriptions
export def "describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --subscription-name: string # The name of the DMS event subscription to be described.
  --filters: list # Filters applied to event subscriptions. Valid filter names: event-subscription-arn | event-subscription-id — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEventSubscriptions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionName, var: subscription_name}, {name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_name: $subscription_name, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on DMS events, see Working with Events and Notifications (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<Marker: string, Events: table<SourceIdentifier: string, SourceType: string, Message: string, EventCategories: list, Date: string>>
# operationId: DescribeEvents
export def "describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --source-identifier: string # The identifier of an event source.
  --source-type: string@source-type-completer # The type of DMS resource that generates events. Valid values: replication-instance | replication-task
  --start-time: string # The start time for the events to be listed. (format: date-time)
  --end-time: string # The end time for the events to be listed. (format: date-time)
  --duration: int # The duration of the events to be listed.
  --event-categories: list<string> # A list of event categories for the source type that you've chosen.
  --filters: list # Filters applied to events. The only valid filter is replication-instance-id. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeEvents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceIdentifier, var: source_identifier}, {name: SourceType, var: source_type}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Duration, var: duration}, {name: EventCategories, var: event_categories}, {name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, source_identifier: $source_identifier, source_type: $source_type, start_time: $start_time, end_time: $end_time, duration: $duration, event_categories: $event_categories, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the Fleet Advisor collectors in your account.
#
# POST /
# Returns: record<Collectors: table<CollectorReferencedId: string, CollectorName: string, CollectorVersion: string, VersionStatus: string, Description: string, S3BucketName: string, ServiceAccessRoleArn: string, CollectorHealthCheck: record, LastDataReceived: string, RegisteredDate: string, CreatedDate: string, ModifiedDate: string, InventoryData: record>, NextToken: string>
# operationId: DescribeFleetAdvisorCollectors
export def "describe-fleet-advisor-collectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those collectors that meet the filter criteria: collector-referenced-id – The ID of the collector agent, for example d4610ac5-e323-4ad9-bc50-eaf7249dfe9d. collector-name – The name of the collector agent. An example is: describe-fleet-advisor-collectors --filter Name="collector-referenced-id",Values="d4610ac5-e323-4ad9-bc50-eaf7249dfe9d" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeFleetAdvisorCollectors"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Fleet Advisor databases in your account.
#
# POST /
# Returns: record<Databases: table<DatabaseId: string, DatabaseName: string, IpAddress: string, NumberOfSchemas: int, Server: record, SoftwareDetails: record, Collectors: list>, NextToken: string>
# operationId: DescribeFleetAdvisorDatabases
export def "describe-fleet-advisor-databases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those databases that meet the filter criteria: database-id – The ID of the database. database-name – The name of the database. database-engine – The name of the database engine. server-ip-address – The IP address of the database server. database-ip-address – The IP address of the database. collector-name – The name of the associated Fleet Advisor collector. An example is: describe-fleet-advisor-databases --filter Name="database-id",Values="45" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeFleetAdvisorDatabases"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides descriptions of large-scale assessment (LSA) analyses produced by your Fleet Advisor collectors.
#
# POST /
# Returns: record<Analysis: table<LsaAnalysisId: string, Status: string>, NextToken: string>
# operationId: DescribeFleetAdvisorLsaAnalysis
export def "describe-fleet-advisor-lsa-analysis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeFleetAdvisorLsaAnalysis"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides descriptions of the schemas discovered by your Fleet Advisor collectors.
#
# POST /
# Returns: record<FleetAdvisorSchemaObjects: table<SchemaId: string, ObjectType: string, NumberOfObjects: int, CodeLineCount: int, CodeSize: int>, NextToken: string>
# operationId: DescribeFleetAdvisorSchemaObjectSummary
export def "describe-fleet-advisor-schema-object-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those schema objects that meet the filter criteria: schema-id – The ID of the schema, for example d4610ac5-e323-4ad9-bc50-eaf7249dfe9d. Example: describe-fleet-advisor-schema-object-summary --filter Name="schema-id",Values="50" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeFleetAdvisorSchemaObjectSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of schemas detected by Fleet Advisor Collectors in your account.
#
# POST /
# Returns: record<FleetAdvisorSchemas: table<CodeLineCount: int, CodeSize: int, Complexity: string, Server: record, DatabaseInstance: record, SchemaId: string, SchemaName: string, OriginalSchema: record, Similarity: float>, NextToken: string>
# operationId: DescribeFleetAdvisorSchemas
export def "describe-fleet-advisor-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  --filters: list # If you specify any of the following filters, the output includes information for only those schemas that meet the filter criteria: complexity – The schema's complexity, for example Simple. database-id – The ID of the schema's database. database-ip-address – The IP address of the schema's database. database-name – The name of the schema's database. database-engine – The name of the schema database's engine. original-schema-name – The name of the schema's database's main schema. schema-id – The ID of the schema, for example 15. schema-name – The name of the schema. server-ip-address – The IP address of the schema database's server. An example is: describe-fleet-advisor-schemas --filter Name="schema-id",Values="50" — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # Sets the maximum number of records returned in the response. (spec name: MaxRecords)
  --body-next-token: string # If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeFleetAdvisorSchemas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the replication instance types that can be created in the specified region.
#
# POST /
# Returns: record<OrderableReplicationInstances: table<EngineVersion: string, ReplicationInstanceClass: string, StorageType: string, MinAllocatedStorage: int, MaxAllocatedStorage: int, DefaultAllocatedStorage: int, IncludedAllocatedStorage: int, AvailabilityZones: list, ReleaseStatus: string>, Marker: string>
# operationId: DescribeOrderableReplicationInstances
export def "describe-orderable-replication-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeOrderableReplicationInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For internal use only
#
# POST /
# Returns: record<PendingMaintenanceActions: table<ResourceIdentifier: string, PendingMaintenanceActionDetails: list>, Marker: string>
# operationId: DescribePendingMaintenanceActions
export def "describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  --replication-instance-arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --filters: list # item shape: {Name: string, Values: list<string>}
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribePendingMaintenanceActions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: Filters, var: filters}, {name: Marker, var: body_marker}, {name: MaxRecords, var: body_max_records}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, filters: $filters, body_marker: $body_marker, body_max_records: $body_max_records
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of limitations for recommendations of target Amazon Web Services engines.
#
# POST /
# Returns: record<NextToken: string, Limitations: table<DatabaseId: string, EngineName: string, Name: string, Description: string, Impact: string, Type: string>>
# operationId: DescribeRecommendationLimitations
export def "describe-recommendation-limitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  --filters: list # Filters applied to the limitations described in the form of key-value pairs. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, Fleet Advisor includes a pagination token in the response so that you can retrieve the remaining results. (spec name: MaxRecords)
  --body-next-token: string # Specifies the unique pagination token that makes it possible to display the next page of results. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeRecommendationLimitations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of target engine recommendations for your source databases.
#
# POST /
# Returns: record<NextToken: string, Recommendations: table<DatabaseId: string, EngineName: string, CreatedDate: string, Status: string, Preferred: bool, Settings: record, Data: record>>
# operationId: DescribeRecommendations
export def "describe-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  --filters: list # Filters applied to the target engine recommendations described in the form of key-value pairs. — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, Fleet Advisor includes a pagination token in the response so that you can retrieve the remaining results. (spec name: MaxRecords)
  --body-next-token: string # Specifies the unique pagination token that makes it possible to display the next page of results. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. If NextToken is returned by a previous response, there are more results available. The value of NextToken is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the status of the RefreshSchemas operation.
#
# POST /
# Returns: record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>
# operationId: DescribeRefreshSchemasStatus
export def "describe-refresh-schemas-status" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeRefreshSchemasStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the task logs for the specified task.
#
# POST /
# Returns: record<ReplicationInstanceArn: string, ReplicationInstanceTaskLogs: table<ReplicationTaskName: string, ReplicationTaskArn: string, ReplicationInstanceTaskLogSize: int>, Marker: string>
# operationId: DescribeReplicationInstanceTaskLogs
export def "describe-replication-instance-task-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about replication instances for your account in the current region.
#
# POST /
# Returns: record<Marker: string, ReplicationInstances: table<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list, AvailabilityZone: string, ReplicationSubnetGroup: record, PreferredMaintenanceWindow: string, PendingModifiedValues: record, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list, ReplicationInstancePrivateIpAddresses: list, ReplicationInstanceIpv6Addresses: list, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>
# operationId: DescribeReplicationInstances
export def "describe-replication-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  --filters: list # Filters applied to replication instances. Valid filter names: replication-instance-arn | replication-instance-id | replication-instance-class | engine-version — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the replication subnet groups.
#
# POST /
# Returns: record<Marker: string, ReplicationSubnetGroups: table<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>>
# operationId: DescribeReplicationSubnetGroups
export def "describe-replication-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  --filters: list # Filters applied to replication subnet groups. Valid filter names: replication-subnet-group-id — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationSubnetGroups"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the task assessment results from the Amazon S3 bucket that DMS creates in your Amazon Web Services account. This action always returns the latest results. For more information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<Marker: string, BucketName: string, ReplicationTaskAssessmentResults: table<ReplicationTaskIdentifier: string, ReplicationTaskArn: string, ReplicationTaskLastAssessmentDate: string, AssessmentStatus: string, AssessmentResultsFile: string, AssessmentResults: string, S3ObjectUrl: string>>
# operationId: DescribeReplicationTaskAssessmentResults
export def "describe-replication-task-assessment-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  --replication-task-arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the task. When this input parameter is specified, the API returns only one result and ignore the values of the MaxRecords and Marker parameters.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of premigration assessment runs based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, replication instances, and assessment run status values. This operation doesn't return information about individual assessments. For this information, see the DescribeReplicationTaskIndividualAssessments operation.
#
# POST /
# Returns: record<Marker: string, ReplicationTaskAssessmentRuns: table<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>
# operationId: DescribeReplicationTaskAssessmentRuns
export def "describe-replication-task-assessment-runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --filters: list # Filters applied to the premigration assessment runs described in the form of key-value pairs. Valid filter names: replication-task-assessment-run-arn, replication-task-arn, replication-instance-arn, status — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationTaskAssessmentRuns"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a paginated list of individual assessments based on filter settings. These filter settings can specify a combination of premigration assessment runs, migration tasks, and assessment status values.
#
# POST /
# Returns: record<Marker: string, ReplicationTaskIndividualAssessments: table<ReplicationTaskIndividualAssessmentArn: string, ReplicationTaskAssessmentRunArn: string, IndividualAssessmentName: string, Status: string, ReplicationTaskIndividualAssessmentStartDate: string>>
# operationId: DescribeReplicationTaskIndividualAssessments
export def "describe-replication-task-individual-assessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  --filters: list # Filters applied to the individual assessments described in the form of key-value pairs. Valid filter names: replication-task-assessment-run-arn, replication-task-arn, status — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationTaskIndividualAssessments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about replication tasks for your account in the current region.
#
# POST /
# Returns: record<Marker: string, ReplicationTasks: table<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: DescribeReplicationTasks
export def "describe-replication-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  --filters: list # Filters applied to replication tasks. Valid filter names: replication-task-arn | replication-task-id | migration-type | endpoint-arn | replication-instance-arn — item shape: {Name: string, Values: list<string>}
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --without-settings: oneof<nothing, bool> # An option to set to avoid returning information about settings. Use this to reduce overhead when setting information is too large. To use this option, choose true; otherwise, choose false (the default).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeReplicationTasks"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}, {name: WithoutSettings, var: without_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_records: $body_max_records, body_marker: $body_marker, without_settings: $without_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the schema for the specified endpoint.
#
# POST /
# Returns: record<Marker: string, Schemas: list<string>>
# operationId: DescribeSchemas
export def "describe-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeSchemas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn, body_max_records: $body_max_records, body_marker: $body_marker
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted. Note that the "last updated" column the DMS console only indicates the time that DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.
#
# POST /
# Returns: record<ReplicationTaskArn: string, TableStatistics: table<SchemaName: string, TableName: string, Inserts: int, Deletes: int, Updates: int, Ddls: int, AppliedInserts: int, AppliedDeletes: int, AppliedUpdates: int, AppliedDdls: int, FullLoadRows: int, FullLoadCondtnlChkFailedRows: int, FullLoadErrorRows: int, FullLoadStartTime: string, FullLoadEndTime: string, FullLoadReloaded: bool, LastUpdateTime: string, TableState: string, ValidationPendingRecords: int, ValidationFailedRecords: int, ValidationSuspendedRecords: int, ValidationState: string, ValidationStateDetails: string>, Marker: string>
# operationId: DescribeTableStatistics
export def "describe-table-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  --body-max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 500. (spec name: MaxRecords)
  --body-marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords. (spec name: Marker)
  --filters: list # Filters applied to table statistics. Valid filter names: schema-name | table-name | table-state A combination of filters creates an AND condition where each record matches all specified filters. — item shape: {Name: string, Values: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: Marker, var: marker}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.DescribeTableStatistics"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: MaxRecords, var: body_max_records}, {name: Marker, var: body_marker}, {name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, marker: $marker, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, body_max_records: $body_max_records, body_marker: $body_marker, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Uploads the specified certificate.
#
# POST /
# Returns: record<Certificate: record<CertificateIdentifier: string, CertificateCreationDate: string, CertificatePem: string, CertificateWallet: string, CertificateArn: string, CertificateOwner: string, ValidFromDate: string, ValidToDate: string, SigningAlgorithm: string, KeyLength: int>>
# operationId: ImportCertificate
export def "import-certificate" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  certificate_identifier: string # A customer-assigned name for the certificate. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen or contain two consecutive hyphens.
  --certificate-pem: string # The contents of a .pem file, which contains an X.509 certificate. (format: password)
  --certificate-wallet: string # The location of an imported Oracle Wallet certificate for use with SSL. Provide the name of a .sso file using the fileb:// prefix. You can't provide the certificate inline. Example: filebase64("${path.root}/rds-ca-2019-root.sso")
  --tags: list # The tags associated with the certificate. — item shape: {Key?: string, Value?: string, ResourceArn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ImportCertificate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CertificateIdentifier, var: certificate_identifier}, {name: CertificatePem, var: certificate_pem}, {name: CertificateWallet, var: certificate_wallet}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, certificate_identifier: $certificate_identifier, certificate_pem: $certificate_pem, certificate_wallet: $certificate_wallet, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all metadata tags attached to an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /
# Returns: record<TagList: table<Key: string, Value: string, ResourceArn: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --resource-arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the DMS resource to list tags for. This returns a list of keys (names of tags) created for the resource and their associated tag values.
  --resource-arn-list: list<string> # List of ARNs that identify multiple DMS resources that you want to list tags for. This returns a list of keys (tag names) and their associated tag values. It also returns each tag's associated ResourceArn value, which is the ARN of the resource for which each listed tag is created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: ResourceArnList, var: resource_arn_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, resource_arn_list: $resource_arn_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the specified endpoint. For a MySQL source or target endpoint, don't explicitly specify the database using the DatabaseName request parameter on the ModifyEndpoint API call. Specifying DatabaseName when you modify a MySQL endpoint replicates all the task tables to this single database. For MySQL endpoints, you specify the database only when you specify the schema in the table-mapping rules of the DMS task.
#
# POST /
# Returns: record<Endpoint: record<EndpointIdentifier: string, EndpointType: string, EngineName: string, EngineDisplayName: string, Username: string, ServerName: string, Port: int, DatabaseName: string, ExtraConnectionAttributes: string, Status: string, KmsKeyId: string, EndpointArn: string, CertificateArn: string, SslMode: string, ServiceAccessRoleArn: string, ExternalTableDefinition: string, ExternalId: string, DynamoDbSettings: record<ServiceAccessRoleArn: string>, S3Settings: record<ServiceAccessRoleArn: string, ExternalTableDefinition: string, CsvRowDelimiter: string, CsvDelimiter: string, BucketFolder: string, BucketName: string, CompressionType: string, EncryptionMode: string, ServerSideEncryptionKmsKeyId: string, DataFormat: string, EncodingType: string, DictPageSizeLimit: int, RowGroupLength: int, DataPageSize: int, ParquetVersion: string, EnableStatistics: bool, IncludeOpForFullLoad: bool, CdcInsertsOnly: bool, TimestampColumnName: string, ParquetTimestampInMillisecond: bool, CdcInsertsAndUpdates: bool, DatePartitionEnabled: bool, DatePartitionSequence: string, DatePartitionDelimiter: string, UseCsvNoSupValue: bool, CsvNoSupValue: string, PreserveTransactions: bool, CdcPath: string, UseTaskStartTimeForFullLoadTimestamp: bool, CannedAclForObjects: string, AddColumnName: bool, CdcMaxBatchInterval: int, CdcMinFileSize: int, CsvNullValue: string, IgnoreHeaderRows: int, MaxFileSize: int, Rfc4180: bool, DatePartitionTimezone: string, AddTrailingPaddingCharacter: bool, ExpectedBucketOwner: string, GlueCatalogGeneration: bool>, DmsTransferSettings: record<ServiceAccessRoleArn: string, BucketName: string>, MongoDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, AuthType: string, AuthMechanism: string, NestingLevel: string, ExtractDocId: string, DocsToInvestigate: string, AuthSource: string, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, KinesisSettings: record<StreamArn: string, MessageFormat: string, ServiceAccessRoleArn: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, IncludeNullAndEmpty: bool, NoHexPrefix: bool>, KafkaSettings: record<Broker: string, Topic: string, MessageFormat: string, IncludeTransactionDetails: bool, IncludePartitionValue: bool, PartitionIncludeSchemaTable: bool, IncludeTableAlterOperations: bool, IncludeControlDetails: bool, MessageMaxBytes: int, IncludeNullAndEmpty: bool, SecurityProtocol: string, SslClientCertificateArn: string, SslClientKeyArn: string, SslClientKeyPassword: string, SslCaCertificateArn: string, SaslUsername: string, SaslPassword: string, NoHexPrefix: bool, SaslMechanism: string>, ElasticsearchSettings: record<ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage: int, ErrorRetryDuration: int, UseNewMappingType: bool>, NeptuneSettings: record<ServiceAccessRoleArn: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration: int, MaxFileSize: int, MaxRetryCount: int, IamAuthEnabled: bool>, RedshiftSettings: record<AcceptAnyDate: bool, AfterConnectScript: string, BucketFolder: string, BucketName: string, CaseSensitiveNames: bool, CompUpdate: bool, ConnectionTimeout: int, DatabaseName: string, DateFormat: string, EmptyAsNull: bool, EncryptionMode: string, ExplicitIds: bool, FileTransferUploadStreams: int, LoadTimeout: int, MaxFileSize: int, Password: string, Port: int, RemoveQuotes: bool, ReplaceInvalidChars: string, ReplaceChars: string, ServerName: string, ServiceAccessRoleArn: string, ServerSideEncryptionKmsKeyId: string, TimeFormat: string, TrimBlanks: bool, TruncateColumns: bool, Username: string, WriteBufferSize: int, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, MapBooleanAsBoolean: bool>, PostgreSQLSettings: record<AfterConnectScript: string, CaptureDdls: bool, MaxFileSize: int, DatabaseName: string, DdlArtifactsSchema: string, ExecuteTimeout: int, FailTasksOnLobTruncation: bool, HeartbeatEnable: bool, HeartbeatSchema: string, HeartbeatFrequency: int, Password: string, Port: int, ServerName: string, Username: string, SlotName: string, PluginName: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, MapBooleanAsBoolean: bool>, MySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, OracleSettings: record<AddSupplementalLogging: bool, ArchivedLogDestId: int, AdditionalArchivedLogDestId: int, ExtraArchivedLogDestIds: list, AllowSelectNestedTables: bool, ParallelAsmReadThreads: int, ReadAheadBlocks: int, AccessAlternateDirectly: bool, UseAlternateFolderForOnline: bool, OraclePathPrefix: string, UsePathPrefix: string, ReplacePathPrefix: bool, EnableHomogenousTablespace: bool, DirectPathNoLog: bool, ArchivedLogsOnly: bool, AsmPassword: string, AsmServer: string, AsmUser: string, CharLengthSemantics: string, DatabaseName: string, DirectPathParallelLoad: bool, FailTasksOnLobTruncation: bool, NumberDatatypeScale: int, Password: string, Port: int, ReadTableSpaceName: bool, RetryInterval: int, SecurityDbEncryption: string, SecurityDbEncryptionName: string, ServerName: string, SpatialDataOptionToGeoJsonFunctionName: string, StandbyDelayTime: int, Username: string, UseBFile: bool, UseDirectPathFullLoad: bool, UseLogminerReader: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, SecretsManagerOracleAsmAccessRoleArn: string, SecretsManagerOracleAsmSecretId: string, TrimSpaceInChar: bool, ConvertTimestampWithZoneToUTC: bool>, SybaseSettings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, MicrosoftSQLServerSettings: record<Port: int, BcpPacketSize: int, DatabaseName: string, ControlTablesFileGroup: string, Password: string, QuerySingleAlwaysOnNode: bool, ReadBackupOnly: bool, SafeguardPolicy: string, ServerName: string, Username: string, UseBcpFullLoad: bool, UseThirdPartyBackupDevice: bool, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string, TrimSpaceInChar: bool, TlogAccessMode: string, ForceLobLookup: bool>, IBMDb2Settings: record<DatabaseName: string, Password: string, Port: int, ServerName: string, SetDataCaptureChanges: bool, CurrentLsn: string, MaxKBytesPerRead: int, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, DocDbSettings: record<Username: string, Password: string, ServerName: string, Port: int, DatabaseName: string, NestingLevel: string, ExtractDocId: bool, DocsToInvestigate: int, KmsKeyId: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>, RedisSettings: record<ServerName: string, Port: int, SslSecurityProtocol: string, AuthType: string, AuthUserName: string, AuthPassword: string, SslCaCertificateArn: string>, GcpMySQLSettings: record<AfterConnectScript: string, CleanSourceMetadataOnMismatch: bool, DatabaseName: string, EventsPollInterval: int, TargetDbType: string, MaxFileSize: int, ParallelLoadThreads: int, Password: string, Port: int, ServerName: string, ServerTimezone: string, Username: string, SecretsManagerAccessRoleArn: string, SecretsManagerSecretId: string>>>
# operationId: ModifyEndpoint
export def "modify-endpoint" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  --endpoint-identifier: string # The database endpoint identifier. Identifiers must begin with a letter and must contain only ASCII letters, digits, and hyphens. They can't end with a hyphen or contain two consecutive hyphens.
  --endpoint-type: string@endpoint-type-completer # The type of endpoint. Valid values are source and target.
  --engine-name: string # The database engine name. Valid values, depending on the EndpointType, include "mysql", "oracle", "postgres", "mariadb", "aurora", "aurora-postgresql", "redshift", "s3", "db2", "db2-zos", "azuredb", "sybase", "dynamodb", "mongodb", "kinesis", "kafka", "elasticsearch", "documentdb", "sqlserver", "neptune", and "babelfish".
  --username: string # The user name to be used to login to the endpoint database.
  --password: string # The password to be used to login to the endpoint database. (format: password)
  --server-name: string # The name of the server where the endpoint database resides.
  --port: int # The port used by the endpoint database.
  --database-name: string # The name of the endpoint database. For a MySQL source or target endpoint, do not specify DatabaseName.
  --extra-connection-attributes: string # Additional attributes associated with the connection. To reset this parameter, pass the empty string ("") as an argument.
  --certificate-arn: string # The Amazon Resource Name (ARN) of the certificate used for SSL connection.
  --ssl-mode: string@ssl-mode-completer # The SSL mode used to connect to the endpoint. The default value is none.
  --service-access-role-arn: string # The Amazon Resource Name (ARN) for the IAM role you want to use to modify the endpoint. The role must allow the iam:PassRole action.
  --external-table-definition: string # The external table definition.
  --dynamo-db-settings: record # Provides the Amazon Resource Name (ARN) of the Identity and Access Management (IAM) role used to define an Amazon DynamoDB target endpoint. — shape: {ServiceAccessRoleArn: string}
  --s3-settings: record # Settings for exporting data to Amazon S3. — shape: {ServiceAccessRoleArn?: string, ExternalTableDefinition?: string, CsvRowDelimiter?: string, CsvDelimiter?: string, BucketFolder?: string, BucketName?: string, CompressionType?: "none"|"gzip", EncryptionMode?: "sse-s3"|"sse-kms", ServerSideEncryptionKmsKeyId?: string, DataFormat?: "csv"|"parquet", EncodingType?: "plain"|"plain-dictionary"|"rle-dictionary", DictPageSizeLimit?: int, RowGroupLength?: int, DataPageSize?: int, ParquetVersion?: "parquet-1-0"|"parquet-2-0", EnableStatistics?: bool, ... (25 more fields)}
  --dms-transfer-settings: record # The settings in JSON format for the DMS Transfer type source endpoint. — shape: {ServiceAccessRoleArn?: string, BucketName?: string}
  --mongo-db-settings: record # Provides information that defines a MongoDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, AuthType?: "no"|"password", AuthMechanism?: "default"|"mongodb_cr"|"scram_sha_1", NestingLevel?: "none"|"one", ExtractDocId?: string, DocsToInvestigate?: string, AuthSource?: string, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --kinesis-settings: record # Provides information that describes an Amazon Kinesis Data Stream endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {StreamArn?: string, MessageFormat?: "json"|"json-unformatted", ServiceAccessRoleArn?: string, IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, IncludeNullAndEmpty?: bool, NoHexPrefix?: bool}
  --kafka-settings: record # Provides information that describes an Apache Kafka endpoint. This information includes the output format of records applied to the endpoint and details of transaction and control table data information. — shape: {Broker?: string, Topic?: string, MessageFormat?: "json"|"json-unformatted", IncludeTransactionDetails?: bool, IncludePartitionValue?: bool, PartitionIncludeSchemaTable?: bool, IncludeTableAlterOperations?: bool, IncludeControlDetails?: bool, MessageMaxBytes?: int, IncludeNullAndEmpty?: bool, SecurityProtocol?: "plaintext"|"ssl-authentication"|"ssl-encryption"|"sasl-ssl", SslClientCertificateArn?: string, SslClientKeyArn?: string, SslClientKeyPassword?: string, SslCaCertificateArn?: string, ... (4 more fields)}
  --elasticsearch-settings: record # Provides information that defines an OpenSearch endpoint. — shape: {ServiceAccessRoleArn: string, EndpointUri: string, FullLoadErrorPercentage?: int, ErrorRetryDuration?: int, UseNewMappingType?: bool}
  --neptune-settings: record # Provides information that defines an Amazon Neptune endpoint. — shape: {ServiceAccessRoleArn?: string, S3BucketName: string, S3BucketFolder: string, ErrorRetryDuration?: int, MaxFileSize?: int, MaxRetryCount?: int, IamAuthEnabled?: bool}
  --redshift-settings: record # Provides information that defines an Amazon Redshift endpoint. — shape: {AcceptAnyDate?: bool, AfterConnectScript?: string, BucketFolder?: string, BucketName?: string, CaseSensitiveNames?: bool, CompUpdate?: bool, ConnectionTimeout?: int, DatabaseName?: string, DateFormat?: string, EmptyAsNull?: bool, EncryptionMode?: "sse-s3"|"sse-kms", ExplicitIds?: bool, FileTransferUploadStreams?: int, LoadTimeout?: int, MaxFileSize?: int, Password?: string, Port?: int, RemoveQuotes?: bool, ReplaceInvalidChars?: string, ReplaceChars?: string, ServerName?: string, ... (10 more fields)}
  --postgre-sql-settings: record # Provides information that defines a PostgreSQL endpoint. — shape: {AfterConnectScript?: string, CaptureDdls?: bool, MaxFileSize?: int, DatabaseName?: string, DdlArtifactsSchema?: string, ExecuteTimeout?: int, FailTasksOnLobTruncation?: bool, HeartbeatEnable?: bool, HeartbeatSchema?: string, HeartbeatFrequency?: int, Password?: string, Port?: int, ServerName?: string, Username?: string, SlotName?: string, PluginName?: "no-preference"|"test-decoding"|"pglogical", SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (1 more fields)}
  --my-sql-settings: record # Provides information that defines a MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --oracle-settings: record # Provides information that defines an Oracle endpoint. — shape: {AddSupplementalLogging?: bool, ArchivedLogDestId?: int, AdditionalArchivedLogDestId?: int, ExtraArchivedLogDestIds?: list<int>, AllowSelectNestedTables?: bool, ParallelAsmReadThreads?: int, ReadAheadBlocks?: int, AccessAlternateDirectly?: bool, UseAlternateFolderForOnline?: bool, OraclePathPrefix?: string, UsePathPrefix?: string, ReplacePathPrefix?: bool, EnableHomogenousTablespace?: bool, DirectPathNoLog?: bool, ArchivedLogsOnly?: bool, AsmPassword?: string, AsmServer?: string, AsmUser?: string, ... (24 more fields)}
  --sybase-settings: record # Provides information that defines a SAP ASE endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --microsoft-sql-server-settings: record # Provides information that defines a Microsoft SQL Server endpoint. — shape: {Port?: int, BcpPacketSize?: int, DatabaseName?: string, ControlTablesFileGroup?: string, Password?: string, QuerySingleAlwaysOnNode?: bool, ReadBackupOnly?: bool, SafeguardPolicy?: "rely-on-sql-server-replication-agent"|"exclusive-automatic-truncation"|"shared-automatic-truncation", ServerName?: string, Username?: string, UseBcpFullLoad?: bool, UseThirdPartyBackupDevice?: bool, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string, TrimSpaceInChar?: bool, ... (2 more fields)}
  --ibm-db2-settings: record # Provides information that defines an IBM Db2 LUW endpoint. — shape: {DatabaseName?: string, Password?: string, Port?: int, ServerName?: string, SetDataCaptureChanges?: bool, CurrentLsn?: string, MaxKBytesPerRead?: int, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --doc-db-settings: record # Provides information that defines a DocumentDB endpoint. — shape: {Username?: string, Password?: string, ServerName?: string, Port?: int, DatabaseName?: string, NestingLevel?: "none"|"one", ExtractDocId?: bool, DocsToInvestigate?: int, KmsKeyId?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
  --redis-settings: record # Provides information that defines a Redis target endpoint. — shape: {ServerName: string, Port: int, SslSecurityProtocol?: "plaintext"|"ssl-encryption", AuthType?: "none"|"auth-role"|"auth-token", AuthUserName?: string, AuthPassword?: string, SslCaCertificateArn?: string}
  --exact-settings: oneof<nothing, bool> # If this attribute is Y, the current call to ModifyEndpoint replaces all existing endpoint settings with the exact settings that you specify in this call. If this attribute is N, the current call to ModifyEndpoint does two things: It replaces any endpoint settings that already exist with new values, for settings with the same names. It creates new endpoint settings that you specify in the call, for settings with different names. For example, if you call create-endpoint ... --endpoint-settings '{"a":1}' ..., the endpoint has the following endpoint settings: '{"a":1}'. If you then call modify-endpoint ... --endpoint-settings '{"b":2}' ... for the same endpoint, the endpoint has the following settings: '{"a":1,"b":2}'. However, suppose that you follow this with a call to modify-endpoint ... --endpoint-settings '{"b":2}' --exact-settings ... for that same endpoint again. Then the endpoint has the following settings: '{"b":2}'. All existing settings are replaced with the exact settings that you specify.
  --gcp-my-sql-settings: record # Settings in JSON format for the source GCP MySQL endpoint. — shape: {AfterConnectScript?: string, CleanSourceMetadataOnMismatch?: bool, DatabaseName?: string, EventsPollInterval?: int, TargetDbType?: "specific-database"|"multiple-databases", MaxFileSize?: int, ParallelLoadThreads?: int, Password?: string, Port?: int, ServerName?: string, ServerTimezone?: string, Username?: string, SecretsManagerAccessRoleArn?: string, SecretsManagerSecretId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ModifyEndpoint"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}, {name: EndpointIdentifier, var: endpoint_identifier}, {name: EndpointType, var: endpoint_type}, {name: EngineName, var: engine_name}, {name: Username, var: username}, {name: Password, var: password}, {name: ServerName, var: server_name}, {name: Port, var: port}, {name: DatabaseName, var: database_name}, {name: ExtraConnectionAttributes, var: extra_connection_attributes}, {name: CertificateArn, var: certificate_arn}, {name: SslMode, var: ssl_mode}, {name: ServiceAccessRoleArn, var: service_access_role_arn}, {name: ExternalTableDefinition, var: external_table_definition}, {name: DynamoDbSettings, var: dynamo_db_settings}, {name: S3Settings, var: s3_settings}, {name: DmsTransferSettings, var: dms_transfer_settings}, {name: MongoDbSettings, var: mongo_db_settings}, {name: KinesisSettings, var: kinesis_settings}, {name: KafkaSettings, var: kafka_settings}, {name: ElasticsearchSettings, var: elasticsearch_settings}, {name: NeptuneSettings, var: neptune_settings}, {name: RedshiftSettings, var: redshift_settings}, {name: PostgreSQLSettings, var: postgre_sql_settings}, {name: MySQLSettings, var: my_sql_settings}, {name: OracleSettings, var: oracle_settings}, {name: SybaseSettings, var: sybase_settings}, {name: MicrosoftSQLServerSettings, var: microsoft_sql_server_settings}, {name: IBMDb2Settings, var: ibm_db2_settings}, {name: DocDbSettings, var: doc_db_settings}, {name: RedisSettings, var: redis_settings}, {name: ExactSettings, var: exact_settings}, {name: GcpMySQLSettings, var: gcp_my_sql_settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn, endpoint_identifier: $endpoint_identifier, endpoint_type: $endpoint_type, engine_name: $engine_name, username: $username, password: $password, server_name: $server_name, port: $port, database_name: $database_name, extra_connection_attributes: $extra_connection_attributes, certificate_arn: $certificate_arn, ssl_mode: $ssl_mode, service_access_role_arn: $service_access_role_arn, external_table_definition: $external_table_definition, dynamo_db_settings: $dynamo_db_settings, s3_settings: $s3_settings, dms_transfer_settings: $dms_transfer_settings, mongo_db_settings: $mongo_db_settings, kinesis_settings: $kinesis_settings, kafka_settings: $kafka_settings, elasticsearch_settings: $elasticsearch_settings, neptune_settings: $neptune_settings, redshift_settings: $redshift_settings, postgre_sql_settings: $postgre_sql_settings, my_sql_settings: $my_sql_settings, oracle_settings: $oracle_settings, sybase_settings: $sybase_settings, microsoft_sql_server_settings: $microsoft_sql_server_settings, ibm_db2_settings: $ibm_db2_settings, doc_db_settings: $doc_db_settings, redis_settings: $redis_settings, exact_settings: $exact_settings, gcp_my_sql_settings: $gcp_my_sql_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies an existing DMS event notification subscription.
#
# POST /
# Returns: record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool>>
# operationId: ModifyEventSubscription
export def "modify-event-subscription" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  subscription_name: string # The name of the DMS event notification subscription to be modified.
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of DMS resource that generates the events you want to subscribe to. Valid values: replication-instance | replication-task
  --event-categories: list<string> # A list of event categories for a source type that you want to subscribe to. Use the DescribeEventCategories action to see a list of event categories.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ModifyEventSubscription"}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubscriptionName, var: subscription_name}, {name: SnsTopicArn, var: sns_topic_arn}, {name: SourceType, var: source_type}, {name: EventCategories, var: event_categories}, {name: Enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, subscription_name: $subscription_name, sns_topic_arn: $sns_topic_arn, source_type: $source_type, event_categories: $event_categories, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request. Some settings are applied during the maintenance window.
#
# POST /
# Returns: record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>
# operationId: ModifyReplicationInstance
export def "modify-replication-instance" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --allocated-storage: int # The amount of storage (in gigabytes) to be allocated for the replication instance.
  --apply-immediately: oneof<nothing, bool> # Indicates whether the changes should be applied immediately or during the next maintenance window.
  --replication-instance-class: string # The compute and memory capacity of the replication instance as defined for the specified replication instance class. For example to specify the instance class dms.c4.large, set this parameter to "dms.c4.large". For more information on the settings and capacities for the available replication instance classes, see Selecting the right DMS replication instance for your migration (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReplicationInstance.html#CHAP_ReplicationInstance.InDepth).
  --vpc-security-group-ids: list<string> # Specifies the VPC security group to be used with the replication instance. The VPC security group must work with the VPC containing the replication instance.
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter does not result in an outage, except in the following situation, and the change is asynchronously applied as soon as possible. If moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure pending changes are applied. Default: Uses existing setting Format: ddd:hh24:mi-ddd:hh24:mi Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Must be at least 30 minutes
  --multi-az: oneof<nothing, bool> # Specifies whether the replication instance is a Multi-AZ deployment. You can't set the AvailabilityZone parameter if the Multi-AZ parameter is set to true.
  --engine-version: string # The engine version number of the replication instance. When modifying a major engine version of an instance, also set AllowMajorVersionUpgrade to true.
  --allow-major-version-upgrade: oneof<nothing, bool> # Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage, and the change is asynchronously applied as soon as possible. This parameter must be set to true when specifying a value for the EngineVersion parameter that is a different major version than the replication instance's current version.
  --auto-minor-version-upgrade: oneof<nothing, bool> # A value that indicates that minor version upgrades are applied automatically to the replication instance during the maintenance window. Changing this parameter doesn't result in an outage, except in the case described following. The change is asynchronously applied as soon as possible. An outage does result if these factors apply: This parameter is set to true during the maintenance window. A newer minor version is available. DMS has enabled automatic patching for the given engine version. When AutoMinorVersionUpgrade is enabled, DMS uses the current default engine version when you modify a replication instance. For example, if you set EngineVersion to a lower version number than the current default version, DMS uses the default version. If AutoMinorVersionUpgrade isn’t enabled when you modify a replication instance, DMS uses the engine version specified by the EngineVersion parameter.
  --replication-instance-identifier: string # The replication instance identifier. This parameter is stored as a lowercase string.
  --network-type: string # The type of IP address protocol used by a replication instance, such as IPv4 only or Dual-stack that supports both IPv4 and IPv6 addressing. IPv6 only is not yet supported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ModifyReplicationInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: AllocatedStorage, var: allocated_storage}, {name: ApplyImmediately, var: apply_immediately}, {name: ReplicationInstanceClass, var: replication_instance_class}, {name: VpcSecurityGroupIds, var: vpc_security_group_ids}, {name: PreferredMaintenanceWindow, var: preferred_maintenance_window}, {name: MultiAZ, var: multi_az}, {name: EngineVersion, var: engine_version}, {name: AllowMajorVersionUpgrade, var: allow_major_version_upgrade}, {name: AutoMinorVersionUpgrade, var: auto_minor_version_upgrade}, {name: ReplicationInstanceIdentifier, var: replication_instance_identifier}, {name: NetworkType, var: network_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, allocated_storage: $allocated_storage, apply_immediately: $apply_immediately, replication_instance_class: $replication_instance_class, vpc_security_group_ids: $vpc_security_group_ids, preferred_maintenance_window: $preferred_maintenance_window, multi_az: $multi_az, engine_version: $engine_version, allow_major_version_upgrade: $allow_major_version_upgrade, auto_minor_version_upgrade: $auto_minor_version_upgrade, replication_instance_identifier: $replication_instance_identifier, network_type: $network_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the settings for the specified replication subnet group.
#
# POST /
# Returns: record<ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, SupportedNetworkTypes: list<string>>>
# operationId: ModifyReplicationSubnetGroup
export def "modify-replication-subnet-group" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  replication_subnet_group_identifier: string # The name of the replication instance subnet group.
  --replication-subnet-group-description: string # A description for the replication instance subnet group.
  subnet_ids: list<string> # A list of subnet IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ModifyReplicationSubnetGroup"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationSubnetGroupIdentifier, var: replication_subnet_group_identifier}, {name: ReplicationSubnetGroupDescription, var: replication_subnet_group_description}, {name: SubnetIds, var: subnet_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_subnet_group_identifier: $replication_subnet_group_identifier, replication_subnet_group_description: $replication_subnet_group_description, subnet_ids: $subnet_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the specified replication task. You can't modify the task endpoints. The task must be stopped before you can modify it. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: ModifyReplicationTask
export def "modify-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  --replication-task-identifier: string # The replication task identifier. Constraints: Must contain 1-255 alphanumeric characters or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens.
  --migration-type: string@migration-type-completer # The migration type. Valid values: full-load | cdc | full-load-and-cdc
  --table-mappings: string # When using the CLI or boto3, provide the path of the JSON file that contains the table mappings. Precede the path with file://. For example, --table-mappings file://mappingfile.json. When working with the DMS API, provide the JSON as the parameter value.
  --replication-task-settings: string # JSON file that contains settings for the task, such as task metadata settings.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
  --task-data: string # Supplemental information that the task requires to migrate the data for certain source and target endpoints. For more information, see Specifying Supplemental Data for Task Settings (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.TaskData.html) in the Database Migration Service User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ModifyReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: ReplicationTaskIdentifier, var: replication_task_identifier}, {name: MigrationType, var: migration_type}, {name: TableMappings, var: table_mappings}, {name: ReplicationTaskSettings, var: replication_task_settings}, {name: CdcStartTime, var: cdc_start_time}, {name: CdcStartPosition, var: cdc_start_position}, {name: CdcStopPosition, var: cdc_stop_position}, {name: TaskData, var: task_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, replication_task_identifier: $replication_task_identifier, migration_type: $migration_type, table_mappings: $table_mappings, replication_task_settings: $replication_task_settings, cdc_start_time: $cdc_start_time, cdc_start_position: $cdc_start_position, cdc_stop_position: $cdc_stop_position, task_data: $task_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a replication task from its current replication instance to a different target replication instance using the specified parameters. The target replication instance must be created with the same or later DMS version as the current replication instance.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: MoveReplicationTask
export def "move-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the task that you want to move.
  target_replication_instance_arn: string # The ARN of the replication instance where you want to move the task to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.MoveReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: TargetReplicationInstanceArn, var: target_replication_instance_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, target_replication_instance_arn: $target_replication_instance_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
#
# POST /
# Returns: record<ReplicationInstance: record<ReplicationInstanceIdentifier: string, ReplicationInstanceClass: string, ReplicationInstanceStatus: string, AllocatedStorage: int, InstanceCreateTime: string, VpcSecurityGroups: list<record>, AvailabilityZone: string, ReplicationSubnetGroup: record<ReplicationSubnetGroupIdentifier: string, ReplicationSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, SupportedNetworkTypes: list>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<ReplicationInstanceClass: string, AllocatedStorage: int, MultiAZ: bool, EngineVersion: string, NetworkType: string>, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, KmsKeyId: string, ReplicationInstanceArn: string, ReplicationInstancePublicIpAddress: string, ReplicationInstancePrivateIpAddress: string, ReplicationInstancePublicIpAddresses: list<string>, ReplicationInstancePrivateIpAddresses: list<string>, ReplicationInstanceIpv6Addresses: list<string>, PubliclyAccessible: bool, SecondaryAvailabilityZone: string, FreeUntil: string, DnsNameServers: string, NetworkType: string>>
# operationId: RebootReplicationInstance
export def "reboot-replication-instance" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  --force-failover: oneof<nothing, bool> # If this parameter is true, the reboot is conducted through a Multi-AZ failover. If the instance isn't configured for Multi-AZ, then you can't specify true. ( --force-planned-failover and --force-failover can't both be set to true.)
  --force-planned-failover: oneof<nothing, bool> # If this parameter is true, the reboot is conducted through a planned Multi-AZ failover where resources are released and cleaned up prior to conducting the failover. If the instance isn''t configured for Multi-AZ, then you can't specify true. ( --force-planned-failover and --force-failover can't both be set to true.)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.RebootReplicationInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: ForceFailover, var: force_failover}, {name: ForcePlannedFailover, var: force_planned_failover}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, force_failover: $force_failover, force_planned_failover: $force_planned_failover
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
#
# POST /
# Returns: record<RefreshSchemasStatus: record<EndpointArn: string, ReplicationInstanceArn: string, Status: string, LastRefreshDate: string, LastFailureMessage: string>>
# operationId: RefreshSchemas
export def "refresh-schemas" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.RefreshSchemas"}]
    body: {content_type: "application/json", kind: json, fields: [{name: EndpointArn, var: endpoint_arn}, {name: ReplicationInstanceArn, var: replication_instance_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, endpoint_arn: $endpoint_arn, replication_instance_arn: $replication_instance_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reloads the target database table with the source data. You can only use this operation with a task in the RUNNING state, otherwise the service will throw an InvalidResourceStateFault exception.
#
# POST /
# Returns: record<ReplicationTaskArn: string>
# operationId: ReloadTables
export def "reload-tables" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
  tables_to_reload: list # The name and schema of the table to be reloaded. — item shape: {SchemaName: string, TableName: string}
  --reload-option: string@reload-option-completer # Options for reload. Specify data-reload to reload the data and re-validate it if validation is enabled. Specify validate-only to re-validate the table. This option applies only when validation is enabled for the task. Valid values: data-reload, validate-only Default value is data-reload.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.ReloadTables"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: TablesToReload, var: tables_to_reload}, {name: ReloadOption, var: reload_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, tables_to_reload: $tables_to_reload, reload_option: $reload_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes metadata tags from an DMS resource, including replication instance, endpoint, subnet group, and migration task. For more information, see Tag (https://docs.aws.amazon.com/dms/latest/APIReference/API_Tag.html) data type description.
#
# POST /
# Returns: record
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_arn: string # An DMS resource from which you want to remove tag(s). The value for this parameter is an Amazon Resource Name (ARN).
  tag_keys: list<string> # The tag key (name) of the tag to be removed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.RemoveTagsFromResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceArn, var: resource_arn}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs large-scale assessment (LSA) analysis on every Fleet Advisor collector in your account.
#
# POST /
# Returns: record<LsaAnalysisId: string, Status: string>
# operationId: RunFleetAdvisorLsaAnalysis
export def "run-fleet-advisor-lsa-analysis" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.RunFleetAdvisorLsaAnalysis"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the analysis of your source database to provide recommendations of target engines. You can create recommendations for multiple source databases using BatchStartRecommendations (https://docs.aws.amazon.com/dms/latest/APIReference/API_BatchStartRecommendations.html).
#
# POST /
# operationId: StartRecommendations
export def "start-recommendations" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  database_id: string # The identifier of the source database to analyze and provide recommendations for.
  settings: record # Provides information about the required target engine settings. — shape: {InstanceSizingType: string, WorkloadType: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.StartRecommendations"}]
    body: {content_type: "application/json", kind: json, fields: [{name: DatabaseId, var: database_id}, {name: Settings, var: settings}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, database_id: $database_id, settings: $settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the replication task. For more information about DMS tasks, see Working with Migration Tasks (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: StartReplicationTask
export def "start-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task to be started.
  start_replication_task_type: string@start-replication-task-type-completer # The type of replication task to start. When the migration type is full-load or full-load-and-cdc, the only valid value for the first run of the task is start-replication. This option will start the migration. You can also use ReloadTables to reload specific tables that failed during migration instead of restarting the task. The resume-processing option isn't applicable for a full-load task, because you can't resume partially loaded tables during the full load phase. For a full-load-and-cdc task, DMS migrates table data, and then applies data changes that occur on the source. To load all the tables again, and start capturing source changes, use reload-target. Otherwise use resume-processing, to replicate the changes from the last stop position.
  --cdc-start-time: string # Indicates the start time for a change data capture (CDC) operation. Use either CdcStartTime or CdcStartPosition to specify when you want a CDC operation to start. Specifying both values results in an error. Timestamp Example: --cdc-start-time “2018-03-08T12:12:12” (format: date-time)
  --cdc-start-position: string # Indicates when you want a change data capture (CDC) operation to start. Use either CdcStartPosition or CdcStartTime to specify when you want a CDC operation to start. Specifying both values results in an error. The value can be in date, checkpoint, or LSN/SCN format. Date Example: --cdc-start-position “2018-03-08T12:12:12” Checkpoint Example: --cdc-start-position "checkpoint:V1#27#mysql-bin-changelog.157832:1975:-1:2002:677883278264080:mysql-bin-changelog.157832:1876#0#0#*#0#93" LSN Example: --cdc-start-position “mysql-bin-changelog.000024:373” When you use this task setting with a source PostgreSQL database, a logical replication slot should already be created and associated with the source endpoint. You can verify this by setting the slotName extra connection attribute to the name of this logical replication slot. For more information, see Extra Connection Attributes When Using PostgreSQL as a Source for DMS (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.PostgreSQL.html#CHAP_Source.PostgreSQL.ConnectionAttrib).
  --cdc-stop-position: string # Indicates when you want a change data capture (CDC) operation to stop. The value can be either server time or commit time. Server time example: --cdc-stop-position “server_time:2018-02-09T12:12:12” Commit time example: --cdc-stop-position “commit_time: 2018-02-09T12:12:12“
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.StartReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: StartReplicationTaskType, var: start_replication_task_type}, {name: CdcStartTime, var: cdc_start_time}, {name: CdcStartPosition, var: cdc_start_position}, {name: CdcStopPosition, var: cdc_stop_position}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, start_replication_task_type: $start_replication_task_type, cdc_start_time: $cdc_start_time, cdc_start_position: $cdc_start_position, cdc_stop_position: $cdc_stop_position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts the replication task assessment for unsupported data types in the source database. You can only use this operation for a task if the following conditions are true: The task must be in the stopped state. The task must have successful connections to the source and target. If either of these conditions are not met, an InvalidResourceStateFault error will result. For information about DMS task assessments, see Creating a task assessment report (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.AssessmentReport.html) in the Database Migration Service User Guide.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: StartReplicationTaskAssessment
export def "start-replication-task-assessment" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  replication_task_arn: string # The Amazon Resource Name (ARN) of the replication task.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.StartReplicationTaskAssessment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a new premigration assessment run for one or more individual assessments of a migration task. The assessments that you can specify depend on the source and target database engine and the migration type defined for the given task. To run this operation, your migration task must already be created. After you run this operation, you can review the status of each individual assessment. You can also run the migration task manually after the assessment run and its individual assessments complete.
#
# POST /
# Returns: record<ReplicationTaskAssessmentRun: record<ReplicationTaskAssessmentRunArn: string, ReplicationTaskArn: string, Status: string, ReplicationTaskAssessmentRunCreationDate: string, AssessmentProgress: record<IndividualAssessmentCount: int, IndividualAssessmentCompletedCount: int>, LastFailureMessage: string, ServiceAccessRoleArn: string, ResultLocationBucket: string, ResultLocationFolder: string, ResultEncryptionMode: string, ResultKmsKeyArn: string, AssessmentRunName: string>>
# operationId: StartReplicationTaskAssessmentRun
export def "start-replication-task-assessment-run" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  replication_task_arn: string # Amazon Resource Name (ARN) of the migration task associated with the premigration assessment run that you want to start.
  service_access_role_arn: string # ARN of the service role needed to start the assessment run. The role must allow the iam:PassRole action.
  result_location_bucket: string # Amazon S3 bucket where you want DMS to store the results of this assessment run.
  --result-location-folder: string # Folder within an Amazon S3 bucket where you want DMS to store the results of this assessment run.
  --result-encryption-mode: string # Encryption mode that you can specify to encrypt the results of this assessment run. If you don't specify this request parameter, DMS stores the assessment run results without encryption. You can specify one of the options following: "SSE_S3" – The server-side encryption provided as a default by Amazon S3. "SSE_KMS" – Key Management Service (KMS) encryption. This encryption can use either a custom KMS encryption key that you specify or the default KMS encryption key that DMS provides.
  --result-kms-key-arn: string # ARN of a custom KMS encryption key that you specify when you set ResultEncryptionMode to "SSE_KMS".
  assessment_run_name: string # Unique name to identify the assessment run.
  --include-only: list<string> # Space-separated list of names for specific individual assessments that you want to include. These names come from the default list of individual assessments that DMS supports for the associated migration task. This task is specified by ReplicationTaskArn. You can't set a value for IncludeOnly if you also set a value for Exclude in the API operation. To identify the names of the default individual assessments that DMS supports for the associated migration task, run the DescribeApplicableIndividualAssessments operation using its own ReplicationTaskArn request parameter.
  --exclude: list<string> # Space-separated list of names for specific individual assessments that you want to exclude. These names come from the default list of individual assessments that DMS supports for the associated migration task. This task is specified by ReplicationTaskArn. You can't set a value for Exclude if you also set a value for IncludeOnly in the API operation. To identify the names of the default individual assessments that DMS supports for the associated migration task, run the DescribeApplicableIndividualAssessments operation using its own ReplicationTaskArn request parameter.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.StartReplicationTaskAssessmentRun"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}, {name: ServiceAccessRoleArn, var: service_access_role_arn}, {name: ResultLocationBucket, var: result_location_bucket}, {name: ResultLocationFolder, var: result_location_folder}, {name: ResultEncryptionMode, var: result_encryption_mode}, {name: ResultKmsKeyArn, var: result_kms_key_arn}, {name: AssessmentRunName, var: assessment_run_name}, {name: IncludeOnly, var: include_only}, {name: Exclude, var: exclude}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn, service_access_role_arn: $service_access_role_arn, result_location_bucket: $result_location_bucket, result_location_folder: $result_location_folder, result_encryption_mode: $result_encryption_mode, result_kms_key_arn: $result_kms_key_arn, assessment_run_name: $assessment_run_name, include_only: $include_only, exclude: $exclude
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops the replication task.
#
# POST /
# Returns: record<ReplicationTask: record<ReplicationTaskIdentifier: string, SourceEndpointArn: string, TargetEndpointArn: string, ReplicationInstanceArn: string, MigrationType: string, TableMappings: string, ReplicationTaskSettings: string, Status: string, LastFailureMessage: string, StopReason: string, ReplicationTaskCreationDate: string, ReplicationTaskStartDate: string, CdcStartPosition: string, CdcStopPosition: string, RecoveryCheckpoint: string, ReplicationTaskArn: string, ReplicationTaskStats: record<FullLoadProgressPercent: int, ElapsedTimeMillis: int, TablesLoaded: int, TablesLoading: int, TablesQueued: int, TablesErrored: int, FreshStartDate: string, StartDate: string, StopDate: string, FullLoadStartDate: string, FullLoadFinishDate: string>, TaskData: string, TargetReplicationInstanceArn: string>>
# operationId: StopReplicationTask
export def "stop-replication-task" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  replication_task_arn: string # The Amazon Resource Name(ARN) of the replication task to be stopped.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.StopReplicationTask"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationTaskArn, var: replication_task_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_task_arn: $replication_task_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tests the connection between the replication instance and the endpoint.
#
# POST /
# Returns: record<Connection: record<ReplicationInstanceArn: string, EndpointArn: string, Status: string, LastFailureMessage: string, EndpointIdentifier: string, ReplicationInstanceIdentifier: string>>
# operationId: TestConnection
export def "test-connection" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  replication_instance_arn: string # The Amazon Resource Name (ARN) of the replication instance.
  endpoint_arn: string # The Amazon Resource Name (ARN) string that uniquely identifies the endpoint.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.TestConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReplicationInstanceArn, var: replication_instance_arn}, {name: EndpointArn, var: endpoint_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, replication_instance_arn: $replication_instance_arn, endpoint_arn: $endpoint_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Migrates 10 active and enabled Amazon SNS subscriptions at a time and converts them to corresponding Amazon EventBridge rules. By default, this operation migrates subscriptions only when all your replication instance versions are 3.4.6 or higher. If any replication instances are from versions earlier than 3.4.6, the operation raises an error and tells you to upgrade these instances to version 3.4.6 or higher. To enable migration regardless of version, set the Force option to true. However, if you don't upgrade instances earlier than version 3.4.6, some types of events might not be available when you use Amazon EventBridge. To call this operation, make sure that you have certain permissions added to your user account. For more information, see Migrating event subscriptions to Amazon EventBridge (https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html#CHAP_Events-migrate-to-eventbridge) in the Amazon Web Services Database Migration Service User Guide.
#
# POST /
# Returns: record<Result: string>
# operationId: UpdateSubscriptionsToEventBridge
export def "update-subscriptions-to-event-bridge" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  --force-move: oneof<nothing, bool> # When set to true, this operation migrates DMS subscriptions for Amazon SNS notifications no matter what your replication instance version is. If not set or set to false, this operation runs only when all your replication instances are from DMS version 3.4.6 or higher.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AmazonDMSv20160101.UpdateSubscriptionsToEventBridge"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ForceMove, var: force_move}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, force_move: $force_move
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
