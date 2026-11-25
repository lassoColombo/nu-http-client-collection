# Auto-generated client for GraphHopper Directions API v1.0.0
# Source: https://api.apis.guru/v2/specs/graphhopper.com/1.0.0/openapi.json
# Auth: --token flag or $env.GRAPHHOPPER_DIRECTIONS_API_TOKEN

const CLIENT = {
  base_url: "https://graphhopper.com/api/1"
  token_env_var: "GRAPHHOPPER_DIRECTIONS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-key, in: query, header_name: key, prefix: ""}
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

def base-url-completer [] { ["https://graphhopper.com/api/1"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def vehicle-completer [] { ["bike" "car" "foot" "hike" "mtb" "racingbike" "scooter" "small_truck" "truck"] }
def weighting-completer [] { ["fastest" "shortest"] }
def algorithm-completer [] { ["alternative_route" "round_trip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    solve-clustering-problem: "record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float>"
    async-clustering-problem: "record<job_id: string>"
    get-cluster-solution: "record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float>"
    get-geocode: "record<hits: table<city: string, country: string, housenumber: string, name: string, osm_id: string, osm_key: string, osm_type: string, point: record, postcode: string, state: string, street: string>, took: float>"
    get-isochrone: "record<copyrights: list<string>, polygons: table<geometry: record, properties: record, type: string>>"
    post-gpx: "record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>"
    get-matrix: "record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>"
    post-matrix: "record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>"
    calculate-matrix: "record<job_id: string>"
    get-matrix-solution: "record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>"
    get-route: "record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>"
    post-route: "record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>"
    get-route-info: "record<bbox: string, features: record, version: string>"
    solve-vrp: "record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int>"
    async-vrp: "record<job_id: string>"
    get-solution: "record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["solve-clustering-problem" "async-clustering-problem" "get-cluster-solution" "get-geocode" "get-isochrone" "post-gpx" "get-matrix" "post-matrix" "calculate-matrix" "get-matrix-solution" "get-route" "post-route" "get-route-info" "solve-vrp" "async-vrp" "get-solution" "commands"] | sort) } | get name | first)
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

# POST Cluster Endpoint
#
# POST /cluster
# Returns: record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float>
# operationId: solveClusteringProblem
export def "solve-clustering-problem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: record # shape: {clustering?: record, response_type?: string, routing?: record}
  --customers: list # item shape: {address?: record, id?: string, quantity?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cluster"
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: customers, var: customers}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    configuration: $configuration, customers: $customers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch Cluster Endpoint
#
# POST /cluster/calculate
# Returns: record<job_id: string>
# operationId: asyncClusteringProblem
export def "async-clustering-problem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: record # shape: {clustering?: record, response_type?: string, routing?: record}
  --customers: list # item shape: {address?: record, id?: string, quantity?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cluster/calculate"
    body: {content_type: "application/json", kind: json, fields: [{name: configuration, var: configuration}, {name: customers, var: customers}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    configuration: $configuration, customers: $customers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET Batch Solution Endpoint
#
# GET /cluster/solution/{jobId}
# Returns: record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float>
# operationId: getClusterSolution
export def "get-cluster-solution" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cluster/solution/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geocoding Endpoint
#
# GET /geocode
# Returns: record<hits: table<city: string, country: string, housenumber: string, name: string, osm_id: string, osm_key: string, osm_type: string, point: record, postcode: string, state: string, street: string>, took: float>
# operationId: getGeocode
export def "get-geocode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # If you do forward geocoding, this is `required` and is a textual description of the address you are looking for.
  --locale: string # Display the search results for the specified locale. Currently French (fr), English (en), German (de) and Italian (it) are supported. If the locale wasn't found the default (en) is used. (default: en)
  --limit: int # Specify the maximum number of results to return (format: int32, default: 10)
  --reverse: oneof<nothing, bool> # It is `required` to be `true` if you want to do a reverse geocoding request. If it is `true`, `point` must be defined as well, and `q` must not be used. (default: false)
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted. (default: false)
  --point: string # _Forward geocoding_: The location bias in the format 'latitude,longitude' e.g. point=45.93272,11.58803. _Reverse geocoding_: The location to find amenities, cities.
  --provider: string # The provider parameter is currently under development and can fall back to `default` at any time. The intend is to provide alternatives to our default geocoder. Each provider has its own strenghts and might fit better for certain scenarios, so it's worth to compare the different providers. To try it append the `provider`parameter to the URL like `&provider=nominatim`, the result structure should be identical in all cases - if not, please report this back to us. Keep in mind that some providers do not support certain parameters or don't return some fields, for example `osm_id` and `osm_type` are not supported by every geocoding provider. If you would like to use additional parameters of one of the providers, but it's not available for the GraphHopper Geocoding API, yet? Please contact us. The credit costs can be different for all providers - see [here](https://support.graphhopper.com/support/solutions/articles/44000718211-what-is-one-credit-) for more information about it. Currently, only the default provider and gisgraphy supports autocompletion of partial search strings. All providers support normal "forward" geocoding and reverse geocoding via `reverse=true`. #### Default (`provider=default`) This provider returns results of our internal geocoding engine, as described above. In addition to the above documented parameters the following parameters are possible: * `bbox` - the expected format is `minLon,minLat,maxLon,maxLat` * `osm_tag` - you can filter `key:value` or exclude places with certain OpenStreetMap tags `!key:value`. E.g. `osm_tag=tourism:museum` or just the key `osm_tag=tourism`. To exclude multiple tags you add multiple `osm_tag` parameters. #### Nominatim (`provider=nominatim`) The GraphHopper Directions API uses a commercially hosted Nominatim geocoder. You can try this provider [here](https://nominatim.openstreetmap.org/). The provider does **not** fall under the [restrictions](https://operations.osmfoundation.org/policies/nominatim/) of the Nominatim instance hosted by OpenStreetMap. In addition to the above documented parameters Nominatim allows to use the following parameters, which can be used as documented [here](https://github.com/openstreetmap/Nominatim/blob/master/docs/api/Search.md#parameters): * `viewbox` - the expected format is `minLon,minLat,maxLon,maxLat` * `bounded` - If 1 and a viewbox is given, restrict the result to items contained within that viewbox. Default is 0. #### Gisgraphy (`provider=gisgraphy`) This provider returns results from the Gisgraphy geocoder which you can try [here](https://services.gisgraphy.com/static/leaflet/index.html). **Limitations:** The `locale` parameter is not supported. Gisgraphy does not return OSM tags or an extent. Gisgraphy has a special autocomplete API, which you can use by adding `autocomplete=true` (does not work with `reverse=true`). The autocomplete API is optimized on predicting text input, but returns less information. In addition to the above documented parameters Gisgraphy allows to use the following parameters, which can be used as documented [here](https://www.gisgraphy.com/documentation/user-guide.php#geocodingservice): * `radius` - radius in meters * `country` - restrict search for the specified country. The value must be the ISO 3166 Alpha 2 code of the country. #### NetToolKit (`provider=nettoolkit`) This provider returns results from the NetToolKit provider which is specialized for US addresses and provides a wrapper around Nominatim for other addresses. You can try it [here](https://www.nettoolkit.com/geo/demo). The following additional NetToolKit parameters are supported (read [here](https://www.nettoolkit.com/docs/geo/geocoding) for more details): - `source`: User can choose which source provider to geocode the address, this value is "NetToolKit" by default - `country_code`: an iso-3166-2 country code (e.g : US) filter the results to the specify country code **Limitations:** NetToolKit does not support the `locale` parameter. NetToolKit does not return OSM tags (e.g. osm_id, osm_type, osm_value). #### OpenCage Data (`provider=opencagedata`) This provider returns results from the OpenCageData geocoder which you can try [here](https://geocoder.opencagedata.com/demo). In addition to the above documented parameters OpenCage Data allows to use the following parameters, which can be used as documented [here](https://geocoder.opencagedata.com/api#forward-opt): * countrycode - The country code is a two letter code as defined by the ISO 3166-1 Alpha 2 standard. E.g. gb for the United Kingdom, fr for France, us for United States. * bounds - the expected format is `minLon,minLat,maxLon,maxLat` (default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geocode"
    query: [{name: q, var: q}, {name: locale, var: locale}, {name: limit, var: limit}, {name: reverse, var: reverse}, {name: debug, var: debug}, {name: point, var: point}, {name: provider, var: provider}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    q: $q, locale: $locale, limit: $limit, reverse: $reverse, debug: $debug, point: $point, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Isochrone Endpoint
#
# GET /isochrone
# Returns: record<copyrights: list<string>, polygons: table<geometry: record, properties: record, type: string>>
# operationId: getIsochrone
export def "get-isochrone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # Specify the start coordinate (required)
  --time-limit: int # Specify which time the vehicle should travel. In seconds. (format: int32, default: 600)
  --distance-limit: int # Specify which distance the vehicle should travel. In meters. (format: int32)
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated. (default: car)
  --buckets: int # Number by which to divide the given `time_limit` to create `buckets` nested isochrones of time intervals `time_limit-n*time_limit/buckets`. Applies analogously to `distance_limit`. (format: int32, default: 1)
  --reverse-flow: oneof<nothing, bool> # If `false` the flow goes from point to the polygon, if `true` the flow goes from the polygon "inside" to the point. Example use case for `false`&#58; *How many potential customer can be reached within 30min travel time from your store* vs. `true`&#58; *How many customers can reach your store within 30min travel time.* (default: false)
  --weighting: string@weighting-completer # Use `"shortest"` to get an isodistance line instead of an isochrone. (default: fastest)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/isochrone"
    query: [{name: point, var: point, required: true}, {name: time_limit, var: time_limit}, {name: distance_limit, var: distance_limit}, {name: vehicle, var: vehicle}, {name: buckets, var: buckets}, {name: reverse_flow, var: reverse_flow}, {name: weighting, var: weighting}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    point: $point, time_limit: $time_limit, distance_limit: $distance_limit, vehicle: $vehicle, buckets: $buckets, reverse_flow: $reverse_flow, weighting: $weighting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map-match a GPX file
#
# POST /match
# Returns: record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>
# operationId: postGPX
export def "post-gpx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gps-accuracy: int # Specify the precision of a point, in meter
  --vehicle: string # Specify the vehicle profile like car
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/match"
    query: [{name: gps_accuracy, var: gps_accuracy}, {name: vehicle, var: vehicle}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    gps_accuracy: $gps_accuracy, vehicle: $vehicle
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET Matrix Endpoint
#
# GET /matrix
# Returns: record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>
# operationId: getMatrix
export def "get-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: list<string> # Specify multiple points in `latitude,longitude` for which the weight-, route-, time- or distance-matrix should be calculated. In this case the starts are identical to the destinations. If there are N points, then NxN entries will be calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with from_point or to_point.
  --from-point: list<string> # The starting points for the routes in `latitude,longitude`. E.g. if you want to calculate the three routes A->1, A->2, A->3 then you have one from_point parameter and three to_point parameters.
  --to-point: list<string> # The destination points for the routes in `latitude,longitude`.
  --point-hint: list<string> # Optional parameter. Specifies a hint for each `point` parameter to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --from-point-hint: list<string> # For the from_point parameter. See point_hint
  --to-point-hint: list<string> # For the to_point parameter. See point_hint
  --snap-prevention: list<string> # Optional parameter to avoid snapping to a certain road class or road environment. Current supported values `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford`. Multiple values are specified like `snap_prevention=ferry&snap_prevention=motorway`
  --curbside: list<string> # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --from-curbside: list<string> # Curbside setting for the from_point parameter. See curbside.
  --to-curbside: list<string> # Curbside setting for the to_point parameter. See curbside.
  --out-array: list<string> # Specifies which arrays should be included in the response. Specify one or more of the following options 'weights', 'times', 'distances'. To specify more than one array use e.g. out_array=times&out_array=distances. The units of the entries of distances are meters, of times are seconds and of weights is arbitrary and it can differ for different vehicles or versions of this API.
  --vehicle: string@vehicle-completer # The vehicle profile for which the matrix should be calculated. (default: car)
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/matrix"
    query: [{name: point, var: point, style: multi}, {name: from_point, var: from_point, style: multi}, {name: to_point, var: to_point, style: multi}, {name: point_hint, var: point_hint, style: multi}, {name: from_point_hint, var: from_point_hint, style: multi}, {name: to_point_hint, var: to_point_hint, style: multi}, {name: snap_prevention, var: snap_prevention, style: multi}, {name: curbside, var: curbside, style: multi}, {name: from_curbside, var: from_curbside, style: multi}, {name: to_curbside, var: to_curbside, style: multi}, {name: out_array, var: out_array, style: multi}, {name: vehicle, var: vehicle}, {name: fail_fast, var: fail_fast}, {name: turn_costs, var: turn_costs}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    point: $point, from_point: $from_point, to_point: $to_point, point_hint: $point_hint, from_point_hint: $from_point_hint, to_point_hint: $to_point_hint, snap_prevention: $snap_prevention, curbside: $curbside, from_curbside: $from_curbside, to_curbside: $to_curbside, out_array: $out_array, vehicle: $vehicle, fail_fast: $fail_fast, turn_costs: $turn_costs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST Matrix Endpoint
#
# POST /matrix
# Returns: record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>
# operationId: postMatrix
export def "post-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --from-curbsides: list<string> # See `curbsides`of symmetrical matrix
  --from-point-hints: list<string> # See `point_hints`of symmetrical matrix
  --from-points: list # The starting points for the routes in an array of `[longitude,latitude]`. For instance, if you want to calculate three routes from point A such as A->1, A->2, A->3 then you have one `from_point` parameter and three `to_point` parameters.
  --out-arrays: list<string> # Specifies which matrices should be included in the response. Specify one or more of the following options `weights`, `times`, `distances`. The units of the entries of `distances` are meters, of `times` are seconds and of `weights` is arbitrary and it can differ for different vehicles or versions of this API.
  --snap-preventions: list<string> # See `snap_preventions` of symmetrical matrix
  --to-curbsides: list<string> # See `curbsides`of symmetrical matrix
  --to-point-hints: list<string> # See `point_hints`of symmetrical matrix
  --to-points: list # The destination points for the routes in an array of `[longitude,latitude]`.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated. Other vehicles are listed [here](#section/Map-Data-and-Routing-Profiles/OpenStreetMap) for the details. (default: car)
  --curbsides: list<string> # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --point-hints: list<string> # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --points: list # Specify multiple points for which the weight-, route-, time- or distance-matrix should be calculated as follows: `[longitude,latitude]`. In this case the origins are identical to the destinations. Thus, if there are N points, NxN entries are calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with `from_point` or `to_point.`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/matrix"
    body: {content_type: "application/json", kind: json, fields: [{name: fail_fast, var: fail_fast}, {name: from_curbsides, var: from_curbsides}, {name: from_point_hints, var: from_point_hints}, {name: from_points, var: from_points}, {name: out_arrays, var: out_arrays}, {name: snap_preventions, var: snap_preventions}, {name: to_curbsides, var: to_curbsides}, {name: to_point_hints, var: to_point_hints}, {name: to_points, var: to_points}, {name: turn_costs, var: turn_costs}, {name: vehicle, var: vehicle}, {name: curbsides, var: curbsides}, {name: point_hints, var: point_hints}, {name: points, var: points}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    fail_fast: $fail_fast, from_curbsides: $from_curbsides, from_point_hints: $from_point_hints, from_points: $from_points, out_arrays: $out_arrays, snap_preventions: $snap_preventions, to_curbsides: $to_curbsides, to_point_hints: $to_point_hints, to_points: $to_points, turn_costs: $turn_costs, vehicle: $vehicle, curbsides: $curbsides, point_hints: $point_hints, points: $points
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch Matrix Endpoint
#
# POST /matrix/calculate
# Returns: record<job_id: string>
# operationId: calculateMatrix
export def "calculate-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --from-curbsides: list<string> # See `curbsides`of symmetrical matrix
  --from-point-hints: list<string> # See `point_hints`of symmetrical matrix
  --from-points: list # The starting points for the routes in an array of `[longitude,latitude]`. For instance, if you want to calculate three routes from point A such as A->1, A->2, A->3 then you have one `from_point` parameter and three `to_point` parameters.
  --out-arrays: list<string> # Specifies which matrices should be included in the response. Specify one or more of the following options `weights`, `times`, `distances`. The units of the entries of `distances` are meters, of `times` are seconds and of `weights` is arbitrary and it can differ for different vehicles or versions of this API.
  --snap-preventions: list<string> # See `snap_preventions` of symmetrical matrix
  --to-curbsides: list<string> # See `curbsides`of symmetrical matrix
  --to-point-hints: list<string> # See `point_hints`of symmetrical matrix
  --to-points: list # The destination points for the routes in an array of `[longitude,latitude]`.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated. Other vehicles are listed [here](#section/Map-Data-and-Routing-Profiles/OpenStreetMap) for the details. (default: car)
  --curbsides: list<string> # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --point-hints: list<string> # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --points: list # Specify multiple points for which the weight-, route-, time- or distance-matrix should be calculated as follows: `[longitude,latitude]`. In this case the origins are identical to the destinations. Thus, if there are N points, NxN entries are calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with `from_point` or `to_point.`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/matrix/calculate"
    body: {content_type: "application/json", kind: json, fields: [{name: fail_fast, var: fail_fast}, {name: from_curbsides, var: from_curbsides}, {name: from_point_hints, var: from_point_hints}, {name: from_points, var: from_points}, {name: out_arrays, var: out_arrays}, {name: snap_preventions, var: snap_preventions}, {name: to_curbsides, var: to_curbsides}, {name: to_point_hints, var: to_point_hints}, {name: to_points, var: to_points}, {name: turn_costs, var: turn_costs}, {name: vehicle, var: vehicle}, {name: curbsides, var: curbsides}, {name: point_hints, var: point_hints}, {name: points, var: points}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    fail_fast: $fail_fast, from_curbsides: $from_curbsides, from_point_hints: $from_point_hints, from_points: $from_points, out_arrays: $out_arrays, snap_preventions: $snap_preventions, to_curbsides: $to_curbsides, to_point_hints: $to_point_hints, to_points: $to_points, turn_costs: $turn_costs, vehicle: $vehicle, curbsides: $curbsides, point_hints: $point_hints, points: $points
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET Batch Matrix Endpoint
#
# GET /matrix/solution/{jobId}
# Returns: record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>>
# operationId: getMatrixSolution
export def "get-matrix-solution" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/matrix/solution/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET Route Endpoint
#
# GET /route
# Returns: record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>
# operationId: getRoute
export def "get-route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: list<string> # The points for which the route should be calculated. Format: `[latitude,longitude]`. Specify at least an origin and a destination. Via points are possible. The maximum number depends on your plan. (required)
  --point-hint: list<string> # The `point_hint` is typically a road name to which the associated `point` parameter should be snapped to. Specify no `point_hint` parameter or the same number as you have `point` parameters.
  --snap-prevention: list<string> # Optional parameter to avoid snapping to a certain road class or road environment. Currently supported values are `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford`. Multiple values are specified like `snap_prevention=ferry&snap_prevention=motorway`.
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated. (default: car)
  --curbside: list<string> # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the route computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
  --locale: string # The locale of the resulting turn instructions. E.g. `pt_PT` for Portuguese or `de` for German. (default: en)
  --elevation: oneof<nothing, bool> # If `true`, a third coordinate, the altitude, is included with all positions in the response. This changes the format of the `points` and `snapped_waypoints` fields of the response, in both their encodings. Unless you switch off the `points_encoded` parameter, you need special code on the client side that can handle three-dimensional coordinates. A request can fail if the vehicle profile does not support elevation. See the features object for every vehicle profile. (default: false)
  --details: list<string> # Optional parameter to retrieve path details. You can request additional details for the route: `street_name`, `time`, `distance`, `max_speed`, `toll`, `road_class`, `road_class_link`, `road_access`, `road_environment`, `lanes`, and `surface`. Read more about the usage of path details [here](https://discuss.graphhopper.com/t/2539).
  --optimize: string # Normally, the calculated route will visit the points in the order you specified them. If you have more than two points, you can set this parameter to `"true"` and the points may be re-ordered to minimize the total travel time. Keep in mind that the limits on the number of locations of the Route Optimization API applies, and the request costs more credits. (default: false)
  --instructions: oneof<nothing, bool> # If instructions should be calculated and returned (default: true)
  --calc-points: oneof<nothing, bool> # If the points for the route should be calculated at all. (default: true)
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted. (default: false)
  --points-encoded: oneof<nothing, bool> # Allows changing the encoding of location data in the response. The default is polyline encoding, which is compact but requires special client code to unpack. (We provide it in our JavaScript client library!) Set this parameter to `false` to switch the encoding to simple coordinate pairs like `[lon,lat]`, or `[lon,lat,elevation]`. See the description of the response format for more information. (default: true)
  --ch-disable: oneof<nothing, bool> # Use this parameter in combination with one or more parameters from below. (default: false)
  --weighting: string # Determines the way the "best" route is calculated. Besides `fastest` you can use `short_fastest` which finds a reasonable balance between the distance influence (`shortest`) and the time (`fastest`). You could also use `shortest` but is deprecated and not recommended for motor vehicles. All except `fastest` require `ch.disable=true`. (default: fastest)
  --heading: list<int> # Favour a heading direction for a certain point. Specify either one heading for the start point or as many as there are points. In this case headings are associated by their order to the specific points. Headings are given as north based clockwise angle between 0 and 360 degree. This parameter also influences the tour generated with `algorithm=round_trip` and forces the initial direction. Requires `ch.disable=true`.
  --heading-penalty: int # Time penalty in seconds for not obeying a specified heading. Requires `ch.disable=true`. (format: int32, default: 120)
  --pass-through: oneof<nothing, bool> # If `true`, u-turns are avoided at via-points with regard to the `heading_penalty`. Requires `ch.disable=true`. (default: false)
  --block-area: string # Block road access by specifying a point close to the road segment to be blocked, with the format `lat,lon`. You can also block all road segments crossing a geometric shape. Specify a circle using the format `lat,lon,radius`, or a polygon using the format `lat1,lon1,lat2,lon2,...,latN,lonN`. You can specify several shapes, separating them with `;`. Requires `ch.disable=true`.
  --avoid: string # Specify which road classes and environments you would like to avoid. Possible values are `motorway`, `steps`, `track`, `toll`, `ferry`, `tunnel` and `bridge`. Separate several values with `;`. Obviously not all the values make sense for all vehicle profiles e.g. `bike` is already forbidden on a `motorway`. Requires `ch.disable=true`.
  --algorithm: string@algorithm-completer # Rather than looking for the shortest or fastest path, this parameter lets you solve two different problems related to routing: With `alternative_route`, we give you not one but several routes that are close to optimal, but not too similar to each other. With `round_trip`, the route will get you back to where you started. This is meant for fun (think of a bike trip), so we will add some randomness. The `round_trip` option requires `ch.disable=true`. You can control both of these features with additional parameters, see below.
  --round-trip-distance: int # If `algorithm=round_trip`, this parameter configures approximative length of the resulting round trip. Requires `ch.disable=true`. (format: int32, default: 10000)
  --round-trip-seed: int # If `algorithm=round_trip`, this sets the random seed. Change this to get a different tour for each value. (format: int64)
  --alternative-route-max-paths: int # If `algorithm=alternative_route`, this parameter sets the number of maximum paths which should be calculated. Increasing can lead to worse alternatives. (format: int32, default: 2)
  --alternative-route-max-weight-factor: float # If `algorithm=alternative_route`, this parameter sets the factor by which the alternatives routes can be longer than the optimal route. Increasing can lead to worse alternatives. (default: 1.4)
  --alternative-route-max-share-factor: float # If `algorithm=alternative_route`, this parameter specifies how similar an alternative route can be to the optimal route. Increasing can lead to worse alternatives. (default: 0.6)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/route"
    query: [{name: point, var: point, style: multi, required: true}, {name: point_hint, var: point_hint, style: multi}, {name: snap_prevention, var: snap_prevention, style: multi}, {name: vehicle, var: vehicle}, {name: curbside, var: curbside, style: multi}, {name: turn_costs, var: turn_costs}, {name: locale, var: locale}, {name: elevation, var: elevation}, {name: details, var: details, style: multi}, {name: optimize, var: optimize}, {name: instructions, var: instructions}, {name: calc_points, var: calc_points}, {name: debug, var: debug}, {name: points_encoded, var: points_encoded}, {name: "ch.disable", var: ch_disable}, {name: weighting, var: weighting}, {name: heading, var: heading, style: multi}, {name: heading_penalty, var: heading_penalty}, {name: pass_through, var: pass_through}, {name: block_area, var: block_area}, {name: avoid, var: avoid}, {name: algorithm, var: algorithm}, {name: "round_trip.distance", var: round_trip_distance}, {name: "round_trip.seed", var: round_trip_seed}, {name: "alternative_route.max_paths", var: alternative_route_max_paths}, {name: "alternative_route.max_weight_factor", var: alternative_route_max_weight_factor}, {name: "alternative_route.max_share_factor", var: alternative_route_max_share_factor}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    point: $point, point_hint: $point_hint, snap_prevention: $snap_prevention, vehicle: $vehicle, curbside: $curbside, turn_costs: $turn_costs, locale: $locale, elevation: $elevation, details: $details, optimize: $optimize, instructions: $instructions, calc_points: $calc_points, debug: $debug, points_encoded: $points_encoded, ch_disable: $ch_disable, weighting: $weighting, heading: $heading, heading_penalty: $heading_penalty, pass_through: $pass_through, block_area: $block_area, avoid: $avoid, algorithm: $algorithm, round_trip_distance: $round_trip_distance, round_trip_seed: $round_trip_seed, alternative_route_max_paths: $alternative_route_max_paths, alternative_route_max_weight_factor: $alternative_route_max_weight_factor, alternative_route_max_share_factor: $alternative_route_max_share_factor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST Route Endpoint
#
# POST /route
# Returns: record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>>
# operationId: postRoute
export def "post-route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # Rather than looking for the shortest or fastest path, this lets you solve two different problems related to routing: With `round_trip`, the route will get you back to where you started. This is meant for fun (think of a bike trip), so we will add some randomness. This requires `ch.disable=true`. With `alternative_route`, we give you not one but several routes that are close to optimal, but not too similar to each other. You can control both of these features with additional parameters, see below.
  --alternative-route-max-paths: int # If `algorithm=alternative_route`, this parameter sets the number of maximum paths which should be calculated. Increasing can lead to worse alternatives. (format: int32, default: 2)
  --alternative-route-max-share-factor: float # If `algorithm=alternative_route`, this parameter specifies how similar an alternative route can be to the optimal route. Increasing can lead to worse alternatives. (default: 0.6)
  --alternative-route-max-weight-factor: float # If `algorithm=alternative_route`, this parameter sets the factor by which the alternatives routes can be longer than the optimal route. Increasing can lead to worse alternatives. (default: 1.4)
  --avoid: string # Specify which road classes and environments you would like to avoid. Possible values are `motorway`, `steps`, `track`, `toll`, `ferry`, `tunnel` and `bridge`. Separate several values with `;`. Obviously not all the values make sense for all vehicle profiles e.g. `bike` is already forbidden on a `motorway`. Requires `ch.disable=true`.
  --block-area: string # Block road access via a point with the format `latitude,longitude` or an area defined by a circle `lat,lon,radius` or a rectangle `lat1,lon1,lat2,lon2`. Separate several values with `;`. Requires `ch.disable=true`.
  --calc-points: oneof<nothing, bool> # If the points for the route should be calculated at all. (default: true)
  --ch-disable: oneof<nothing, bool> # Use this parameter in combination with one or more parameters from below. (default: false)
  --curbsides: list<string> # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap. (e.g. [any, right])
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted. (default: false)
  --details: list<string> # Optional parameter to retrieve path details. You can request additional details for the route: `street_name`, `time`, `distance`, `max_speed`, `toll`, `road_class`, `road_class_link`, `road_access`, `road_environment`, `lanes`, and `surface`. Read more about the usage of path details [here](https://discuss.graphhopper.com/t/2539).
  --elevation: oneof<nothing, bool> # If `true`, a third coordinate, the altitude, is included with all positions in the response. This changes the format of the `points` and `snapped_waypoints` fields of the response, in both their encodings. Unless you switch off the `points_encoded` parameter, you need special code on the client side that can handle three-dimensional coordinates. A request can fail if the vehicle profile does not support elevation. See the features object for every vehicle profile. (default: false)
  --heading-penalty: int # Time penalty in seconds for not obeying a specified heading. Requires `ch.disable=true`. (format: int32, default: 120)
  --headings: list<int> # Favour a heading direction for a certain point. Specify either one heading for the start point or as many as there are points. In this case headings are associated by their order to the specific points. Headings are given as north based clockwise angle between 0 and 360 degree. This parameter also influences the tour generated with `algorithm=round_trip` and forces the initial direction. Requires `ch.disable=true`.
  --instructions: oneof<nothing, bool> # If instructions should be calculated and returned (default: true)
  --locale: string # The locale of the resulting turn instructions. E.g. `pt_PT` for Portuguese or `de` for German. (default: en)
  --optimize: string # Normally, the calculated route will visit the points in the order you specified them. If you have more than two points, you can set this parameter to `"true"` and the points may be re-ordered to minimize the total travel time. Keep in mind that the limits on the number of locations of the Route Optimization API applies, and the request costs more credits. (default: false)
  --pass-through: oneof<nothing, bool> # If `true`, u-turns are avoided at via-points with regard to the `heading_penalty`. Requires `ch.disable=true`. (default: false)
  --point-hints: list<string> # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up. (e.g. [Lindenschmitstraße, Thalkirchener Str.])
  --points: list # The points for the route in an array of `[longitude,latitude]`. For instance, if you want to calculate a route from point A to B to C then you specify `points: [ [A_longitude, A_latitude], [B_longitude, B_latitude], [C_longitude, C_latitude]] (e.g. [[11.539421, 48.118477], [11.559023, 48.12228]])
  --points-encoded: oneof<nothing, bool> # Allows changing the encoding of location data in the response. The default is polyline encoding, which is compact but requires special client code to unpack. (We provide it in our JavaScript client library!) Set this parameter to `false` to switch the encoding to simple coordinate pairs like `[lon,lat]`, or `[lon,lat,elevation]`. See the description of the response format for more information. (default: true)
  --round-trip-distance: int # If `algorithm=round_trip`, this parameter configures approximative length of the resulting round trip. Requires `ch.disable=true`. (format: int32, default: 10000)
  --round-trip-seed: int # If `algorithm=round_trip`, this sets the random seed. Change this to get a different tour for each value. (format: int64)
  --snap-preventions: list<string> # Optional parameter to avoid snapping to a certain road class or road environment. Current supported values `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford` (e.g. [motorway, ferry, tunnel])
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated. Other vehicles are listed [here](#section/Map-Data-and-Routing-Profiles/OpenStreetMap) for the details. (default: car, e.g. bike)
  --weighting: string # Determines the way the ''best'' route is calculated. Default is `fastest`. Other options are `shortest` (e.g. for `vehicle=foot` or `bike`) and `short_fastest` which finds a reasonable balance between `shortest` and `fastest`. Requires `ch.disable=true`. (default: fastest)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/route"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: "alternative_route.max_paths", var: alternative_route_max_paths}, {name: "alternative_route.max_share_factor", var: alternative_route_max_share_factor}, {name: "alternative_route.max_weight_factor", var: alternative_route_max_weight_factor}, {name: avoid, var: avoid}, {name: block_area, var: block_area}, {name: calc_points, var: calc_points}, {name: "ch.disable", var: ch_disable}, {name: curbsides, var: curbsides}, {name: debug, var: debug}, {name: details, var: details}, {name: elevation, var: elevation}, {name: heading_penalty, var: heading_penalty}, {name: headings, var: headings}, {name: instructions, var: instructions}, {name: locale, var: locale}, {name: optimize, var: optimize}, {name: pass_through, var: pass_through}, {name: point_hints, var: point_hints}, {name: points, var: points}, {name: points_encoded, var: points_encoded}, {name: "round_trip.distance", var: round_trip_distance}, {name: "round_trip.seed", var: round_trip_seed}, {name: snap_preventions, var: snap_preventions}, {name: vehicle, var: vehicle}, {name: weighting, var: weighting}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    algorithm: $algorithm, alternative_route_max_paths: $alternative_route_max_paths, alternative_route_max_share_factor: $alternative_route_max_share_factor, alternative_route_max_weight_factor: $alternative_route_max_weight_factor, avoid: $avoid, block_area: $block_area, calc_points: $calc_points, ch_disable: $ch_disable, curbsides: $curbsides, debug: $debug, details: $details, elevation: $elevation, heading_penalty: $heading_penalty, headings: $headings, instructions: $instructions, locale: $locale, optimize: $optimize, pass_through: $pass_through, point_hints: $point_hints, points: $points, points_encoded: $points_encoded, round_trip_distance: $round_trip_distance, round_trip_seed: $round_trip_seed, snap_preventions: $snap_preventions, vehicle: $vehicle, weighting: $weighting
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Coverage information
#
# GET /route/info
# Returns: record<bbox: string, features: record, version: string>
export def "get-route-info" [
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
    path: "/route/info"
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST route optimization problem
#
# POST /vrp
# Returns: record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int>
# operationId: solveVRP
@deprecated --flag algorithm
export def "solve-vrp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: record # Use `objectives` instead. (DEPRECATED) — shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
  --configuration: record # Specifies general configurations that are taken into account when solving the vehicle routing problem. — shape: {routing?: record}
  --cost-matrices: list # Specifies your own tranport time and distance matrices. (e.g. [{data: {distances: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]], times: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]]}, location_ids: [start, Dammstrasse, Bergstrasse, Koppstrasse, start2, nirvana], profile: car}]) — item shape: {data?: record, location_ids?: list<string>, profile?: string, type?: "default"|"google"}
  --objectives: list # Specifies an objective function. The vehicle routing problem is solved in such a way that this objective function is minimized. (e.g. [{type: min, value: vehicles}, {type: min, value: completion_time}]) — item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
  --relations: list # Defines additional relationships between orders.
  --services: list # Specifies the orders of the type "service". These are, for example, pick-ups, deliveries or other stops that are to be approached by the specified vehicles. Each of these orders contains only one location. — item shape: {address?: record, allowed_vehicles?: list<string>, disallowed_vehicles?: list<string>, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list<string>, size?: list<int>, time_windows?: list, type?: "service"|"pickup"|"delivery"}
  --shipments: list # Specifies the available shipments. Each shipment contains a pickup and a delivery stop, which must be processed one after the other. — item shape: {allowed_vehicles?: list<string>, delivery: record, disallowed_vehicles?: list<string>, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list<string>, size?: list<int>}
  --vehicle-types: list # Specifies the available vehicle types. These types can be assigned to vehicles. — item shape: {capacity?: list<int>, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: "car"|"bike"|"foot"|"hike"|"mtb"|"racingbike"|"scooter"|"truck"|"small_truck", service_time_factor?: float, speed_factor?: float, type_id: string}
  --vehicles: list # Specifies the available vehicles. — item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list<string>, start_address: record, type_id?: string, vehicle_id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vrp"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: configuration, var: configuration}, {name: cost_matrices, var: cost_matrices}, {name: objectives, var: objectives}, {name: relations, var: relations}, {name: services, var: services}, {name: shipments, var: shipments}, {name: vehicle_types, var: vehicle_types}, {name: vehicles, var: vehicles}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    algorithm: $algorithm, configuration: $configuration, cost_matrices: $cost_matrices, objectives: $objectives, relations: $relations, services: $services, shipments: $shipments, vehicle_types: $vehicle_types, vehicles: $vehicles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST route optimization problem (batch mode)
#
# POST /vrp/optimize
# Returns: record<job_id: string>
# operationId: asyncVRP
@deprecated --flag algorithm
export def "async-vrp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: record # Use `objectives` instead. (DEPRECATED) — shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
  --configuration: record # Specifies general configurations that are taken into account when solving the vehicle routing problem. — shape: {routing?: record}
  --cost-matrices: list # Specifies your own tranport time and distance matrices. (e.g. [{data: {distances: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]], times: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]]}, location_ids: [start, Dammstrasse, Bergstrasse, Koppstrasse, start2, nirvana], profile: car}]) — item shape: {data?: record, location_ids?: list<string>, profile?: string, type?: "default"|"google"}
  --objectives: list # Specifies an objective function. The vehicle routing problem is solved in such a way that this objective function is minimized. (e.g. [{type: min, value: vehicles}, {type: min, value: completion_time}]) — item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
  --relations: list # Defines additional relationships between orders.
  --services: list # Specifies the orders of the type "service". These are, for example, pick-ups, deliveries or other stops that are to be approached by the specified vehicles. Each of these orders contains only one location. — item shape: {address?: record, allowed_vehicles?: list<string>, disallowed_vehicles?: list<string>, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list<string>, size?: list<int>, time_windows?: list, type?: "service"|"pickup"|"delivery"}
  --shipments: list # Specifies the available shipments. Each shipment contains a pickup and a delivery stop, which must be processed one after the other. — item shape: {allowed_vehicles?: list<string>, delivery: record, disallowed_vehicles?: list<string>, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list<string>, size?: list<int>}
  --vehicle-types: list # Specifies the available vehicle types. These types can be assigned to vehicles. — item shape: {capacity?: list<int>, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: "car"|"bike"|"foot"|"hike"|"mtb"|"racingbike"|"scooter"|"truck"|"small_truck", service_time_factor?: float, speed_factor?: float, type_id: string}
  --vehicles: list # Specifies the available vehicles. — item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list<string>, start_address: record, type_id?: string, vehicle_id: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vrp/optimize"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: configuration, var: configuration}, {name: cost_matrices, var: cost_matrices}, {name: objectives, var: objectives}, {name: relations, var: relations}, {name: services, var: services}, {name: shipments, var: shipments}, {name: vehicle_types, var: vehicle_types}, {name: vehicles, var: vehicles}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    algorithm: $algorithm, configuration: $configuration, cost_matrices: $cost_matrices, objectives: $objectives, relations: $relations, services: $services, shipments: $shipments, vehicle_types: $vehicle_types, vehicles: $vehicles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET the solution (batch mode)
#
# GET /vrp/solution/{jobId}
# Returns: record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int>
# operationId: getSolution
export def "get-solution" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/vrp/solution/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
