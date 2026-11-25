# Auto-generated client for Search v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/search/1.0.0/openapi.json
# Auth: --token flag or $env.SEARCH_TOKEN

const CLIENT = {
  base_url: "https://api.tomtom.com"
  token_env_var: "SEARCH_TOKEN"
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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def version-number-completer [] { ["2"] }
def ext-completer [] { ["json"] }
def geometries-zoom-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "3" "4" "5" "6" "7" "8" "9"] }
def ext-completer-1 [] { ["js" "json" "jsonp" "xml"] }
def view-completer [] { ["IL" "IN" "MA" "PK" "Unified"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-search-version-number-additional-data-ext" "get-search-version-number-c-s-category-ext" "get-search-version-number-category-search-query-ext" "get-search-version-number-geocode-query-ext" "get-search-version-number-geometry-filter-ext" "post-search-version-number-geometry-filter-ext" "get-search-version-number-geometry-search-query-ext" "post-search-version-number-geometry-search-query-ext" "get-search-version-number-nearby-search-ext" "get-search-version-number-poi-search-query-ext" "get-search-version-number-reverse-geocode-cross-street-position-ext" "get-search-version-number-reverse-geocode-position-ext" "get-search-version-number-routed-filter-position-heading-ext" "post-search-version-number-routed-filter-position-heading-ext" "get-search-version-number-routed-search-query-position-heading-ext" "get-search-version-number-s-query-ext" "get-search-version-number-search-query-ext" "post-search-version-number-search-along-route-query-ext" "get-search-version-number-structured-geocode-ext" "commands"] | sort) } | get name | first)
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

# Additional Data
#
# GET /search/{versionNumber}/additionalData.{ext}
export def "get-search-version-number-additional-data-ext" [
  version_number: int@version-number-completer
  ext: string@ext-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometries: string # Comma separated list of geometry UUIDs, previously retrieved from an Search API request. (required, e.g. 00004631-3400-3c00-0000-0000673c4d2e,00004631-3400-3c00-0000-0000673c42fe)
  --geometries-zoom: int@geometries-zoom-completer # Defines the precision of the geometries.
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/additionalData.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: ext, var: ext}]
    query: [{name: geometries, var: geometries, required: true}, {name: geometriesZoom, var: geometries_zoom}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, ext: $ext, geometries: $geometries, geometries_zoom: $geometries_zoom
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Low Bandwith Category Search
#
# GET /search/{versionNumber}/cS/{category}.{ext}
# DEPRECATED
@deprecated
export def "get-search-version-number-c-s-category-ext" [
  version_number: int@version-number-completer
  category: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/cS/{category}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: category, var: category}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: idxSet, var: idx_set}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, category: $category, ext: $ext, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, idx_set: $idx_set, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Category Search
#
# GET /search/{versionNumber}/categorySearch/{query}.{ext}
export def "get-search-version-number-category-search-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/categorySearch/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, extended_postal_codes_for: $extended_postal_codes_for, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geocode
#
# GET /search/{versionNumber}/geocode/{query}.{ext}
@deprecated --flag store-result
export def "get-search-version-number-geocode-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-result: oneof<nothing, bool> # If the "storeResult" flag is set, the query will be interpreted as a stored geocode and will be billed according to the terms of use. (DEPRECATED, default: false)
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/geocode/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: storeResult, var: store_result}, {name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, store_result: $store_result, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, extended_postal_codes_for: $extended_postal_codes_for, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geometry Filter
#
# GET /search/{versionNumber}/geometryFilter.{ext}
export def "get-search-version-number-geometry-filter-ext" [
  version_number: int@version-number-completer
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (required, e.g. [{"type":"CIRCLE", "position":"40.80558, -73.96548", "radius":100}, {"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}])
  --poi-list: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (required, e.g. [{"poi":{"name":"S Restaurant Toms"},"address":{"freeformAddress":"2880 Broadway, New York, NY 10025"},"position":{"lat":40.80558,"lon":-73.96548}},{"poi":{"name":"Yasha Raman Corporation"},"address":{"freeformAddress":"940 Amsterdam Ave, New York, NY 10025"},"position":{"lat":40.80076,"lon":-73.96556}}])
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/geometryFilter.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: ext, var: ext}]
    query: [{name: geometryList, var: geometry_list, required: true}, {name: poiList, var: poi_list, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, ext: $ext, geometry_list: $geometry_list, poi_list: $poi_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geometry Filter
#
# POST /search/{versionNumber}/geometryFilter.{ext}
export def "post-search-version-number-geometry-filter-ext" [
  version_number: int@version-number-completer
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
  --poi-list: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/search/{versionNumber}/geometryFilter.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: ext, var: ext}]
    body: {content_type: "application/json", kind: json, fields: [{name: geometryList, var: geometry_list}, {name: poiList, var: poi_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, ext: $ext, geometry_list: $geometry_list, poi_list: $poi_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geometry Search
#
# GET /search/{versionNumber}/geometrySearch/{query}.{ext}
export def "get-search-version-number-geometry-search-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (e.g. [{"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}, {"type":"CIRCLE", "position":"37.71205, -121.36434", "radius":6000}, {"type":"CIRCLE", "position":"37.31205, -121.36434", "radius":1000}])
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/geometrySearch/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: geometryList, var: geometry_list}, {name: limit, var: limit}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: idxSet, var: idx_set}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, geometry_list: $geometry_list, limit: $limit, language: $language, extended_postal_codes_for: $extended_postal_codes_for, idx_set: $idx_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Geometry Search
#
# POST /search/{versionNumber}/geometrySearch/{query}.{ext}
export def "post-search-version-number-geometry-search-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --geometry-list: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
]: any -> any {
  $in | http-request {
    method: post
    path: "/search/{versionNumber}/geometrySearch/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: limit, var: limit}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: idxSet, var: idx_set}]
    body: {content_type: "application/json", kind: json, fields: [{name: geometryList, var: geometry_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, limit: $limit, language: $language, extended_postal_codes_for: $extended_postal_codes_for, idx_set: $idx_set, geometry_list: $geometry_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Nearby Search
#
# GET /search/{versionNumber}/nearbySearch/.{ext}
@deprecated --flag top-left
@deprecated --flag btm-right
export def "get-search-version-number-nearby-search-ext" [
  version_number: int@version-number-completer
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (required, format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (required, format: float, e.g. -121.89)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters. (default: 10000)
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --min-fuzzy-level: int # Minimum fuzziness level to be used. (default: 1)
  --max-fuzzy-level: int # Maximum fuzziness level to be used. (default: 2)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/nearbySearch/.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: ext, var: ext}]
    query: [{name: lat, var: lat, required: true}, {name: lon, var: lon, required: true}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: minFuzzyLevel, var: min_fuzzy_level}, {name: maxFuzzyLevel, var: max_fuzzy_level}, {name: idxSet, var: idx_set}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, ext: $ext, lat: $lat, lon: $lon, limit: $limit, ofs: $ofs, country_set: $country_set, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, extended_postal_codes_for: $extended_postal_codes_for, min_fuzzy_level: $min_fuzzy_level, max_fuzzy_level: $max_fuzzy_level, idx_set: $idx_set, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Points of Interest Search
#
# GET /search/{versionNumber}/poiSearch/{query}.{ext}
export def "get-search-version-number-poi-search-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/poiSearch/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, extended_postal_codes_for: $extended_postal_codes_for, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cross Street lookup
#
# GET /search/{versionNumber}/reverseGeocode/crossStreet/{position}.{ext}
@deprecated --flag spatial-keys
export def "get-search-version-number-reverse-geocode-cross-street-position-ext" [
  version_number: int@version-number-completer
  position: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of cross-streets to return. (default: 1)
  --spatial-keys: oneof<nothing, bool> # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/reverseGeocode/crossStreet/{position}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: position, var: position}, {name: ext, var: ext}]
    query: [{name: limit, var: limit}, {name: spatialKeys, var: spatial_keys}, {name: heading, var: heading}, {name: radius, var: radius}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, position: $position, ext: $ext, limit: $limit, spatial_keys: $spatial_keys, heading: $heading, radius: $radius, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverse Geocode
#
# GET /search/{versionNumber}/reverseGeocode/{position}.{ext}
@deprecated --flag spatial-keys
export def "get-search-version-number-reverse-geocode-position-ext" [
  version_number: int@version-number-completer
  position: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --spatial-keys: oneof<nothing, bool> # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --return-speed-limit: oneof<nothing, bool> # To enable return of the posted speed limit (where available). (default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --number: string # If a number is sent in along with the request, the response may include the side of the street (Left/Right) and an offset position for that number.
  --return-road-use: oneof<nothing, bool> # Enables return of the road use array for reverse geocodes at street level. (default: false)
  --road-use: string # Restricts reverse geocodes to a certain type of road use. The road use array for reverse geocodes can be one or more of: ["LimitedAccess", "Arterial", "Terminal", "Ramp", "Rotary", "LocalStreet"].
  --callback: string # Specifies the jsonp callback method. (default: cb)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/reverseGeocode/{position}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: position, var: position}, {name: ext, var: ext}]
    query: [{name: spatialKeys, var: spatial_keys}, {name: returnSpeedLimit, var: return_speed_limit}, {name: heading, var: heading}, {name: radius, var: radius}, {name: number, var: number}, {name: returnRoadUse, var: return_road_use}, {name: roadUse, var: road_use}, {name: callback, var: callback}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, position: $position, ext: $ext, spatial_keys: $spatial_keys, return_speed_limit: $return_speed_limit, heading: $heading, radius: $radius, number: $number, return_road_use: $return_road_use, road_use: $road_use, callback: $callback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Routed Filter
#
# GET /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "get-search-version-number-routed-filter-position-heading-ext" [
  version_number: int@version-number-completer
  position: string
  heading: float
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --poi-list: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (required, e.g. [{"poi":{"name":"Cleaire Advanced Emission Controls"},"address":{"freeformAddress":"7220 Trade St, San Diego, CA 92121"},"position":{"lat":"37.83274","lon":"-122.27631"}}])
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/routedFilter/{position}/{heading}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: position, var: position}, {name: heading, var: heading}, {name: ext, var: ext}]
    query: [{name: poiList, var: poi_list, required: true}, {name: routingTimeout, var: routing_timeout}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, position: $position, heading: $heading, ext: $ext, poi_list: $poi_list, routing_timeout: $routing_timeout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Routed Filter
#
# POST /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "post-search-version-number-routed-filter-position-heading-ext" [
  version_number: int@version-number-completer
  position: string
  heading: float
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --poi-list: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/search/{versionNumber}/routedFilter/{position}/{heading}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: position, var: position}, {name: heading, var: heading}, {name: ext, var: ext}]
    query: [{name: routingTimeout, var: routing_timeout}]
    body: {content_type: "application/json", kind: json, fields: [{name: poiList, var: poi_list}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, position: $position, heading: $heading, ext: $ext, routing_timeout: $routing_timeout, poi_list: $poi_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Routed Search
#
# GET /search/{versionNumber}/routedSearch/{query}/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "get-search-version-number-routed-search-query-position-heading-ext" [
  version_number: int@version-number-completer
  query: string
  position: string
  heading: float
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --multiplier: int # Multiplies the limit by N to gather more candidate POIs, which will then be sorted by drive distance, returning only the top candidates according to the limit. (default: 2)
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/routedSearch/{query}/{position}/{heading}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: position, var: position}, {name: heading, var: heading}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: multiplier, var: multiplier}, {name: routingTimeout, var: routing_timeout}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: idxSet, var: idx_set}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, position: $position, heading: $heading, ext: $ext, typeahead: $typeahead, limit: $limit, multiplier: $multiplier, routing_timeout: $routing_timeout, language: $language, extended_postal_codes_for: $extended_postal_codes_for, idx_set: $idx_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Low bandwith Search
#
# GET /search/{versionNumber}/s/{query}.{ext}
# DEPRECATED
@deprecated
export def "get-search-version-number-s-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/s/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: idxSet, var: idx_set}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, idx_set: $idx_set, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fuzzy Search
#
# GET /search/{versionNumber}/search/{query}.{ext}
export def "get-search-version-number-search-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --min-fuzzy-level: int # Minimum fuzziness level to be used. (default: 1)
  --max-fuzzy-level: int # Maximum fuzziness level to be used. (default: 2)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/search/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: typeahead, var: typeahead}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: countrySet, var: country_set}, {name: lat, var: lat}, {name: lon, var: lon}, {name: radius, var: radius}, {name: topLeft, var: top_left}, {name: btmRight, var: btm_right}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}, {name: minFuzzyLevel, var: min_fuzzy_level}, {name: maxFuzzyLevel, var: max_fuzzy_level}, {name: idxSet, var: idx_set}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, typeahead: $typeahead, limit: $limit, ofs: $ofs, country_set: $country_set, lat: $lat, lon: $lon, radius: $radius, top_left: $top_left, btm_right: $btm_right, language: $language, extended_postal_codes_for: $extended_postal_codes_for, min_fuzzy_level: $min_fuzzy_level, max_fuzzy_level: $max_fuzzy_level, idx_set: $idx_set, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Along Route Search
#
# POST /search/{versionNumber}/searchAlongRoute/{query}.{ext}
export def "post-search-version-number-search-along-route-query-ext" [
  version_number: int@version-number-completer
  query: string
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-detour-time: int # Maximum detour time (required, e.g. 1200)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --route: record # shape: {points?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/search/{versionNumber}/searchAlongRoute/{query}.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: query, var: query}, {name: ext, var: ext}]
    query: [{name: maxDetourTime, var: max_detour_time, required: true}, {name: limit, var: limit}]
    body: {content_type: "application/json", kind: json, fields: [{name: route, var: route}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, query: $query, ext: $ext, max_detour_time: $max_detour_time, limit: $limit, route: $route
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Structured Geocode
#
# GET /search/{versionNumber}/structuredGeocode.{ext}
export def "get-search-version-number-structured-geocode-ext" [
  version_number: int@version-number-completer
  ext: string@ext-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # 2 or 3 letter country code (e.g.: FR, ES). (required, e.g. NL)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --street-number: string # The street number for the structured address.
  --street-name: string # The street name for the structured address.
  --cross-street: string # The cross street name for the structured address.
  --municipality: string # The municipality (city/town) for the structured address. (e.g. Amsterdam)
  --municipality-subdivision: string # The municipality subdivision (sub/super city) for the structured address.
  --country-tertiary-subdivision: string # The named area for the structured address.
  --country-secondary-subdivision: string # The county for the structured address.
  --country-subdivision: string # The state or province for the structured address.
  --postal-code: string # The zip code or postal code for the structured address.
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{versionNumber}/structuredGeocode.{ext}"
    path_params: [{name: versionNumber, var: version_number}, {name: ext, var: ext}]
    query: [{name: countryCode, var: country_code, required: true}, {name: limit, var: limit}, {name: ofs, var: ofs}, {name: streetNumber, var: street_number}, {name: streetName, var: street_name}, {name: crossStreet, var: cross_street}, {name: municipality, var: municipality}, {name: municipalitySubdivision, var: municipality_subdivision}, {name: countryTertiarySubdivision, var: country_tertiary_subdivision}, {name: countrySecondarySubdivision, var: country_secondary_subdivision}, {name: countrySubdivision, var: country_subdivision}, {name: postalCode, var: postal_code}, {name: language, var: language}, {name: extendedPostalCodesFor, var: extended_postal_codes_for}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    version_number: $version_number, ext: $ext, country_code: $country_code, limit: $limit, ofs: $ofs, street_number: $street_number, street_name: $street_name, cross_street: $cross_street, municipality: $municipality, municipality_subdivision: $municipality_subdivision, country_tertiary_subdivision: $country_tertiary_subdivision, country_secondary_subdivision: $country_secondary_subdivision, country_subdivision: $country_subdivision, postal_code: $postal_code, language: $language, extended_postal_codes_for: $extended_postal_codes_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
