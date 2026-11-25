# Auto-generated client for College Football Data API v4.4.12
# Source: https://api.apis.guru/v2/specs/collegefootballdata.com/4.4.12/openapi.json
# Auth: --token flag or $env.COLLEGE_FOOTBALL_DATA_API_TOKEN

const CLIENT = {
  base_url: "https://api.collegefootballdata.com"
  token_env_var: "COLLEGE_FOOTBALL_DATA_API_TOKEN"
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

def base-url-completer [] { ["https://api.collegefootballdata.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-calendar: "table<firstGameStart: string, lastGameStart: string, season: int, seasonType: string, week: int>"
    get-coaches: "table<first_name: string, hire_date: string, last_name: string, seasons: list<record>>"
    get-conferences: "table<abbreviation: string, classification: string, id: int, name: string, short_name: string>"
    get-draft-picks: "table<collegeAthleteId: int, collegeConference: string, collegeId: int, collegeTeam: string, height: int, hometownInfo: record<city: string, country: string, countryFips: int, latitude: float, longitude: float, state: string>, name: string, nflAthleteId: int, nflTeam: string, overall: int, pick: int, position: string, preDraftGrade: int, preDraftPositionRanking: int, preDraftRanking: int, round: int, weight: int, year: int>"
    get-nfl-positions: "table<abbreviation: string, name: string>"
    get-nfl-teams: "table<displayName: string, location: string, logo: string, nickname: string>"
    get-drives: "table<defense: string, defense_conference: string, drive_number: int, drive_result: string, end_defense_score: int, end_offense_score: int, end_period: int, end_time: record<minutes: int, seconds: int>, end_yardline: int, end_yards_to_goal: int, game_id: int, id: int, is_home_offense: bool, offense: string, offense_conference: string, plays: int, scoring: bool, start_defense_score: int, start_offense_score: int, start_period: int, start_time: record<minutes: int, seconds: int>, start_yardline: int, start_yards_to_goal: int, yards: int>"
    get-advanced-box-score: "record<players: record<ppa: list<record>, usage: list<record>>, teams: record<cumulativePpa: list<record>, explosiveness: list<record>, fieldPosition: list<record>, havoc: list<record>, ppa: list<record>, rushing: list<record>, scoringOpportunities: list<record>, successRates: list<record>>>"
    get-games: "table<attendance: int, away_conference: string, away_division: string, away_id: int, away_line_scores: list<int>, away_points: int, away_post_win_prob: float, away_postgame_elo: int, away_pregame_elo: int, away_team: string, completed: bool, conference_game: bool, excitement_index: float, highlights: string, home_conference: string, home_division: string, home_id: int, home_line_scores: list<int>, home_points: int, home_post_win_prob: float, home_postgame_elo: int, home_pregame_elo: int, home_team: string, id: int, neutral_site: bool, notes: string, season: int, season_type: string, start_date: string, start_time_tbd: bool, venue: string, venue_id: int, week: int>"
    get-game-media: "table<awayConference: string, awayTeam: string, homeConference: string, homeTeam: string, id: int, isStartTimeTBD: bool, mediaType: string, outlet: string, season: int, seasonType: string, startTime: string, week: int>"
    get-player-game-stats: "table<id: int, teams: list<record>>"
    get-team-game-stats: "table<id: int, teams: list<record>>"
    get-game-weather: "table<awayConference: string, awayTeam: string, dewPoint: float, gameIndoors: bool, homeConference: string, homeTeam: string, humidity: float, id: int, precipitation: float, pressure: float, season: int, seasonType: string, snowfall: float, startTime: string, temperature: float, venue: string, venueId: int, weatherCondition: string, weatherConditionCode: int, week: int, windDirection: float, windSpeed: float>"
    get-lines: "table<awayConference: string, awayScore: int, awayTeam: string, homeConference: string, homeScore: int, homeTeam: string, id: int, lines: list<record>, season: int, seasonType: string, startDate: string, week: int>"
    get-live-plays: "record<clock: string, distance: int, down: int, drives: table<defense: string, defenseId: int, duration: string, endClock: string, endPeriod: int, endYardsToGoal: int, id: int, offense: string, offenseId: int, playCount: int, plays: list, scoringOpportunity: bool, startClock: string, startPeriod: int, startYardsToGoal: int, yards: int>, id: int, period: int, possession: string, status: string, teams: table<drives: int, epaPerPass: float, epaPerPlay: float, epaPerRush: float, explosiveness: float, homeAway: string, lineYards: int, lineYardsPerRush: float, openFieldYards: int, openFieldYardsPerRush: float, passingDownSuccessRate: float, passingEpa: float, plays: int, points: int, pointsPerOpportunity: float, rushingEpa: float, scoringOpportunities: int, secondLevelYards: int, secondLevelYardsPerRush: float, standardDownSuccessRate: float, successRate: float, team: string, teamId: int, totalEpa: float>, yardsToGoal: int>"
    get-win-probability-data: "table<away: string, awayId: int, awayScore: int, distance: int, down: int, gamesId: int, home: string, homeBall: bool, homeId: int, homeScore: int, homeWinProb: float, playId: int, playNumber: int, playText: string, spread: float, timeRemaining: int, yardLine: int>"
    get-pregame-win-probabilities: "table<awayTeam: string, gameId: int, homeTeam: string, homeWinProb: float, season: int, seasonType: string, spread: float, week: int>"
    get-play-stat-types: "table<id: int, name: string>"
    get-play-stats: "table<athleteId: int, athleteName: string, clock: record<minutes: int, seconds: int>, conference: string, distance: int, down: int, driveId: int, gameId: int, opponent: string, opponentScore: int, period: int, playId: int, season: int, stat: int, statType: string, team: string, teamScore: int, week: int, yardsToGoal: int>"
    get-play-types: "table<abbreviation: string, id: int, text: string>"
    get-transfer-portal: "table<destination: string, eligibility: string, firstName: string, lastName: string, origin: string, position: string, rating: float, season: int, stars: int, transferDate: string>"
    get-returning-production: "table<conference: string, passingUsage: float, percentPPA: float, percentPassingPPA: float, percentReceivingPPA: float, percentRushingPPA: float, receivingUsage: float, rushingUsage: float, season: int, team: string, totalPPA: float, totalPassingPPA: float, totalReceivingPPA: float, totalRushingPPA: float, usage: float>"
    player-search: "table<firstName: string, height: int, hometown: string, id: int, jersey: int, lastName: string, name: string, position: string, team: string, teamColor: string, teamColorSecondary: string, weight: int>"
    get-player-usage: "table<conference: string, id: int, name: string, position: string, season: int, team: string, usage: record<firstDown: float, overall: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>>"
    get-plays: "table<away: string, clock: record<minutes: int, seconds: int>, defense: string, defense_conference: string, defense_score: int, defense_timeouts: int, distance: int, down: int, drive_id: int, drive_number: int, game_id: int, home: string, id: int, offense: string, offense_conference: string, offense_score: int, offense_timeouts: int, period: int, play_number: int, play_text: string, play_type: string, ppa: float, scoring: bool, wallclock: string, yard_line: int, yards_gained: int, yards_to_goal: int>"
    get-game-ppa: "table<conference: string, defense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, gameId: int, offense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, opponent: string, season: int, team: string, week: int>"
    get-player-game-ppa: "table<averagePPA: record<all: float, pass: float, rush: float>, name: string, opponent: string, position: string, season: int, team: string, week: int>"
    get-player-season-ppa: "table<averagePPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>, conference: string, id: int, name: string, position: string, season: int, team: string, totalPPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>>"
    get-predicted-points: "table<predictedPoints: float, yardLine: int>"
    get-team-ppa: "table<conference: string, defense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, offense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, season: int, team: string>"
    get-rankings: "table<polls: list<record>, season: int, seasonType: string, week: int>"
    get-elo-ratings: "table<conference: string, elo: float, team: string, year: int>"
    get-sp-ratings: "table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, ranking: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, ranking: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, ranking: float, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, team: string, year: int>"
    get-conference-sp-ratings: "table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, year: int>"
    get-srs-ratings: "table<conference: string, division: string, ranking: float, rating: float, team: string, year: int>"
    get-team-records: "table<awayGames: record<games: int, losses: int, ties: int, wins: int>, conference: string, conferenceGames: record<games: int, losses: int, ties: int, wins: int>, division: string, expectedWins: float, homeGames: record<games: int, losses: int, ties: int, wins: int>, team: string, total: record<games: int, losses: int, ties: int, wins: int>, year: int>"
    get-recruiting-groups: "table<averageRating: float, averageStars: float, commits: float, conference: string, positionGroup: string, team: string, totalRating: float>"
    get-recruiting-players: "table<athleteId: int, city: string, committedTo: string, country: string, height: float, hometownInfo: record<countyFips: string, latitude: float, longitude: float>, id: int, name: string, position: string, ranking: int, rating: float, recruitType: string, school: string, stars: int, stateProvince: string, weight: int, year: int>"
    get-recruiting-teams: "table<points: float, rank: int, team: string, year: int>"
    get-roster: "table<first_name: string, height: int, home_city: string, home_country: string, home_county_fips: string, home_latitude: float, home_longitude: float, home_state: string, id: int, jersey: int, last_name: string, position: string, recruit_ids: list<int>, team: string, weight: int, year: int>"
    get-scoreboard: "table<awayTeam: record<classification: string, conference: string, id: int, name: string, points: int>, betting: record<awayMoneyline: int, homeMoneyline: int, overUnder: float, spread: float>, clock: string, conferenceGame: bool, homeTeam: record<classification: string, conference: string, id: int, name: string, points: int>, id: int, neutralSite: bool, period: int, possession: string, situation: string, startDate: string, startTimeTBD: bool, status: string, tv: string, venue: record<city: string, name: string, state: string>, weather: record<description: string, temperature: float, windDirection: float, windSpeed: float>>"
    get-stat-categories: "list<string>"
    get-advanced-team-game-stats: "table<defense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, gameId: int, offense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, opponent: string, season: int, team: string, week: int>"
    get-player-season-stats: "table<category: string, conference: string, player: string, playerId: int, season: int, stat: float, statType: string, team: string>"
    get-team-season-stats: "table<conference: string, season: int, statName: string, statValue: int, team: string>"
    get-advanced-team-season-stats: "table<conference: string, defense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, offense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, season: int, team: string>"
    get-talent: "table<school: string, talent: float, year: int>"
    get-teams: "table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string>"
    get-fbs-teams: "table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string>"
    get-team-matchup: "record<endYear: int, games: table<awayScore: int, awayTeam: string, date: string, homeScore: int, homeTeam: string, neutralSite: bool, season: int, season_type: string, venue: string, week: int, winner: string>, startYear: int, team1: string, team1Wins: int, team2: string, team2Wins: int, ties: int>"
    get-venues: "table<capacity: int, city: string, country_code: string, dome: bool, elevation: float, grass: bool, id: int, location: record<x: float, y: float>, name: string, state: string, timezone: string, year_constructed: int, zip: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-calendar" "get-coaches" "get-conferences" "get-draft-picks" "get-nfl-positions" "get-nfl-teams" "get-drives" "get-advanced-box-score" "get-games" "get-game-media" "get-player-game-stats" "get-team-game-stats" "get-game-weather" "get-lines" "get-live-plays" "get-win-probability-data" "get-pregame-win-probabilities" "get-play-stat-types" "get-play-stats" "get-play-types" "get-transfer-portal" "get-returning-production" "player-search" "get-player-usage" "get-plays" "get-game-ppa" "get-player-game-ppa" "get-player-season-ppa" "get-predicted-points" "get-team-ppa" "get-rankings" "get-elo-ratings" "get-sp-ratings" "get-conference-sp-ratings" "get-srs-ratings" "get-team-records" "get-recruiting-groups" "get-recruiting-players" "get-recruiting-teams" "get-roster" "get-scoreboard" "get-stat-categories" "get-advanced-team-game-stats" "get-player-season-stats" "get-team-season-stats" "get-advanced-team-season-stats" "get-talent" "get-teams" "get-fbs-teams" "get-team-matchup" "get-venues" "commands"] | sort) } | get name | first)
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

# Season calendar
#
# GET /calendar
# Returns: table<firstGameStart: string, lastGameStart: string, season: int, seasonType: string, week: int>
# operationId: getCalendar
export def "get-calendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/calendar"
    query: [{name: year, var: year, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Coaching records and history
#
# GET /coaches
# Returns: table<first_name: string, hire_date: string, last_name: string, seasons: list<record>>
# operationId: getCoaches
export def "get-coaches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string # First name filter
  --last-name: string # Last name filter
  --team: string # Team name filter
  --year: int # Year filter
  --min-year: int # Minimum year filter (inclusive)
  --max-year: int # Maximum year filter (inclusive)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/coaches"
    query: [{name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: team, var: team}, {name: year, var: year}, {name: minYear, var: min_year}, {name: maxYear, var: max_year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    first_name: $first_name, last_name: $last_name, team: $team, year: $year, min_year: $min_year, max_year: $max_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conferences
#
# GET /conferences
# Returns: table<abbreviation: string, classification: string, id: int, name: string, short_name: string>
# operationId: getConferences
export def "get-conferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/conferences"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of NFL Draft picks
#
# GET /draft/picks
# Returns: table<collegeAthleteId: int, collegeConference: string, collegeId: int, collegeTeam: string, height: int, hometownInfo: record<city: string, country: string, countryFips: int, latitude: float, longitude: float, state: string>, name: string, nflAthleteId: int, nflTeam: string, overall: int, pick: int, position: string, preDraftGrade: int, preDraftPositionRanking: int, preDraftRanking: int, round: int, weight: int, year: int>
# operationId: getDraftPicks
export def "get-draft-picks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --nfl-team: string # NFL team filter
  --college: string # Player college filter
  --conference: string # College confrence abbreviation filter
  --position: string # NFL position filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/draft/picks"
    query: [{name: year, var: year}, {name: nflTeam, var: nfl_team}, {name: college, var: college}, {name: conference, var: conference}, {name: position, var: position}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, nfl_team: $nfl_team, college: $college, conference: $conference, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of NFL positions
#
# GET /draft/positions
# Returns: table<abbreviation: string, name: string>
# operationId: getNFLPositions
export def "get-nfl-positions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/draft/positions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of NFL teams
#
# GET /draft/teams
# Returns: table<displayName: string, location: string, logo: string, nickname: string>
# operationId: getNFLTeams
export def "get-nfl-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/draft/teams"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Drive data and results
#
# GET /drives
# Returns: table<defense: string, defense_conference: string, drive_number: int, drive_result: string, end_defense_score: int, end_offense_score: int, end_period: int, end_time: record<minutes: int, seconds: int>, end_yardline: int, end_yards_to_goal: int, game_id: int, id: int, is_home_offense: bool, offense: string, offense_conference: string, plays: int, scoring: bool, start_defense_score: int, start_offense_score: int, start_period: int, start_time: record<minutes: int, seconds: int>, start_yardline: int, start_yards_to_goal: int, yards: int>
# operationId: getDrives
export def "get-drives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --season-type: string # Season type filter (default: regular)
  --year: int # Year filter (required)
  --week: int # Week filter
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offense-conference: string # Offensive conference filter
  --defense-conference: string # Defensive conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/drives"
    query: [{name: seasonType, var: season_type}, {name: year, var: year, required: true}, {name: week, var: week}, {name: team, var: team}, {name: offense, var: offense}, {name: defense, var: defense}, {name: conference, var: conference}, {name: offenseConference, var: offense_conference}, {name: defenseConference, var: defense_conference}, {name: classification, var: classification}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    season_type: $season_type, year: $year, week: $week, team: $team, offense: $offense, defense: $defense, conference: $conference, offense_conference: $offense_conference, defense_conference: $defense_conference, classification: $classification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Advanced box scores
#
# GET /game/box/advanced
# Returns: record<players: record<ppa: list<record>, usage: list<record>>, teams: record<cumulativePpa: list<record>, explosiveness: list<record>, fieldPosition: list<record>, havoc: list<record>, ppa: list<record>, rushing: list<record>, scoringOpportunities: list<record>, successRates: list<record>>>
# operationId: getAdvancedBoxScore
export def "get-advanced-box-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id parameters (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/game/box/advanced"
    query: [{name: gameId, var: game_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Games and results
#
# GET /games
# Returns: table<attendance: int, away_conference: string, away_division: string, away_id: int, away_line_scores: list<int>, away_points: int, away_post_win_prob: float, away_postgame_elo: int, away_pregame_elo: int, away_team: string, completed: bool, conference_game: bool, excitement_index: float, highlights: string, home_conference: string, home_division: string, home_id: int, home_line_scores: list<int>, home_points: int, home_post_win_prob: float, home_postgame_elo: int, home_pregame_elo: int, home_team: string, id: int, neutral_site: bool, notes: string, season: int, season_type: string, start_date: string, start_time_tbd: bool, venue: string, venue_id: int, week: int>
# operationId: getGames
export def "get-games" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games (required)
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
  --division: string # Division classification filter (fbs/fcs/ii/iii)
  --id: int # id filter for querying a single game
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/games"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: home, var: home}, {name: away, var: away}, {name: conference, var: conference}, {name: division, var: division}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, season_type: $season_type, team: $team, home: $home, away: $away, conference: $conference, division: $division, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Game media information and schedules
#
# GET /games/media
# Returns: table<awayConference: string, awayTeam: string, homeConference: string, homeTeam: string, id: int, isStartTimeTBD: bool, mediaType: string, outlet: string, season: int, seasonType: string, startTime: string, week: int>
# operationId: getGameMedia
export def "get-game-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required)
  --week: int # Week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --media-type: string # Media type filter (tv, radio, web, ppv, or mobile)
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/games/media"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: conference, var: conference}, {name: mediaType, var: media_type}, {name: classification, var: classification}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, season_type: $season_type, team: $team, conference: $conference, media_type: $media_type, classification: $classification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player game stats
#
# GET /games/players
# Returns: table<id: int, teams: list<record>>
# operationId: getPlayerGameStats
export def "get-player-game-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games (required)
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --category: string # Category filter (e.g defensive)
  --game-id: int # Game id filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/games/players"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: conference, var: conference}, {name: category, var: category}, {name: gameId, var: game_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, season_type: $season_type, team: $team, conference: $conference, category: $category, game_id: $game_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team game stats
#
# GET /games/teams
# Returns: table<id: int, teams: list<record>>
# operationId: getTeamGameStats
export def "get-team-game-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games (required)
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --game-id: int # Game id filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/games/teams"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: conference, var: conference}, {name: gameId, var: game_id}, {name: classification, var: classification}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, season_type: $season_type, team: $team, conference: $conference, game_id: $game_id, classification: $classification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Game weather information (Patreon only)
#
# GET /games/weather
# Returns: table<awayConference: string, awayTeam: string, dewPoint: float, gameIndoors: bool, homeConference: string, homeTeam: string, humidity: float, id: int, precipitation: float, pressure: float, season: int, seasonType: string, snowfall: float, startTime: string, temperature: float, venue: string, venueId: int, weatherCondition: string, weatherConditionCode: int, week: int, windDirection: float, windSpeed: float>
# operationId: getGameWeather
export def "get-game-weather" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter (required if no year)
  --year: int # Year filter (required if no game id)
  --week: int # Week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/games/weather"
    query: [{name: gameId, var: game_id}, {name: year, var: year}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: conference, var: conference}, {name: classification, var: classification}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, year: $year, week: $week, season_type: $season_type, team: $team, conference: $conference, classification: $classification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Betting lines
#
# GET /lines
# Returns: table<awayConference: string, awayScore: int, awayTeam: string, homeConference: string, homeScore: int, homeTeam: string, id: int, lines: list<record>, season: int, seasonType: string, startDate: string, week: int>
# operationId: getLines
export def "get-lines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/lines"
    query: [{name: gameId, var: game_id}, {name: year, var: year}, {name: week, var: week}, {name: seasonType, var: season_type}, {name: team, var: team}, {name: home, var: home}, {name: away, var: away}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id, year: $year, week: $week, season_type: $season_type, team: $team, home: $home, away: $away, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Live metrics and PBP (Patreon only)
#
# GET /live/plays
# Returns: record<clock: string, distance: int, down: int, drives: table<defense: string, defenseId: int, duration: string, endClock: string, endPeriod: int, endYardsToGoal: int, id: int, offense: string, offenseId: int, playCount: int, plays: list, scoringOpportunity: bool, startClock: string, startPeriod: int, startYardsToGoal: int, yards: int>, id: int, period: int, possession: string, status: string, teams: table<drives: int, epaPerPass: float, epaPerPlay: float, epaPerRush: float, explosiveness: float, homeAway: string, lineYards: int, lineYardsPerRush: float, openFieldYards: int, openFieldYardsPerRush: float, passingDownSuccessRate: float, passingEpa: float, plays: int, points: int, pointsPerOpportunity: float, rushingEpa: float, scoringOpportunities: int, secondLevelYards: int, secondLevelYardsPerRush: float, standardDownSuccessRate: float, successRate: float, team: string, teamId: int, totalEpa: float>, yardsToGoal: int>
# operationId: getLivePlays
export def "get-live-plays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Game id (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/live/plays"
    query: [{name: id, var: id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Win probability chart data
#
# GET /metrics/wp
# Returns: table<away: string, awayId: int, awayScore: int, distance: int, down: int, gamesId: int, home: string, homeBall: bool, homeId: int, homeScore: int, homeWinProb: float, playId: int, playNumber: int, playText: string, spread: float, timeRemaining: int, yardLine: int>
# operationId: getWinProbabilityData
export def "get-win-probability-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/wp"
    query: [{name: gameId, var: game_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    game_id: $game_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pregame win probability data
#
# GET /metrics/wp/pregame
# Returns: table<awayTeam: string, gameId: int, homeTeam: string, homeWinProb: float, season: int, seasonType: string, spread: float, week: int>
# operationId: getPregameWinProbabilities
export def "get-pregame-win-probabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --season-type: string # regular or postseason
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/wp/pregame"
    query: [{name: year, var: year}, {name: week, var: week}, {name: team, var: team}, {name: seasonType, var: season_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Types of player play stats
#
# GET /play/stat/types
# Returns: table<id: int, name: string>
# operationId: getPlayStatTypes
export def "get-play-stat-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/play/stat/types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Play stats by play
#
# GET /play/stats
# Returns: table<athleteId: int, athleteName: string, clock: record<minutes: int, seconds: int>, conference: string, distance: int, down: int, driveId: int, gameId: int, opponent: string, opponentScore: int, period: int, playId: int, season: int, stat: int, statType: string, team: string, teamScore: int, week: int, yardsToGoal: int>
# operationId: getPlayStats
export def "get-play-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --game-id: int # gameId filter (from /games endpoint)
  --athlete-id: int # athleteId filter (from /roster endpoint)
  --stat-type-id: int # statTypeId filter (from /play/stat/types endpoint)
  --season-type: string # regular, postseason, or both
  --conference: string # conference abbreviation filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/play/stats"
    query: [{name: year, var: year}, {name: week, var: week}, {name: team, var: team}, {name: gameId, var: game_id}, {name: athleteId, var: athlete_id}, {name: statTypeId, var: stat_type_id}, {name: seasonType, var: season_type}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, game_id: $game_id, athlete_id: $athlete_id, stat_type_id: $stat_type_id, season_type: $season_type, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Play types
#
# GET /play/types
# Returns: table<abbreviation: string, id: int, text: string>
# operationId: getPlayTypes
export def "get-play-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/play/types"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer portal by season
#
# GET /player/portal
# Returns: table<destination: string, eligibility: string, firstName: string, lastName: string, origin: string, position: string, rating: float, season: int, stars: int, transferDate: string>
# operationId: getTransferPortal
export def "get-transfer-portal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/player/portal"
    query: [{name: year, var: year, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team returning production metrics
#
# GET /player/returning
# Returns: table<conference: string, passingUsage: float, percentPPA: float, percentPassingPPA: float, percentReceivingPPA: float, percentRushingPPA: float, receivingUsage: float, rushingUsage: float, season: int, team: string, totalPPA: float, totalPassingPPA: float, totalReceivingPPA: float, totalRushingPPA: float, usage: float>
# operationId: getReturningProduction
export def "get-returning-production" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/player/returning"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for player information
#
# GET /player/search
# Returns: table<firstName: string, height: int, hometown: string, id: int, jersey: int, lastName: string, name: string, position: string, team: string, teamColor: string, teamColorSecondary: string, weight: int>
# operationId: playerSearch
export def "player-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # Term to search on (required)
  --position: string # Position abbreviation filter
  --team: string # Team filter
  --year: int # Year filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/player/search"
    query: [{name: searchTerm, var: search_term, required: true}, {name: position, var: position}, {name: team, var: team}, {name: year, var: year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_term: $search_term, position: $position, team: $team, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player usage metrics broken down by season
#
# GET /player/usage
# Returns: table<conference: string, id: int, name: string, position: string, season: int, team: string, usage: record<firstDown: float, overall: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>>
# operationId: getPlayerUsage
export def "get-player-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required, default: 2022)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/player/usage"
    query: [{name: year, var: year, required: true, default: 2022}, {name: team, var: team}, {name: conference, var: conference}, {name: position, var: position}, {name: playerId, var: player_id}, {name: excludeGarbageTime, var: exclude_garbage_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference, position: $position, player_id: $player_id, exclude_garbage_time: $exclude_garbage_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Play by play data
#
# GET /plays
# Returns: table<away: string, clock: record<minutes: int, seconds: int>, defense: string, defense_conference: string, defense_score: int, defense_timeouts: int, distance: int, down: int, drive_id: int, drive_number: int, game_id: int, home: string, id: int, offense: string, offense_conference: string, offense_score: int, offense_timeouts: int, period: int, play_number: int, play_text: string, play_type: string, ppa: float, scoring: bool, wallclock: string, yard_line: int, yards_gained: int, yards_to_goal: int>
# operationId: getPlays
export def "get-plays" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --season-type: string # Season type filter (default: regular)
  --year: int # Year filter (required)
  --week: int # Week filter (required if team, offense, or defense, not specified) (required)
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offense-conference: string # Offensive conference filter
  --defense-conference: string # Defensive conference filter
  --play-type: int # Play type filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/plays"
    query: [{name: seasonType, var: season_type}, {name: year, var: year, required: true}, {name: week, var: week, required: true}, {name: team, var: team}, {name: offense, var: offense}, {name: defense, var: defense}, {name: conference, var: conference}, {name: offenseConference, var: offense_conference}, {name: defenseConference, var: defense_conference}, {name: playType, var: play_type}, {name: classification, var: classification}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    season_type: $season_type, year: $year, week: $week, team: $team, offense: $offense, defense: $defense, conference: $conference, offense_conference: $offense_conference, defense_conference: $defense_conference, play_type: $play_type, classification: $classification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team Predicated Points Added (PPA/EPA) by game
#
# GET /ppa/games
# Returns: table<conference: string, defense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, gameId: int, offense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, opponent: string, season: int, team: string, week: int>
# operationId: getGamePPA
export def "get-game-ppa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required)
  --week: int # Week filter
  --team: string # Team filter
  --conference: string # Conference filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ppa/games"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: team, var: team}, {name: conference, var: conference}, {name: excludeGarbageTime, var: exclude_garbage_time}, {name: seasonType, var: season_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, conference: $conference, exclude_garbage_time: $exclude_garbage_time, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Predicated Points Added (PPA/EPA) broken down by game
#
# GET /ppa/players/games
# Returns: table<averagePPA: record<all: float, pass: float, rush: float>, name: string, opponent: string, position: string, season: int, team: string, week: int>
# operationId: getPlayerGamePPA
export def "get-player-game-ppa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ppa/players/games"
    query: [{name: year, var: year}, {name: week, var: week}, {name: team, var: team}, {name: position, var: position}, {name: playerId, var: player_id}, {name: threshold, var: threshold}, {name: excludeGarbageTime, var: exclude_garbage_time}, {name: seasonType, var: season_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, position: $position, player_id: $player_id, threshold: $threshold, exclude_garbage_time: $exclude_garbage_time, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player Predicated Points Added (PPA/EPA) broken down by season
#
# GET /ppa/players/season
# Returns: table<averagePPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>, conference: string, id: int, name: string, position: string, season: int, team: string, totalPPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>>
# operationId: getPlayerSeasonPPA
export def "get-player-season-ppa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ppa/players/season"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}, {name: position, var: position}, {name: playerId, var: player_id}, {name: threshold, var: threshold}, {name: excludeGarbageTime, var: exclude_garbage_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference, position: $position, player_id: $player_id, threshold: $threshold, exclude_garbage_time: $exclude_garbage_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Predicted Points (i.e. Expected Points or EP)
#
# GET /ppa/predicted
# Returns: table<predictedPoints: float, yardLine: int>
# operationId: getPredictedPoints
export def "get-predicted-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --down: int # Down filter (required)
  --distance: int # Distance filter (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ppa/predicted"
    query: [{name: down, var: down, required: true}, {name: distance, var: distance, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    down: $down, distance: $distance
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Predicted Points Added (PPA/EPA) data by team
#
# GET /ppa/teams
# Returns: table<conference: string, defense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, offense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, season: int, team: string>
# operationId: getTeamPPA
export def "get-team-ppa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ppa/teams"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}, {name: excludeGarbageTime, var: exclude_garbage_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference, exclude_garbage_time: $exclude_garbage_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Historical polls and rankings
#
# GET /rankings
# Returns: table<polls: list<record>, season: int, seasonType: string, week: int>
# operationId: getRankings
export def "get-rankings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games (required)
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/rankings"
    query: [{name: year, var: year, required: true}, {name: week, var: week}, {name: seasonType, var: season_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Historical Elo ratings
#
# GET /ratings/elo
# Returns: table<conference: string, elo: float, team: string, year: int>
# operationId: getEloRatings
export def "get-elo-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --week: int # Maximum week filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ratings/elo"
    query: [{name: year, var: year}, {name: week, var: week}, {name: team, var: team}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Historical SP+ ratings
#
# GET /ratings/sp
# Returns: table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, ranking: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, ranking: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, ranking: float, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, team: string, year: int>
# operationId: getSPRatings
export def "get-sp-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ratings/sp"
    query: [{name: year, var: year}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Historical SP+ ratings by conference
#
# GET /ratings/sp/conferences
# Returns: table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, year: int>
# operationId: getConferenceSPRatings
export def "get-conference-sp-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --conference: string # Conference abbreviation filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ratings/sp/conferences"
    query: [{name: year, var: year}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Historical SRS ratings
#
# GET /ratings/srs
# Returns: table<conference: string, division: string, ranking: float, rating: float, team: string, year: int>
# operationId: getSRSRatings
export def "get-srs-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ratings/srs"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team records
#
# GET /records
# Returns: table<awayGames: record<games: int, losses: int, ties: int, wins: int>, conference: string, conferenceGames: record<games: int, losses: int, ties: int, wins: int>, division: string, expectedWins: float, homeGames: record<games: int, losses: int, ties: int, wins: int>, team: string, total: record<games: int, losses: int, ties: int, wins: int>, year: int>
# operationId: getTeamRecords
export def "get-team-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/records"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recruit position group ratings
#
# GET /recruiting/groups
# Returns: table<averageRating: float, averageStars: float, commits: float, conference: string, positionGroup: string, team: string, totalRating: float>
# operationId: getRecruitingGroups
export def "get-recruiting-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-year: int # Starting year
  --end-year: int # Ending year
  --team: string # Team filter
  --conference: string # conference filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recruiting/groups"
    query: [{name: startYear, var: start_year}, {name: endYear, var: end_year}, {name: team, var: team}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_year: $start_year, end_year: $end_year, team: $team, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player recruiting ratings and rankings
#
# GET /recruiting/players
# Returns: table<athleteId: int, city: string, committedTo: string, country: string, height: float, hometownInfo: record<countyFips: string, latitude: float, longitude: float>, id: int, name: string, position: string, ranking: int, rating: float, recruitType: string, school: string, stars: int, stateProvince: string, weight: int, year: int>
# operationId: getRecruitingPlayers
export def "get-recruiting-players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Recruiting class year (required if team no specified)
  --classification: string # Type of recruit (HighSchool, JUCO, PrepSchool) (default: HighSchool)
  --position: string # Position abbreviation filter
  --state: string # State or province abbreviation filter
  --team: string # Committed team filter (required if year not specified)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recruiting/players"
    query: [{name: year, var: year}, {name: classification, var: classification}, {name: position, var: position}, {name: state, var: state}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, classification: $classification, position: $position, state: $state, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team recruiting rankings and ratings
#
# GET /recruiting/teams
# Returns: table<points: float, rank: int, team: string, year: int>
# operationId: getRecruitingTeams
export def "get-recruiting-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Recruiting class year
  --team: string # Team filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recruiting/teams"
    query: [{name: year, var: year}, {name: team, var: team}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team rosters
#
# GET /roster
# Returns: table<first_name: string, height: int, home_city: string, home_country: string, home_county_fips: string, home_latitude: float, home_longitude: float, home_state: string, id: int, jersey: int, last_name: string, position: string, recruit_ids: list<int>, team: string, weight: int, year: int>
# operationId: getRoster
export def "get-roster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team: string # Team name
  --year: int # Season year
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/roster"
    query: [{name: team, var: team}, {name: year, var: year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team: $team, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Live game results (Patreon only)
#
# GET /scoreboard
# Returns: table<awayTeam: record<classification: string, conference: string, id: int, name: string, points: int>, betting: record<awayMoneyline: int, homeMoneyline: int, overUnder: float, spread: float>, clock: string, conferenceGame: bool, homeTeam: record<classification: string, conference: string, id: int, name: string, points: int>, id: int, neutralSite: bool, period: int, possession: string, situation: string, startDate: string, startTimeTBD: bool, status: string, tv: string, venue: record<city: string, name: string, state: string>, weather: record<description: string, temperature: float, windDirection: float, windSpeed: float>>
# operationId: getScoreboard
export def "get-scoreboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --classification: string # Classification filter (fbs, fcs, ii, or iii). Defaults to fbs.
  --conference: string # Conference abbreviation filter.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scoreboard"
    query: [{name: classification, var: classification}, {name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    classification: $classification, conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team stat categories
#
# GET /stats/categories
# Returns: list<string>
# operationId: getStatCategories
export def "get-stat-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/categories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Advanced team metrics by game
#
# GET /stats/game/advanced
# Returns: table<defense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, gameId: int, offense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, opponent: string, season: int, team: string, week: int>
# operationId: getAdvancedTeamGameStats
export def "get-advanced-team-game-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --week: int # Week filter
  --team: string # Team filter (required if no year specified)
  --opponent: string # Opponent filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular, postseason, or both)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/game/advanced"
    query: [{name: year, var: year}, {name: week, var: week}, {name: team, var: team}, {name: opponent, var: opponent}, {name: excludeGarbageTime, var: exclude_garbage_time}, {name: seasonType, var: season_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, week: $week, team: $team, opponent: $opponent, exclude_garbage_time: $exclude_garbage_time, season_type: $season_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Player stats by season
#
# GET /stats/player/season
# Returns: table<category: string, conference: string, player: string, playerId: int, season: int, stat: float, statType: string, team: string>
# operationId: getPlayerSeasonStats
export def "get-player-season-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --start-week: int # Start week filter
  --end-week: int # Start week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --category: string # Stat category filter (e.g. passing)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/player/season"
    query: [{name: year, var: year, required: true}, {name: team, var: team}, {name: conference, var: conference}, {name: startWeek, var: start_week}, {name: endWeek, var: end_week}, {name: seasonType, var: season_type}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference, start_week: $start_week, end_week: $end_week, season_type: $season_type, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team statistics by season
#
# GET /stats/season
# Returns: table<conference: string, season: int, statName: string, statValue: int, team: string>
# operationId: getTeamSeasonStats
export def "get-team-season-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --conference: string # Conference abbreviation filter
  --start-week: int # Starting week filter
  --end-week: int # Starting week filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/season"
    query: [{name: year, var: year}, {name: team, var: team}, {name: conference, var: conference}, {name: startWeek, var: start_week}, {name: endWeek, var: end_week}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, conference: $conference, start_week: $start_week, end_week: $end_week
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Advanced team metrics by season
#
# GET /stats/season/advanced
# Returns: table<conference: string, defense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, offense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, season: int, team: string>
# operationId: getAdvancedTeamSeasonStats
export def "get-advanced-team-season-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --start-week: int # Starting week filter
  --end-week: int # Starting week filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats/season/advanced"
    query: [{name: year, var: year}, {name: team, var: team}, {name: excludeGarbageTime, var: exclude_garbage_time}, {name: startWeek, var: start_week}, {name: endWeek, var: end_week}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, team: $team, exclude_garbage_time: $exclude_garbage_time, start_week: $start_week, end_week: $end_week
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team talent composite rankings
#
# GET /talent
# Returns: table<school: string, talent: float, year: int>
# operationId: getTalent
export def "get-talent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/talent"
    query: [{name: year, var: year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team information
#
# GET /teams
# Returns: table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string>
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
  --conference: string # Conference abbreviation filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams"
    query: [{name: conference, var: conference}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conference: $conference
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# FBS team list
#
# GET /teams/fbs
# Returns: table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string>
# operationId: getFbsTeams
export def "get-fbs-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/fbs"
    query: [{name: year, var: year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Team matchup history
#
# GET /teams/matchup
# Returns: record<endYear: int, games: table<awayScore: int, awayTeam: string, date: string, homeScore: int, homeTeam: string, neutralSite: bool, season: int, season_type: string, venue: string, week: int, winner: string>, startYear: int, team1: string, team1Wins: int, team2: string, team2Wins: int, ties: int>
# operationId: getTeamMatchup
export def "get-team-matchup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team1: string # First team (required)
  --team2: string # Second team (required)
  --min-year: int # Minimum year
  --max-year: int # Maximum year
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/matchup"
    query: [{name: team1, var: team1, required: true}, {name: team2, var: team2, required: true}, {name: minYear, var: min_year}, {name: maxYear, var: max_year}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team1: $team1, team2: $team2, min_year: $min_year, max_year: $max_year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Arena and venue information
#
# GET /venues
# Returns: table<capacity: int, city: string, country_code: string, dome: bool, elevation: float, grass: bool, id: int, location: record<x: float, y: float>, name: string, state: string, timezone: string, year_constructed: int, zip: string>
# operationId: getVenues
export def "get-venues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/venues"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
