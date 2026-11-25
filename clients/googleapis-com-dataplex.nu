# Auto-generated client for Cloud Dataplex API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/dataplex/v1/openapi.json
# Auth: --token flag or $env.CLOUD_DATAPLEX_API_TOKEN

const CLIENT = {
  base_url: "https://dataplex.googleapis.com"
  token_env_var: "CLOUD_DATAPLEX_API_TOKEN"
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

def base-url-completer [] { ["https://dataplex.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def view-completer [] { ["BASIC" "ENTITY_VIEW_UNSPECIFIED" "FULL" "SCHEMA"] }
def system-completer [] { ["BIGQUERY" "CLOUD_STORAGE" "STORAGE_SYSTEM_UNSPECIFIED"] }
def type-completer [] { ["FILESET" "TABLE" "TYPE_UNSPECIFIED"] }
def view-completer-1 [] { ["ENTITY_VIEW_UNSPECIFIED" "FILESETS" "TABLES"] }
def type-completer-1 [] { ["CURATED" "RAW" "TYPE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    dataplex-projects-locations-operations-delete: "record"
    dataplex-projects-locations-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-assets-patch: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-entities-update: "record<access: record<read: string>, asset: string, catalogEntry: string, compatibility: record<bigquery: record<compatible: bool, reason: string>, hiveMetastore: record<compatible: bool, reason: string>>, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record<compressionFormat: string, csv: record<delimiter: string, encoding: string, headerRows: int, quote: string>, format: string, iceberg: record<metadataLocation: string>, json: record<encoding: string>, mimeType: string>, id: string, name: string, schema: record<fields: list<record>, partitionFields: list<record>, partitionStyle: string, userManaged: bool>, system: string, type: string, uid: string, updateTime: string>"
    dataplex-projects-locations-list: "record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>"
    dataplex-projects-locations-operations-list: "record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>"
    dataplex-projects-locations-operations-cancel: "record"
    dataplex-projects-locations-lakes-tasks-run: "record<job: record<endTime: string, message: string, name: string, retryCount: int, service: string, serviceJob: string, startTime: string, state: string, uid: string>>"
    dataplex-projects-locations-lakes-zones-assets-actions-list: "record<actions: table<asset: string, category: string, dataLocations: list, detectTime: string, failedSecurityPolicyApply: record, incompatibleDataSchema: record, invalidDataFormat: record, invalidDataOrganization: record, invalidDataPartition: record, issue: string, lake: string, missingData: record, missingResource: record, name: string, unauthorizedResource: record, zone: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-zones-assets-list: "record<assets: table<createTime: string, description: string, discoverySpec: record, discoveryStatus: record, displayName: string, labels: record, name: string, resourceSpec: record, resourceStatus: record, securityStatus: record, state: string, uid: string, updateTime: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-zones-assets-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-data-taxonomies-attributes-list: "record<dataAttributes: table<attributeCount: int, createTime: string, dataAccessSpec: record, description: string, displayName: string, etag: string, labels: record, name: string, parentId: string, resourceAccessSpec: record, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>"
    dataplex-projects-locations-data-taxonomies-attributes-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-content-list: "record<content: table<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record, path: string, sqlScript: record, uid: string, updateTime: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-content-create: "record<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record<kernelType: string>, path: string, sqlScript: record<engine: string>, uid: string, updateTime: string>"
    dataplex-projects-locations-lakes-contentitems-list: "record<content: table<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record, path: string, sqlScript: record, uid: string, updateTime: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-contentitems-create: "record<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record<kernelType: string>, path: string, sqlScript: record<engine: string>, uid: string, updateTime: string>"
    dataplex-projects-locations-data-attribute-bindings-list: "record<dataAttributeBindings: table<attributes: list, createTime: string, description: string, displayName: string, etag: string, labels: record, name: string, paths: list, resource: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>"
    dataplex-projects-locations-data-attribute-bindings-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-data-scans-list: "record<dataScans: table<createTime: string, data: record, dataProfileResult: record, dataProfileSpec: record, dataQualityResult: record, dataQualitySpec: record, description: string, displayName: string, executionSpec: record, executionStatus: record, labels: record, name: string, state: string, type: string, uid: string, updateTime: string>, nextPageToken: string, unreachable: list<string>>"
    dataplex-projects-locations-data-scans-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-data-taxonomies-list: "record<dataTaxonomies: table<attributeCount: int, createTime: string, description: string, displayName: string, etag: string, labels: record, name: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>"
    dataplex-projects-locations-data-taxonomies-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-entities-list: "record<entities: table<access: record, asset: string, catalogEntry: string, compatibility: record, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record, id: string, name: string, schema: record, system: string, type: string, uid: string, updateTime: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-zones-entities-create: "record<access: record<read: string>, asset: string, catalogEntry: string, compatibility: record<bigquery: record<compatible: bool, reason: string>, hiveMetastore: record<compatible: bool, reason: string>>, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record<compressionFormat: string, csv: record<delimiter: string, encoding: string, headerRows: int, quote: string>, format: string, iceberg: record<metadataLocation: string>, json: record<encoding: string>, mimeType: string>, id: string, name: string, schema: record<fields: list<record>, partitionFields: list<record>, partitionStyle: string, userManaged: bool>, system: string, type: string, uid: string, updateTime: string>"
    dataplex-projects-locations-lakes-environments-list: "record<environments: table<createTime: string, description: string, displayName: string, endpoints: record, infrastructureSpec: record, labels: record, name: string, sessionSpec: record, sessionStatus: record, state: string, uid: string, updateTime: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-environments-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-tasks-jobs-list: "record<jobs: table<endTime: string, message: string, name: string, retryCount: int, service: string, serviceJob: string, startTime: string, state: string, uid: string>, nextPageToken: string>"
    dataplex-projects-locations-lakes-list: "record<lakes: table<assetStatus: record, createTime: string, description: string, displayName: string, labels: record, metastore: record, metastoreStatus: record, name: string, serviceAccount: string, state: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>"
    dataplex-projects-locations-lakes-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-entities-partitions-list: "record<nextPageToken: string, partitions: table<etag: string, location: string, name: string, values: list>>"
    dataplex-projects-locations-lakes-zones-entities-partitions-create: "record<etag: string, location: string, name: string, values: list<string>>"
    dataplex-projects-locations-lakes-environments-sessions-list: "record<nextPageToken: string, sessions: table<createTime: string, name: string, state: string, userId: string>>"
    dataplex-projects-locations-lakes-tasks-list: "record<nextPageToken: string, tasks: table<createTime: string, description: string, displayName: string, executionSpec: record, executionStatus: record, labels: record, name: string, notebook: record, spark: record, state: string, triggerSpec: record, uid: string, updateTime: string>, unreachableLocations: list<string>>"
    dataplex-projects-locations-lakes-tasks-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-list: "record<nextPageToken: string, zones: table<assetStatus: record, createTime: string, description: string, discoverySpec: record, displayName: string, labels: record, name: string, resourceSpec: record, state: string, type: string, uid: string, updateTime: string>>"
    dataplex-projects-locations-lakes-zones-create: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    dataplex-projects-locations-lakes-zones-assets-get-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dataplex-projects-locations-lakes-zones-assets-set-iam-policy: "record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>"
    dataplex-projects-locations-lakes-zones-assets-test-iam-permissions: "record<permissions: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["dataplex-projects-locations-operations-delete" "dataplex-projects-locations-operations-get" "dataplex-projects-locations-lakes-zones-assets-patch" "dataplex-projects-locations-lakes-zones-entities-update" "dataplex-projects-locations-list" "dataplex-projects-locations-operations-list" "dataplex-projects-locations-operations-cancel" "dataplex-projects-locations-lakes-tasks-run" "dataplex-projects-locations-lakes-zones-assets-actions-list" "dataplex-projects-locations-lakes-zones-assets-list" "dataplex-projects-locations-lakes-zones-assets-create" "dataplex-projects-locations-data-taxonomies-attributes-list" "dataplex-projects-locations-data-taxonomies-attributes-create" "dataplex-projects-locations-lakes-content-list" "dataplex-projects-locations-lakes-content-create" "dataplex-projects-locations-lakes-contentitems-list" "dataplex-projects-locations-lakes-contentitems-create" "dataplex-projects-locations-data-attribute-bindings-list" "dataplex-projects-locations-data-attribute-bindings-create" "dataplex-projects-locations-data-scans-list" "dataplex-projects-locations-data-scans-create" "dataplex-projects-locations-data-taxonomies-list" "dataplex-projects-locations-data-taxonomies-create" "dataplex-projects-locations-lakes-zones-entities-list" "dataplex-projects-locations-lakes-zones-entities-create" "dataplex-projects-locations-lakes-environments-list" "dataplex-projects-locations-lakes-environments-create" "dataplex-projects-locations-lakes-tasks-jobs-list" "dataplex-projects-locations-lakes-list" "dataplex-projects-locations-lakes-create" "dataplex-projects-locations-lakes-zones-entities-partitions-list" "dataplex-projects-locations-lakes-zones-entities-partitions-create" "dataplex-projects-locations-lakes-environments-sessions-list" "dataplex-projects-locations-lakes-tasks-list" "dataplex-projects-locations-lakes-tasks-create" "dataplex-projects-locations-lakes-zones-list" "dataplex-projects-locations-lakes-zones-create" "dataplex-projects-locations-lakes-zones-assets-get-iam-policy" "dataplex-projects-locations-lakes-zones-assets-set-iam-policy" "dataplex-projects-locations-lakes-zones-assets-test-iam-permissions" "commands"] | sort) } | get name | first)
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

# Deletes a long-running operation. This method indicates that the client is no longer interested in the operation result. It does not cancel the operation. If the server doesn't support this method, it returns google.rpc.Code.UNIMPLEMENTED.
#
# DELETE /v1/{name}
# Returns: record
# operationId: dataplex.projects.locations.operations.delete
export def "dataplex-projects-locations-operations-delete" [
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
  --etag: string # Optional. The etag associated with the partition.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: etag, var: etag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.operations.get
export def "dataplex-projects-locations-operations-get" [
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
  --view: string@view-completer # Optional. Used to select the subset of entity information to return. Defaults to BASIC.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an asset resource.
#
# PATCH /v1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.zones.assets.patch
export def "dataplex-projects-locations-lakes-zones-assets-patch" [
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
  --update-mask: string # Required. Mask of fields to update.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --description: string # Optional. Description of the asset.
  --discovery-spec: record # Settings to manage the metadata discovery and publishing for an asset. — shape: {csvOptions?: record, enabled?: bool, excludePatterns?: list<string>, includePatterns?: list<string>, jsonOptions?: record, schedule?: string}
  --discovery-status: record # Status of discovery for an asset. — shape: {lastRunDuration?: string, lastRunTime?: string, message?: string, state?: "STATE_UNSPECIFIED"|"SCHEDULED"|"IN_PROGRESS"|"PAUSED"|"DISABLED", stats?: record, updateTime?: string}
  --display-name: string # Optional. User friendly display name.
  --labels: record # Optional. User defined labels for the asset.
  --resource-spec: record # Identifies the cloud resource that is referenced by this asset. — shape: {name?: string, readAccessMode?: "ACCESS_MODE_UNSPECIFIED"|"DIRECT"|"MANAGED", type?: "TYPE_UNSPECIFIED"|"STORAGE_BUCKET"|"BIGQUERY_DATASET"}
  --resource-status: record # Status of the resource referenced by an asset. — shape: {message?: string, state?: "STATE_UNSPECIFIED"|"READY"|"ERROR", updateTime?: string}
  --security-status: record # Security policy status of the asset. Data security policy, i.e., readers, writers & owners, should be specified in the lake/zone/asset IAM policy. — shape: {message?: string, state?: "STATE_UNSPECIFIED"|"READY"|"APPLYING"|"ERROR", updateTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: discoverySpec, var: discovery_spec}, {name: discoveryStatus, var: discovery_status}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: resourceSpec, var: resource_spec}, {name: resourceStatus, var: resource_status}, {name: securityStatus, var: security_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, validate_only: $validate_only, description: $description, discovery_spec: $discovery_spec, discovery_status: $discovery_status, display_name: $display_name, labels: $labels, resource_spec: $resource_spec, resource_status: $resource_status, security_status: $security_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a metadata entity. Only supports full resource update.
#
# PUT /v1/{name}
# Returns: record<access: record<read: string>, asset: string, catalogEntry: string, compatibility: record<bigquery: record<compatible: bool, reason: string>, hiveMetastore: record<compatible: bool, reason: string>>, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record<compressionFormat: string, csv: record<delimiter: string, encoding: string, headerRows: int, quote: string>, format: string, iceberg: record<metadataLocation: string>, json: record<encoding: string>, mimeType: string>, id: string, name: string, schema: record<fields: list<record>, partitionFields: list<record>, partitionStyle: string, userManaged: bool>, system: string, type: string, uid: string, updateTime: string>
# operationId: dataplex.projects.locations.lakes.zones.entities.update
export def "dataplex-projects-locations-lakes-zones-entities-update" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --access: record # Describes the access mechanism of the data within its storage location.
  --asset: string # Required. Immutable. The ID of the asset associated with the storage location containing the entity data. The entity must be with in the same zone with the asset.
  --compatibility: record # Provides compatibility information for various metadata stores. — shape: {bigquery?: record, hiveMetastore?: record}
  --data-path: string # Required. Immutable. The storage path of the entity data. For Cloud Storage data, this is the fully-qualified path to the entity, such as gs://bucket/path/to/data. For BigQuery data, this is the name of the table resource, such as projects/project_id/datasets/dataset_id/tables/table_id.
  --data-path-pattern: string # Optional. The set of items within the data path constituting the data in the entity, represented as a glob path. Example: gs://bucket/path/to/data/**/*.csv.
  --description: string # Optional. User friendly longer description text. Must be shorter than or equal to 1024 characters.
  --display-name: string # Optional. Display name must be shorter than or equal to 256 characters.
  --etag: string # Optional. The etag associated with the entity, which can be retrieved with a GetEntity request. Required for update and delete requests.
  --format: record # Describes the format of the data within its storage location. — shape: {compressionFormat?: "COMPRESSION_FORMAT_UNSPECIFIED"|"GZIP"|"BZIP2", csv?: record, iceberg?: record, json?: record, mimeType?: string}
  --id: string # Required. A user-provided entity ID. It is mutable, and will be used as the published table name. Specifying a new ID in an update entity request will override the existing value. The ID must contain only letters (a-z, A-Z), numbers (0-9), and underscores, and consist of 256 or fewer characters.
  --schema: record # Schema information describing the structure and layout of the data. — shape: {fields?: list, partitionFields?: list, partitionStyle?: "PARTITION_STYLE_UNSPECIFIED"|"HIVE_COMPATIBLE", userManaged?: bool}
  --system: string@system-completer # Required. Immutable. Identifies the storage system of the entity data.
  --type: string@type-completer # Required. Immutable. The type of entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: asset, var: asset}, {name: compatibility, var: compatibility}, {name: dataPath, var: data_path}, {name: dataPathPattern, var: data_path_pattern}, {name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: format, var: format}, {name: id, var: id}, {name: schema, var: schema}, {name: system, var: system}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, access: $access, asset: $asset, compatibility: $compatibility, data_path: $data_path, data_path_pattern: $data_path_pattern, description: $description, display_name: $display_name, etag: $etag, format: $format, id: $id, schema: $schema, system: $system, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists information about the supported locations for this service.
#
# GET /v1/{name}/locations
# Returns: record<locations: table<displayName: string, labels: record, locationId: string, metadata: record, name: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.list
export def "dataplex-projects-locations-list" [
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
  --filter: string # A filter to narrow down results to a preferred subset. The filtering language accepts strings like "displayName=tokyo", and is documented in more detail in AIP-160 (https://google.aip.dev/160).
  --page-size: int # The maximum number of results to return. If not set, the service selects a default.
  --page-token: string # A page token received from the next_page_token field in the response. Send that page token to receive the subsequent page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{name}/locations"
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

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns UNIMPLEMENTED.
#
# GET /v1/{name}/operations
# Returns: record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>>
# operationId: dataplex.projects.locations.operations.list
export def "dataplex-projects-locations-operations-list" [
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

# Starts asynchronous cancellation on a long-running operation. The server makes a best effort to cancel the operation, but success is not guaranteed. If the server doesn't support this method, it returns google.rpc.Code.UNIMPLEMENTED. Clients can use Operations.GetOperation or other methods to check whether the cancellation succeeded or whether the operation completed despite cancellation. On successful cancellation, the operation is not deleted; instead, it becomes an operation with an Operation.error value with a google.rpc.Status.code of 1, corresponding to Code.CANCELLED.
#
# POST /v1/{name}:cancel
# Returns: record
# operationId: dataplex.projects.locations.operations.cancel
export def "dataplex-projects-locations-operations-cancel" [
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
    path: "/v1/{name}:cancel"
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

# Run an on demand execution of a Task.
#
# POST /v1/{name}:run
# Returns: record<job: record<endTime: string, message: string, name: string, retryCount: int, service: string, serviceJob: string, startTime: string, state: string, uid: string>>
# operationId: dataplex.projects.locations.lakes.tasks.run
export def "dataplex-projects-locations-lakes-tasks-run" [
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
    path: "/v1/{name}:run"
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

# Lists action resources in an asset.
#
# GET /v1/{parent}/actions
# Returns: record<actions: table<asset: string, category: string, dataLocations: list, detectTime: string, failedSecurityPolicyApply: record, incompatibleDataSchema: record, invalidDataFormat: record, invalidDataOrganization: record, invalidDataPartition: record, issue: string, lake: string, missingData: record, missingResource: record, name: string, unauthorizedResource: record, zone: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.zones.assets.actions.list
export def "dataplex-projects-locations-lakes-zones-assets-actions-list" [
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
  --page-size: int # Optional. Maximum number of actions to return. The service may return fewer than this value. If unspecified, at most 10 actions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListAssetActions call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListAssetActions must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/actions"
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

# Lists asset resources in a zone.
#
# GET /v1/{parent}/assets
# Returns: record<assets: table<createTime: string, description: string, discoverySpec: record, discoveryStatus: record, displayName: string, labels: record, name: string, resourceSpec: record, resourceStatus: record, securityStatus: record, state: string, uid: string, updateTime: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.zones.assets.list
export def "dataplex-projects-locations-lakes-zones-assets-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of asset to return. The service may return fewer than this value. If unspecified, at most 10 assets will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListAssets call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListAssets must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/assets"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an asset resource.
#
# POST /v1/{parent}/assets
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.zones.assets.create
export def "dataplex-projects-locations-lakes-zones-assets-create" [
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
  --asset-id: string # Required. Asset identifier. This ID will be used to generate names such as table names when publishing metadata to Hive Metastore and BigQuery. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must end with a number or a letter. * Must be between 1-63 characters. * Must be unique within the zone.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --description: string # Optional. Description of the asset.
  --discovery-spec: record # Settings to manage the metadata discovery and publishing for an asset. — shape: {csvOptions?: record, enabled?: bool, excludePatterns?: list<string>, includePatterns?: list<string>, jsonOptions?: record, schedule?: string}
  --discovery-status: record # Status of discovery for an asset. — shape: {lastRunDuration?: string, lastRunTime?: string, message?: string, state?: "STATE_UNSPECIFIED"|"SCHEDULED"|"IN_PROGRESS"|"PAUSED"|"DISABLED", stats?: record, updateTime?: string}
  --display-name: string # Optional. User friendly display name.
  --labels: record # Optional. User defined labels for the asset.
  --resource-spec: record # Identifies the cloud resource that is referenced by this asset. — shape: {name?: string, readAccessMode?: "ACCESS_MODE_UNSPECIFIED"|"DIRECT"|"MANAGED", type?: "TYPE_UNSPECIFIED"|"STORAGE_BUCKET"|"BIGQUERY_DATASET"}
  --resource-status: record # Status of the resource referenced by an asset. — shape: {message?: string, state?: "STATE_UNSPECIFIED"|"READY"|"ERROR", updateTime?: string}
  --security-status: record # Security policy status of the asset. Data security policy, i.e., readers, writers & owners, should be specified in the lake/zone/asset IAM policy. — shape: {message?: string, state?: "STATE_UNSPECIFIED"|"READY"|"APPLYING"|"ERROR", updateTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/assets"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: assetId, var: asset_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: discoverySpec, var: discovery_spec}, {name: discoveryStatus, var: discovery_status}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: resourceSpec, var: resource_spec}, {name: resourceStatus, var: resource_status}, {name: securityStatus, var: security_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, asset_id: $asset_id, validate_only: $validate_only, description: $description, discovery_spec: $discovery_spec, discovery_status: $discovery_status, display_name: $display_name, labels: $labels, resource_spec: $resource_spec, resource_status: $resource_status, security_status: $security_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Data Attribute resources in a DataTaxonomy.
#
# GET /v1/{parent}/attributes
# Returns: record<dataAttributes: table<attributeCount: int, createTime: string, dataAccessSpec: record, description: string, displayName: string, etag: string, labels: record, name: string, parentId: string, resourceAccessSpec: record, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>
# operationId: dataplex.projects.locations.dataTaxonomies.attributes.list
export def "dataplex-projects-locations-data-taxonomies-attributes-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of DataAttributes to return. The service may return fewer than this value. If unspecified, at most 10 dataAttributes will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListDataAttributes call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDataAttributes must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/attributes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a DataAttribute resource.
#
# POST /v1/{parent}/attributes
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.dataTaxonomies.attributes.create
export def "dataplex-projects-locations-data-taxonomies-attributes-create" [
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
  --data-attribute-id: string # Required. DataAttribute identifier. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the DataTaxonomy.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --data-access-spec: record # DataAccessSpec holds the access control configuration to be enforced on data stored within resources (eg: rows, columns in BigQuery Tables). When associated with data, the data is only accessible to principals explicitly granted access through the DataAccessSpec. Principals with access to the containing resource are not implicitly granted access. — shape: {readers?: list<string>}
  --description: string # Optional. Description of the DataAttribute.
  --display-name: string # Optional. User friendly display name.
  --etag: string # This checksum is computed by the server based on the value of other fields, and may be sent on update and delete requests to ensure the client has an up-to-date value before proceeding.
  --labels: record # Optional. User-defined labels for the DataAttribute.
  --parent-id: string # Optional. The ID of the parent DataAttribute resource, should belong to the same data taxonomy. Circular dependency in parent chain is not valid. Maximum depth of the hierarchy allowed is 4. a -> b -> c -> d -> e, depth = 4
  --resource-access-spec: record # ResourceAccessSpec holds the access control configuration to be enforced on the resources, for example, Cloud Storage bucket, BigQuery dataset, BigQuery table. — shape: {owners?: list<string>, readers?: list<string>, writers?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/attributes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataAttributeId, var: data_attribute_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataAccessSpec, var: data_access_spec}, {name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: labels, var: labels}, {name: parentId, var: parent_id}, {name: resourceAccessSpec, var: resource_access_spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_attribute_id: $data_attribute_id, validate_only: $validate_only, data_access_spec: $data_access_spec, description: $description, display_name: $display_name, etag: $etag, labels: $labels, parent_id: $parent_id, resource_access_spec: $resource_access_spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List content.
#
# GET /v1/{parent}/content
# Returns: record<content: table<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record, path: string, sqlScript: record, uid: string, updateTime: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.content.list
export def "dataplex-projects-locations-lakes-content-list" [
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
  --filter: string # Optional. Filter request. Filters are case-sensitive. The following formats are supported:labels.key1 = "value1" labels:key1 type = "NOTEBOOK" type = "SQL_SCRIPT"These restrictions can be coinjoined with AND, OR and NOT conjunctions.
  --page-size: int # Optional. Maximum number of content to return. The service may return fewer than this value. If unspecified, at most 10 content will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListContent call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListContent must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/content"
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

# Create a content.
#
# POST /v1/{parent}/content
# Returns: record<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record<kernelType: string>, path: string, sqlScript: record<engine: string>, uid: string, updateTime: string>
# operationId: dataplex.projects.locations.lakes.content.create
export def "dataplex-projects-locations-lakes-content-create" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --data-text: string # Required. Content data in string format.
  --description: string # Optional. Description of the content.
  --labels: record # Optional. User defined labels for the content.
  --notebook: record # Configuration for Notebook content. — shape: {kernelType?: "KERNEL_TYPE_UNSPECIFIED"|"PYTHON3"}
  --path: string # Required. The path for the Content file, represented as directory structure. Unique within a lake. Limited to alphanumerics, hyphens, underscores, dots and slashes.
  --sql-script: record # Configuration for the Sql Script content. — shape: {engine?: "QUERY_ENGINE_UNSPECIFIED"|"SPARK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/content"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataText, var: data_text}, {name: description, var: description}, {name: labels, var: labels}, {name: notebook, var: notebook}, {name: path, var: path}, {name: sqlScript, var: sql_script}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, data_text: $data_text, description: $description, labels: $labels, notebook: $notebook, path: $path, sql_script: $sql_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List content.
#
# GET /v1/{parent}/contentitems
# Returns: record<content: table<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record, path: string, sqlScript: record, uid: string, updateTime: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.contentitems.list
export def "dataplex-projects-locations-lakes-contentitems-list" [
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
  --filter: string # Optional. Filter request. Filters are case-sensitive. The following formats are supported:labels.key1 = "value1" labels:key1 type = "NOTEBOOK" type = "SQL_SCRIPT"These restrictions can be coinjoined with AND, OR and NOT conjunctions.
  --page-size: int # Optional. Maximum number of content to return. The service may return fewer than this value. If unspecified, at most 10 content will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListContent call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListContent must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/contentitems"
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

# Create a content.
#
# POST /v1/{parent}/contentitems
# Returns: record<createTime: string, dataText: string, description: string, labels: record, name: string, notebook: record<kernelType: string>, path: string, sqlScript: record<engine: string>, uid: string, updateTime: string>
# operationId: dataplex.projects.locations.lakes.contentitems.create
export def "dataplex-projects-locations-lakes-contentitems-create" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --data-text: string # Required. Content data in string format.
  --description: string # Optional. Description of the content.
  --labels: record # Optional. User defined labels for the content.
  --notebook: record # Configuration for Notebook content. — shape: {kernelType?: "KERNEL_TYPE_UNSPECIFIED"|"PYTHON3"}
  --path: string # Required. The path for the Content file, represented as directory structure. Unique within a lake. Limited to alphanumerics, hyphens, underscores, dots and slashes.
  --sql-script: record # Configuration for the Sql Script content. — shape: {engine?: "QUERY_ENGINE_UNSPECIFIED"|"SPARK"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/contentitems"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataText, var: data_text}, {name: description, var: description}, {name: labels, var: labels}, {name: notebook, var: notebook}, {name: path, var: path}, {name: sqlScript, var: sql_script}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, data_text: $data_text, description: $description, labels: $labels, notebook: $notebook, path: $path, sql_script: $sql_script
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists DataAttributeBinding resources in a project and location.
#
# GET /v1/{parent}/dataAttributeBindings
# Returns: record<dataAttributeBindings: table<attributes: list, createTime: string, description: string, displayName: string, etag: string, labels: record, name: string, paths: list, resource: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>
# operationId: dataplex.projects.locations.dataAttributeBindings.list
export def "dataplex-projects-locations-data-attribute-bindings-list" [
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
  --filter: string # Optional. Filter request. Filter using resource: filter=resource:"resource-name" Filter using attribute: filter=attributes:"attribute-name" Filter using attribute in paths list: filter=paths.attributes:"attribute-name"
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of DataAttributeBindings to return. The service may return fewer than this value. If unspecified, at most 10 DataAttributeBindings will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListDataAttributeBindings call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDataAttributeBindings must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/dataAttributeBindings"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a DataAttributeBinding resource.
#
# POST /v1/{parent}/dataAttributeBindings
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.dataAttributeBindings.create
export def "dataplex-projects-locations-data-attribute-bindings-create" [
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
  --data-attribute-binding-id: string # Required. DataAttributeBinding identifier. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the Location.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --attributes: list<string> # Optional. List of attributes to be associated with the resource, provided in the form: projects/{project}/locations/{location}/dataTaxonomies/{dataTaxonomy}/attributes/{data_attribute_id}
  --description: string # Optional. Description of the DataAttributeBinding.
  --display-name: string # Optional. User friendly display name.
  --etag: string # This checksum is computed by the server based on the value of other fields, and may be sent on update and delete requests to ensure the client has an up-to-date value before proceeding. Etags must be used when calling the DeleteDataAttributeBinding and the UpdateDataAttributeBinding method.
  --labels: record # Optional. User-defined labels for the DataAttributeBinding.
  --paths: list # Optional. The list of paths for items within the associated resource (eg. columns and partitions within a table) along with attribute bindings. — item shape: {attributes?: list<string>, name?: string}
  --resource: string # Optional. Immutable. The resource name of the resource that is associated to attributes. Presently, only entity resource is supported in the form: projects/{project}/locations/{location}/lakes/{lake}/zones/{zone}/entities/{entity_id} Must belong in the same project and region as the attribute binding, and there can only exist one active binding for a resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/dataAttributeBindings"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataAttributeBindingId, var: data_attribute_binding_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: labels, var: labels}, {name: paths, var: paths}, {name: resource, var: resource}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_attribute_binding_id: $data_attribute_binding_id, validate_only: $validate_only, attributes: $attributes, description: $description, display_name: $display_name, etag: $etag, labels: $labels, paths: $paths, resource: $resource
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists DataScans.
#
# GET /v1/{parent}/dataScans
# Returns: record<dataScans: table<createTime: string, data: record, dataProfileResult: record, dataProfileSpec: record, dataQualityResult: record, dataQualitySpec: record, description: string, displayName: string, executionSpec: record, executionStatus: record, labels: record, name: string, state: string, type: string, uid: string, updateTime: string>, nextPageToken: string, unreachable: list<string>>
# operationId: dataplex.projects.locations.dataScans.list
export def "dataplex-projects-locations-data-scans-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields (name or create_time) for the result. If not specified, the ordering is undefined.
  --page-size: int # Optional. Maximum number of dataScans to return. The service may return fewer than this value. If unspecified, at most 500 scans will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListDataScans call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDataScans must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/dataScans"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a DataScan resource.
#
# POST /v1/{parent}/dataScans
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.dataScans.create
export def "dataplex-projects-locations-data-scans-create" [
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
  --data-scan-id: string # Required. DataScan identifier. Must contain only lowercase letters, numbers and hyphens. Must start with a letter. Must end with a number or a letter. Must be between 1-63 characters. Must be unique within the customer project / location.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --data: record # The data source for DataScan. — shape: {entity?: string, resource?: string}
  --data-profile-result: record # DataProfileResult defines the output of DataProfileScan. Each field of the table will have field type specific profile result. — shape: {profile?: record, rowCount?: string, scannedData?: record}
  --data-profile-spec: record # DataProfileScan related setting.
  --data-quality-result: record # The output of a DataQualityScan. — shape: {dimensions?: list, passed?: bool, rowCount?: string, rules?: list, scannedData?: record}
  --data-quality-spec: record # DataQualityScan related setting. — shape: {rules?: list}
  --description: string # Optional. Description of the scan. Must be between 1-1024 characters.
  --display-name: string # Optional. User friendly display name. Must be between 1-256 characters.
  --execution-spec: record # DataScan execution settings. — shape: {field?: string, trigger?: record}
  --execution-status: record # Status of the data scan execution. — shape: {latestJobEndTime?: string, latestJobStartTime?: string}
  --labels: record # Optional. User-defined labels for the scan.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/dataScans"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataScanId, var: data_scan_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: dataProfileResult, var: data_profile_result}, {name: dataProfileSpec, var: data_profile_spec}, {name: dataQualityResult, var: data_quality_result}, {name: dataQualitySpec, var: data_quality_spec}, {name: description, var: description}, {name: displayName, var: display_name}, {name: executionSpec, var: execution_spec}, {name: executionStatus, var: execution_status}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_scan_id: $data_scan_id, validate_only: $validate_only, data: $data, data_profile_result: $data_profile_result, data_profile_spec: $data_profile_spec, data_quality_result: $data_quality_result, data_quality_spec: $data_quality_spec, description: $description, display_name: $display_name, execution_spec: $execution_spec, execution_status: $execution_status, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists DataTaxonomy resources in a project and location.
#
# GET /v1/{parent}/dataTaxonomies
# Returns: record<dataTaxonomies: table<attributeCount: int, createTime: string, description: string, displayName: string, etag: string, labels: record, name: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>
# operationId: dataplex.projects.locations.dataTaxonomies.list
export def "dataplex-projects-locations-data-taxonomies-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of DataTaxonomies to return. The service may return fewer than this value. If unspecified, at most 10 DataTaxonomies will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListDataTaxonomies call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListDataTaxonomies must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/dataTaxonomies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a DataTaxonomy resource.
#
# POST /v1/{parent}/dataTaxonomies
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.dataTaxonomies.create
export def "dataplex-projects-locations-data-taxonomies-create" [
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
  --data-taxonomy-id: string # Required. DataTaxonomy identifier. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the Project.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --description: string # Optional. Description of the DataTaxonomy.
  --display-name: string # Optional. User friendly display name.
  --etag: string # This checksum is computed by the server based on the value of other fields, and may be sent on update and delete requests to ensure the client has an up-to-date value before proceeding.
  --labels: record # Optional. User-defined labels for the DataTaxonomy.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/dataTaxonomies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: dataTaxonomyId, var: data_taxonomy_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: labels, var: labels}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, data_taxonomy_id: $data_taxonomy_id, validate_only: $validate_only, description: $description, display_name: $display_name, etag: $etag, labels: $labels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata entities in a zone.
#
# GET /v1/{parent}/entities
# Returns: record<entities: table<access: record, asset: string, catalogEntry: string, compatibility: record, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record, id: string, name: string, schema: record, system: string, type: string, uid: string, updateTime: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.zones.entities.list
export def "dataplex-projects-locations-lakes-zones-entities-list" [
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
  --filter: string # Optional. The following filter parameters can be added to the URL to limit the entities returned by the API: Entity ID: ?filter="id=entityID" Asset ID: ?filter="asset=assetID" Data path ?filter="data_path=gs://my-bucket" Is HIVE compatible: ?filter="hive_compatible=true" Is BigQuery compatible: ?filter="bigquery_compatible=true"
  --page-size: int # Optional. Maximum number of entities to return. The service may return fewer than this value. If unspecified, 100 entities will be returned by default. The maximum value is 500; larger values will will be truncated to 500.
  --page-token: string # Optional. Page token received from a previous ListEntities call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListEntities must match the call that provided the page token.
  --view: string@view-completer-1 # Required. Specify the entity view to make a partial list request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/entities"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a metadata entity.
#
# POST /v1/{parent}/entities
# Returns: record<access: record<read: string>, asset: string, catalogEntry: string, compatibility: record<bigquery: record<compatible: bool, reason: string>, hiveMetastore: record<compatible: bool, reason: string>>, createTime: string, dataPath: string, dataPathPattern: string, description: string, displayName: string, etag: string, format: record<compressionFormat: string, csv: record<delimiter: string, encoding: string, headerRows: int, quote: string>, format: string, iceberg: record<metadataLocation: string>, json: record<encoding: string>, mimeType: string>, id: string, name: string, schema: record<fields: list<record>, partitionFields: list<record>, partitionStyle: string, userManaged: bool>, system: string, type: string, uid: string, updateTime: string>
# operationId: dataplex.projects.locations.lakes.zones.entities.create
export def "dataplex-projects-locations-lakes-zones-entities-create" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --access: record # Describes the access mechanism of the data within its storage location.
  --asset: string # Required. Immutable. The ID of the asset associated with the storage location containing the entity data. The entity must be with in the same zone with the asset.
  --compatibility: record # Provides compatibility information for various metadata stores. — shape: {bigquery?: record, hiveMetastore?: record}
  --data-path: string # Required. Immutable. The storage path of the entity data. For Cloud Storage data, this is the fully-qualified path to the entity, such as gs://bucket/path/to/data. For BigQuery data, this is the name of the table resource, such as projects/project_id/datasets/dataset_id/tables/table_id.
  --data-path-pattern: string # Optional. The set of items within the data path constituting the data in the entity, represented as a glob path. Example: gs://bucket/path/to/data/**/*.csv.
  --description: string # Optional. User friendly longer description text. Must be shorter than or equal to 1024 characters.
  --display-name: string # Optional. Display name must be shorter than or equal to 256 characters.
  --etag: string # Optional. The etag associated with the entity, which can be retrieved with a GetEntity request. Required for update and delete requests.
  --format: record # Describes the format of the data within its storage location. — shape: {compressionFormat?: "COMPRESSION_FORMAT_UNSPECIFIED"|"GZIP"|"BZIP2", csv?: record, iceberg?: record, json?: record, mimeType?: string}
  --id: string # Required. A user-provided entity ID. It is mutable, and will be used as the published table name. Specifying a new ID in an update entity request will override the existing value. The ID must contain only letters (a-z, A-Z), numbers (0-9), and underscores, and consist of 256 or fewer characters.
  --schema: record # Schema information describing the structure and layout of the data. — shape: {fields?: list, partitionFields?: list, partitionStyle?: "PARTITION_STYLE_UNSPECIFIED"|"HIVE_COMPATIBLE", userManaged?: bool}
  --system: string@system-completer # Required. Immutable. Identifies the storage system of the entity data.
  --type: string@type-completer # Required. Immutable. The type of entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/entities"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: asset, var: asset}, {name: compatibility, var: compatibility}, {name: dataPath, var: data_path}, {name: dataPathPattern, var: data_path_pattern}, {name: description, var: description}, {name: displayName, var: display_name}, {name: etag, var: etag}, {name: format, var: format}, {name: id, var: id}, {name: schema, var: schema}, {name: system, var: system}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, access: $access, asset: $asset, compatibility: $compatibility, data_path: $data_path, data_path_pattern: $data_path_pattern, description: $description, display_name: $display_name, etag: $etag, format: $format, id: $id, schema: $schema, system: $system, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists environments under the given lake.
#
# GET /v1/{parent}/environments
# Returns: record<environments: table<createTime: string, description: string, displayName: string, endpoints: record, infrastructureSpec: record, labels: record, name: string, sessionSpec: record, sessionStatus: record, state: string, uid: string, updateTime: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.environments.list
export def "dataplex-projects-locations-lakes-environments-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of environments to return. The service may return fewer than this value. If unspecified, at most 10 environments will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListEnvironments call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListEnvironments must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/environments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an environment resource.
#
# POST /v1/{parent}/environments
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.environments.create
export def "dataplex-projects-locations-lakes-environments-create" [
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
  --environment-id: string # Required. Environment identifier. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the lake.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --description: string # Optional. Description of the environment.
  --display-name: string # Optional. User friendly display name.
  --endpoints: record # URI Endpoints to access sessions associated with the Environment.
  --infrastructure-spec: record # Configuration for the underlying infrastructure used to run workloads. — shape: {compute?: record, osImage?: record}
  --labels: record # Optional. User defined labels for the environment.
  --session-spec: record # Configuration for sessions created for this environment. — shape: {enableFastStartup?: bool, maxIdleDuration?: string}
  --session-status: record # Status of sessions created for this environment.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/environments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: environmentId, var: environment_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: endpoints, var: endpoints}, {name: infrastructureSpec, var: infrastructure_spec}, {name: labels, var: labels}, {name: sessionSpec, var: session_spec}, {name: sessionStatus, var: session_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, environment_id: $environment_id, validate_only: $validate_only, description: $description, display_name: $display_name, endpoints: $endpoints, infrastructure_spec: $infrastructure_spec, labels: $labels, session_spec: $session_spec, session_status: $session_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Jobs under the given task.
#
# GET /v1/{parent}/jobs
# Returns: record<jobs: table<endTime: string, message: string, name: string, retryCount: int, service: string, serviceJob: string, startTime: string, state: string, uid: string>, nextPageToken: string>
# operationId: dataplex.projects.locations.lakes.tasks.jobs.list
export def "dataplex-projects-locations-lakes-tasks-jobs-list" [
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
  --page-size: int # Optional. Maximum number of jobs to return. The service may return fewer than this value. If unspecified, at most 10 jobs will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListJobs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListJobs must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/jobs"
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

# Lists lake resources in a project and location.
#
# GET /v1/{parent}/lakes
# Returns: record<lakes: table<assetStatus: record, createTime: string, description: string, displayName: string, labels: record, metastore: record, metastoreStatus: record, name: string, serviceAccount: string, state: string, uid: string, updateTime: string>, nextPageToken: string, unreachableLocations: list<string>>
# operationId: dataplex.projects.locations.lakes.list
export def "dataplex-projects-locations-lakes-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of Lakes to return. The service may return fewer than this value. If unspecified, at most 10 lakes will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListLakes call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListLakes must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/lakes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a lake resource.
#
# POST /v1/{parent}/lakes
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.create
export def "dataplex-projects-locations-lakes-create" [
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
  --lake-id: string # Required. Lake identifier. This ID will be used to generate names such as database and dataset names when publishing metadata to Hive Metastore and BigQuery. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must end with a number or a letter. * Must be between 1-63 characters. * Must be unique within the customer project / location.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --asset-status: record # Aggregated status of the underlying assets of a lake or zone. — shape: {activeAssets?: int, securityPolicyApplyingAssets?: int, updateTime?: string}
  --description: string # Optional. Description of the lake.
  --display-name: string # Optional. User friendly display name.
  --labels: record # Optional. User-defined labels for the lake.
  --metastore: record # Settings to manage association of Dataproc Metastore with a lake. — shape: {service?: string}
  --metastore-status: record # Status of Lake and Dataproc Metastore service instance association. — shape: {endpoint?: string, message?: string, state?: "STATE_UNSPECIFIED"|"NONE"|"READY"|"UPDATING"|"ERROR", updateTime?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/lakes"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: lakeId, var: lake_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetStatus, var: asset_status}, {name: description, var: description}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: metastore, var: metastore}, {name: metastoreStatus, var: metastore_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, lake_id: $lake_id, validate_only: $validate_only, asset_status: $asset_status, description: $description, display_name: $display_name, labels: $labels, metastore: $metastore, metastore_status: $metastore_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List metadata partitions of an entity.
#
# GET /v1/{parent}/partitions
# Returns: record<nextPageToken: string, partitions: table<etag: string, location: string, name: string, values: list>>
# operationId: dataplex.projects.locations.lakes.zones.entities.partitions.list
export def "dataplex-projects-locations-lakes-zones-entities-partitions-list" [
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
  --filter: string # Optional. Filter the partitions returned to the caller using a key value pair expression. Supported operators and syntax: logic operators: AND, OR comparison operators: <, >, >=, <= ,=, != LIKE operators: The right hand of a LIKE operator supports "." and "*" for wildcard searches, for example "value1 LIKE ".*oo.*" parenthetical grouping: ( )Sample filter expression: `?filter="key1 < value1 OR key2 > value2"Notes: Keys to the left of operators are case insensitive. Partition results are sorted first by creation time, then by lexicographic order. Up to 20 key value filter pairs are allowed, but due to performance considerations, only the first 10 will be used as a filter.
  --page-size: int # Optional. Maximum number of partitions to return. The service may return fewer than this value. If unspecified, 100 partitions will be returned by default. The maximum page size is 500; larger values will will be truncated to 500.
  --page-token: string # Optional. Page token received from a previous ListPartitions call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListPartitions must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/partitions"
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

# Create a metadata partition.
#
# POST /v1/{parent}/partitions
# Returns: record<etag: string, location: string, name: string, values: list<string>>
# operationId: dataplex.projects.locations.lakes.zones.entities.partitions.create
export def "dataplex-projects-locations-lakes-zones-entities-partitions-create" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --etag: string # Optional. The etag for this partition.
  --location: string # Required. Immutable. The location of the entity data within the partition, for example, gs://bucket/path/to/entity/key1=value1/key2=value2. Or projects//datasets//tables/
  --values: list<string> # Required. Immutable. The set of values representing the partition, which correspond to the partition schema defined in the parent entity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/partitions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: location, var: location}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, etag: $etag, location: $location, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists session resources in an environment.
#
# GET /v1/{parent}/sessions
# Returns: record<nextPageToken: string, sessions: table<createTime: string, name: string, state: string, userId: string>>
# operationId: dataplex.projects.locations.lakes.environments.sessions.list
export def "dataplex-projects-locations-lakes-environments-sessions-list" [
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
  --filter: string # Optional. Filter request. The following mode filter is supported to return only the sessions belonging to the requester when the mode is USER and return sessions of all the users when the mode is ADMIN. When no filter is sent default to USER mode. NOTE: When the mode is ADMIN, the requester should have dataplex.environments.listAllSessions permission to list all sessions, in absence of the permission, the request fails.mode = ADMIN | USER
  --page-size: int # Optional. Maximum number of sessions to return. The service may return fewer than this value. If unspecified, at most 10 sessions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListSessions call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListSessions must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/sessions"
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

# Lists tasks under the given lake.
#
# GET /v1/{parent}/tasks
# Returns: record<nextPageToken: string, tasks: table<createTime: string, description: string, displayName: string, executionSpec: record, executionStatus: record, labels: record, name: string, notebook: record, spark: record, state: string, triggerSpec: record, uid: string, updateTime: string>, unreachableLocations: list<string>>
# operationId: dataplex.projects.locations.lakes.tasks.list
export def "dataplex-projects-locations-lakes-tasks-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of tasks to return. The service may return fewer than this value. If unspecified, at most 10 tasks will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListZones call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListZones must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/tasks"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a task resource within a lake.
#
# POST /v1/{parent}/tasks
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.tasks.create
export def "dataplex-projects-locations-lakes-tasks-create" [
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
  --task-id: string # Required. Task identifier.
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --description: string # Optional. Description of the task.
  --display-name: string # Optional. User friendly display name.
  --execution-spec: record # Execution related settings, like retry and service_account. — shape: {args?: record, kmsKey?: string, maxJobExecutionLifetime?: string, project?: string, serviceAccount?: string}
  --execution-status: record # Status of the task execution (e.g. Jobs). — shape: {latestJob?: record}
  --labels: record # Optional. User-defined labels for the task.
  --notebook: record # Config for running scheduled notebooks. — shape: {archiveUris?: list<string>, fileUris?: list<string>, infrastructureSpec?: record, notebook?: string}
  --spark: record # User-specified config for running a Spark task. — shape: {archiveUris?: list<string>, fileUris?: list<string>, infrastructureSpec?: record, mainClass?: string, mainJarFileUri?: string, pythonScriptFile?: string, sqlScript?: string, sqlScriptFile?: string}
  --trigger-spec: record # Task scheduling and trigger settings. — shape: {disabled?: bool, maxRetries?: int, schedule?: string, startTime?: string, type?: "TYPE_UNSPECIFIED"|"ON_DEMAND"|"RECURRING"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/tasks"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: taskId, var: task_id}, {name: validateOnly, var: validate_only}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: executionSpec, var: execution_spec}, {name: executionStatus, var: execution_status}, {name: labels, var: labels}, {name: notebook, var: notebook}, {name: spark, var: spark}, {name: triggerSpec, var: trigger_spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, task_id: $task_id, validate_only: $validate_only, description: $description, display_name: $display_name, execution_spec: $execution_spec, execution_status: $execution_status, labels: $labels, notebook: $notebook, spark: $spark, trigger_spec: $trigger_spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists zone resources in a lake.
#
# GET /v1/{parent}/zones
# Returns: record<nextPageToken: string, zones: table<assetStatus: record, createTime: string, description: string, discoverySpec: record, displayName: string, labels: record, name: string, resourceSpec: record, state: string, type: string, uid: string, updateTime: string>>
# operationId: dataplex.projects.locations.lakes.zones.list
export def "dataplex-projects-locations-lakes-zones-list" [
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
  --filter: string # Optional. Filter request.
  --order-by: string # Optional. Order by fields for the result.
  --page-size: int # Optional. Maximum number of zones to return. The service may return fewer than this value. If unspecified, at most 10 zones will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # Optional. Page token received from a previous ListZones call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ListZones must match the call that provided the page token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{parent}/zones"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a zone resource within a lake.
#
# POST /v1/{parent}/zones
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: dataplex.projects.locations.lakes.zones.create
export def "dataplex-projects-locations-lakes-zones-create" [
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
  --validate-only: oneof<nothing, bool> # Optional. Only validate the request, but do not perform mutations. The default is false.
  --zone-id: string # Required. Zone identifier. This ID will be used to generate names such as database and dataset names when publishing metadata to Hive Metastore and BigQuery. * Must contain only lowercase letters, numbers and hyphens. * Must start with a letter. * Must end with a number or a letter. * Must be between 1-63 characters. * Must be unique across all lakes from all locations in a project. * Must not be one of the reserved IDs (i.e. "default", "global-temp")
  --asset-status: record # Aggregated status of the underlying assets of a lake or zone. — shape: {activeAssets?: int, securityPolicyApplyingAssets?: int, updateTime?: string}
  --description: string # Optional. Description of the zone.
  --discovery-spec: record # Settings to manage the metadata discovery and publishing in a zone. — shape: {csvOptions?: record, enabled?: bool, excludePatterns?: list<string>, includePatterns?: list<string>, jsonOptions?: record, schedule?: string}
  --display-name: string # Optional. User friendly display name.
  --labels: record # Optional. User defined labels for the zone.
  --resource-spec: record # Settings for resources attached as assets within a zone. — shape: {locationType?: "LOCATION_TYPE_UNSPECIFIED"|"SINGLE_REGION"|"MULTI_REGION"}
  --type: string@type-completer-1 # Required. Immutable. The type of the zone.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{parent}/zones"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: validateOnly, var: validate_only}, {name: zoneId, var: zone_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assetStatus, var: asset_status}, {name: description, var: description}, {name: discoverySpec, var: discovery_spec}, {name: displayName, var: display_name}, {name: labels, var: labels}, {name: resourceSpec, var: resource_spec}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, validate_only: $validate_only, zone_id: $zone_id, asset_status: $asset_status, description: $description, discovery_spec: $discovery_spec, display_name: $display_name, labels: $labels, resource_spec: $resource_spec, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1/{resource}:getIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dataplex.projects.locations.lakes.zones.assets.getIamPolicy
export def "dataplex-projects-locations-lakes-zones-assets-get-iam-policy" [
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
  --options-requested-policy-version: int # Optional. The maximum policy version that will be used to format the policy.Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected.Requests for policies with any conditional role bindings must specify version 3. Policies with no conditional role bindings may specify any valid value or leave the field unset.The policy in the response might use the policy version that you specified, or it might use a lower policy version. For example, if you specify version 3, but the policy has no conditional role bindings, the response uses version 1.To learn which resources support conditions in their IAM policies, see the IAM documentation (https://cloud.google.com/iam/help/conditions/resource-policies).
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

# Sets the access control policy on the specified resource. Replaces any existing policy.Can return NOT_FOUND, INVALID_ARGUMENT, and PERMISSION_DENIED errors.
#
# POST /v1/{resource}:setIamPolicy
# Returns: record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int>
# operationId: dataplex.projects.locations.lakes.zones.assets.setIamPolicy
export def "dataplex-projects-locations-lakes-zones-assets-set-iam-policy" [
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
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources.A Policy is a collection of bindings. A binding binds one or more members, or principals, to a single role. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A role is a named list of permissions; each role can be an IAM predefined role or a user-created custom role.For some types of Google Cloud resources, a binding can also specify a condition, which is a logical expression that allows access to a resource only if the expression evaluates to true. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the IAM documentation (https://cloud.google.com/iam/help/conditions/resource-policies).JSON example: { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } YAML example: bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the IAM documentation (https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used:paths: "bindings, etag" (format: google-fieldmask)
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

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a NOT_FOUND error.Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1/{resource}:testIamPermissions
# Returns: record<permissions: list<string>>
# operationId: dataplex.projects.locations.lakes.zones.assets.testIamPermissions
export def "dataplex-projects-locations-lakes-zones-assets-test-iam-permissions" [
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
  --permissions: list<string> # The set of permissions to check for the resource. Permissions with wildcards (such as * or storage.*) are not allowed. For more information see IAM Overview (https://cloud.google.com/iam/docs/overview#permissions).
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
