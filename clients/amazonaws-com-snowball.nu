# Auto-generated client for Amazon Import/Export Snowball v2016-06-30
# Source: https://api.apis.guru/v2/specs/amazonaws.com/snowball/2016-06-30/openapi.json
# Auth: --token flag or $env.AMAZON_IMPORT_EXPORT_SNOWBALL_TOKEN

const CLIENT = {
  base_url: "http://snowball.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_IMPORT_EXPORT_SNOWBALL_TOKEN"
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

def base-url-completer [] { ["http://snowball.us-east-1.amazonaws.com" "http://snowball.us-east-2.amazonaws.com" "http://snowball.us-west-1.amazonaws.com" "http://snowball.us-west-2.amazonaws.com" "http://snowball.us-gov-west-1.amazonaws.com" "http://snowball.us-gov-east-1.amazonaws.com" "http://snowball.ca-central-1.amazonaws.com" "http://snowball.eu-north-1.amazonaws.com" "http://snowball.eu-west-1.amazonaws.com" "http://snowball.eu-west-2.amazonaws.com" "http://snowball.eu-west-3.amazonaws.com" "http://snowball.eu-central-1.amazonaws.com" "http://snowball.eu-south-1.amazonaws.com" "http://snowball.af-south-1.amazonaws.com" "http://snowball.ap-northeast-1.amazonaws.com" "http://snowball.ap-northeast-2.amazonaws.com" "http://snowball.ap-northeast-3.amazonaws.com" "http://snowball.ap-southeast-1.amazonaws.com" "http://snowball.ap-southeast-2.amazonaws.com" "http://snowball.ap-east-1.amazonaws.com" "http://snowball.ap-south-1.amazonaws.com" "http://snowball.sa-east-1.amazonaws.com" "http://snowball.me-south-1.amazonaws.com" "https://snowball.us-east-1.amazonaws.com" "https://snowball.us-east-2.amazonaws.com" "https://snowball.us-west-1.amazonaws.com" "https://snowball.us-west-2.amazonaws.com" "https://snowball.us-gov-west-1.amazonaws.com" "https://snowball.us-gov-east-1.amazonaws.com" "https://snowball.ca-central-1.amazonaws.com" "https://snowball.eu-north-1.amazonaws.com" "https://snowball.eu-west-1.amazonaws.com" "https://snowball.eu-west-2.amazonaws.com" "https://snowball.eu-west-3.amazonaws.com" "https://snowball.eu-central-1.amazonaws.com" "https://snowball.eu-south-1.amazonaws.com" "https://snowball.af-south-1.amazonaws.com" "https://snowball.ap-northeast-1.amazonaws.com" "https://snowball.ap-northeast-2.amazonaws.com" "https://snowball.ap-northeast-3.amazonaws.com" "https://snowball.ap-southeast-1.amazonaws.com" "https://snowball.ap-southeast-2.amazonaws.com" "https://snowball.ap-east-1.amazonaws.com" "https://snowball.ap-south-1.amazonaws.com" "https://snowball.sa-east-1.amazonaws.com" "https://snowball.me-south-1.amazonaws.com" "http://snowball.cn-north-1.amazonaws.com.cn" "http://snowball.cn-northwest-1.amazonaws.com.cn" "https://snowball.cn-north-1.amazonaws.com.cn" "https://snowball.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSIESnowballJobManagementService.CancelCluster"] }
def x-amz-target-completer-1 [] { ["AWSIESnowballJobManagementService.CancelJob"] }
def x-amz-target-completer-2 [] { ["AWSIESnowballJobManagementService.CreateAddress"] }
def job-type-completer [] { ["EXPORT" "IMPORT" "LOCAL_USE"] }
def snowball-type-completer [] { ["EDGE" "EDGE_C" "EDGE_CG" "EDGE_S" "SNC1_HDD" "SNC1_SSD" "STANDARD" "V3_5C" "V3_5S"] }
def shipping-option-completer [] { ["EXPRESS" "NEXT_DAY" "SECOND_DAY" "STANDARD"] }
def remote-management-completer [] { ["INSTALLED_AUTOSTART" "INSTALLED_ONLY"] }
def snowball-capacity-preference-completer [] { ["NoPreference" "T100" "T14" "T240" "T32" "T42" "T50" "T8" "T80" "T98"] }
def x-amz-target-completer-3 [] { ["AWSIESnowballJobManagementService.CreateCluster"] }
def x-amz-target-completer-4 [] { ["AWSIESnowballJobManagementService.CreateJob"] }
def long-term-pricing-type-completer [] { ["OneMonth" "OneYear" "ThreeYear"] }
def x-amz-target-completer-5 [] { ["AWSIESnowballJobManagementService.CreateLongTermPricing"] }
def x-amz-target-completer-6 [] { ["AWSIESnowballJobManagementService.CreateReturnShippingLabel"] }
def x-amz-target-completer-7 [] { ["AWSIESnowballJobManagementService.DescribeAddress"] }
def x-amz-target-completer-8 [] { ["AWSIESnowballJobManagementService.DescribeAddresses"] }
def x-amz-target-completer-9 [] { ["AWSIESnowballJobManagementService.DescribeCluster"] }
def x-amz-target-completer-10 [] { ["AWSIESnowballJobManagementService.DescribeJob"] }
def x-amz-target-completer-11 [] { ["AWSIESnowballJobManagementService.DescribeReturnShippingLabel"] }
def x-amz-target-completer-12 [] { ["AWSIESnowballJobManagementService.GetJobManifest"] }
def x-amz-target-completer-13 [] { ["AWSIESnowballJobManagementService.GetJobUnlockCode"] }
def x-amz-target-completer-14 [] { ["AWSIESnowballJobManagementService.GetSnowballUsage"] }
def x-amz-target-completer-15 [] { ["AWSIESnowballJobManagementService.GetSoftwareUpdates"] }
def x-amz-target-completer-16 [] { ["AWSIESnowballJobManagementService.ListClusterJobs"] }
def x-amz-target-completer-17 [] { ["AWSIESnowballJobManagementService.ListClusters"] }
def x-amz-target-completer-18 [] { ["AWSIESnowballJobManagementService.ListCompatibleImages"] }
def x-amz-target-completer-19 [] { ["AWSIESnowballJobManagementService.ListJobs"] }
def x-amz-target-completer-20 [] { ["AWSIESnowballJobManagementService.ListLongTermPricing"] }
def service-name-completer [] { ["EKS_ANYWHERE" "KUBERNETES"] }
def x-amz-target-completer-21 [] { ["AWSIESnowballJobManagementService.ListServiceVersions"] }
def x-amz-target-completer-22 [] { ["AWSIESnowballJobManagementService.UpdateCluster"] }
def x-amz-target-completer-23 [] { ["AWSIESnowballJobManagementService.UpdateJob"] }
def shipment-state-completer [] { ["RECEIVED" "RETURNED"] }
def x-amz-target-completer-24 [] { ["AWSIESnowballJobManagementService.UpdateJobShipmentState"] }
def x-amz-target-completer-25 [] { ["AWSIESnowballJobManagementService.UpdateLongTermPricing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-cluster: "record"
    cancel-job: "record"
    create-address: "record<AddressId: string>"
    create-cluster: "record<ClusterId: string, JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>>"
    create-job: "record<JobId: string>"
    create-long-term-pricing: "record<LongTermPricingId: string>"
    create-return-shipping-label: "record<Status: string>"
    describe-address: "record<Address: record<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>>"
    describe-addresses: "record<Addresses: table<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>, NextToken: string>"
    describe-cluster: "record<ClusterMetadata: record<ClusterId: string, Description: string, KmsKeyARN: string, RoleARN: string, ClusterState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, AddressId: string, ShippingOption: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, ForwardingAddressId: string, TaxDocuments: record<IND: record>, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>>"
    describe-job: "record<JobMetadata: record<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record<ShippingOption: string, InboundShipment: record, OutboundShipment: record>, SnowballCapacityPreference: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, DataTransferProgress: record<BytesTransferred: int, ObjectsTransferred: int, TotalBytes: int, TotalObjects: int>, JobLogInfo: record<JobCompletionReportURI: string, JobSuccessLogURI: string, JobFailureLogURI: string>, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record<IND: record>, DeviceConfiguration: record<SnowconeDeviceConfiguration: record>, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>, SubJobMetadata: table<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record, SnowballCapacityPreference: string, Notification: record, DataTransferProgress: record, JobLogInfo: record, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record, DeviceConfiguration: record, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record>>"
    describe-return-shipping-label: "record<Status: string, ExpirationDate: string, ReturnShippingLabelURI: string>"
    get-job-manifest: "record<ManifestURI: string>"
    get-job-unlock-code: "record<UnlockCode: string>"
    get-snowball-usage: "record<SnowballLimit: int, SnowballsInUse: int>"
    get-software-updates: "record<UpdatesURI: string>"
    list-cluster-jobs: "record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string>"
    list-clusters: "record<ClusterListEntries: table<ClusterId: string, ClusterState: string, CreationDate: string, Description: string>, NextToken: string>"
    list-compatible-images: "record<CompatibleImages: table<AmiId: string, Name: string>, NextToken: string>"
    list-jobs: "record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string>"
    list-long-term-pricing: "record<LongTermPricingEntries: table<LongTermPricingId: string, LongTermPricingEndDate: string, LongTermPricingStartDate: string, LongTermPricingType: string, CurrentActiveJob: string, ReplacementJob: string, IsLongTermPricingAutoRenew: bool, LongTermPricingStatus: string, SnowballType: string, JobIds: list>, NextToken: string>"
    list-service-versions: "record<ServiceVersions: table<Version: string>, ServiceName: string, DependentServices: table<ServiceName: string, ServiceVersion: record>, NextToken: string>"
    update-cluster: "record"
    update-job: "record"
    update-job-shipment-state: "record"
    update-long-term-pricing: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-cluster" "cancel-job" "create-address" "create-cluster" "create-job" "create-long-term-pricing" "create-return-shipping-label" "describe-address" "describe-addresses" "describe-cluster" "describe-job" "describe-return-shipping-label" "get-job-manifest" "get-job-unlock-code" "get-snowball-usage" "get-software-updates" "list-cluster-jobs" "list-clusters" "list-compatible-images" "list-jobs" "list-long-term-pricing" "list-service-versions" "update-cluster" "update-job" "update-job-shipment-state" "update-long-term-pricing" "commands"] | sort) } | get name | first)
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

# Cancels a cluster job. You can only cancel a cluster job while it's in the AwaitingQuorum status. You'll have at least an hour after creating a cluster job to cancel it.
#
# POST /
# Returns: record
# operationId: CancelCluster
export def "cancel-cluster" [
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
  cluster_id: string # The 39-character ID for the cluster that you want to cancel, for example CID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CancelCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the specified job. You can only cancel a job before its JobState value changes to PreparingAppliance. Requesting the ListJobs or DescribeJob action returns a job's JobState as part of the response element data returned.
#
# POST /
# Returns: record
# operationId: CancelJob
export def "cancel-job" [
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
  job_id: string # The 39-character job ID for the job that you want to cancel, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CancelJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an address for a Snow device to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
#
# POST /
# Returns: record<AddressId: string>
# operationId: CreateAddress
export def "create-address" [
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
  address: record # The address that you want the Snow device(s) associated with a specific job to be shipped to. Addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. Although no individual elements of the Address are required, if the address is invalid or unsupported, then an exception is thrown. — shape: {AddressId?: string, Name?: string, Company?: string, Street1?: string, Street2?: string, Street3?: string, City?: string, StateOrProvince?: string, PrefectureOrDistrict?: string, Landmark?: string, Country?: string, PostalCode?: string, PhoneNumber?: string, IsRestricted?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CreateAddress"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Address, var: address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty cluster. Each cluster supports five nodes. You use the CreateJob action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
#
# POST /
# Returns: record<ClusterId: string, JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>>
# operationId: CreateCluster
export def "create-cluster" [
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
  job_type: string@job-type-completer # The type of job for this cluster. Currently, the only job type supported for clusters is LOCAL_USE. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --description: string # An optional description of this specific cluster, for example Environmental Data Cluster-01.
  address_id: string # The ID for the address that you want the cluster shipped to.
  --kms-key-arn: string # The KmsKeyARN value that you want to associate with this cluster. KmsKeyARN values are created by using the CreateKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_CreateKey.html) API action in Key Management Service (KMS).
  --role-arn: string # The RoleARN that you want to associate with this cluster. RoleArn values are created by using the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) API action in Identity and Access Management (IAM).
  snowball_type: string@snowball-type-completer # The type of Snow Family devices to use for this cluster. For cluster jobs, Amazon Web Services Snow Family currently supports only the EDGE device type. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  shipping_option: string@shipping-option-completer # The shipping speed for each node in this cluster. This speed doesn't dictate how soon you'll get each Snowball Edge device, rather it represents how quickly each device moves to its destination while in transit. Regional shipping speeds are as follows: In Australia, you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the United States of America (US), you have access to one-day shipping and two-day shipping. In Australia, you have access to express shipping. Typically, devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the US, you have access to one-day shipping and two-day shipping.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --forwarding-address-id: string # The forwarding address ID for a cluster. This field is not supported in most regions.
  --tax-documents: record # The tax documents required in your Amazon Web Services Region. — shape: {IND?: record}
  --remote-management: string@remote-management-completer # Allows you to securely operate and manage Snow devices in a cluster remotely from outside of your internal network. When set to INSTALLED_AUTOSTART, remote management will automatically be available when the device arrives at your location. Otherwise, you need to use the Snowball Client to manage the device.
  --initial-cluster-size: int # If provided, each job will be automatically created and associated with the new cluster. If not provided, will be treated as 0.
  --force-create-jobs: oneof<nothing, bool> # Force to create cluster when user attempts to overprovision or underprovision a cluster. A cluster is overprovisioned or underprovisioned if the initial size of the cluster is more (overprovisioned) or less (underprovisioned) than what needed to meet capacity requirement specified with OnDeviceServiceConfiguration.
  --long-term-pricing-ids: list<string> # Lists long-term pricing id that will be used to associate with jobs automatically created for the new cluster.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # If your job is being created in one of the US regions, you have the option of specifying what size Snow device you'd like for this job. In all other regions, Snowballs come with 80 TB in storage capacity. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CreateCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobType, var: job_type}, {name: Resources, var: resources}, {name: OnDeviceServiceConfiguration, var: on_device_service_configuration}, {name: Description, var: description}, {name: AddressId, var: address_id}, {name: KmsKeyARN, var: kms_key_arn}, {name: RoleARN, var: role_arn}, {name: SnowballType, var: snowball_type}, {name: ShippingOption, var: shipping_option}, {name: Notification, var: notification}, {name: ForwardingAddressId, var: forwarding_address_id}, {name: TaxDocuments, var: tax_documents}, {name: RemoteManagement, var: remote_management}, {name: InitialClusterSize, var: initial_cluster_size}, {name: ForceCreateJobs, var: force_create_jobs}, {name: LongTermPricingIds, var: long_term_pricing_ids}, {name: SnowballCapacityPreference, var: snowball_capacity_preference}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_type: $job_type, resources: $resources, on_device_service_configuration: $on_device_service_configuration, description: $description, address_id: $address_id, kms_key_arn: $kms_key_arn, role_arn: $role_arn, snowball_type: $snowball_type, shipping_option: $shipping_option, notification: $notification, forwarding_address_id: $forwarding_address_id, tax_documents: $tax_documents, remote_management: $remote_management, initial_cluster_size: $initial_cluster_size, force_create_jobs: $force_create_jobs, long_term_pricing_ids: $long_term_pricing_ids, snowball_capacity_preference: $snowball_capacity_preference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job to import or export data between Amazon S3 and your on-premises data center. Your Amazon Web Services account must have the right trust policies and permissions in place to create a job for a Snow device. If you're creating a job for a node in a cluster, you only need to provide the clusterId value; the other job attributes are inherited from the cluster. Only the Snowball; Edge device type is supported when ordering clustered jobs. The device capacity is optional. Availability of device types differ by Amazon Web Services Region. For more information about Region availability, see Amazon Web Services Regional Services (https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/?p=ngi&loc=4). Snow Family devices and their capacities. Device type: SNC1_SSD Capacity: T14 Description: Snowcone Device type: SNC1_HDD Capacity: T8 Description: Snowcone Device type: EDGE_S Capacity: T98 Description: Snowball Edge Storage Optimized for data transfer only Device type: EDGE_CG Capacity: T42 Description: Snowball Edge Compute Optimized with GPU Device type: EDGE_C Capacity: T42 Description: Snowball Edge Compute Optimized without GPU Device type: EDGE Capacity: T100 Description: Snowball Edge Storage Optimized with EC2 Compute Device type: STANDARD Capacity: T50 Description: Original Snowball device This device is only available in the Ningxia, Beijing, and Singapore Amazon Web Services Region Device type: STANDARD Capacity: T80 Description: Original Snowball device This device is only available in the Ningxia, Beijing, and Singapore Amazon Web Services Region. Device type: V3_5C Capacity: T32 Description: Snowball Edge Compute Optimized without GPU Device type: V3_5S Capacity: T240 Description: Snowball Edge Storage Optimized 210TB
#
# POST /
# Returns: record<JobId: string>
# operationId: CreateJob
export def "create-job" [
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
  --job-type: string@job-type-completer # Defines the type of job that you're creating.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --description: string # Defines an optional description of this specific job, for example Important Photos 2016-08-11.
  --address-id: string # The ID for the address that you want the Snow device shipped to.
  --kms-key-arn: string # The KmsKeyARN that you want to associate with this job. KmsKeyARNs are created using the CreateKey (https://docs.aws.amazon.com/kms/latest/APIReference/API_CreateKey.html) Key Management Service (KMS) API action.
  --role-arn: string # The RoleARN that you want to associate with this job. RoleArns are created using the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) Identity and Access Management (IAM) API action.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # If your job is being created in one of the US regions, you have the option of specifying what size Snow device you'd like for this job. In all other regions, Snowballs come with 80 TB in storage capacity. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --shipping-option: string@shipping-option-completer # The shipping speed for this job. This speed doesn't dictate how soon you'll get the Snow device, rather it represents how quickly the Snow device moves to its destination while in transit. Regional shipping speeds are as follows: In Australia, you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In the European Union (EU), you have access to express shipping. Typically, Snow devices shipped express are delivered in about a day. In addition, most countries in the EU have access to standard shipping, which typically takes less than a week, one way. In India, Snow devices are delivered in one to seven days. In the US, you have access to one-day shipping and two-day shipping.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --cluster-id: string # The ID of a cluster. If you're creating a job for a node in a cluster, you need to provide only this clusterId value. The other job attributes are inherited from the cluster.
  --snowball-type: string@snowball-type-completer # The type of Snow Family devices to use for this job. For cluster jobs, Amazon Web Services Snow Family currently supports only the EDGE device type. The type of Amazon Web Services Snow device to use for this job. Currently, the only supported device type for cluster jobs is EDGE. For more information, see Snowball Edge Device Options (https://docs.aws.amazon.com/snowball/latest/developer-guide/device-differences.html) in the Snowball Edge Developer Guide. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --forwarding-address-id: string # The forwarding address ID for a job. This field is not supported in most Regions.
  --tax-documents: record # The tax documents required in your Amazon Web Services Region. — shape: {IND?: record}
  --device-configuration: record # The container for SnowconeDeviceConfiguration. — shape: {SnowconeDeviceConfiguration?: record}
  --remote-management: string@remote-management-completer # Allows you to securely operate and manage Snowcone devices remotely from outside of your internal network. When set to INSTALLED_AUTOSTART, remote management will automatically be available when the device arrives at your location. Otherwise, you need to use the Snowball Client to manage the device.
  --long-term-pricing-id: string # The ID of the long-term pricing type for the device.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CreateJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobType, var: job_type}, {name: Resources, var: resources}, {name: OnDeviceServiceConfiguration, var: on_device_service_configuration}, {name: Description, var: description}, {name: AddressId, var: address_id}, {name: KmsKeyARN, var: kms_key_arn}, {name: RoleARN, var: role_arn}, {name: SnowballCapacityPreference, var: snowball_capacity_preference}, {name: ShippingOption, var: shipping_option}, {name: Notification, var: notification}, {name: ClusterId, var: cluster_id}, {name: SnowballType, var: snowball_type}, {name: ForwardingAddressId, var: forwarding_address_id}, {name: TaxDocuments, var: tax_documents}, {name: DeviceConfiguration, var: device_configuration}, {name: RemoteManagement, var: remote_management}, {name: LongTermPricingId, var: long_term_pricing_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_type: $job_type, resources: $resources, on_device_service_configuration: $on_device_service_configuration, description: $description, address_id: $address_id, kms_key_arn: $kms_key_arn, role_arn: $role_arn, snowball_capacity_preference: $snowball_capacity_preference, shipping_option: $shipping_option, notification: $notification, cluster_id: $cluster_id, snowball_type: $snowball_type, forwarding_address_id: $forwarding_address_id, tax_documents: $tax_documents, device_configuration: $device_configuration, remote_management: $remote_management, long_term_pricing_id: $long_term_pricing_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a job with the long-term usage option for a device. The long-term usage is a 1-year or 3-year long-term pricing type for the device. You are billed upfront, and Amazon Web Services provides discounts for long-term pricing.
#
# POST /
# Returns: record<LongTermPricingId: string>
# operationId: CreateLongTermPricing
export def "create-long-term-pricing" [
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
  long_term_pricing_type: string@long-term-pricing-type-completer # The type of long-term pricing option you want for the device, either 1-year or 3-year long-term pricing.
  --is-long-term-pricing-auto-renew: oneof<nothing, bool> # Specifies whether the current long-term pricing type for the device should be renewed.
  --snowball-type: string@snowball-type-completer # The type of Snow Family devices to use for the long-term pricing job.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CreateLongTermPricing"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LongTermPricingType, var: long_term_pricing_type}, {name: IsLongTermPricingAutoRenew, var: is_long_term_pricing_auto_renew}, {name: SnowballType, var: snowball_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, long_term_pricing_type: $long_term_pricing_type, is_long_term_pricing_auto_renew: $is_long_term_pricing_auto_renew, snowball_type: $snowball_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a shipping label that will be used to return the Snow device to Amazon Web Services.
#
# POST /
# Returns: record<Status: string>
# operationId: CreateReturnShippingLabel
export def "create-return-shipping-label" [
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
  job_id: string # The ID for a job that you want to create the return shipping label for; for example, JID123e4567-e89b-12d3-a456-426655440000.
  --shipping-option: string@shipping-option-completer # The shipping speed for a particular job. This speed doesn't dictate how soon the device is returned to Amazon Web Services. This speed represents how quickly it moves to its destination while in transit. Regional shipping speeds are as follows:
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.CreateReturnShippingLabel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: ShippingOption, var: shipping_option}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, shipping_option: $shipping_option
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes an AddressId and returns specific details about that address in the form of an Address object.
#
# POST /
# Returns: record<Address: record<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>>
# operationId: DescribeAddress
export def "describe-address" [
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
  address_id: string # The automatically generated ID for a specific address.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.DescribeAddress"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddressId, var: address_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, address_id: $address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a specified number of ADDRESS objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
#
# POST /
# Returns: record<Addresses: table<AddressId: string, Name: string, Company: string, Street1: string, Street2: string, Street3: string, City: string, StateOrProvince: string, PrefectureOrDistrict: string, Landmark: string, Country: string, PostalCode: string, PhoneNumber: string, IsRestricted: bool>, NextToken: string>
# operationId: DescribeAddresses
export def "describe-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  --body-max-results: int # The number of ADDRESS objects to return. (spec name: MaxResults)
  --body-next-token: string # HTTP requests are stateless. To identify what object comes "next" in the list of ADDRESS objects, you have the option of specifying a value for NextToken as the starting point for your list of returned addresses. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.DescribeAddresses"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
#
# POST /
# Returns: record<ClusterMetadata: record<ClusterId: string, Description: string, KmsKeyARN: string, RoleARN: string, ClusterState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, AddressId: string, ShippingOption: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, ForwardingAddressId: string, TaxDocuments: record<IND: record>, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>>
# operationId: DescribeCluster
export def "describe-cluster" [
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
  cluster_id: string # The automatically generated ID for a cluster.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.DescribeCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific job including shipping information, job status, and other important metadata.
#
# POST /
# Returns: record<JobMetadata: record<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record<S3Resources: list, LambdaResources: list, Ec2AmiResources: list>, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record<ShippingOption: string, InboundShipment: record, OutboundShipment: record>, SnowballCapacityPreference: string, Notification: record<SnsTopicARN: string, JobStatesToNotify: list, NotifyAll: bool>, DataTransferProgress: record<BytesTransferred: int, ObjectsTransferred: int, TotalBytes: int, TotalObjects: int>, JobLogInfo: record<JobCompletionReportURI: string, JobSuccessLogURI: string, JobFailureLogURI: string>, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record<IND: record>, DeviceConfiguration: record<SnowconeDeviceConfiguration: record>, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record<NFSOnDeviceService: record, TGWOnDeviceService: record, EKSOnDeviceService: record, S3OnDeviceService: record>>, SubJobMetadata: table<JobId: string, JobState: string, JobType: string, SnowballType: string, CreationDate: string, Resources: record, Description: string, KmsKeyARN: string, RoleARN: string, AddressId: string, ShippingDetails: record, SnowballCapacityPreference: string, Notification: record, DataTransferProgress: record, JobLogInfo: record, ClusterId: string, ForwardingAddressId: string, TaxDocuments: record, DeviceConfiguration: record, RemoteManagement: string, LongTermPricingId: string, OnDeviceServiceConfiguration: record>>
# operationId: DescribeJob
export def "describe-job" [
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
  job_id: string # The automatically generated ID for a job, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.DescribeJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information on the shipping label of a Snow device that is being returned to Amazon Web Services.
#
# POST /
# Returns: record<Status: string, ExpirationDate: string, ReturnShippingLabelURI: string>
# operationId: DescribeReturnShippingLabel
export def "describe-return-shipping-label" [
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
  job_id: string # The automatically generated ID for a job, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.DescribeReturnShippingLabel"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified JobId value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the GetJobManifest action. The manifest is an encrypted file that you can download after your job enters the WithCustomer status. This is the only valid status for calling this API as the manifest and UnlockCode code value are used for securing your device and should only be used when you have the device. The manifest is decrypted by using the UnlockCode code value, when you pass both values to the Snow device through the Snowball client when the client is started for the first time. As a best practice, we recommend that you don't save a copy of an UnlockCode value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snow device associated with that job. The credentials of a given job, including its manifest file and unlock code, expire 360 days after the job is created.
#
# POST /
# Returns: record<ManifestURI: string>
# operationId: GetJobManifest
export def "get-job-manifest" [
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
  job_id: string # The ID for a job that you want to get the manifest file for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.GetJobManifest"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the UnlockCode code value for the specified job. A particular UnlockCode value can be accessed for up to 360 days after the associated job has been created. The UnlockCode value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snow device through the Snowball client when the client is started for the first time. The only valid status for calling this API is WithCustomer as the manifest and Unlock code values are used for securing your device and should only be used when you have the device. As a best practice, we recommend that you don't save a copy of the UnlockCode in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snow device associated with that job.
#
# POST /
# Returns: record<UnlockCode: string>
# operationId: GetJobUnlockCode
export def "get-job-unlock-code" [
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
  job_id: string # The ID for the job that you want to get the UnlockCode value for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.GetJobUnlockCode"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the Snow Family service limit for your account, and also the number of Snow devices your account has in use. The default service limit for the number of Snow devices that you can have at one time is 1. If you want to increase your service limit, contact Amazon Web Services Support.
#
# POST /
# Returns: record<SnowballLimit: int, SnowballsInUse: int>
# operationId: GetSnowballUsage
export def "get-snowball-usage" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.GetSnowballUsage"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an Amazon S3 presigned URL for an update file associated with a specified JobId.
#
# POST /
# Returns: record<UpdatesURI: string>
# operationId: GetSoftwareUpdates
export def "get-software-updates" [
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
  job_id: string # The ID for a job that you want to get the software update file for, for example JID123e4567-e89b-12d3-a456-426655440000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.GetSoftwareUpdates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of JobListEntry objects of the specified length. Each JobListEntry object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
#
# POST /
# Returns: record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string>
# operationId: ListClusterJobs
export def "list-cluster-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  cluster_id: string # The 39-character ID for the cluster that you want to list, for example CID123e4567-e89b-12d3-a456-426655440000.
  --body-max-results: int # The number of JobListEntry objects to return. (spec name: MaxResults)
  --body-next-token: string # HTTP requests are stateless. To identify what object comes "next" in the list of JobListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListClusterJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of ClusterListEntry objects of the specified length. Each ClusterListEntry object contains a cluster's state, a cluster's ID, and other important status information.
#
# POST /
# Returns: record<ClusterListEntries: table<ClusterId: string, ClusterState: string, CreationDate: string, Description: string>, NextToken: string>
# operationId: ListClusters
export def "list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --body-max-results: int # The number of ClusterListEntry objects to return. (spec name: MaxResults)
  --body-next-token: string # HTTP requests are stateless. To identify what object comes "next" in the list of ClusterListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListClusters"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your Amazon Web Services accountthat would be supported for use on a Snow device. Currently, supported AMIs are based on the Amazon Linux-2, Ubuntu 20.04 LTS - Focal, or Ubuntu 22.04 LTS - Jammy images, available on the Amazon Web Services Marketplace. Ubuntu 16.04 LTS - Xenial (HVM) images are no longer supported in the Market, but still supported for use on devices through Amazon EC2 VM Import/Export and running locally in AMIs.
#
# POST /
# Returns: record<CompatibleImages: table<AmiId: string, Name: string>, NextToken: string>
# operationId: ListCompatibleImages
export def "list-compatible-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  --body-max-results: int # The maximum number of results for the list of compatible images. Currently, a Snowball Edge device can store 10 AMIs. (spec name: MaxResults)
  --body-next-token: string # HTTP requests are stateless. To identify what object comes "next" in the list of compatible images, you can specify a value for NextToken as the starting point for your list of returned images. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListCompatibleImages"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of JobListEntry objects of the specified length. Each JobListEntry object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
#
# POST /
# Returns: record<JobListEntries: table<JobId: string, JobState: string, IsMaster: bool, JobType: string, SnowballType: string, CreationDate: string, Description: string>, NextToken: string>
# operationId: ListJobs
export def "list-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  --body-max-results: int # The number of JobListEntry objects to return. (spec name: MaxResults)
  --body-next-token: string # HTTP requests are stateless. To identify what object comes "next" in the list of JobListEntry objects, you have the option of specifying NextToken as the starting point for your returned list. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListJobs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all long-term pricing types.
#
# POST /
# Returns: record<LongTermPricingEntries: table<LongTermPricingId: string, LongTermPricingEndDate: string, LongTermPricingStartDate: string, LongTermPricingType: string, CurrentActiveJob: string, ReplacementJob: string, IsLongTermPricingAutoRenew: bool, LongTermPricingStatus: string, SnowballType: string, JobIds: list>, NextToken: string>
# operationId: ListLongTermPricing
export def "list-long-term-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  --body-max-results: int # The maximum number of ListLongTermPricing objects to return. (spec name: MaxResults)
  --body-next-token: string # Because HTTP requests are stateless, this is the starting point for your next list of ListLongTermPricing to return. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListLongTermPricing"}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all supported versions for Snow on-device services. Returns an array of ServiceVersion object containing the supported versions for a particular service.
#
# POST /
# Returns: record<ServiceVersions: table<Version: string>, ServiceName: string, DependentServices: table<ServiceName: string, ServiceVersion: record>, NextToken: string>
# operationId: ListServiceVersions
export def "list-service-versions" [
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
  service_name: string@service-name-completer # The name of the service for which you're requesting supported versions.
  --dependent-services: list # A list of names and versions of dependant services of the requested service. — item shape: {ServiceName?: "KUBERNETES"|"EKS_ANYWHERE", ServiceVersion?: record}
  --max-results: int # The maximum number of ListServiceVersions objects to return.
  --next-token: string # Because HTTP requests are stateless, this is the starting point for the next list of returned ListServiceVersionsRequest versions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.ListServiceVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServiceName, var: service_name}, {name: DependentServices, var: dependent_services}, {name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name, dependent_services: $dependent_services, max_results: $max_results, next_token: $next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# While a cluster's ClusterState value is in the AwaitingQuorum state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
#
# POST /
# Returns: record
# operationId: UpdateCluster
export def "update-cluster" [
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
  cluster_id: string # The cluster ID of the cluster that you want to update, for example CID123e4567-e89b-12d3-a456-426655440000.
  --role-arn: string # The new role Amazon Resource Name (ARN) that you want to associate with this cluster. To create a role ARN, use the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html) API action in Identity and Access Management (IAM).
  --description: string # The updated description of this cluster.
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --address-id: string # The ID of the updated Address object.
  --shipping-option: string@shipping-option-completer # The updated shipping option value of this cluster's ShippingDetails object.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --forwarding-address-id: string # The updated ID for the forwarding address for a cluster. This field is not supported in most regions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.UpdateCluster"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ClusterId, var: cluster_id}, {name: RoleARN, var: role_arn}, {name: Description, var: description}, {name: Resources, var: resources}, {name: OnDeviceServiceConfiguration, var: on_device_service_configuration}, {name: AddressId, var: address_id}, {name: ShippingOption, var: shipping_option}, {name: Notification, var: notification}, {name: ForwardingAddressId, var: forwarding_address_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, cluster_id: $cluster_id, role_arn: $role_arn, description: $description, resources: $resources, on_device_service_configuration: $on_device_service_configuration, address_id: $address_id, shipping_option: $shipping_option, notification: $notification, forwarding_address_id: $forwarding_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# While a job's JobState value is New, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
#
# POST /
# Returns: record
# operationId: UpdateJob
export def "update-job" [
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
  job_id: string # The job ID of the job that you want to update, for example JID123e4567-e89b-12d3-a456-426655440000.
  --role-arn: string # The new role Amazon Resource Name (ARN) that you want to associate with this job. To create a role ARN, use the CreateRole (https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html)Identity and Access Management (IAM) API action.
  --notification: record # The Amazon Simple Notification Service (Amazon SNS) notification settings associated with a specific job. The Notification object is returned as a part of the response syntax of the DescribeJob action in the JobMetadata data type. When the notification settings are defined during job creation, you can choose to notify based on a specific set of job states using the JobStatesToNotify array of strings, or you can specify that you want to have Amazon SNS notifications sent out for all job states with NotifyAll set to true. — shape: {SnsTopicARN?: string, JobStatesToNotify?: list<string>, NotifyAll?: bool}
  --resources: record # Contains an array of Amazon Web Services resource objects. Each object represents an Amazon S3 bucket, an Lambda function, or an Amazon Machine Image (AMI) based on Amazon EC2 that is associated with a particular job. — shape: {S3Resources?: list, LambdaResources?: list, Ec2AmiResources?: list}
  --on-device-service-configuration: record # An object that represents the metadata and configuration settings for services on an Amazon Web Services Snow Family device. — shape: {NFSOnDeviceService?: record, TGWOnDeviceService?: record, EKSOnDeviceService?: record, S3OnDeviceService?: record}
  --address-id: string # The ID of the updated Address object.
  --shipping-option: string@shipping-option-completer # The updated shipping option value of this job's ShippingDetails object.
  --description: string # The updated description of this job's JobMetadata object.
  --snowball-capacity-preference: string@snowball-capacity-preference-completer # The updated SnowballCapacityPreference of this job's JobMetadata object. The 50 TB Snowballs are only available in the US regions. For more information, see "https://docs.aws.amazon.com/snowball/latest/snowcone-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide or "https://docs.aws.amazon.com/snowball/latest/developer-guide/snow-device-types.html" (Snow Family Devices and Capacity) in the Snowcone User Guide.
  --forwarding-address-id: string # The updated ID for the forwarding address for a job. This field is not supported in most regions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.UpdateJob"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: RoleARN, var: role_arn}, {name: Notification, var: notification}, {name: Resources, var: resources}, {name: OnDeviceServiceConfiguration, var: on_device_service_configuration}, {name: AddressId, var: address_id}, {name: ShippingOption, var: shipping_option}, {name: Description, var: description}, {name: SnowballCapacityPreference, var: snowball_capacity_preference}, {name: ForwardingAddressId, var: forwarding_address_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, role_arn: $role_arn, notification: $notification, resources: $resources, on_device_service_configuration: $on_device_service_configuration, address_id: $address_id, shipping_option: $shipping_option, description: $description, snowball_capacity_preference: $snowball_capacity_preference, forwarding_address_id: $forwarding_address_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the state when a shipment state changes to a different state.
#
# POST /
# Returns: record
# operationId: UpdateJobShipmentState
export def "update-job-shipment-state" [
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
  job_id: string # The job ID of the job whose shipment date you want to update, for example JID123e4567-e89b-12d3-a456-426655440000.
  shipment_state: string@shipment-state-completer # The state of a device when it is being shipped. Set to RECEIVED when the device arrives at your location. Set to RETURNED when you have returned the device to Amazon Web Services.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.UpdateJobShipmentState"}]
    body: {content_type: "application/json", kind: json, fields: [{name: JobId, var: job_id}, {name: ShipmentState, var: shipment_state}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, job_id: $job_id, shipment_state: $shipment_state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the long-term pricing type.
#
# POST /
# Returns: record
# operationId: UpdateLongTermPricing
export def "update-long-term-pricing" [
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
  long_term_pricing_id: string # The ID of the long-term pricing type for the device.
  --replacement-job: string # Specifies that a device that is ordered with long-term pricing should be replaced with a new device.
  --is-long-term-pricing-auto-renew: oneof<nothing, bool> # If set to true, specifies that the current long-term pricing type for the device should be automatically renewed before the long-term pricing contract expires.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSIESnowballJobManagementService.UpdateLongTermPricing"}]
    body: {content_type: "application/json", kind: json, fields: [{name: LongTermPricingId, var: long_term_pricing_id}, {name: ReplacementJob, var: replacement_job}, {name: IsLongTermPricingAutoRenew, var: is_long_term_pricing_auto_renew}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, long_term_pricing_id: $long_term_pricing_id, replacement_job: $replacement_job, is_long_term_pricing_auto_renew: $is_long_term_pricing_auto_renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
