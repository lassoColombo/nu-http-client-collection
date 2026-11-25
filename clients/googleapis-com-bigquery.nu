# Auto-generated client for BigQuery API v2
# Source: https://api.apis.guru/v2/specs/googleapis.com/bigquery/v2/openapi.json
# Auth: --token flag or $env.BIGQUERY_API_TOKEN

const CLIENT = {
  base_url: "https://bigquery.googleapis.com/bigquery/v2"
  token_env_var: "BIGQUERY_API_TOKEN"
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

def base-url-completer [] { ["https://bigquery.googleapis.com/bigquery/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def determinism-level-completer [] { ["DETERMINISM_LEVEL_UNSPECIFIED" "DETERMINISTIC" "NOT_DETERMINISTIC"] }
def language-completer [] { ["JAVA" "JAVASCRIPT" "LANGUAGE_UNSPECIFIED" "PYTHON" "SCALA" "SQL"] }
def routine-type-completer [] { ["PROCEDURE" "ROUTINE_TYPE_UNSPECIFIED" "SCALAR_FUNCTION" "TABLE_VALUED_FUNCTION"] }
def view-completer [] { ["BASIC" "FULL" "STORAGE_STATS" "TABLE_METADATA_VIEW_UNSPECIFIED"] }
def projection-completer [] { ["full" "minimal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    bigquery-projects-list: "record<etag: string, kind: string, nextPageToken: string, projects: table<friendlyName: string, id: string, kind: string, numericId: string, projectReference: record>, totalItems: int>"
    bigquery-datasets-list: "record<datasets: table<datasetReference: record, friendlyName: string, id: string, kind: string, labels: record, location: string>, etag: string, kind: string, nextPageToken: string>"
    bigquery-datasets-insert: "record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>"
    bigquery-datasets-get: "record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>"
    bigquery-datasets-patch: "record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>"
    bigquery-datasets-update: "record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>"
    bigquery-models-list: "record<models: table<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record, etag: string, expirationTime: string, featureColumns: list, friendlyName: string, hparamSearchSpaces: record, hparamTrials: list, labelColumns: list, labels: record, lastModifiedTime: string, location: string, modelReference: record, modelType: string, optimalTrialIds: list, trainingRuns: list>, nextPageToken: string>"
    bigquery-models-get: "record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>>"
    bigquery-models-patch: "record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>>"
    bigquery-routines-list: "record<nextPageToken: string, routines: table<arguments: list, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list, language: string, lastModifiedTime: string, remoteFunctionOptions: record, returnTableType: record, returnType: record, routineReference: record, routineType: string, sparkOptions: record, strictMode: bool>>"
    bigquery-routines-insert: "record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>"
    bigquery-routines-get: "record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>"
    bigquery-routines-update: "record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>"
    bigquery-tables-list: "record<etag: string, kind: string, nextPageToken: string, tables: table<clustering: record, creationTime: string, expirationTime: string, friendlyName: string, id: string, kind: string, labels: record, rangePartitioning: record, tableReference: record, timePartitioning: record, type: string, view: record>, totalItems: int>"
    bigquery-tables-insert: "record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>"
    bigquery-tables-get: "record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>"
    bigquery-tables-patch: "record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>"
    bigquery-tables-update: "record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>"
    bigquery-tabledata-list: "record<etag: string, kind: string, pageToken: string, rows: table<f: list>, totalRows: string>"
    bigquery-tabledata-insert-all: "record<insertErrors: table<errors: list, index: int>, kind: string>"
    bigquery-row-access-policies-list: "record<nextPageToken: string, rowAccessPolicies: table<creationTime: string, etag: string, filterPredicate: string, lastModifiedTime: string, rowAccessPolicyReference: record>>"
    bigquery-jobs-list: "record<etag: string, jobs: table<configuration: record, errorResult: record, id: string, jobReference: record, kind: string, state: string, statistics: record, status: record, user_email: string>, kind: string, nextPageToken: string>"
    bigquery-jobs-insert: "record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string>"
    bigquery-jobs-get: "record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string>"
    bigquery-jobs-cancel: "record<job: record<configuration: record<copy: record, dryRun: bool, extract: record, jobTimeoutMs: string, jobType: string, labels: record, load: record, query: record>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record, creationTime: string, dataMaskingStatistics: record, endTime: string, extract: record, load: record, numChildJobs: string, parentJobId: string, query: record, quotaDeferments: list, reservationUsage: list, reservation_id: string, rowLevelSecurityStatistics: record, scriptStatistics: record, sessionInfo: record, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record>, status: record<errorResult: record, errors: list, state: string>, user_email: string>, kind: string>"
    bigquery-jobs-query: "record<cacheHit: bool, dmlStats: record<deletedRowCount: string, insertedRowCount: string, updatedRowCount: string>, errors: table<debugInfo: string, location: string, message: string, reason: string>, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, sessionInfo: record<sessionId: string>, totalBytesProcessed: string, totalRows: string>"
    bigquery-jobs-get-query-results: "record<cacheHit: bool, errors: table<debugInfo: string, location: string, message: string, reason: string>, etag: string, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, totalBytesProcessed: string, totalRows: string>"
    bigquery-projects-get-service-account: "record<email: string, kind: string>"
    bigquery-tables-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    bigquery-tables-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    bigquery-tables-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["bigquery-projects-list" "bigquery-datasets-list" "bigquery-datasets-insert" "bigquery-datasets-delete" "bigquery-datasets-get" "bigquery-datasets-patch" "bigquery-datasets-update" "bigquery-models-list" "bigquery-models-delete" "bigquery-models-get" "bigquery-models-patch" "bigquery-routines-list" "bigquery-routines-insert" "bigquery-routines-delete" "bigquery-routines-get" "bigquery-routines-update" "bigquery-tables-list" "bigquery-tables-insert" "bigquery-tables-delete" "bigquery-tables-get" "bigquery-tables-patch" "bigquery-tables-update" "bigquery-tabledata-list" "bigquery-tabledata-insert-all" "bigquery-row-access-policies-list" "bigquery-jobs-list" "bigquery-jobs-insert" "bigquery-jobs-get" "bigquery-jobs-cancel" "bigquery-jobs-delete" "bigquery-jobs-query" "bigquery-jobs-get-query-results" "bigquery-projects-get-service-account" "bigquery-tables-get-iam-policy" "bigquery-tables-set-iam-policy" "bigquery-tables-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Lists all projects to which you have been granted any project role.
#
# GET /projects
# Returns: record<etag: string, kind: string, nextPageToken: string, projects: table<friendlyName: string, id: string, kind: string, numericId: string, projectReference: record>, totalItems: int>
# operationId: bigquery.projects.list
export def "bigquery-projects-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all datasets in the specified project to which you have been granted the READER dataset role.
#
# GET /projects/{projectId}/datasets
# Returns: record<datasets: table<datasetReference: record, friendlyName: string, id: string, kind: string, labels: record, location: string>, etag: string, kind: string, nextPageToken: string>
# operationId: bigquery.datasets.list
export def "bigquery-datasets-list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --all: oneof<nothing, bool> # Whether to list all datasets, including hidden ones
  --filter: string # An expression for filtering the results of the request by label. The syntax is "labels.[:]". Multiple filters can be ANDed together by connecting with a space. Example: "labels.department:receiving labels.active". See Filtering datasets using labels for details.
  --max-results: int # The maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: all, var: all}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, all: $all, filter: $filter, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new empty dataset.
#
# POST /projects/{projectId}/datasets
# Returns: record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>
# operationId: bigquery.datasets.insert
export def "bigquery-datasets-insert" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/datasets"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: creationTime, var: creation_time}, {name: datasetReference, var: dataset_reference}, {name: defaultCollation, var: default_collation}, {name: defaultEncryptionConfiguration, var: default_encryption_configuration}, {name: defaultPartitionExpirationMs, var: default_partition_expiration_ms}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: defaultTableExpirationMs, var: default_table_expiration_ms}, {name: description, var: description}, {name: etag, var: etag}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: isCaseInsensitive, var: is_case_insensitive}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: maxTimeTravelHours, var: max_time_travel_hours}, {name: satisfiesPzs, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageBillingModel, var: storage_billing_model}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, access: $access, creation_time: $creation_time, dataset_reference: $dataset_reference, default_collation: $default_collation, default_encryption_configuration: $default_encryption_configuration, default_partition_expiration_ms: $default_partition_expiration_ms, default_rounding_mode: $default_rounding_mode, default_table_expiration_ms: $default_table_expiration_ms, description: $description, etag: $etag, friendly_name: $friendly_name, id: $id, is_case_insensitive: $is_case_insensitive, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, max_time_travel_hours: $max_time_travel_hours, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_billing_model: $storage_billing_model, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the dataset specified by the datasetId value. Before you can delete a dataset, you must delete all its tables, either manually or by specifying deleteContents. Immediately after deletion, you can create another dataset with the same name.
#
# DELETE /projects/{projectId}/datasets/{datasetId}
# operationId: bigquery.datasets.delete
export def "bigquery-datasets-delete" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --delete-contents: oneof<nothing, bool> # If True, delete all the tables in the dataset. If False and the dataset contains tables, the request will fail. Default is False
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/datasets/{datasetId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: deleteContents, var: delete_contents}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, delete_contents: $delete_contents
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the dataset specified by datasetID.
#
# GET /projects/{projectId}/datasets/{datasetId}
# Returns: record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>
# operationId: bigquery.datasets.get
export def "bigquery-datasets-get" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}
# Returns: record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>
# operationId: bigquery.datasets.patch
export def "bigquery-datasets-patch" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}/datasets/{datasetId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: creationTime, var: creation_time}, {name: datasetReference, var: dataset_reference}, {name: defaultCollation, var: default_collation}, {name: defaultEncryptionConfiguration, var: default_encryption_configuration}, {name: defaultPartitionExpirationMs, var: default_partition_expiration_ms}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: defaultTableExpirationMs, var: default_table_expiration_ms}, {name: description, var: description}, {name: etag, var: etag}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: isCaseInsensitive, var: is_case_insensitive}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: maxTimeTravelHours, var: max_time_travel_hours}, {name: satisfiesPzs, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageBillingModel, var: storage_billing_model}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, access: $access, creation_time: $creation_time, dataset_reference: $dataset_reference, default_collation: $default_collation, default_encryption_configuration: $default_encryption_configuration, default_partition_expiration_ms: $default_partition_expiration_ms, default_rounding_mode: $default_rounding_mode, default_table_expiration_ms: $default_table_expiration_ms, description: $description, etag: $etag, friendly_name: $friendly_name, id: $id, is_case_insensitive: $is_case_insensitive, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, max_time_travel_hours: $max_time_travel_hours, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_billing_model: $storage_billing_model, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information in an existing dataset. The update method replaces the entire dataset resource, whereas the patch method only replaces fields that are provided in the submitted dataset resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}
# Returns: record<access: table<dataset: record, domain: string, groupByEmail: string, iamMember: string, role: string, routine: record, specialGroup: string, userByEmail: string, view: record>, creationTime: string, datasetReference: record<datasetId: string, projectId: string>, defaultCollation: string, defaultEncryptionConfiguration: record<kmsKeyName: string>, defaultPartitionExpirationMs: string, defaultRoundingMode: string, defaultTableExpirationMs: string, description: string, etag: string, friendlyName: string, id: string, isCaseInsensitive: bool, kind: string, labels: record, lastModifiedTime: string, location: string, maxTimeTravelHours: string, satisfiesPzs: bool, selfLink: string, storageBillingModel: string, tags: table<tagKey: string, tagValue: string>>
# operationId: bigquery.datasets.update
export def "bigquery-datasets-update" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --access: list # [Optional] An array of objects that define dataset access for one or more entities. You can set this property when inserting or updating a dataset in order to control who is allowed to access the data. If unspecified at dataset creation time, BigQuery adds default dataset access for the following entities: access.specialGroup: projectReaders; access.role: READER; access.specialGroup: projectWriters; access.role: WRITER; access.specialGroup: projectOwners; access.role: OWNER; access.userByEmail: [dataset creator email]; access.role: OWNER; — item shape: {dataset?: record, domain?: string, groupByEmail?: string, iamMember?: string, role?: string, routine?: record, specialGroup?: string, userByEmail?: string, view?: record}
  --creation-time: string # [Output-only] The time when this dataset was created, in milliseconds since the epoch. (format: int64)
  --dataset-reference: record # shape: {datasetId?: string, projectId?: string}
  --default-collation: string # [Output-only] The default collation of the dataset.
  --default-encryption-configuration: record # shape: {kmsKeyName?: string}
  --default-partition-expiration-ms: string # [Optional] The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. Setting this property overrides the use of defaultTableExpirationMs for partitioned tables: only one of defaultTableExpirationMs and defaultPartitionExpirationMs will be used for any new partitioned table. If you provide an explicit timePartitioning.expirationMs when creating or updating a partitioned table, that value takes precedence over the default partition expiration time indicated by this property. (format: int64)
  --default-rounding-mode: string # [Output-only] The default rounding mode of the dataset.
  --default-table-expiration-ms: string # [Optional] The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. (format: int64)
  --description: string # [Optional] A user-friendly description of the dataset.
  --etag: string # [Output-only] A hash of the resource.
  --friendly-name: string # [Optional] A descriptive name for the dataset.
  --id: string # [Output-only] The fully-qualified unique name of the dataset in the format projectId:datasetId. The dataset name without the project name is given in the datasetId field. When creating a new dataset, leave this field blank, and instead specify the datasetId field.
  --is-case-insensitive: oneof<nothing, bool> # [Optional] Indicates if table names are case insensitive in the dataset.
  --kind: string # [Output-only] The resource type. (default: bigquery#dataset)
  --labels: record # The labels associated with this dataset. You can use these to organize and group your datasets. You can set this property when inserting or updating a dataset. See Creating and Updating Dataset Labels for more information.
  --last-modified-time: string # [Output-only] The date when this dataset or any of its tables was last modified, in milliseconds since the epoch. (format: int64)
  --location: string # The geographic location where the dataset should reside. The default value is US. See details at https://cloud.google.com/bigquery/docs/locations.
  --max-time-travel-hours: string # [Optional] Number of hours for the max time travel for all tables in the dataset. (format: int64)
  --satisfies-pzs: oneof<nothing, bool> # [Output-only] Reserved for future use.
  --self-link: string # [Output-only] A URL that can be used to access the resource again. You can use this URL in Get or Update requests to the resource.
  --storage-billing-model: string # [Optional] Storage billing model to be used for all tables in the dataset. Can be set to PHYSICAL. Default is LOGICAL.
  --tags: list # [Optional]The tags associated with this dataset. Tag keys are globally unique. — item shape: {tagKey?: string, tagValue?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/datasets/{datasetId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: creationTime, var: creation_time}, {name: datasetReference, var: dataset_reference}, {name: defaultCollation, var: default_collation}, {name: defaultEncryptionConfiguration, var: default_encryption_configuration}, {name: defaultPartitionExpirationMs, var: default_partition_expiration_ms}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: defaultTableExpirationMs, var: default_table_expiration_ms}, {name: description, var: description}, {name: etag, var: etag}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: isCaseInsensitive, var: is_case_insensitive}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: maxTimeTravelHours, var: max_time_travel_hours}, {name: satisfiesPzs, var: satisfies_pzs}, {name: selfLink, var: self_link}, {name: storageBillingModel, var: storage_billing_model}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, access: $access, creation_time: $creation_time, dataset_reference: $dataset_reference, default_collation: $default_collation, default_encryption_configuration: $default_encryption_configuration, default_partition_expiration_ms: $default_partition_expiration_ms, default_rounding_mode: $default_rounding_mode, default_table_expiration_ms: $default_table_expiration_ms, description: $description, etag: $etag, friendly_name: $friendly_name, id: $id, is_case_insensitive: $is_case_insensitive, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, max_time_travel_hours: $max_time_travel_hours, satisfies_pzs: $satisfies_pzs, self_link: $self_link, storage_billing_model: $storage_billing_model, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all models in the specified dataset. Requires the READER dataset role. After retrieving the list of models, you can get information about a particular model by calling the models.get method.
#
# GET /projects/{projectId}/datasets/{datasetId}/models
# Returns: record<models: table<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record, etag: string, expirationTime: string, featureColumns: list, friendlyName: string, hparamSearchSpaces: record, hparamTrials: list, labelColumns: list, labels: record, lastModifiedTime: string, location: string, modelReference: record, modelType: string, optimalTrialIds: list, trainingRuns: list>, nextPageToken: string>
# operationId: bigquery.models.list
export def "bigquery-models-list" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call to request the next page of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/models"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the model specified by modelId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# operationId: bigquery.models.delete
export def "bigquery-models-delete" [
  project_id: string
  dataset_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/datasets/{datasetId}/models/{modelId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: modelId, var: model_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, model_id: $model_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified model resource by model ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# Returns: record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>>
# operationId: bigquery.models.get
export def "bigquery-models-get" [
  project_id: string
  dataset_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/models/{modelId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: modelId, var: model_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, model_id: $model_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch specific fields in the specified model.
#
# PATCH /projects/{projectId}/datasets/{datasetId}/models/{modelId}
# Returns: record<bestTrialId: string, creationTime: string, defaultTrialId: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, featureColumns: table<name: string, type: record>, friendlyName: string, hparamSearchSpaces: record<activationFn: record<candidates: list>, batchSize: record<candidates: record, range: record>, boosterType: record<candidates: list>, colsampleBylevel: record<candidates: record, range: record>, colsampleBynode: record<candidates: record, range: record>, colsampleBytree: record<candidates: record, range: record>, dartNormalizeType: record<candidates: list>, dropout: record<candidates: record, range: record>, hiddenUnits: record<candidates: list>, l1Reg: record<candidates: record, range: record>, l2Reg: record<candidates: record, range: record>, learnRate: record<candidates: record, range: record>, maxTreeDepth: record<candidates: record, range: record>, minSplitLoss: record<candidates: record, range: record>, minTreeChildWeight: record<candidates: record, range: record>, numClusters: record<candidates: record, range: record>, numFactors: record<candidates: record, range: record>, numParallelTree: record<candidates: record, range: record>, optimizer: record<candidates: list>, subsample: record<candidates: record, range: record>, treeMethod: record<candidates: list>, walsAlpha: record<candidates: record, range: record>>, hparamTrials: table<endTimeMs: string, errorMessage: string, evalLoss: float, evaluationMetrics: record, hparamTuningEvaluationMetrics: record, hparams: record, startTimeMs: string, status: string, trainingLoss: float, trialId: string>, labelColumns: table<name: string, type: record>, labels: record, lastModifiedTime: string, location: string, modelReference: record<datasetId: string, modelId: string, projectId: string>, modelType: string, optimalTrialIds: list<string>, trainingRuns: table<classLevelGlobalExplanations: list, dataSplitResult: record, evaluationMetrics: record, modelLevelGlobalExplanation: record, results: list, startTime: string, trainingOptions: record, trainingStartTime: string, vertexAiModelId: string, vertexAiModelVersion: string>>
# operationId: bigquery.models.patch
export def "bigquery-models-patch" [
  project_id: string
  dataset_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --best-trial-id: string # The best trial_id across all training runs. (format: int64)
  --description: string # Optional. A user-friendly description of this model.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --expiration-time: string # Optional. The time when this model expires, in milliseconds since the epoch. If not present, the model will persist indefinitely. Expired models will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created models. (format: int64)
  --friendly-name: string # Optional. A descriptive name for this model.
  --hparam-search-spaces: record # Hyperparameter search spaces. These should be a subset of training_options. — shape: {activationFn?: record, batchSize?: record, boosterType?: record, colsampleBylevel?: record, colsampleBynode?: record, colsampleBytree?: record, dartNormalizeType?: record, dropout?: record, hiddenUnits?: record, l1Reg?: record, l2Reg?: record, learnRate?: record, maxTreeDepth?: record, minSplitLoss?: record, minTreeChildWeight?: record, numClusters?: record, numFactors?: record, numParallelTree?: record, optimizer?: record, subsample?: record, treeMethod?: record, walsAlpha?: record}
  --labels: record # The labels associated with this model. You can use these to organize and group your models. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --model-reference: record # shape: {datasetId?: string, modelId?: string, projectId?: string}
  --training-runs: list # Information for all training runs in increasing order of start_time. — item shape: {dataSplitResult?: record, evaluationMetrics?: record, modelLevelGlobalExplanation?: record, trainingOptions?: record, vertexAiModelId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}/datasets/{datasetId}/models/{modelId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: modelId, var: model_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: bestTrialId, var: best_trial_id}, {name: description, var: description}, {name: encryptionConfiguration, var: encryption_configuration}, {name: expirationTime, var: expiration_time}, {name: friendlyName, var: friendly_name}, {name: hparamSearchSpaces, var: hparam_search_spaces}, {name: labels, var: labels}, {name: modelReference, var: model_reference}, {name: trainingRuns, var: training_runs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, model_id: $model_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, best_trial_id: $best_trial_id, description: $description, encryption_configuration: $encryption_configuration, expiration_time: $expiration_time, friendly_name: $friendly_name, hparam_search_spaces: $hparam_search_spaces, labels: $labels, model_reference: $model_reference, training_runs: $training_runs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all routines in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines
# Returns: record<nextPageToken: string, routines: table<arguments: list, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list, language: string, lastModifiedTime: string, remoteFunctionOptions: record, returnTableType: record, returnType: record, routineReference: record, routineType: string, sparkOptions: record, strictMode: bool>>
# operationId: bigquery.routines.list
export def "bigquery-routines-list" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter: string # If set, then only the Routines matching this filter are returned. The current supported form is either "routine_type:" or "routineType:", where is a RoutineType enum. Example: "routineType:SCALAR_FUNCTION".
  --max-results: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --read-mask: string # If set, then only the Routine fields in the field mask, as well as project_id, dataset_id and routine_id, are returned in the response. If unset, then the following Routine fields are returned: etag, project_id, dataset_id, routine_id, routine_type, creation_time, last_modified_time, and language.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/routines"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: filter, var: filter}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, filter: $filter, max_results: $max_results, page_token: $page_token, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new routine in the dataset.
#
# POST /projects/{projectId}/datasets/{datasetId}/routines
# Returns: record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>
# operationId: bigquery.routines.insert
export def "bigquery-routines-insert" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definition-body: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinism-level: string@determinism-level-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --imported-libraries: list<string> # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remote-function-options: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --return-table-type: record # A table type — shape: {columns?: list}
  --return-type: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routine-reference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routine-type: string@routine-type-completer # Required. The type of routine.
  --spark-options: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
  --strict-mode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/datasets/{datasetId}/routines"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: arguments, var: arguments}, {name: definitionBody, var: definition_body}, {name: description, var: description}, {name: determinismLevel, var: determinism_level}, {name: importedLibraries, var: imported_libraries}, {name: language, var: language}, {name: remoteFunctionOptions, var: remote_function_options}, {name: returnTableType, var: return_table_type}, {name: returnType, var: return_type}, {name: routineReference, var: routine_reference}, {name: routineType, var: routine_type}, {name: sparkOptions, var: spark_options}, {name: strictMode, var: strict_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, arguments: $arguments, definition_body: $definition_body, description: $description, determinism_level: $determinism_level, imported_libraries: $imported_libraries, language: $language, remote_function_options: $remote_function_options, return_table_type: $return_table_type, return_type: $return_type, routine_reference: $routine_reference, routine_type: $routine_type, spark_options: $spark_options, strict_mode: $strict_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the routine specified by routineId from the dataset.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# operationId: bigquery.routines.delete
export def "bigquery-routines-delete" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/datasets/{datasetId}/routines/{routineId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: routineId, var: routine_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, routine_id: $routine_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified routine resource by routine ID.
#
# GET /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# Returns: record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>
# operationId: bigquery.routines.get
export def "bigquery-routines-get" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --read-mask: string # If set, only the Routine fields in the field mask are returned in the response. If unset, all Routine fields are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/routines/{routineId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: routineId, var: routine_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, routine_id: $routine_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information in an existing routine. The update method replaces the entire Routine resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}/routines/{routineId}
# Returns: record<arguments: table<argumentKind: string, dataType: record, mode: string, name: string>, creationTime: string, definitionBody: string, description: string, determinismLevel: string, etag: string, importedLibraries: list<string>, language: string, lastModifiedTime: string, remoteFunctionOptions: record<connection: string, endpoint: string, maxBatchingRows: string, userDefinedContext: record>, returnTableType: record<columns: list<record>>, returnType: record<arrayElementType: any, structType: record<fields: list>, typeKind: string>, routineReference: record<datasetId: string, projectId: string, routineId: string>, routineType: string, sparkOptions: record<archiveUris: list<string>, connection: string, containerImage: string, fileUris: list<string>, jarUris: list<string>, mainClass: string, mainFileUri: string, properties: record, pyFileUris: list<string>, runtimeVersion: string>, strictMode: bool>
# operationId: bigquery.routines.update
export def "bigquery-routines-update" [
  project_id: string
  dataset_id: string
  routine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --arguments: list # Optional. — item shape: {argumentKind?: "ARGUMENT_KIND_UNSPECIFIED"|"FIXED_TYPE"|"ANY_TYPE", dataType?: record, mode?: "MODE_UNSPECIFIED"|"IN"|"OUT"|"INOUT", name?: string}
  --definition-body: string # Required. The body of the routine. For functions, this is the expression in the AS clause. If language=SQL, it is the substring inside (but excluding) the parentheses. For example, for the function created with the following statement: `CREATE FUNCTION JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body is `concat(x, "\n", y)` (\n is not replaced with linebreak). If language=JAVASCRIPT, it is the evaluated string in the AS clause. For example, for the function created with the following statement: `CREATE FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The definition_body is `return "\n";\n` Note that both \n are replaced with linebreaks.
  --description: string # Optional. The description of the routine, if defined.
  --determinism-level: string@determinism-level-completer # Optional. The determinism level of the JavaScript UDF, if defined.
  --imported-libraries: list<string> # Optional. If language = "JAVASCRIPT", this field stores the path of the imported JAVASCRIPT libraries.
  --language: string@language-completer # Optional. Defaults to "SQL" if remote_function_options field is absent, not set otherwise.
  --remote-function-options: record # Options for a remote user-defined function. — shape: {connection?: string, endpoint?: string, maxBatchingRows?: string, userDefinedContext?: record}
  --return-table-type: record # A table type — shape: {columns?: list}
  --return-type: record # The data type of a variable such as a function argument. Examples include: * INT64: `{"typeKind": "INT64"}` * ARRAY: { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "STRING"} } * STRUCT>: { "typeKind": "STRUCT", "structType": { "fields": [ { "name": "x", "type": {"typeKind": "STRING"} }, { "name": "y", "type": { "typeKind": "ARRAY", "arrayElementType": {"typeKind": "DATE"} } } ] } } — shape: {arrayElementType?: record, structType?: record, typeKind?: "TYPE_KIND_UNSPECIFIED"|"INT64"|"BOOL"|"FLOAT64"|"STRING"|"BYTES"|"TIMESTAMP"|"DATE"|"TIME"|"DATETIME"|"INTERVAL"|"GEOGRAPHY"|"NUMERIC"|"BIGNUMERIC"|"JSON"|"ARRAY"|"STRUCT"}
  --routine-reference: record # shape: {datasetId?: string, projectId?: string, routineId?: string}
  --routine-type: string@routine-type-completer # Required. The type of routine.
  --spark-options: record # Options for a user-defined Spark routine. — shape: {archiveUris?: list<string>, connection?: string, containerImage?: string, fileUris?: list<string>, jarUris?: list<string>, mainClass?: string, mainFileUri?: string, properties?: record, pyFileUris?: list<string>, runtimeVersion?: string}
  --strict-mode: oneof<nothing, bool> # Optional. Can be set for procedures only. If true (default), the definition body will be validated in the creation and the updates of the procedure. For procedures with an argument of ANY TYPE, the definition body validtion is not supported at creation/update time, and thus this field must be set to false explicitly.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/datasets/{datasetId}/routines/{routineId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: routineId, var: routine_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: arguments, var: arguments}, {name: definitionBody, var: definition_body}, {name: description, var: description}, {name: determinismLevel, var: determinism_level}, {name: importedLibraries, var: imported_libraries}, {name: language, var: language}, {name: remoteFunctionOptions, var: remote_function_options}, {name: returnTableType, var: return_table_type}, {name: returnType, var: return_type}, {name: routineReference, var: routine_reference}, {name: routineType, var: routine_type}, {name: sparkOptions, var: spark_options}, {name: strictMode, var: strict_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, routine_id: $routine_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, arguments: $arguments, definition_body: $definition_body, description: $description, determinism_level: $determinism_level, imported_libraries: $imported_libraries, language: $language, remote_function_options: $remote_function_options, return_table_type: $return_table_type, return_type: $return_type, routine_reference: $routine_reference, routine_type: $routine_type, spark_options: $spark_options, strict_mode: $strict_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all tables in the specified dataset. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables
# Returns: record<etag: string, kind: string, nextPageToken: string, tables: table<clustering: record, creationTime: string, expirationTime: string, friendlyName: string, id: string, kind: string, labels: record, rangePartitioning: record, tableReference: record, timePartitioning: record, type: string, view: record>, totalItems: int>
# operationId: bigquery.tables.list
export def "bigquery-tables-list" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, to request the next page of results
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/tables"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new, empty table in the dataset.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables
# Returns: record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>
# operationId: bigquery.tables.insert
export def "bigquery-tables-insert" [
  project_id: string
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/datasets/{datasetId}/tables"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloneDefinition, var: clone_definition}, {name: clustering, var: clustering}, {name: creationTime, var: creation_time}, {name: defaultCollation, var: default_collation}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: description, var: description}, {name: encryptionConfiguration, var: encryption_configuration}, {name: etag, var: etag}, {name: expirationTime, var: expiration_time}, {name: externalDataConfiguration, var: external_data_configuration}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: materializedView, var: materialized_view}, {name: maxStaleness, var: max_staleness}, {name: model, var: model}, {name: numBytes, var: num_bytes}, {name: numLongTermBytes, var: num_long_term_bytes}, {name: numPhysicalBytes, var: num_physical_bytes}, {name: numRows, var: num_rows}, {name: num_active_logical_bytes, var: num_active_logical_bytes}, {name: num_active_physical_bytes, var: num_active_physical_bytes}, {name: num_long_term_logical_bytes, var: num_long_term_logical_bytes}, {name: num_long_term_physical_bytes, var: num_long_term_physical_bytes}, {name: num_partitions, var: num_partitions}, {name: num_time_travel_physical_bytes, var: num_time_travel_physical_bytes}, {name: num_total_logical_bytes, var: num_total_logical_bytes}, {name: num_total_physical_bytes, var: num_total_physical_bytes}, {name: rangePartitioning, var: range_partitioning}, {name: requirePartitionFilter, var: require_partition_filter}, {name: schema, var: schema}, {name: selfLink, var: self_link}, {name: snapshotDefinition, var: snapshot_definition}, {name: streamingBuffer, var: streaming_buffer}, {name: tableReference, var: table_reference}, {name: timePartitioning, var: time_partitioning}, {name: type, var: type}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, clone_definition: $clone_definition, clustering: $clustering, creation_time: $creation_time, default_collation: $default_collation, default_rounding_mode: $default_rounding_mode, description: $description, encryption_configuration: $encryption_configuration, etag: $etag, expiration_time: $expiration_time, external_data_configuration: $external_data_configuration, friendly_name: $friendly_name, id: $id, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, materialized_view: $materialized_view, max_staleness: $max_staleness, model: $model, num_bytes: $num_bytes, num_long_term_bytes: $num_long_term_bytes, num_physical_bytes: $num_physical_bytes, num_rows: $num_rows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, range_partitioning: $range_partitioning, require_partition_filter: $require_partition_filter, schema: $schema, self_link: $self_link, snapshot_definition: $snapshot_definition, streaming_buffer: $streaming_buffer, table_reference: $table_reference, time_partitioning: $time_partitioning, type: $type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the table specified by tableId from the dataset. If the table contains data, all the data will be deleted.
#
# DELETE /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# operationId: bigquery.tables.delete
export def "bigquery-tables-delete" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified table resource by table ID. This method does not return the data in the table, it only returns the table resource, which describes the structure of this table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# Returns: record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>
# operationId: bigquery.tables.get
export def "bigquery-tables-get" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --selected-fields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --view: string@view-completer # Specifies the view that determines which table information is returned. By default, basic table information and storage statistics (STORAGE_STATS) are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: selectedFields, var: selected_fields}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, selected_fields: $selected_fields, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource. This method supports patch semantics.
#
# PATCH /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# Returns: record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>
# operationId: bigquery.tables.patch
export def "bigquery-tables-patch" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: autodetect_schema, var: autodetect_schema}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloneDefinition, var: clone_definition}, {name: clustering, var: clustering}, {name: creationTime, var: creation_time}, {name: defaultCollation, var: default_collation}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: description, var: description}, {name: encryptionConfiguration, var: encryption_configuration}, {name: etag, var: etag}, {name: expirationTime, var: expiration_time}, {name: externalDataConfiguration, var: external_data_configuration}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: materializedView, var: materialized_view}, {name: maxStaleness, var: max_staleness}, {name: model, var: model}, {name: numBytes, var: num_bytes}, {name: numLongTermBytes, var: num_long_term_bytes}, {name: numPhysicalBytes, var: num_physical_bytes}, {name: numRows, var: num_rows}, {name: num_active_logical_bytes, var: num_active_logical_bytes}, {name: num_active_physical_bytes, var: num_active_physical_bytes}, {name: num_long_term_logical_bytes, var: num_long_term_logical_bytes}, {name: num_long_term_physical_bytes, var: num_long_term_physical_bytes}, {name: num_partitions, var: num_partitions}, {name: num_time_travel_physical_bytes, var: num_time_travel_physical_bytes}, {name: num_total_logical_bytes, var: num_total_logical_bytes}, {name: num_total_physical_bytes, var: num_total_physical_bytes}, {name: rangePartitioning, var: range_partitioning}, {name: requirePartitionFilter, var: require_partition_filter}, {name: schema, var: schema}, {name: selfLink, var: self_link}, {name: snapshotDefinition, var: snapshot_definition}, {name: streamingBuffer, var: streaming_buffer}, {name: tableReference, var: table_reference}, {name: timePartitioning, var: time_partitioning}, {name: type, var: type}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, autodetect_schema: $autodetect_schema, clone_definition: $clone_definition, clustering: $clustering, creation_time: $creation_time, default_collation: $default_collation, default_rounding_mode: $default_rounding_mode, description: $description, encryption_configuration: $encryption_configuration, etag: $etag, expiration_time: $expiration_time, external_data_configuration: $external_data_configuration, friendly_name: $friendly_name, id: $id, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, materialized_view: $materialized_view, max_staleness: $max_staleness, model: $model, num_bytes: $num_bytes, num_long_term_bytes: $num_long_term_bytes, num_physical_bytes: $num_physical_bytes, num_rows: $num_rows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, range_partitioning: $range_partitioning, require_partition_filter: $require_partition_filter, schema: $schema, self_link: $self_link, snapshot_definition: $snapshot_definition, streaming_buffer: $streaming_buffer, table_reference: $table_reference, time_partitioning: $time_partitioning, type: $type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates information in an existing table. The update method replaces the entire table resource, whereas the patch method only replaces fields that are provided in the submitted table resource.
#
# PUT /projects/{projectId}/datasets/{datasetId}/tables/{tableId}
# Returns: record<cloneDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, cloneTime: string>, clustering: record<fields: list<string>>, creationTime: string, defaultCollation: string, defaultRoundingMode: string, description: string, encryptionConfiguration: record<kmsKeyName: string>, etag: string, expirationTime: string, externalDataConfiguration: record<autodetect: bool, avroOptions: record<useAvroLogicalTypes: bool>, bigtableOptions: record<columnFamilies: list, ignoreUnspecifiedColumnFamilies: bool, readRowkeyAsString: bool>, compression: string, connectionId: string, csvOptions: record<allowJaggedRows: bool, allowQuotedNewlines: bool, encoding: string, fieldDelimiter: string, null_marker: string, preserveAsciiControlCharacters: bool, quote: string, skipLeadingRows: string>, decimalTargetTypes: list<string>, googleSheetsOptions: record<range: string, skipLeadingRows: string>, hivePartitioningOptions: record<mode: string, requirePartitionFilter: bool, sourceUriPrefix: string>, ignoreUnknownValues: bool, maxBadRecords: int, metadataCacheMode: string, objectMetadata: string, parquetOptions: record<enableListInference: bool, enumAsString: bool>, referenceFileSchemaUri: string, schema: record<fields: list>, sourceFormat: string, sourceUris: list<string>>, friendlyName: string, id: string, kind: string, labels: record, lastModifiedTime: string, location: string, materializedView: record<allow_non_incremental_definition: bool, enableRefresh: bool, lastRefreshTime: string, maxStaleness: string, query: string, refreshIntervalMs: string>, maxStaleness: string, model: record<modelOptions: record<labels: list, lossType: string, modelType: string>, trainingRuns: list<record>>, numBytes: string, numLongTermBytes: string, numPhysicalBytes: string, numRows: string, num_active_logical_bytes: string, num_active_physical_bytes: string, num_long_term_logical_bytes: string, num_long_term_physical_bytes: string, num_partitions: string, num_time_travel_physical_bytes: string, num_total_logical_bytes: string, num_total_physical_bytes: string, rangePartitioning: record<field: string, range: record<end: string, interval: string, start: string>>, requirePartitionFilter: bool, schema: record<fields: list<record>>, selfLink: string, snapshotDefinition: record<baseTableReference: record<datasetId: string, projectId: string, tableId: string>, snapshotTime: string>, streamingBuffer: record<estimatedBytes: string, estimatedRows: string, oldestEntryTime: string>, tableReference: record<datasetId: string, projectId: string, tableId: string>, timePartitioning: record<expirationMs: string, field: string, requirePartitionFilter: bool, type: string>, type: string, view: record<query: string, useExplicitColumnNames: bool, useLegacySql: bool, userDefinedFunctionResources: list<record>>>
# operationId: bigquery.tables.update
export def "bigquery-tables-update" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --autodetect-schema: oneof<nothing, bool> # When true will autodetect schema, else will keep original schema
  --clone-definition: record # shape: {baseTableReference?: record, cloneTime?: string}
  --clustering: record # shape: {fields?: list<string>}
  --creation-time: string # [Output-only] The time when this table was created, in milliseconds since the epoch. (format: int64)
  --default-collation: string # [Output-only] The default collation of the table.
  --default-rounding-mode: string # [Output-only] The default rounding mode of the table.
  --description: string # [Optional] A user-friendly description of this table.
  --encryption-configuration: record # shape: {kmsKeyName?: string}
  --etag: string # [Output-only] A hash of the table metadata. Used to ensure there were no concurrent modifications to the resource when attempting an update. Not guaranteed to change when the table contents or the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  --expiration-time: string # [Optional] The time when this table expires, in milliseconds since the epoch. If not present, the table will persist indefinitely. Expired tables will be deleted and their storage reclaimed. The defaultTableExpirationMs property of the encapsulating dataset can be used to set a default expirationTime on newly created tables. (format: int64)
  --external-data-configuration: record # shape: {autodetect?: bool, avroOptions?: record, bigtableOptions?: record, compression?: string, connectionId?: string, csvOptions?: record, decimalTargetTypes?: list<string>, googleSheetsOptions?: record, hivePartitioningOptions?: record, ignoreUnknownValues?: bool, maxBadRecords?: int, metadataCacheMode?: string, objectMetadata?: string, parquetOptions?: record, referenceFileSchemaUri?: string, schema?: record, sourceFormat?: string, sourceUris?: list<string>}
  --friendly-name: string # [Optional] A descriptive name for this table.
  --id: string # [Output-only] An opaque ID uniquely identifying the table.
  --kind: string # [Output-only] The type of the resource. (default: bigquery#table)
  --labels: record # The labels associated with this table. You can use these to organize and group your tables. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --last-modified-time: string # [Output-only] The time when this table was last modified, in milliseconds since the epoch. (format: uint64)
  --location: string # [Output-only] The geographic location where the table resides. This value is inherited from the dataset.
  --materialized-view: record # shape: {allow_non_incremental_definition?: bool, enableRefresh?: bool, lastRefreshTime?: string, maxStaleness?: string, query?: string, refreshIntervalMs?: string}
  --max-staleness: string # [Optional] Max staleness of data that could be returned when table or materialized view is queried (formatted as Google SQL Interval type). (format: byte)
  --model: record # shape: {modelOptions?: record, trainingRuns?: list}
  --num-bytes: string # [Output-only] The size of this table in bytes, excluding any data in the streaming buffer. (format: int64)
  --num-long-term-bytes: string # [Output-only] The number of bytes in the table that are considered "long-term storage". (format: int64)
  --num-physical-bytes: string # [Output-only] [TrustedTester] The physical size of this table in bytes, excluding any data in the streaming buffer. This includes compression and storage used for time travel. (format: int64)
  --num-rows: string # [Output-only] The number of rows of data in this table, excluding any data in the streaming buffer. (format: uint64)
  --num-active-logical-bytes: string # [Output-only] Number of logical bytes that are less than 90 days old. (format: int64)
  --num-active-physical-bytes: string # [Output-only] Number of physical bytes less than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-long-term-logical-bytes: string # [Output-only] Number of logical bytes that are more than 90 days old. (format: int64)
  --num-long-term-physical-bytes: string # [Output-only] Number of physical bytes more than 90 days old. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-partitions: string # [Output-only] The number of partitions present in the table or materialized view. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-time-travel-physical-bytes: string # [Output-only] Number of physical bytes used by time travel storage (deleted or changed data). This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --num-total-logical-bytes: string # [Output-only] Total number of logical bytes in the table or materialized view. (format: int64)
  --num-total-physical-bytes: string # [Output-only] The physical size of this table in bytes. This also includes storage used for time travel. This data is not kept in real time, and might be delayed by a few seconds to a few minutes. (format: int64)
  --range-partitioning: record # shape: {field?: string, range?: record}
  --require-partition-filter: oneof<nothing, bool> # [Optional] If set to true, queries over this table require a partition filter that can be used for partition elimination to be specified. (default: false)
  --schema: record # shape: {fields?: list}
  --self-link: string # [Output-only] A URL that can be used to access this resource again.
  --snapshot-definition: record # shape: {baseTableReference?: record, snapshotTime?: string}
  --streaming-buffer: record # shape: {estimatedBytes?: string, estimatedRows?: string, oldestEntryTime?: string}
  --table-reference: record # shape: {datasetId?: string, projectId?: string, tableId?: string}
  --time-partitioning: record # shape: {expirationMs?: string, field?: string, requirePartitionFilter?: bool, type?: string}
  --type: string # [Output-only] Describes the table type. The following values are supported: TABLE: A normal BigQuery table. VIEW: A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only table that is a copy of another table. [TrustedTester] MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table that references data stored in an external storage system, such as Google Cloud Storage. The default value is TABLE.
  --view: record # shape: {query?: string, useExplicitColumnNames?: bool, useLegacySql?: bool, userDefinedFunctionResources?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: autodetect_schema, var: autodetect_schema}]
    body: {content_type: "application/json", kind: json, fields: [{name: cloneDefinition, var: clone_definition}, {name: clustering, var: clustering}, {name: creationTime, var: creation_time}, {name: defaultCollation, var: default_collation}, {name: defaultRoundingMode, var: default_rounding_mode}, {name: description, var: description}, {name: encryptionConfiguration, var: encryption_configuration}, {name: etag, var: etag}, {name: expirationTime, var: expiration_time}, {name: externalDataConfiguration, var: external_data_configuration}, {name: friendlyName, var: friendly_name}, {name: id, var: id}, {name: kind, var: kind}, {name: labels, var: labels}, {name: lastModifiedTime, var: last_modified_time}, {name: location, var: location}, {name: materializedView, var: materialized_view}, {name: maxStaleness, var: max_staleness}, {name: model, var: model}, {name: numBytes, var: num_bytes}, {name: numLongTermBytes, var: num_long_term_bytes}, {name: numPhysicalBytes, var: num_physical_bytes}, {name: numRows, var: num_rows}, {name: num_active_logical_bytes, var: num_active_logical_bytes}, {name: num_active_physical_bytes, var: num_active_physical_bytes}, {name: num_long_term_logical_bytes, var: num_long_term_logical_bytes}, {name: num_long_term_physical_bytes, var: num_long_term_physical_bytes}, {name: num_partitions, var: num_partitions}, {name: num_time_travel_physical_bytes, var: num_time_travel_physical_bytes}, {name: num_total_logical_bytes, var: num_total_logical_bytes}, {name: num_total_physical_bytes, var: num_total_physical_bytes}, {name: rangePartitioning, var: range_partitioning}, {name: requirePartitionFilter, var: require_partition_filter}, {name: schema, var: schema}, {name: selfLink, var: self_link}, {name: snapshotDefinition, var: snapshot_definition}, {name: streamingBuffer, var: streaming_buffer}, {name: tableReference, var: table_reference}, {name: timePartitioning, var: time_partitioning}, {name: type, var: type}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, autodetect_schema: $autodetect_schema, clone_definition: $clone_definition, clustering: $clustering, creation_time: $creation_time, default_collation: $default_collation, default_rounding_mode: $default_rounding_mode, description: $description, encryption_configuration: $encryption_configuration, etag: $etag, expiration_time: $expiration_time, external_data_configuration: $external_data_configuration, friendly_name: $friendly_name, id: $id, kind: $kind, labels: $labels, last_modified_time: $last_modified_time, location: $location, materialized_view: $materialized_view, max_staleness: $max_staleness, model: $model, num_bytes: $num_bytes, num_long_term_bytes: $num_long_term_bytes, num_physical_bytes: $num_physical_bytes, num_rows: $num_rows, num_active_logical_bytes: $num_active_logical_bytes, num_active_physical_bytes: $num_active_physical_bytes, num_long_term_logical_bytes: $num_long_term_logical_bytes, num_long_term_physical_bytes: $num_long_term_physical_bytes, num_partitions: $num_partitions, num_time_travel_physical_bytes: $num_time_travel_physical_bytes, num_total_logical_bytes: $num_total_logical_bytes, num_total_physical_bytes: $num_total_physical_bytes, range_partitioning: $range_partitioning, require_partition_filter: $require_partition_filter, schema: $schema, self_link: $self_link, snapshot_definition: $snapshot_definition, streaming_buffer: $streaming_buffer, table_reference: $table_reference, time_partitioning: $time_partitioning, type: $type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves table data from a specified set of rows. Requires the READER dataset role.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/data
# Returns: record<etag: string, kind: string, pageToken: string, rows: table<f: list>, totalRows: string>
# operationId: bigquery.tabledata.list
export def "bigquery-tabledata-list" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of results to return
  --page-token: string # Page token, returned by a previous call, identifying the result set
  --selected-fields: string # List of fields to return (comma-separated). If unspecified, all fields are returned
  --start-index: string # Zero-based index of the starting row to read
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}/data"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: selectedFields, var: selected_fields}, {name: startIndex, var: start_index}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token, selected_fields: $selected_fields, start_index: $start_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Streams data into BigQuery one record at a time without needing to run a load job. Requires the WRITER dataset role.
#
# POST /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/insertAll
# Returns: record<insertErrors: table<errors: list, index: int>, kind: string>
# operationId: bigquery.tabledata.insertAll
export def "bigquery-tabledata-insert-all" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-unknown-values: oneof<nothing, bool> # [Optional] Accept rows that contain values that do not match the schema. The unknown values are ignored. Default is false, which treats unknown values as errors.
  --kind: string # The resource type of the response. (default: bigquery#tableDataInsertAllRequest)
  --rows: list # The rows to insert. — item shape: {insertId?: string, json?: record}
  --skip-invalid-rows: oneof<nothing, bool> # [Optional] Insert all valid rows of a request, even if invalid rows exist. The default value is false, which causes the entire request to fail if any invalid rows exist.
  --template-suffix: string # If specified, treats the destination table as a base template, and inserts the rows into an instance table named "{destination}{templateSuffix}". BigQuery will manage creation of the instance table, using the schema of the base template table. See https://cloud.google.com/bigquery/streaming-data-into-bigquery#template-tables for considerations when working with templates tables.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}/insertAll"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreUnknownValues, var: ignore_unknown_values}, {name: kind, var: kind}, {name: rows, var: rows}, {name: skipInvalidRows, var: skip_invalid_rows}, {name: templateSuffix, var: template_suffix}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, ignore_unknown_values: $ignore_unknown_values, kind: $kind, rows: $rows, skip_invalid_rows: $skip_invalid_rows, template_suffix: $template_suffix
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all row access policies on the specified table.
#
# GET /projects/{projectId}/datasets/{datasetId}/tables/{tableId}/rowAccessPolicies
# Returns: record<nextPageToken: string, rowAccessPolicies: table<creationTime: string, etag: string, filterPredicate: string, lastModifiedTime: string, rowAccessPolicyReference: record>>
# operationId: bigquery.rowAccessPolicies.list
export def "bigquery-row-access-policies-list" [
  project_id: string
  dataset_id: string
  table_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --page-size: int # The maximum number of results to return in a single response page. Leverage the page tokens to iterate through the entire collection.
  --page-token: string # Page token, returned by a previous call, to request the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/datasets/{datasetId}/tables/{tableId}/rowAccessPolicies"
    path_params: [{name: projectId, var: project_id}, {name: datasetId, var: dataset_id}, {name: tableId, var: table_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, dataset_id: $dataset_id, table_id: $table_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all jobs that you started in the specified project. Job information is available for a six month period after creation. The job list is sorted in reverse chronological order, by job creation time. Requires the Can View project role, or the Is Owner project role if you set the allUsers property.
#
# GET /projects/{projectId}/jobs
# Returns: record<etag: string, jobs: table<configuration: record, errorResult: record, id: string, jobReference: record, kind: string, state: string, statistics: record, status: record, user_email: string>, kind: string, nextPageToken: string>
# operationId: bigquery.jobs.list
export def "bigquery-jobs-list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --all-users: oneof<nothing, bool> # Whether to display jobs owned by all users in the project. Default false
  --max-creation-time: string # Max value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created before or at this timestamp are returned
  --max-results: int # Maximum number of results to return
  --min-creation-time: string # Min value for job creation time, in milliseconds since the POSIX epoch. If set, only jobs created after or at this timestamp are returned
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --parent-job-id: string # If set, retrieves only jobs whose parent is this job. Otherwise, retrieves only jobs which have no parent
  --projection: string@projection-completer # Restrict information returned to a set of selected fields
  --state-filter: list<string> # Filter for job state
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/jobs"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: allUsers, var: all_users}, {name: maxCreationTime, var: max_creation_time}, {name: maxResults, var: max_results}, {name: minCreationTime, var: min_creation_time}, {name: pageToken, var: page_token}, {name: parentJobId, var: parent_job_id}, {name: projection, var: projection}, {name: stateFilter, var: state_filter, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, all_users: $all_users, max_creation_time: $max_creation_time, max_results: $max_results, min_creation_time: $min_creation_time, page_token: $page_token, parent_job_id: $parent_job_id, projection: $projection, state_filter: $state_filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a new asynchronous job. Requires the Can View project role.
#
# POST /projects/{projectId}/jobs
# Returns: record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string>
# operationId: bigquery.jobs.insert
export def "bigquery-jobs-insert" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/jobs"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a specific job. Job information is available for a six month period after creation. Requires that you're the person who ran the job, or have the Is Owner project role.
#
# GET /projects/{projectId}/jobs/{jobId}
# Returns: record<configuration: record<copy: record<createDisposition: string, destinationEncryptionConfiguration: record, destinationExpirationTime: any, destinationTable: record, operationType: string, sourceTable: record, sourceTables: list, writeDisposition: string>, dryRun: bool, extract: record<compression: string, destinationFormat: string, destinationUri: string, destinationUris: list, fieldDelimiter: string, printHeader: bool, sourceModel: record, sourceTable: record, useAvroLogicalTypes: bool>, jobTimeoutMs: string, jobType: string, labels: record, load: record<allowJaggedRows: bool, allowQuotedNewlines: bool, autodetect: bool, clustering: record, connectionProperties: list, createDisposition: string, createSession: bool, decimalTargetTypes: list, destinationEncryptionConfiguration: record, destinationTable: record, destinationTableProperties: record, encoding: string, fieldDelimiter: string, hivePartitioningOptions: record, ignoreUnknownValues: bool, jsonExtension: string, maxBadRecords: int, nullMarker: string, parquetOptions: record, preserveAsciiControlCharacters: bool, projectionFields: list, quote: string, rangePartitioning: record, referenceFileSchemaUri: string, schema: record, schemaInline: string, schemaInlineFormat: string, schemaUpdateOptions: list, skipLeadingRows: int, sourceFormat: string, sourceUris: list, timePartitioning: record, useAvroLogicalTypes: bool, writeDisposition: string>, query: record<allowLargeResults: bool, clustering: record, connectionProperties: list, continuous: bool, createDisposition: string, createSession: bool, defaultDataset: record, destinationEncryptionConfiguration: record, destinationTable: record, flattenResults: bool, maximumBillingTier: int, maximumBytesBilled: string, parameterMode: string, preserveNulls: bool, priority: string, query: string, queryParameters: list, rangePartitioning: record, schemaUpdateOptions: list, tableDefinitions: record, timePartitioning: record, useLegacySql: bool, useQueryCache: bool, userDefinedFunctionResources: list, writeDisposition: string>>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record<copied_logical_bytes: string, copied_rows: string>, creationTime: string, dataMaskingStatistics: record<dataMaskingApplied: bool>, endTime: string, extract: record<destinationUriFileCounts: list, inputBytes: string>, load: record<badRecords: string, inputFileBytes: string, inputFiles: string, outputBytes: string, outputRows: string>, numChildJobs: string, parentJobId: string, query: record<biEngineStatistics: record, billingTier: int, cacheHit: bool, ddlAffectedRowAccessPolicyCount: string, ddlDestinationTable: record, ddlOperationPerformed: string, ddlTargetDataset: record, ddlTargetRoutine: record, ddlTargetRowAccessPolicy: record, ddlTargetTable: record, dmlStats: record, estimatedBytesProcessed: string, mlStatistics: record, modelTraining: record, modelTrainingCurrentIteration: int, modelTrainingExpectedTotalIteration: string, numDmlAffectedRows: string, queryPlan: list, referencedRoutines: list, referencedTables: list, reservationUsage: list, schema: record, searchStatistics: record, sparkStatistics: record, statementType: string, timeline: list, totalBytesBilled: string, totalBytesProcessed: string, totalBytesProcessedAccuracy: string, totalPartitionsProcessed: string, totalSlotMs: string, transferredBytes: string, undeclaredQueryParameters: list>, quotaDeferments: list<string>, reservationUsage: list<record>, reservation_id: string, rowLevelSecurityStatistics: record<rowLevelSecurityApplied: bool>, scriptStatistics: record<evaluationKind: string, stackFrames: list>, sessionInfo: record<sessionId: string>, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record<transactionId: string>>, status: record<errorResult: record<debugInfo: string, location: string, message: string, reason: string>, errors: list<record>, state: string>, user_email: string>
# operationId: bigquery.jobs.get
export def "bigquery-jobs-get" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/jobs/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: location, var: location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests that a job be cancelled. This call will return immediately, and the client will need to poll for the job status to see if the cancel completed successfully. Cancelled jobs may still incur costs.
#
# POST /projects/{projectId}/jobs/{jobId}/cancel
# Returns: record<job: record<configuration: record<copy: record, dryRun: bool, extract: record, jobTimeoutMs: string, jobType: string, labels: record, load: record, query: record>, etag: string, id: string, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, selfLink: string, statistics: record<completionRatio: float, copy: record, creationTime: string, dataMaskingStatistics: record, endTime: string, extract: record, load: record, numChildJobs: string, parentJobId: string, query: record, quotaDeferments: list, reservationUsage: list, reservation_id: string, rowLevelSecurityStatistics: record, scriptStatistics: record, sessionInfo: record, startTime: string, totalBytesProcessed: string, totalSlotMs: string, transactionInfo: record>, status: record<errorResult: record, errors: list, state: string>, user_email: string>, kind: string>
# operationId: bigquery.jobs.cancel
export def "bigquery-jobs-cancel" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/projects/{projectId}/jobs/{jobId}/cancel"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: location, var: location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests the deletion of the metadata of a job. This call returns when the job's metadata is deleted.
#
# DELETE /projects/{projectId}/jobs/{jobId}/delete
# operationId: bigquery.jobs.delete
export def "bigquery-jobs-delete" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location of the job. Required. See details at: https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
]: nothing -> any {
  http-request {
    method: delete
    path: "/projects/{projectId}/jobs/{jobId}/delete"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: location, var: location}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs a BigQuery SQL query synchronously and returns query results if the query completes within a specified timeout.
#
# POST /projects/{projectId}/queries
# Returns: record<cacheHit: bool, dmlStats: record<deletedRowCount: string, insertedRowCount: string, updatedRowCount: string>, errors: table<debugInfo: string, location: string, message: string, reason: string>, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, sessionInfo: record<sessionId: string>, totalBytesProcessed: string, totalRows: string>
# operationId: bigquery.jobs.query
export def "bigquery-jobs-query" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --connection-properties: list # Connection properties. — item shape: {key?: string, value?: string}
  --continuous: oneof<nothing, bool> # [Optional] Specifies whether the query should be executed as a continuous query. The default value is false.
  --create-session: oneof<nothing, bool> # If true, creates a new session, where session id will be a server generated random id. If false, runs query with an existing session_id passed in ConnectionProperty, otherwise runs query in non-session mode.
  --default-dataset: record # shape: {datasetId?: string, projectId?: string}
  --body-dry-run: oneof<nothing, bool> # [Optional] If set to true, BigQuery doesn't run the job. Instead, if the query is valid, BigQuery returns statistics about the job such as how many bytes would be processed. If the query is invalid, an error returns. The default value is false. (spec name: dryRun)
  --kind: string # The resource type of the request. (default: bigquery#queryRequest)
  --labels: record # The labels associated with this job. You can use these to organize and group your jobs. Label keys and values can be no longer than 63 characters, can only contain lowercase letters, numeric characters, underscores and dashes. International characters are allowed. Label values are optional. Label keys must start with a letter and each label in the list must have a different key.
  --location: string # The geographic location where the job should run. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --max-results: int # [Optional] The maximum number of rows of data to return per page of results. Setting this flag to a small value such as 1000 and then paging through results might improve reliability when the query result set is large. In addition to this limit, responses are also limited to 10 MB. By default, there is no maximum row count, and only the byte limit applies. (format: uint32)
  --maximum-bytes-billed: string # [Optional] Limits the bytes billed for this job. Queries that will have bytes billed beyond this limit will fail (without incurring a charge). If unspecified, this will be set to your project default. (format: int64)
  --parameter-mode: string # Standard SQL only. Set to POSITIONAL to use positional (?) query parameters or to NAMED to use named (@myparam) query parameters in this query.
  --preserve-nulls: oneof<nothing, bool> # [Deprecated] This property is deprecated.
  --query: string # [Required] A query string, following the BigQuery query syntax, of the query to execute. Example: "SELECT count(f1) FROM [myProjectId:myDatasetId.myTableId]".
  --query-parameters: list # Query parameters for Standard SQL queries. — item shape: {name?: string, parameterType?: record, parameterValue?: record}
  --request-id: string # A unique user provided identifier to ensure idempotent behavior for queries. Note that this is different from the job_id. It has the following properties: 1. It is case-sensitive, limited to up to 36 ASCII characters. A UUID is recommended. 2. Read only queries can ignore this token since they are nullipotent by definition. 3. For the purposes of idempotency ensured by the request_id, a request is considered duplicate of another only if they have the same request_id and are actually duplicates. When determining whether a request is a duplicate of the previous request, all parameters in the request that may affect the behavior are considered. For example, query, connection_properties, query_parameters, use_legacy_sql are parameters that affect the result and are considered when determining whether a request is a duplicate, but properties like timeout_ms don't affect the result and are thus not considered. Dry run query requests are never considered duplicate of another request. 4. When a duplicate mutating query request is detected, it returns: a. the results of the mutation if it completes successfully within the timeout. b. the running operation if it is still in progress at the end of the timeout. 5. Its lifetime is limited to 15 minutes. In other words, if two requests are sent with the same request_id, but more than 15 minutes apart, idempotency is not guaranteed.
  --timeout-ms: int # [Optional] How long to wait for the query to complete, in milliseconds, before the request times out and returns. Note that this is only a timeout for the request, not the query. If the query takes longer to run than the timeout value, the call returns without any results and with the 'jobComplete' flag set to false. You can call GetQueryResults() to wait for the query to complete and read the results. The default value is 10000 milliseconds (10 seconds). (format: uint32)
  --use-legacy-sql: oneof<nothing, bool> # Specifies whether to use BigQuery's legacy SQL dialect for this query. The default value is true. If set to false, the query will use BigQuery's standard SQL: https://cloud.google.com/bigquery/sql-reference/ When useLegacySql is set to false, the value of flattenResults is ignored; query will be run as if flattenResults is false. (default: true)
  --use-query-cache: oneof<nothing, bool> # [Optional] Whether to look for the result in the query cache. The query cache is a best-effort cache that will be flushed whenever tables in the query are modified. The default value is true. (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{projectId}/queries"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionProperties, var: connection_properties}, {name: continuous, var: continuous}, {name: createSession, var: create_session}, {name: defaultDataset, var: default_dataset}, {name: dryRun, var: body_dry_run}, {name: kind, var: kind}, {name: labels, var: labels}, {name: location, var: location}, {name: maxResults, var: max_results}, {name: maximumBytesBilled, var: maximum_bytes_billed}, {name: parameterMode, var: parameter_mode}, {name: preserveNulls, var: preserve_nulls}, {name: query, var: query}, {name: queryParameters, var: query_parameters}, {name: requestId, var: request_id}, {name: timeoutMs, var: timeout_ms}, {name: useLegacySql, var: use_legacy_sql}, {name: useQueryCache, var: use_query_cache}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, connection_properties: $connection_properties, continuous: $continuous, create_session: $create_session, default_dataset: $default_dataset, body_dry_run: $body_dry_run, kind: $kind, labels: $labels, location: $location, max_results: $max_results, maximum_bytes_billed: $maximum_bytes_billed, parameter_mode: $parameter_mode, preserve_nulls: $preserve_nulls, query: $query, query_parameters: $query_parameters, request_id: $request_id, timeout_ms: $timeout_ms, use_legacy_sql: $use_legacy_sql, use_query_cache: $use_query_cache
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the results of a query job.
#
# GET /projects/{projectId}/queries/{jobId}
# Returns: record<cacheHit: bool, errors: table<debugInfo: string, location: string, message: string, reason: string>, etag: string, jobComplete: bool, jobReference: record<jobId: string, location: string, projectId: string>, kind: string, numDmlAffectedRows: string, pageToken: string, rows: table<f: list>, schema: record<fields: list<record>>, totalBytesProcessed: string, totalRows: string>
# operationId: bigquery.jobs.getQueryResults
export def "bigquery-jobs-get-query-results" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --location: string # The geographic location where the job should run. Required except for US and EU. See details at https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  --max-results: int # Maximum number of results to read
  --page-token: string # Page token, returned by a previous call, to request the next page of results
  --start-index: string # Zero-based index of the starting row
  --timeout-ms: int # How long to wait for the query to complete, in milliseconds, before returning. Default is 10 seconds. If the timeout passes before the job completes, the 'jobComplete' field in the response will be false
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/queries/{jobId}"
    path_params: [{name: projectId, var: project_id}, {name: jobId, var: job_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: location, var: location}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: startIndex, var: start_index}, {name: timeoutMs, var: timeout_ms}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, job_id: $job_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, location: $location, max_results: $max_results, page_token: $page_token, start_index: $start_index, timeout_ms: $timeout_ms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the email address of the service account for your project used for interactions with Google Cloud KMS.
#
# GET /projects/{projectId}/serviceAccount
# Returns: record<email: string, kind: string>
# operationId: bigquery.projects.getServiceAccount
export def "bigquery-projects-get-service-account" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{projectId}/serviceAccount"
    path_params: [{name: projectId, var: project_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# POST /{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: bigquery.tables.getIamPolicy
export def "bigquery-tables-get-iam-policy" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --options: record # Encapsulates settings provided to GetIamPolicy. — shape: {requestedPolicyVersion?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{resource}:getIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`, and `PERMISSION_DENIED` errors.
#
# POST /{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: bigquery.tables.setIamPolicy
export def "bigquery-tables-set-iam-policy" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{resource}:setIamPolicy"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: policy, var: policy}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, policy: $policy, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a `NOT_FOUND` error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: bigquery.tables.testIamPermissions
export def "bigquery-tables-test-iam-permissions" [
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
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/{resource}:testIamPermissions"
    path_params: [{name: resource, var: resource}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: permissions, var: permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, permissions: $permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
