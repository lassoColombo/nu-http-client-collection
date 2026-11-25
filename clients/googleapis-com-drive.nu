# Auto-generated client for Drive API v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/drive/v3/openapi.json
# Auth: --token flag or $env.DRIVE_API_TOKEN

const CLIENT = {
  base_url: "https://www.googleapis.com/drive/v3"
  token_env_var: "DRIVE_API_TOKEN"
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

def base-url-completer [] { ["https://www.googleapis.com/drive/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def corpus-completer [] { ["domain" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    drive-about-get: "record<appInstalled: bool, canCreateDrives: bool, canCreateTeamDrives: bool, driveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, exportFormats: record, folderColorPalette: list<string>, importFormats: record, kind: string, maxImportSizes: record, maxUploadSize: string, storageQuota: record<limit: string, usage: string, usageInDrive: string, usageInDriveTrash: string>, teamDriveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, user: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>>"
    drive-changes-list: "record<changes: table<changeType: string, drive: record, driveId: string, file: record, fileId: string, kind: string, removed: bool, teamDrive: record, teamDriveId: string, time: string, type: string>, kind: string, newStartPageToken: string, nextPageToken: string>"
    drive-changes-get-start-page-token: "record<kind: string, startPageToken: string>"
    drive-changes-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    drive-drives-list: "record<drives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>, kind: string, nextPageToken: string>"
    drive-drives-create: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>"
    drive-drives-get: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>"
    drive-drives-update: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>"
    drive-drives-hide: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>"
    drive-drives-unhide: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>"
    drive-files-list: "record<files: table<appProperties: record, capabilities: record, contentHints: record, contentRestrictions: list, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record, isAppAuthorized: bool, kind: string, labelInfo: record, lastModifyingUser: record, linkShareMetadata: record, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: list, parents: list, permissionIds: list, permissions: list, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record, shortcutDetails: record, size: string, spaces: list, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record, version: string, videoMediaMetadata: record, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>, incompleteSearch: bool, kind: string, nextPageToken: string>"
    drive-files-create: "record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>"
    drive-files-generate-ids: "record<ids: list<string>, kind: string, space: string>"
    drive-files-get: "record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>"
    drive-files-update: "record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>"
    drive-comments-list: "record<comments: table<anchor: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record, replies: list, resolved: bool>, kind: string, nextPageToken: string>"
    drive-comments-create: "record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>"
    drive-comments-get: "record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>"
    drive-comments-update: "record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>"
    drive-replies-list: "record<kind: string, nextPageToken: string, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>>"
    drive-replies-create: "record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>"
    drive-replies-get: "record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>"
    drive-replies-update: "record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>"
    drive-files-copy: "record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>"
    drive-files-list-labels: "record<kind: string, labels: table<fields: record, id: string, kind: string, revisionId: string>, nextPageToken: string>"
    drive-files-modify-labels: "record<kind: string, modifiedLabels: table<fields: record, id: string, kind: string, revisionId: string>>"
    drive-permissions-list: "record<kind: string, nextPageToken: string, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>>"
    drive-permissions-create: "record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>"
    drive-permissions-get: "record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>"
    drive-permissions-update: "record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>"
    drive-revisions-list: "record<kind: string, nextPageToken: string, revisions: table<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>>"
    drive-revisions-get: "record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>"
    drive-revisions-update: "record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>"
    drive-files-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    drive-teamdrives-list: "record<kind: string, nextPageToken: string, teamDrives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>>"
    drive-teamdrives-create: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>"
    drive-teamdrives-get: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>"
    drive-teamdrives-update: "record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["drive-about-get" "drive-changes-list" "drive-changes-get-start-page-token" "drive-changes-watch" "drive-channels-stop" "drive-drives-list" "drive-drives-create" "drive-drives-delete" "drive-drives-get" "drive-drives-update" "drive-drives-hide" "drive-drives-unhide" "drive-files-list" "drive-files-create" "drive-files-generate-ids" "drive-files-empty-trash" "drive-files-delete" "drive-files-get" "drive-files-update" "drive-comments-list" "drive-comments-create" "drive-comments-delete" "drive-comments-get" "drive-comments-update" "drive-replies-list" "drive-replies-create" "drive-replies-delete" "drive-replies-get" "drive-replies-update" "drive-files-copy" "drive-files-export" "drive-files-list-labels" "drive-files-modify-labels" "drive-permissions-list" "drive-permissions-create" "drive-permissions-delete" "drive-permissions-get" "drive-permissions-update" "drive-revisions-list" "drive-revisions-delete" "drive-revisions-get" "drive-revisions-update" "drive-files-watch" "drive-teamdrives-list" "drive-teamdrives-create" "drive-teamdrives-delete" "drive-teamdrives-get" "drive-teamdrives-update" "commands"] | sort) } | get name | first)
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

# Gets information about the user, the user's Drive, and system capabilities.
#
# GET /about
# Returns: record<appInstalled: bool, canCreateDrives: bool, canCreateTeamDrives: bool, driveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, exportFormats: record, folderColorPalette: list<string>, importFormats: record, kind: string, maxImportSizes: record, maxUploadSize: string, storageQuota: record<limit: string, usage: string, usageInDrive: string, usageInDriveTrash: string>, teamDriveThemes: table<backgroundImageLink: string, colorRgb: string, id: string>, user: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>>
# operationId: drive.about.get
export def "drive-about-get" [
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
    path: "/about"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the changes for a user or shared drive.
#
# GET /changes
# Returns: record<changes: table<changeType: string, drive: record, driveId: string, file: record, fileId: string, kind: string, removed: bool, teamDrive: record, teamDriveId: string, time: string, type: string>, kind: string, newStartPageToken: string, nextPageToken: string>
# operationId: drive.changes.list
export def "drive-changes-list" [
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
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response or to the response from the getStartPageToken method. (required)
  --drive-id: string # The shared drive from which changes are returned. If specified the change IDs will be reflective of the shared drive; use the combined drive ID and change ID as an identifier.
  --include-corpus-removals: oneof<nothing, bool> # Whether changes should include the file resource if the file is still accessible by the user at the time of the request, even when a file was removed from the list of changes and there will be no further change entries for this file.
  --include-items-from-all-drives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --include-removed: oneof<nothing, bool> # Whether to include changes indicating that items have been removed from the list of changes, for example by deletion or loss of access.
  --include-team-drive-items: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --page-size: int # The maximum number of changes to return per page.
  --restrict-to-my-drive: oneof<nothing, bool> # Whether to restrict the results to changes inside the My Drive hierarchy. This omits changes to files such as those in the Application Data folder or shared files which have not been added to My Drive.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --team-drive-id: string # Deprecated use driveId instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changes"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageToken, var: page_token, required: true}, {name: driveId, var: drive_id}, {name: includeCorpusRemovals, var: include_corpus_removals}, {name: includeItemsFromAllDrives, var: include_items_from_all_drives}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: includeRemoved, var: include_removed}, {name: includeTeamDriveItems, var: include_team_drive_items}, {name: pageSize, var: page_size}, {name: restrictToMyDrive, var: restrict_to_my_drive}, {name: spaces, var: spaces}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: teamDriveId, var: team_drive_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_token: $page_token, drive_id: $drive_id, include_corpus_removals: $include_corpus_removals, include_items_from_all_drives: $include_items_from_all_drives, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, include_removed: $include_removed, include_team_drive_items: $include_team_drive_items, page_size: $page_size, restrict_to_my_drive: $restrict_to_my_drive, spaces: $spaces, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, team_drive_id: $team_drive_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the starting pageToken for listing future changes.
#
# GET /changes/startPageToken
# Returns: record<kind: string, startPageToken: string>
# operationId: drive.changes.getStartPageToken
export def "drive-changes-get-start-page-token" [
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
  --drive-id: string # The ID of the shared drive for which the starting pageToken for listing future changes from that shared drive is returned.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --team-drive-id: string # Deprecated use driveId instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/changes/startPageToken"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: driveId, var: drive_id}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: teamDriveId, var: team_drive_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, drive_id: $drive_id, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, team_drive_id: $team_drive_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribes to changes for a user. To use this method, you must include the pageToken query parameter.
#
# POST /changes/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: drive.changes.watch
export def "drive-changes-watch" [
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
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response or to the response from the getStartPageToken method. (required)
  --drive-id: string # The shared drive from which changes are returned. If specified the change IDs will be reflective of the shared drive; use the combined drive ID and change ID as an identifier.
  --include-corpus-removals: oneof<nothing, bool> # Whether changes should include the file resource if the file is still accessible by the user at the time of the request, even when a file was removed from the list of changes and there will be no further change entries for this file.
  --include-items-from-all-drives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --include-removed: oneof<nothing, bool> # Whether to include changes indicating that items have been removed from the list of changes, for example by deletion or loss of access.
  --include-team-drive-items: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --page-size: int # The maximum number of changes to return per page.
  --restrict-to-my-drive: oneof<nothing, bool> # Whether to restrict the results to changes inside the My Drive hierarchy. This omits changes to files such as those in the Application Data folder or shared files which have not been added to My Drive.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --team-drive-id: string # Deprecated use driveId instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/changes/watch"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageToken, var: page_token, required: true}, {name: driveId, var: drive_id}, {name: includeCorpusRemovals, var: include_corpus_removals}, {name: includeItemsFromAllDrives, var: include_items_from_all_drives}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: includeRemoved, var: include_removed}, {name: includeTeamDriveItems, var: include_team_drive_items}, {name: pageSize, var: page_size}, {name: restrictToMyDrive, var: restrict_to_my_drive}, {name: spaces, var: spaces}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: teamDriveId, var: team_drive_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_token: $page_token, drive_id: $drive_id, include_corpus_removals: $include_corpus_removals, include_items_from_all_drives: $include_items_from_all_drives, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, include_removed: $include_removed, include_team_drive_items: $include_team_drive_items, page_size: $page_size, restrict_to_my_drive: $restrict_to_my_drive, spaces: $spaces, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, team_drive_id: $team_drive_id, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: drive.channels.stop
export def "drive-channels-stop" [
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
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> any {
  $in | http-request {
    method: post
    path: "/channels/stop"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the user's shared drives.
#
# GET /drives
# Returns: record<drives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>, kind: string, nextPageToken: string>
# operationId: drive.drives.list
export def "drive-drives-list" [
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
  --page-size: int # Maximum number of shared drives to return per page.
  --page-token: string # Page token for shared drives.
  --q: string # Query string for searching shared drives.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then all shared drives of the domain in which the requester is an administrator are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/drives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: q, var: q}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_size: $page_size, page_token: $page_token, q: $q, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a shared drive.
#
# POST /drives
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>
# operationId: drive.drives.create
export def "drive-drives-create" [
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
  --request-id: string # An ID, such as a random UUID, which uniquely identifies this user's request for idempotent creation of a shared drive. A repeated request by the same user and with the same request ID will avoid creating duplicates by attempting to create the same shared drive. If the shared drive already exists a 409 error will be returned. (required)
  --background-image-file: record # An image file and cropping parameters from which a background image for this shared drive is set. This is a write-only field; it can only be set on drive.drives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --background-image-link: string # A short-lived link to this shared drive's background image.
  --capabilities: record # Capabilities the current user has on this shared drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, ... (4 more fields)}
  --color-rgb: string # The color of this shared drive as an RGB hex string. It can only be set on drive.drives.update requests that don't set themeId.
  --created-time: string # The time at which the shared drive was created (RFC 3339 date-time). (format: date-time)
  --hidden: oneof<nothing, bool> # Whether the shared drive is hidden from default view.
  --id: string # The ID of this shared drive which is also the ID of the top level folder of this shared drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#drive". (default: drive#drive)
  --name: string # The name of this shared drive.
  --org-unit-id: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this shared drive or items inside this shared drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
  --theme-id: string # The ID of the theme from which the background image and color are set. The set of possible driveThemes can be retrieved from a drive.about.get response. When not specified on a drive.drives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/drives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: requestId, var: request_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundImageFile, var: background_image_file}, {name: backgroundImageLink, var: background_image_link}, {name: capabilities, var: capabilities}, {name: colorRgb, var: color_rgb}, {name: createdTime, var: created_time}, {name: hidden, var: hidden}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: restrictions, var: restrictions}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, request_id: $request_id, background_image_file: $background_image_file, background_image_link: $background_image_link, capabilities: $capabilities, color_rgb: $color_rgb, created_time: $created_time, hidden: $hidden, id: $id, kind: $kind, name: $name, org_unit_id: $org_unit_id, restrictions: $restrictions, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes a shared drive for which the user is an organizer. The shared drive cannot contain any untrashed items.
#
# DELETE /drives/{driveId}
# operationId: drive.drives.delete
export def "drive-drives-delete" [
  drive_id: string
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
  --allow-item-deletion: oneof<nothing, bool> # Whether any items inside the shared drive should also be deleted. This option is only supported when useDomainAdminAccess is also set to true.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the shared drive belongs.
]: nothing -> any {
  http-request {
    method: delete
    path: "/drives/{driveId}"
    path_params: [{name: driveId, var: drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: allowItemDeletion, var: allow_item_deletion}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drive_id: $drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, allow_item_deletion: $allow_item_deletion, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a shared drive's metadata by ID.
#
# GET /drives/{driveId}
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>
# operationId: drive.drives.get
export def "drive-drives-get" [
  drive_id: string
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
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the shared drive belongs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/drives/{driveId}"
    path_params: [{name: driveId, var: drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drive_id: $drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the metadata for a shared drive.
#
# PATCH /drives/{driveId}
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>
# operationId: drive.drives.update
export def "drive-drives-update" [
  drive_id: string
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
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator. If set to true, then the requester is granted access if they're an administrator of the domain to which the shared drive belongs.
  --background-image-file: record # An image file and cropping parameters from which a background image for this shared drive is set. This is a write-only field; it can only be set on drive.drives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --background-image-link: string # A short-lived link to this shared drive's background image.
  --capabilities: record # Capabilities the current user has on this shared drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeDriveBackground?: bool, canChangeDriveMembersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRename?: bool, ... (4 more fields)}
  --color-rgb: string # The color of this shared drive as an RGB hex string. It can only be set on drive.drives.update requests that don't set themeId.
  --created-time: string # The time at which the shared drive was created (RFC 3339 date-time). (format: date-time)
  --hidden: oneof<nothing, bool> # Whether the shared drive is hidden from default view.
  --id: string # The ID of this shared drive which is also the ID of the top level folder of this shared drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#drive". (default: drive#drive)
  --name: string # The name of this shared drive.
  --org-unit-id: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this shared drive or items inside this shared drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, driveMembersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool}
  --theme-id: string # The ID of the theme from which the background image and color are set. The set of possible driveThemes can be retrieved from a drive.about.get response. When not specified on a drive.drives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/drives/{driveId}"
    path_params: [{name: driveId, var: drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundImageFile, var: background_image_file}, {name: backgroundImageLink, var: background_image_link}, {name: capabilities, var: capabilities}, {name: colorRgb, var: color_rgb}, {name: createdTime, var: created_time}, {name: hidden, var: hidden}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: restrictions, var: restrictions}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drive_id: $drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, use_domain_admin_access: $use_domain_admin_access, background_image_file: $background_image_file, background_image_link: $background_image_link, capabilities: $capabilities, color_rgb: $color_rgb, created_time: $created_time, hidden: $hidden, id: $id, kind: $kind, name: $name, org_unit_id: $org_unit_id, restrictions: $restrictions, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hides a shared drive from the default view.
#
# POST /drives/{driveId}/hide
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>
# operationId: drive.drives.hide
export def "drive-drives-hide" [
  drive_id: string
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
    method: post
    path: "/drives/{driveId}/hide"
    path_params: [{name: driveId, var: drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drive_id: $drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a shared drive to the default view.
#
# POST /drives/{driveId}/unhide
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeDriveBackground: bool, canChangeDriveMembersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRename: bool, canRenameDrive: bool, canResetDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, hidden: bool, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, driveMembersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool>, themeId: string>
# operationId: drive.drives.unhide
export def "drive-drives-unhide" [
  drive_id: string
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
    method: post
    path: "/drives/{driveId}/unhide"
    path_params: [{name: driveId, var: drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    drive_id: $drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists or searches files.
#
# GET /files
# Returns: record<files: table<appProperties: record, capabilities: record, contentHints: record, contentRestrictions: list, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record, isAppAuthorized: bool, kind: string, labelInfo: record, lastModifyingUser: record, linkShareMetadata: record, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: list, parents: list, permissionIds: list, permissions: list, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record, shortcutDetails: record, size: string, spaces: list, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record, version: string, videoMediaMetadata: record, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>, incompleteSearch: bool, kind: string, nextPageToken: string>
# operationId: drive.files.list
export def "drive-files-list" [
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
  --corpora: string # Groupings of files to which the query applies. Supported groupings are: 'user' (files created by, opened by, or shared directly with the user), 'drive' (files in the specified shared drive as indicated by the 'driveId'), 'domain' (files shared to the user's domain), and 'allDrives' (A combination of 'user' and 'drive' for all drives where the user is a member). When able, use 'user' or 'drive', instead of 'allDrives', for efficiency.
  --corpus: string@corpus-completer # The source of files to list. Deprecated: use 'corpora' instead.
  --drive-id: string # ID of the shared drive to search.
  --include-items-from-all-drives: oneof<nothing, bool> # Whether both My Drive and shared drive items should be included in results.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --include-team-drive-items: oneof<nothing, bool> # Deprecated use includeItemsFromAllDrives instead.
  --order-by: string # A comma-separated list of sort keys. Valid keys are 'createdTime', 'folder', 'modifiedByMeTime', 'modifiedTime', 'name', 'name_natural', 'quotaBytesUsed', 'recency', 'sharedWithMeTime', 'starred', and 'viewedByMeTime'. Each key sorts ascending by default, but may be reversed with the 'desc' modifier. Example usage: ?orderBy=folder,modifiedTime desc,name. Please note that there is a current limitation for users with approximately one million files in which the requested sort order is ignored.
  --page-size: int # The maximum number of files to return per page. Partial or empty result pages are possible even before the end of the files list has been reached.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --q: string # A query for filtering the file results. See the "Search for Files" guide for supported syntax.
  --spaces: string # A comma-separated list of spaces to query within the corpora. Supported values are 'drive' and 'appDataFolder'.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --team-drive-id: string # Deprecated use driveId instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: corpora, var: corpora}, {name: corpus, var: corpus}, {name: driveId, var: drive_id}, {name: includeItemsFromAllDrives, var: include_items_from_all_drives}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: includeTeamDriveItems, var: include_team_drive_items}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: q, var: q}, {name: spaces, var: spaces}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: teamDriveId, var: team_drive_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, corpora: $corpora, corpus: $corpus, drive_id: $drive_id, include_items_from_all_drives: $include_items_from_all_drives, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, include_team_drive_items: $include_team_drive_items, order_by: $order_by, page_size: $page_size, page_token: $page_token, q: $q, spaces: $spaces, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, team_drive_id: $team_drive_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a file.
#
# POST /files
# Returns: record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>
# operationId: drive.files.create
export def "drive-files-create" [
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
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. Creating files in multiple folders is no longer supported.
  --ignore-default-visibility: oneof<nothing, bool> # Whether to ignore the domain's default visibility settings for the created file. Domain administrators can choose to make all uploaded files visible to the domain by default; this parameter bypasses that behavior for the request. Permissions are still inherited from parent folders.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keep-revision-forever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocr-language: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --use-content-as-indexable-text: oneof<nothing, bool> # Whether to use the uploaded content as indexable text.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: enforceSingleParent, var: enforce_single_parent}, {name: ignoreDefaultVisibility, var: ignore_default_visibility}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: keepRevisionForever, var: keep_revision_forever}, {name: ocrLanguage, var: ocr_language}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: useContentAsIndexableText, var: use_content_as_indexable_text}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, enforce_single_parent: $enforce_single_parent, ignore_default_visibility: $ignore_default_visibility, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, keep_revision_forever: $keep_revision_forever, ocr_language: $ocr_language, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, use_content_as_indexable_text: $use_content_as_indexable_text, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a set of file IDs which can be provided in create or copy requests.
#
# GET /files/generateIds
# Returns: record<ids: list<string>, kind: string, space: string>
# operationId: drive.files.generateIds
export def "drive-files-generate-ids" [
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
  --count: int # The number of IDs to return.
  --space: string # The space in which the IDs can be used to create new files. Supported values are 'drive' and 'appDataFolder'. (Default: 'drive')
  --type: string # The type of items which the IDs can be used for. Supported values are 'files' and 'shortcuts'. Note that 'shortcuts' are only supported in the drive 'space'. (Default: 'files')
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/generateIds"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: count, var: count}, {name: space, var: space}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, count: $count, space: $space, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes all of the user's trashed files.
#
# DELETE /files/trash
# operationId: drive.files.emptyTrash
export def "drive-files-empty-trash" [
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
  --drive-id: string # If set, empties the trash of the provided shared drive.
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root.
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/trash"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: driveId, var: drive_id}, {name: enforceSingleParent, var: enforce_single_parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, drive_id: $drive_id, enforce_single_parent: $enforce_single_parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes a file owned by the user without moving it to the trash. If the file belongs to a shared drive the user must be an organizer on the parent. If the target is a folder, all descendants owned by the user are also deleted.
#
# DELETE /files/{fileId}
# operationId: drive.files.delete
export def "drive-files-delete" [
  file_id: string
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
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. If an item is not in a shared drive and its last parent is deleted but the item itself is not, the item will be placed under its owner's root.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: enforceSingleParent, var: enforce_single_parent}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, enforce_single_parent: $enforce_single_parent, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a file's metadata or content by ID.
#
# GET /files/{fileId}
# Returns: record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>
# operationId: drive.files.get
export def "drive-files-get" [
  file_id: string
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
  --acknowledge-abuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: acknowledgeAbuse, var: acknowledge_abuse}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, acknowledge_abuse: $acknowledge_abuse, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a file's metadata and/or content. When calling this method, only populate fields in the request that you want to modify. When updating fields, some fields might change automatically, such as modifiedDate. This method supports patch semantics.
#
# PATCH /files/{fileId}
# Returns: record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>
# operationId: drive.files.update
export def "drive-files-update" [
  file_id: string
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
  --add-parents: string # A comma-separated list of parent IDs to add.
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. Adding files to multiple folders is no longer supported. Use shortcuts instead.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keep-revision-forever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocr-language: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --remove-parents: string # A comma-separated list of parent IDs to remove.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --use-content-as-indexable-text: oneof<nothing, bool> # Whether to use the uploaded content as indexable text.
  --body: any
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: addParents, var: add_parents}, {name: enforceSingleParent, var: enforce_single_parent}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: keepRevisionForever, var: keep_revision_forever}, {name: ocrLanguage, var: ocr_language}, {name: removeParents, var: remove_parents}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: useContentAsIndexableText, var: use_content_as_indexable_text}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, add_parents: $add_parents, enforce_single_parent: $enforce_single_parent, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, keep_revision_forever: $keep_revision_forever, ocr_language: $ocr_language, remove_parents: $remove_parents, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, use_content_as_indexable_text: $use_content_as_indexable_text, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a file's comments.
#
# GET /files/{fileId}/comments
# Returns: record<comments: table<anchor: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record, replies: list, resolved: bool>, kind: string, nextPageToken: string>
# operationId: drive.comments.list
export def "drive-comments-list" [
  file_id: string
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
  --include-deleted: oneof<nothing, bool> # Whether to include deleted comments. Deleted comments will not include their original content.
  --page-size: int # The maximum number of comments to return per page.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --start-modified-time: string # The minimum value of 'modifiedTime' for the result comments (RFC 3339 date-time).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/comments"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: includeDeleted, var: include_deleted}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: startModifiedTime, var: start_modified_time}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, include_deleted: $include_deleted, page_size: $page_size, page_token: $page_token, start_modified_time: $start_modified_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a comment on a file.
#
# POST /files/{fileId}/comments
# Returns: record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>
# operationId: drive.comments.create
export def "drive-comments-create" [
  file_id: string
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
  --anchor: string # A region of the document represented as a JSON string. For details on defining anchor properties, refer to Add comments and replies.
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the comment. This field is used for setting the content, while htmlContent should be displayed.
  --created-time: string # The time at which the comment was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the comment has been deleted. A deleted comment has no content.
  --html-content: string # The content of the comment with HTML formatting.
  --id: string # The ID of the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#comment". (default: drive#comment)
  --modified-time: string # The last time the comment or any of its replies was modified (RFC 3339 date-time). (format: date-time)
  --quoted-file-content: record # The file content to which the comment refers, typically within the anchor region. For a text file, for example, this would be the text at the location of the comment. — shape: {mimeType?: string, value?: string}
  --replies: list # The full list of replies to the comment in chronological order. — item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
  --resolved: oneof<nothing, bool> # Whether the comment has been resolved by one of its replies.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/comments"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: anchor, var: anchor}, {name: author, var: author}, {name: content, var: content}, {name: createdTime, var: created_time}, {name: deleted, var: deleted}, {name: htmlContent, var: html_content}, {name: id, var: id}, {name: kind, var: kind}, {name: modifiedTime, var: modified_time}, {name: quotedFileContent, var: quoted_file_content}, {name: replies, var: replies}, {name: resolved, var: resolved}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, anchor: $anchor, author: $author, content: $content, created_time: $created_time, deleted: $deleted, html_content: $html_content, id: $id, kind: $kind, modified_time: $modified_time, quoted_file_content: $quoted_file_content, replies: $replies, resolved: $resolved
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a comment.
#
# DELETE /files/{fileId}/comments/{commentId}
# operationId: drive.comments.delete
export def "drive-comments-delete" [
  file_id: string
  comment_id: string
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
    path: "/files/{fileId}/comments/{commentId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a comment by ID.
#
# GET /files/{fileId}/comments/{commentId}
# Returns: record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>
# operationId: drive.comments.get
export def "drive-comments-get" [
  file_id: string
  comment_id: string
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
  --include-deleted: oneof<nothing, bool> # Whether to return deleted comments. Deleted comments will not include their original content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/comments/{commentId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a comment with patch semantics.
#
# PATCH /files/{fileId}/comments/{commentId}
# Returns: record<anchor: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string, quotedFileContent: record<mimeType: string, value: string>, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>, resolved: bool>
# operationId: drive.comments.update
export def "drive-comments-update" [
  file_id: string
  comment_id: string
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
  --anchor: string # A region of the document represented as a JSON string. For details on defining anchor properties, refer to Add comments and replies.
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the comment. This field is used for setting the content, while htmlContent should be displayed.
  --created-time: string # The time at which the comment was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the comment has been deleted. A deleted comment has no content.
  --html-content: string # The content of the comment with HTML formatting.
  --id: string # The ID of the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#comment". (default: drive#comment)
  --modified-time: string # The last time the comment or any of its replies was modified (RFC 3339 date-time). (format: date-time)
  --quoted-file-content: record # The file content to which the comment refers, typically within the anchor region. For a text file, for example, this would be the text at the location of the comment. — shape: {mimeType?: string, value?: string}
  --replies: list # The full list of replies to the comment in chronological order. — item shape: {action?: string, author?: record, content?: string, createdTime?: string, deleted?: bool, htmlContent?: string, id?: string, kind?: string, modifiedTime?: string}
  --resolved: oneof<nothing, bool> # Whether the comment has been resolved by one of its replies.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{fileId}/comments/{commentId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: anchor, var: anchor}, {name: author, var: author}, {name: content, var: content}, {name: createdTime, var: created_time}, {name: deleted, var: deleted}, {name: htmlContent, var: html_content}, {name: id, var: id}, {name: kind, var: kind}, {name: modifiedTime, var: modified_time}, {name: quotedFileContent, var: quoted_file_content}, {name: replies, var: replies}, {name: resolved, var: resolved}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, anchor: $anchor, author: $author, content: $content, created_time: $created_time, deleted: $deleted, html_content: $html_content, id: $id, kind: $kind, modified_time: $modified_time, quoted_file_content: $quoted_file_content, replies: $replies, resolved: $resolved
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a comment's replies.
#
# GET /files/{fileId}/comments/{commentId}/replies
# Returns: record<kind: string, nextPageToken: string, replies: table<action: string, author: record, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>>
# operationId: drive.replies.list
export def "drive-replies-list" [
  file_id: string
  comment_id: string
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
  --include-deleted: oneof<nothing, bool> # Whether to include deleted replies. Deleted replies will not include their original content.
  --page-size: int # The maximum number of replies to return per page.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/comments/{commentId}/replies"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: includeDeleted, var: include_deleted}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, include_deleted: $include_deleted, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a reply to a comment.
#
# POST /files/{fileId}/comments/{commentId}/replies
# Returns: record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>
# operationId: drive.replies.create
export def "drive-replies-create" [
  file_id: string
  comment_id: string
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
  --action: string # The action the reply performed to the parent comment. Valid values are: - resolve - reopen
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the reply. This field is used for setting the content, while htmlContent should be displayed. This is required on creates if no action is specified.
  --created-time: string # The time at which the reply was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the reply has been deleted. A deleted reply has no content.
  --html-content: string # The content of the reply with HTML formatting.
  --id: string # The ID of the reply.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#reply". (default: drive#reply)
  --modified-time: string # The last time the reply was modified (RFC 3339 date-time). (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/comments/{commentId}/replies"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: author, var: author}, {name: content, var: content}, {name: createdTime, var: created_time}, {name: deleted, var: deleted}, {name: htmlContent, var: html_content}, {name: id, var: id}, {name: kind, var: kind}, {name: modifiedTime, var: modified_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, action: $action, author: $author, content: $content, created_time: $created_time, deleted: $deleted, html_content: $html_content, id: $id, kind: $kind, modified_time: $modified_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a reply.
#
# DELETE /files/{fileId}/comments/{commentId}/replies/{replyId}
# operationId: drive.replies.delete
export def "drive-replies-delete" [
  file_id: string
  comment_id: string
  reply_id: string
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
    path: "/files/{fileId}/comments/{commentId}/replies/{replyId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}, {name: replyId, var: reply_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, reply_id: $reply_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a reply by ID.
#
# GET /files/{fileId}/comments/{commentId}/replies/{replyId}
# Returns: record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>
# operationId: drive.replies.get
export def "drive-replies-get" [
  file_id: string
  comment_id: string
  reply_id: string
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
  --include-deleted: oneof<nothing, bool> # Whether to return deleted replies. Deleted replies will not include their original content.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/comments/{commentId}/replies/{replyId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}, {name: replyId, var: reply_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, reply_id: $reply_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a reply with patch semantics.
#
# PATCH /files/{fileId}/comments/{commentId}/replies/{replyId}
# Returns: record<action: string, author: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, content: string, createdTime: string, deleted: bool, htmlContent: string, id: string, kind: string, modifiedTime: string>
# operationId: drive.replies.update
export def "drive-replies-update" [
  file_id: string
  comment_id: string
  reply_id: string
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
  --action: string # The action the reply performed to the parent comment. Valid values are: - resolve - reopen
  --author: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --content: string # The plain text content of the reply. This field is used for setting the content, while htmlContent should be displayed. This is required on creates if no action is specified.
  --created-time: string # The time at which the reply was created (RFC 3339 date-time). (format: date-time)
  --deleted: oneof<nothing, bool> # Whether the reply has been deleted. A deleted reply has no content.
  --html-content: string # The content of the reply with HTML formatting.
  --id: string # The ID of the reply.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#reply". (default: drive#reply)
  --modified-time: string # The last time the reply was modified (RFC 3339 date-time). (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{fileId}/comments/{commentId}/replies/{replyId}"
    path_params: [{name: fileId, var: file_id}, {name: commentId, var: comment_id}, {name: replyId, var: reply_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: author, var: author}, {name: content, var: content}, {name: createdTime, var: created_time}, {name: deleted, var: deleted}, {name: htmlContent, var: html_content}, {name: id, var: id}, {name: kind, var: kind}, {name: modifiedTime, var: modified_time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, comment_id: $comment_id, reply_id: $reply_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, action: $action, author: $author, content: $content, created_time: $created_time, deleted: $deleted, html_content: $html_content, id: $id, kind: $kind, modified_time: $modified_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a copy of a file and applies any requested updates with patch semantics. Folders cannot be copied.
#
# POST /files/{fileId}/copy
# Returns: record<appProperties: record, capabilities: record<canAcceptOwnership: bool, canAddChildren: bool, canAddFolderFromAnotherDrive: bool, canAddMyDriveParent: bool, canChangeCopyRequiresWriterPermission: bool, canChangeSecurityUpdateEnabled: bool, canChangeViewersCanCopyContent: bool, canComment: bool, canCopy: bool, canDelete: bool, canDeleteChildren: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canModifyContent: bool, canModifyContentRestriction: bool, canModifyLabels: bool, canMoveChildrenOutOfDrive: bool, canMoveChildrenOutOfTeamDrive: bool, canMoveChildrenWithinDrive: bool, canMoveChildrenWithinTeamDrive: bool, canMoveItemIntoTeamDrive: bool, canMoveItemOutOfDrive: bool, canMoveItemOutOfTeamDrive: bool, canMoveItemWithinDrive: bool, canMoveItemWithinTeamDrive: bool, canMoveTeamDriveItem: bool, canReadDrive: bool, canReadLabels: bool, canReadRevisions: bool, canReadTeamDrive: bool, canRemoveChildren: bool, canRemoveMyDriveParent: bool, canRename: bool, canShare: bool, canTrash: bool, canTrashChildren: bool, canUntrash: bool>, contentHints: record<indexableText: string, thumbnail: record<image: string, mimeType: string>>, contentRestrictions: table<readOnly: bool, reason: string, restrictingUser: record, restrictionTime: string, type: string>, copyRequiresWriterPermission: bool, createdTime: string, description: string, driveId: string, explicitlyTrashed: bool, exportLinks: record, fileExtension: string, folderColorRgb: string, fullFileExtension: string, hasAugmentedPermissions: bool, hasThumbnail: bool, headRevisionId: string, iconLink: string, id: string, imageMediaMetadata: record<aperture: float, cameraMake: string, cameraModel: string, colorSpace: string, exposureBias: float, exposureMode: string, exposureTime: float, flashUsed: bool, focalLength: float, height: int, isoSpeed: int, lens: string, location: record<altitude: float, latitude: float, longitude: float>, maxApertureValue: float, meteringMode: string, rotation: int, sensor: string, subjectDistance: int, time: string, whiteBalance: string, width: int>, isAppAuthorized: bool, kind: string, labelInfo: record<labels: list<record>>, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, linkShareMetadata: record<securityUpdateEligible: bool, securityUpdateEnabled: bool>, md5Checksum: string, mimeType: string, modifiedByMe: bool, modifiedByMeTime: string, modifiedTime: string, name: string, originalFilename: string, ownedByMe: bool, owners: table<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, parents: list<string>, permissionIds: list<string>, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>, properties: record, quotaBytesUsed: string, resourceKey: string, sha1Checksum: string, sha256Checksum: string, shared: bool, sharedWithMeTime: string, sharingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, shortcutDetails: record<targetId: string, targetMimeType: string, targetResourceKey: string>, size: string, spaces: list<string>, starred: bool, teamDriveId: string, thumbnailLink: string, thumbnailVersion: string, trashed: bool, trashedTime: string, trashingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, version: string, videoMediaMetadata: record<durationMillis: string, height: int, width: int>, viewedByMe: bool, viewedByMeTime: string, viewersCanCopyContent: bool, webContentLink: string, webViewLink: string, writersCanShare: bool>
# operationId: drive.files.copy
export def "drive-files-copy" [
  file_id: string
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
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. Copying files into multiple folders is no longer supported. Use shortcuts instead.
  --ignore-default-visibility: oneof<nothing, bool> # Whether to ignore the domain's default visibility settings for the created file. Domain administrators can choose to make all uploaded files visible to the domain by default; this parameter bypasses that behavior for the request. Permissions are still inherited from parent folders.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --keep-revision-forever: oneof<nothing, bool> # Whether to set the 'keepForever' field in the new head revision. This is only applicable to files with binary content in Google Drive. Only 200 revisions for the file can be kept forever. If the limit is reached, try deleting pinned revisions.
  --ocr-language: string # A language hint for OCR processing during image import (ISO 639-1 code).
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --app-properties: record # A collection of arbitrary key-value pairs that are private to the requesting app. Entries with null values are cleared in update and copy requests. These properties can only be retrieved using an authenticated request. An authenticated request uses an access token obtained with an OAuth 2 client ID. You cannot use an API key to retrieve private properties.
  --capabilities: record # Capabilities the current user has on this file. Each capability corresponds to a fine-grained action that a user can take. — shape: {canAcceptOwnership?: bool, canAddChildren?: bool, canAddFolderFromAnotherDrive?: bool, canAddMyDriveParent?: bool, canChangeCopyRequiresWriterPermission?: bool, canChangeSecurityUpdateEnabled?: bool, canChangeViewersCanCopyContent?: bool, canComment?: bool, canCopy?: bool, canDelete?: bool, canDeleteChildren?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canModifyContent?: bool, canModifyContentRestriction?: bool, canModifyLabels?: bool, canMoveChildrenOutOfDrive?: bool, ... (20 more fields)}
  --content-hints: record # Additional information about the content of the file. These fields are never populated in responses. — shape: {indexableText?: string, thumbnail?: record}
  --content-restrictions: list # Restrictions for accessing the content of the file. Only populated if such a restriction exists. — item shape: {readOnly?: bool, reason?: string, restrictingUser?: record, restrictionTime?: string, type?: string}
  --copy-requires-writer-permission: oneof<nothing, bool> # Whether the options to copy, print, or download this file, should be disabled for readers and commenters.
  --created-time: string # The time at which the file was created (RFC 3339 date-time). (format: date-time)
  --description: string # A short description of the file.
  --drive-id: string # ID of the shared drive the file resides in. Only populated for items in shared drives.
  --explicitly-trashed: oneof<nothing, bool> # Whether the file has been explicitly trashed, as opposed to recursively trashed from a parent folder.
  --file-extension: string # The final component of fullFileExtension. This is only available for files with binary content in Google Drive.
  --folder-color-rgb: string # The color for a folder or shortcut to a folder as an RGB hex string. The supported colors are published in the folderColorPalette field of the About resource. If an unsupported color is specified, the closest color in the palette will be used instead.
  --full-file-extension: string # The full file extension extracted from the name field. Can contain multiple concatenated extensions, such as "tar.gz". This is only available for files with binary content in Google Drive. This is automatically updated when the name field changes, however it's not cleared if the new name does not contain a valid extension.
  --has-augmented-permissions: oneof<nothing, bool> # Whether there are permissions directly on this file. This field is only populated for items in shared drives.
  --has-thumbnail: oneof<nothing, bool> # Whether this file has a thumbnail. This does not indicate whether the requesting app has access to the thumbnail. To check access, look for the presence of the thumbnailLink field.
  --head-revision-id: string # The ID of the file's head revision. This is only available for files with binary content in Google Drive.
  --icon-link: string # A static, unauthenticated link to the file's icon.
  --id: string # The ID of the file.
  --image-media-metadata: record # Additional metadata about image media, if available. — shape: {aperture?: float, cameraMake?: string, cameraModel?: string, colorSpace?: string, exposureBias?: float, exposureMode?: string, exposureTime?: float, flashUsed?: bool, focalLength?: float, height?: int, isoSpeed?: int, lens?: string, location?: record, maxApertureValue?: float, meteringMode?: string, rotation?: int, sensor?: string, subjectDistance?: int, time?: string, whiteBalance?: string, width?: int}
  --is-app-authorized: oneof<nothing, bool> # Whether the requesting app created or opened the file.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#file". (default: drive#file)
  --label-info: record # An overview of the labels on the file. — shape: {labels?: list}
  --last-modifying-user: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --link-share-metadata: record # Contains details about the link URLs that clients are using to refer to this item. — shape: {securityUpdateEligible?: bool, securityUpdateEnabled?: bool}
  --md5-checksum: string # The MD5 checksum for the content of the file. This is only applicable to files with binary content in Google Drive.
  --mime-type: string # The MIME type of the file. Google Drive will attempt to automatically detect an appropriate value from uploaded content if no value is provided. The value cannot be changed unless a new revision is uploaded. If a file is created with a Google Doc MIME type, the uploaded content will be imported if possible. The supported import formats are published in the About resource.
  --modified-by-me: oneof<nothing, bool> # Whether this user has modified the file.
  --modified-by-me-time: string # The last time the user modified the file (RFC 3339 date-time). (format: date-time)
  --modified-time: string # The last time anyone modified the file (RFC 3339 date-time). Note that setting modifiedTime will also update modifiedByMeTime for the user. (format: date-time)
  --name: string # The name of the file. This isn't necessarily unique within a folder. Note that for immutable items such as the top-level folders of shared drives, My Drive root folder, and Application Data folder the name is constant.
  --original-filename: string # The original filename of the uploaded content if available, or else the original value of the name field. This is only available for files with binary content in Google Drive.
  --owned-by-me: oneof<nothing, bool> # Whether the user owns the file. Not populated for items in shared drives.
  --owners: list # The owner of this file. Only certain legacy files might have more than one owner. This field isn't populated for items in shared drives. — item shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --parents: list<string> # The IDs of the parent folders that contain the file. If not specified as part of a create request, the file will be placed directly in the user's My Drive folder. If not specified as part of a copy request, the file will inherit any discoverable parents of the source file. Update requests must use the addParents and removeParents parameters to modify the parents list.
  --permission-ids: list<string> # List of permission IDs for users with access to this file.
  --permissions: list # The full list of permissions for the file. This is only available if the requesting user can share the file. Not populated for items in shared drives. — item shape: {allowFileDiscovery?: bool, deleted?: bool, displayName?: string, domain?: string, emailAddress?: string, expirationTime?: string, id?: string, kind?: string, pendingOwner?: bool, photoLink?: string, role?: string, type?: string, view?: string}
  --properties: record # A collection of arbitrary key-value pairs that are visible to all apps. Entries with null values are cleared in update and copy requests.
  --quota-bytes-used: string # The number of storage quota bytes used by the file. This includes the head revision as well as previous revisions with keepForever enabled. (format: int64)
  --resource-key: string # A key needed to access the item via a shared link.
  --sha1-checksum: string # The SHA1 checksum associated with this file, if available. This field is only populated for files with content stored in Google Drive; it's not populated for Docs Editors or shortcut files.
  --sha256-checksum: string # The SHA256 checksum associated with this file, if available. This field is only populated for files with content stored in Google Drive; it's not populated for Docs Editors or shortcut files.
  --shared: oneof<nothing, bool> # Whether the file has been shared. Not populated for items in shared drives.
  --shared-with-me-time: string # The time at which the file was shared with the user, if applicable (RFC 3339 date-time). (format: date-time)
  --sharing-user: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --shortcut-details: record # Shortcut file details. Only populated for shortcut files, which have the mimeType field set to application/vnd.google-apps.shortcut. — shape: {targetId?: string, targetMimeType?: string, targetResourceKey?: string}
  --size: string # The size of the file's content in bytes. This field is populated for files with binary content stored in Google Drive and for Docs Editors files; it's not populated for shortcuts or folders. (format: int64)
  --spaces: list<string> # The list of spaces that contain the file. The currently supported values are 'drive', 'appDataFolder' and 'photos'.
  --starred: oneof<nothing, bool> # Whether the user has starred the file.
  --team-drive-id: string # Deprecated - use driveId instead.
  --thumbnail-link: string # A short-lived link to the file's thumbnail, if available. Typically lasts on the order of hours. Only populated when the requesting app can access the file's content. If the file isn't shared publicly, the URL returned in Files.thumbnailLink must be fetched using a credentialed request.
  --thumbnail-version: string # The thumbnail version for use in thumbnail cache invalidation. (format: int64)
  --trashed: oneof<nothing, bool> # Whether the file has been trashed, either explicitly or from a trashed parent folder. Only the owner can trash a file. The trashed item is excluded from all files.list responses returned for any user who does not own the file. However, all users with access to the file can see the trashed item metadata in an API response. All users with access can copy, download, export, and share the file.
  --trashed-time: string # The time that the item was trashed (RFC 3339 date-time). Only populated for items in shared drives. (format: date-time)
  --trashing-user: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --version: string # A monotonically increasing version number for the file. This reflects every change made to the file on the server, even those not visible to the user. (format: int64)
  --video-media-metadata: record # Additional metadata about video media. This might not be available immediately upon upload. — shape: {durationMillis?: string, height?: int, width?: int}
  --viewed-by-me: oneof<nothing, bool> # Whether this user has viewed the file.
  --viewed-by-me-time: string # The last time the user viewed the file (RFC 3339 date-time). (format: date-time)
  --viewers-can-copy-content: oneof<nothing, bool> # Deprecated - use copyRequiresWriterPermission instead.
  --web-content-link: string # A link for downloading the content of the file in a browser. This is only available for files with binary content in Google Drive.
  --web-view-link: string # A link for opening the file in a relevant Google editor or viewer in a browser.
  --writers-can-share: oneof<nothing, bool> # Whether users with only writer permission can modify the file's permissions. Not populated for items in shared drives.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/copy"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: enforceSingleParent, var: enforce_single_parent}, {name: ignoreDefaultVisibility, var: ignore_default_visibility}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: keepRevisionForever, var: keep_revision_forever}, {name: ocrLanguage, var: ocr_language}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}]
    body: {content_type: "application/json", kind: json, fields: [{name: appProperties, var: app_properties}, {name: capabilities, var: capabilities}, {name: contentHints, var: content_hints}, {name: contentRestrictions, var: content_restrictions}, {name: copyRequiresWriterPermission, var: copy_requires_writer_permission}, {name: createdTime, var: created_time}, {name: description, var: description}, {name: driveId, var: drive_id}, {name: explicitlyTrashed, var: explicitly_trashed}, {name: fileExtension, var: file_extension}, {name: folderColorRgb, var: folder_color_rgb}, {name: fullFileExtension, var: full_file_extension}, {name: hasAugmentedPermissions, var: has_augmented_permissions}, {name: hasThumbnail, var: has_thumbnail}, {name: headRevisionId, var: head_revision_id}, {name: iconLink, var: icon_link}, {name: id, var: id}, {name: imageMediaMetadata, var: image_media_metadata}, {name: isAppAuthorized, var: is_app_authorized}, {name: kind, var: kind}, {name: labelInfo, var: label_info}, {name: lastModifyingUser, var: last_modifying_user}, {name: linkShareMetadata, var: link_share_metadata}, {name: md5Checksum, var: md5_checksum}, {name: mimeType, var: mime_type}, {name: modifiedByMe, var: modified_by_me}, {name: modifiedByMeTime, var: modified_by_me_time}, {name: modifiedTime, var: modified_time}, {name: name, var: name}, {name: originalFilename, var: original_filename}, {name: ownedByMe, var: owned_by_me}, {name: owners, var: owners}, {name: parents, var: parents}, {name: permissionIds, var: permission_ids}, {name: permissions, var: permissions}, {name: properties, var: properties}, {name: quotaBytesUsed, var: quota_bytes_used}, {name: resourceKey, var: resource_key}, {name: sha1Checksum, var: sha1_checksum}, {name: sha256Checksum, var: sha256_checksum}, {name: shared, var: shared}, {name: sharedWithMeTime, var: shared_with_me_time}, {name: sharingUser, var: sharing_user}, {name: shortcutDetails, var: shortcut_details}, {name: size, var: size}, {name: spaces, var: spaces}, {name: starred, var: starred}, {name: teamDriveId, var: team_drive_id}, {name: thumbnailLink, var: thumbnail_link}, {name: thumbnailVersion, var: thumbnail_version}, {name: trashed, var: trashed}, {name: trashedTime, var: trashed_time}, {name: trashingUser, var: trashing_user}, {name: version, var: version}, {name: videoMediaMetadata, var: video_media_metadata}, {name: viewedByMe, var: viewed_by_me}, {name: viewedByMeTime, var: viewed_by_me_time}, {name: viewersCanCopyContent, var: viewers_can_copy_content}, {name: webContentLink, var: web_content_link}, {name: webViewLink, var: web_view_link}, {name: writersCanShare, var: writers_can_share}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, enforce_single_parent: $enforce_single_parent, ignore_default_visibility: $ignore_default_visibility, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, keep_revision_forever: $keep_revision_forever, ocr_language: $ocr_language, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, app_properties: $app_properties, capabilities: $capabilities, content_hints: $content_hints, content_restrictions: $content_restrictions, copy_requires_writer_permission: $copy_requires_writer_permission, created_time: $created_time, description: $description, drive_id: $drive_id, explicitly_trashed: $explicitly_trashed, file_extension: $file_extension, folder_color_rgb: $folder_color_rgb, full_file_extension: $full_file_extension, has_augmented_permissions: $has_augmented_permissions, has_thumbnail: $has_thumbnail, head_revision_id: $head_revision_id, icon_link: $icon_link, id: $id, image_media_metadata: $image_media_metadata, is_app_authorized: $is_app_authorized, kind: $kind, label_info: $label_info, last_modifying_user: $last_modifying_user, link_share_metadata: $link_share_metadata, md5_checksum: $md5_checksum, mime_type: $mime_type, modified_by_me: $modified_by_me, modified_by_me_time: $modified_by_me_time, modified_time: $modified_time, name: $name, original_filename: $original_filename, owned_by_me: $owned_by_me, owners: $owners, parents: $parents, permission_ids: $permission_ids, permissions: $permissions, properties: $properties, quota_bytes_used: $quota_bytes_used, resource_key: $resource_key, sha1_checksum: $sha1_checksum, sha256_checksum: $sha256_checksum, shared: $shared, shared_with_me_time: $shared_with_me_time, sharing_user: $sharing_user, shortcut_details: $shortcut_details, size: $size, spaces: $spaces, starred: $starred, team_drive_id: $team_drive_id, thumbnail_link: $thumbnail_link, thumbnail_version: $thumbnail_version, trashed: $trashed, trashed_time: $trashed_time, trashing_user: $trashing_user, version: $version, video_media_metadata: $video_media_metadata, viewed_by_me: $viewed_by_me, viewed_by_me_time: $viewed_by_me_time, viewers_can_copy_content: $viewers_can_copy_content, web_content_link: $web_content_link, web_view_link: $web_view_link, writers_can_share: $writers_can_share
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exports a Google Workspace document to the requested MIME type and returns exported byte content. Note that the exported content is limited to 10MB.
#
# GET /files/{fileId}/export
# operationId: drive.files.export
export def "drive-files-export" [
  file_id: string
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
  --mime-type: string # The MIME type of the format requested for this export. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/files/{fileId}/export"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: mimeType, var: mime_type, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, mime_type: $mime_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the labels on a file.
#
# GET /files/{fileId}/listLabels
# Returns: record<kind: string, labels: table<fields: record, id: string, kind: string, revisionId: string>, nextPageToken: string>
# operationId: drive.files.listLabels
export def "drive-files-list-labels" [
  file_id: string
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
  --max-results: int # The maximum number of labels to return per page. When not set, this defaults to 100.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/listLabels"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modifies the set of labels on a file.
#
# POST /files/{fileId}/modifyLabels
# Returns: record<kind: string, modifiedLabels: table<fields: record, id: string, kind: string, revisionId: string>>
# operationId: drive.files.modifyLabels
export def "drive-files-modify-labels" [
  file_id: string
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
  --kind: string # This is always drive#modifyLabelsRequest (default: drive#modifyLabelsRequest)
  --label-modifications: list # The list of modifications to apply to the labels on the file. — item shape: {fieldModifications?: list, kind?: string, labelId?: string, removeLabel?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/modifyLabels"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: kind, var: kind}, {name: labelModifications, var: label_modifications}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, kind: $kind, label_modifications: $label_modifications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a file's or shared drive's permissions.
#
# GET /files/{fileId}/permissions
# Returns: record<kind: string, nextPageToken: string, permissions: table<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: list, photoLink: string, role: string, teamDrivePermissionDetails: list, type: string, view: string>>
# operationId: drive.permissions.list
export def "drive-permissions-list" [
  file_id: string
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
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --page-size: int # The maximum number of permissions to return per page. When not set for files in a shared drive, at most 100 results will be returned. When not set for files that are not in a shared drive, the entire list will be returned.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/permissions"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, include_permissions_for_view: $include_permissions_for_view, page_size: $page_size, page_token: $page_token, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a permission for a file or shared drive. For more information on creating permissions, see Share files, folders & drives.
#
# POST /files/{fileId}/permissions
# Returns: record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>
# operationId: drive.permissions.create
export def "drive-permissions-create" [
  file_id: string
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
  --email-message: string # A plain text custom message to include in the notification email.
  --enforce-single-parent: oneof<nothing, bool> # Deprecated. See moveToNewOwnersRoot for details.
  --move-to-new-owners-root: oneof<nothing, bool> # This parameter will only take effect if the item is not in a shared drive and the request is attempting to transfer the ownership of the item. If set to true, the item will be moved to the new owner's My Drive root folder and all prior parents removed. If set to false, parents are not changed.
  --send-notification-email: oneof<nothing, bool> # Whether to send a notification email when sharing to users or groups. This defaults to true for users and groups, and is not allowed for other requests. It must not be disabled for ownership transfers.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --transfer-ownership: oneof<nothing, bool> # Whether to transfer ownership to the specified user and downgrade the current owner to a writer. This parameter is required as an acknowledgement of the side effect. File owners can only transfer ownership of files existing on My Drive. Files existing in a shared drive are owned by the organization that owns that shared drive. Ownership transfers are not supported for files and folders in shared drives. Organizers of a shared drive can move items from that shared drive into their My Drive which transfers the ownership to them.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
  --allow-file-discovery: oneof<nothing, bool> # Whether the permission allows the file to be discovered through search. This is only applicable for permissions of type domain or anyone.
  --deleted: oneof<nothing, bool> # Whether the account associated with this permission has been deleted. This field only pertains to user and group permissions.
  --display-name: string # The "pretty" name of the value of the permission. The following is a list of examples for each type of permission: - user - User's full name, as defined for their Google Account, such as "Joe Smith." - group - Name of the Google Group, such as "The Company Administrators." - domain - String domain name, such as "your-company.com." - anyone - No displayName is present.
  --domain: string # The domain to which this permission refers. The following options are currently allowed: - The entire domain, such as "your-company.com." - A target audience, such as "ID.audience.googledomains.com."
  --email-address: string # The email address of the user or group to which this permission refers.
  --expiration-time: string # The time at which this permission will expire (RFC 3339 date-time). Expiration times have the following restrictions: - They cannot be set on shared drive items. - They can only be set on user and group permissions. - The time must be in the future. - The time cannot be more than one year in the future. (format: date-time)
  --id: string # The ID of this permission. This is a unique identifier for the grantee, and is published in User resources as permissionId. IDs should be treated as opaque values.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#permission". (default: drive#permission)
  --pending-owner: oneof<nothing, bool> # Whether the account associated with this permission is a pending owner. Only populated for user type permissions for files that aren't in a shared drive.
  --photo-link: string # A link to the user's profile photo, if available.
  --role: string # The role granted by this permission. While new values may be supported in the future, the following are currently allowed: - owner - organizer - fileOrganizer - writer - commenter - reader
  --type: string # The type of the grantee. Valid values are: - user - group - domain - anyone When creating a permission, if type is user or group, you must provide an emailAddress for the user or group. When type is domain, you must provide a domain. There isn't extra information required for the anyone type.
  --view: string # Indicates the view for this permission. Only populated for permissions that belong to a view. published is the only supported value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/permissions"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: emailMessage, var: email_message}, {name: enforceSingleParent, var: enforce_single_parent}, {name: moveToNewOwnersRoot, var: move_to_new_owners_root}, {name: sendNotificationEmail, var: send_notification_email}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: transferOwnership, var: transfer_ownership}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowFileDiscovery, var: allow_file_discovery}, {name: deleted, var: deleted}, {name: displayName, var: display_name}, {name: domain, var: domain}, {name: emailAddress, var: email_address}, {name: expirationTime, var: expiration_time}, {name: id, var: id}, {name: kind, var: kind}, {name: pendingOwner, var: pending_owner}, {name: photoLink, var: photo_link}, {name: role, var: role}, {name: type, var: type}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, email_message: $email_message, enforce_single_parent: $enforce_single_parent, move_to_new_owners_root: $move_to_new_owners_root, send_notification_email: $send_notification_email, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, transfer_ownership: $transfer_ownership, use_domain_admin_access: $use_domain_admin_access, allow_file_discovery: $allow_file_discovery, deleted: $deleted, display_name: $display_name, domain: $domain, email_address: $email_address, expiration_time: $expiration_time, id: $id, kind: $kind, pending_owner: $pending_owner, photo_link: $photo_link, role: $role, type: $type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a permission.
#
# DELETE /files/{fileId}/permissions/{permissionId}
# operationId: drive.permissions.delete
export def "drive-permissions-delete" [
  file_id: string
  permission_id: string
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
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/{fileId}/permissions/{permissionId}"
    path_params: [{name: fileId, var: file_id}, {name: permissionId, var: permission_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, permission_id: $permission_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a permission by ID.
#
# GET /files/{fileId}/permissions/{permissionId}
# Returns: record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>
# operationId: drive.permissions.get
export def "drive-permissions-get" [
  file_id: string
  permission_id: string
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
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/permissions/{permissionId}"
    path_params: [{name: fileId, var: file_id}, {name: permissionId, var: permission_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, permission_id: $permission_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a permission with patch semantics.
#
# PATCH /files/{fileId}/permissions/{permissionId}
# Returns: record<allowFileDiscovery: bool, deleted: bool, displayName: string, domain: string, emailAddress: string, expirationTime: string, id: string, kind: string, pendingOwner: bool, permissionDetails: table<inherited: bool, inheritedFrom: string, permissionType: string, role: string>, photoLink: string, role: string, teamDrivePermissionDetails: table<inherited: bool, inheritedFrom: string, role: string, teamDrivePermissionType: string>, type: string, view: string>
# operationId: drive.permissions.update
export def "drive-permissions-update" [
  file_id: string
  permission_id: string
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
  --remove-expiration: oneof<nothing, bool> # Whether to remove the expiration date.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --transfer-ownership: oneof<nothing, bool> # Whether to transfer ownership to the specified user and downgrade the current owner to a writer. This parameter is required as an acknowledgement of the side effect. File owners can only transfer ownership of files existing on My Drive. Files existing in a shared drive are owned by the organization that owns that shared drive. Ownership transfers are not supported for files and folders in shared drives. Organizers of a shared drive can move items from that shared drive into their My Drive which transfers the ownership to them.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if the file ID parameter refers to a shared drive and the requester is an administrator of the domain to which the shared drive belongs.
  --allow-file-discovery: oneof<nothing, bool> # Whether the permission allows the file to be discovered through search. This is only applicable for permissions of type domain or anyone.
  --deleted: oneof<nothing, bool> # Whether the account associated with this permission has been deleted. This field only pertains to user and group permissions.
  --display-name: string # The "pretty" name of the value of the permission. The following is a list of examples for each type of permission: - user - User's full name, as defined for their Google Account, such as "Joe Smith." - group - Name of the Google Group, such as "The Company Administrators." - domain - String domain name, such as "your-company.com." - anyone - No displayName is present.
  --domain: string # The domain to which this permission refers. The following options are currently allowed: - The entire domain, such as "your-company.com." - A target audience, such as "ID.audience.googledomains.com."
  --email-address: string # The email address of the user or group to which this permission refers.
  --expiration-time: string # The time at which this permission will expire (RFC 3339 date-time). Expiration times have the following restrictions: - They cannot be set on shared drive items. - They can only be set on user and group permissions. - The time must be in the future. - The time cannot be more than one year in the future. (format: date-time)
  --id: string # The ID of this permission. This is a unique identifier for the grantee, and is published in User resources as permissionId. IDs should be treated as opaque values.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#permission". (default: drive#permission)
  --pending-owner: oneof<nothing, bool> # Whether the account associated with this permission is a pending owner. Only populated for user type permissions for files that aren't in a shared drive.
  --photo-link: string # A link to the user's profile photo, if available.
  --role: string # The role granted by this permission. While new values may be supported in the future, the following are currently allowed: - owner - organizer - fileOrganizer - writer - commenter - reader
  --type: string # The type of the grantee. Valid values are: - user - group - domain - anyone When creating a permission, if type is user or group, you must provide an emailAddress for the user or group. When type is domain, you must provide a domain. There isn't extra information required for the anyone type.
  --view: string # Indicates the view for this permission. Only populated for permissions that belong to a view. published is the only supported value.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{fileId}/permissions/{permissionId}"
    path_params: [{name: fileId, var: file_id}, {name: permissionId, var: permission_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: removeExpiration, var: remove_expiration}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}, {name: transferOwnership, var: transfer_ownership}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowFileDiscovery, var: allow_file_discovery}, {name: deleted, var: deleted}, {name: displayName, var: display_name}, {name: domain, var: domain}, {name: emailAddress, var: email_address}, {name: expirationTime, var: expiration_time}, {name: id, var: id}, {name: kind, var: kind}, {name: pendingOwner, var: pending_owner}, {name: photoLink, var: photo_link}, {name: role, var: role}, {name: type, var: type}, {name: view, var: view}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, permission_id: $permission_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, remove_expiration: $remove_expiration, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, transfer_ownership: $transfer_ownership, use_domain_admin_access: $use_domain_admin_access, allow_file_discovery: $allow_file_discovery, deleted: $deleted, display_name: $display_name, domain: $domain, email_address: $email_address, expiration_time: $expiration_time, id: $id, kind: $kind, pending_owner: $pending_owner, photo_link: $photo_link, role: $role, type: $type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a file's revisions.
#
# GET /files/{fileId}/revisions
# Returns: record<kind: string, nextPageToken: string, revisions: table<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>>
# operationId: drive.revisions.list
export def "drive-revisions-list" [
  file_id: string
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
  --page-size: int # The maximum number of revisions to return per page.
  --page-token: string # The token for continuing a previous list request on the next page. This should be set to the value of 'nextPageToken' from the previous response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/revisions"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes a file version. You can only delete revisions for files with binary content in Google Drive, like images or videos. Revisions for other files, like Google Docs or Sheets, and the last remaining file version can't be deleted.
#
# DELETE /files/{fileId}/revisions/{revisionId}
# operationId: drive.revisions.delete
export def "drive-revisions-delete" [
  file_id: string
  revision_id: string
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
    path: "/files/{fileId}/revisions/{revisionId}"
    path_params: [{name: fileId, var: file_id}, {name: revisionId, var: revision_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, revision_id: $revision_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a revision's metadata or content by ID.
#
# GET /files/{fileId}/revisions/{revisionId}
# Returns: record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>
# operationId: drive.revisions.get
export def "drive-revisions-get" [
  file_id: string
  revision_id: string
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
  --acknowledge-abuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/{fileId}/revisions/{revisionId}"
    path_params: [{name: fileId, var: file_id}, {name: revisionId, var: revision_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: acknowledgeAbuse, var: acknowledge_abuse}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, revision_id: $revision_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, acknowledge_abuse: $acknowledge_abuse
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a revision with patch semantics.
#
# PATCH /files/{fileId}/revisions/{revisionId}
# Returns: record<exportLinks: record, id: string, keepForever: bool, kind: string, lastModifyingUser: record<displayName: string, emailAddress: string, kind: string, me: bool, permissionId: string, photoLink: string>, md5Checksum: string, mimeType: string, modifiedTime: string, originalFilename: string, publishAuto: bool, published: bool, publishedLink: string, publishedOutsideDomain: bool, size: string>
# operationId: drive.revisions.update
export def "drive-revisions-update" [
  file_id: string
  revision_id: string
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
  --export-links: record # Links for exporting Docs Editors files to specific formats.
  --id: string # The ID of the revision.
  --keep-forever: oneof<nothing, bool> # Whether to keep this revision forever, even if it is no longer the head revision. If not set, the revision will be automatically purged 30 days after newer content is uploaded. This can be set on a maximum of 200 revisions for a file. This field is only applicable to files with binary content in Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#revision". (default: drive#revision)
  --last-modifying-user: record # Information about a Drive user. — shape: {displayName?: string, emailAddress?: string, kind?: string, me?: bool, permissionId?: string, photoLink?: string}
  --md5-checksum: string # The MD5 checksum of the revision's content. This is only applicable to files with binary content in Drive.
  --mime-type: string # The MIME type of the revision.
  --modified-time: string # The last time the revision was modified (RFC 3339 date-time). (format: date-time)
  --original-filename: string # The original filename used to create this revision. This is only applicable to files with binary content in Drive.
  --publish-auto: oneof<nothing, bool> # Whether subsequent revisions will be automatically republished. This is only applicable to Docs Editors files.
  --published: oneof<nothing, bool> # Whether this revision is published. This is only applicable to Docs Editors files.
  --published-link: string # A link to the published revision. This is only populated for Google Sites files.
  --published-outside-domain: oneof<nothing, bool> # Whether this revision is published outside the domain. This is only applicable to Docs Editors files.
  --size: string # The size of the revision's content in bytes. This is only applicable to files with binary content in Drive. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/{fileId}/revisions/{revisionId}"
    path_params: [{name: fileId, var: file_id}, {name: revisionId, var: revision_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    body: {content_type: "application/json", kind: json, fields: [{name: exportLinks, var: export_links}, {name: id, var: id}, {name: keepForever, var: keep_forever}, {name: kind, var: kind}, {name: lastModifyingUser, var: last_modifying_user}, {name: md5Checksum, var: md5_checksum}, {name: mimeType, var: mime_type}, {name: modifiedTime, var: modified_time}, {name: originalFilename, var: original_filename}, {name: publishAuto, var: publish_auto}, {name: published, var: published}, {name: publishedLink, var: published_link}, {name: publishedOutsideDomain, var: published_outside_domain}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, revision_id: $revision_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, export_links: $export_links, id: $id, keep_forever: $keep_forever, kind: $kind, last_modifying_user: $last_modifying_user, md5_checksum: $md5_checksum, mime_type: $mime_type, modified_time: $modified_time, original_filename: $original_filename, publish_auto: $publish_auto, published: $published, published_link: $published_link, published_outside_domain: $published_outside_domain, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribes to changes to a file.
#
# POST /files/{fileId}/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: drive.files.watch
export def "drive-files-watch" [
  file_id: string
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
  --acknowledge-abuse: oneof<nothing, bool> # Whether the user is acknowledging the risk of downloading known malware or other abusive files. This is only applicable when alt=media.
  --include-labels: string # A comma-separated list of IDs of labels to include in the labelInfo part of the response.
  --include-permissions-for-view: string # Specifies which additional view's permissions to include in the response. Only 'published' is supported.
  --supports-all-drives: oneof<nothing, bool> # Whether the requesting application supports both My Drives and shared drives.
  --supports-team-drives: oneof<nothing, bool> # Deprecated use supportsAllDrives instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/{fileId}/watch"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: acknowledgeAbuse, var: acknowledge_abuse}, {name: includeLabels, var: include_labels}, {name: includePermissionsForView, var: include_permissions_for_view}, {name: supportsAllDrives, var: supports_all_drives}, {name: supportsTeamDrives, var: supports_team_drives}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, acknowledge_abuse: $acknowledge_abuse, include_labels: $include_labels, include_permissions_for_view: $include_permissions_for_view, supports_all_drives: $supports_all_drives, supports_team_drives: $supports_team_drives, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated use drives.list instead.
#
# GET /teamdrives
# Returns: record<kind: string, nextPageToken: string, teamDrives: table<backgroundImageFile: record, backgroundImageLink: string, capabilities: record, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record, themeId: string>>
# operationId: drive.teamdrives.list
export def "drive-teamdrives-list" [
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
  --page-size: int # Maximum number of Team Drives to return.
  --page-token: string # Page token for Team Drives.
  --q: string # Query string for searching Team Drives.
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then all Team Drives of the domain in which the requester is an administrator are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teamdrives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: q, var: q}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, page_size: $page_size, page_token: $page_token, q: $q, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated use drives.create instead.
#
# POST /teamdrives
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>
# operationId: drive.teamdrives.create
export def "drive-teamdrives-create" [
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
  --request-id: string # An ID, such as a random UUID, which uniquely identifies this user's request for idempotent creation of a Team Drive. A repeated request by the same user and with the same request ID will avoid creating duplicates by attempting to create the same Team Drive. If the Team Drive already exists a 409 error will be returned. (required)
  --background-image-file: record # An image file and cropping parameters from which a background image for this Team Drive is set. This is a write only field; it can only be set on drive.teamdrives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --background-image-link: string # A short-lived link to this Team Drive's background image.
  --capabilities: record # Capabilities the current user has on this Team Drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, ... (5 more fields)}
  --color-rgb: string # The color of this Team Drive as an RGB hex string. It can only be set on a drive.teamdrives.update request that does not set themeId.
  --created-time: string # The time at which the Team Drive was created (RFC 3339 date-time). (format: date-time)
  --id: string # The ID of this Team Drive which is also the ID of the top level folder of this Team Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#teamDrive". (default: drive#teamDrive)
  --name: string # The name of this Team Drive.
  --org-unit-id: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this Team Drive or items inside this Team Drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
  --theme-id: string # The ID of the theme from which the background image and color will be set. The set of possible teamDriveThemes can be retrieved from a drive.about.get response. When not specified on a drive.teamdrives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teamdrives"
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: requestId, var: request_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundImageFile, var: background_image_file}, {name: backgroundImageLink, var: background_image_link}, {name: capabilities, var: capabilities}, {name: colorRgb, var: color_rgb}, {name: createdTime, var: created_time}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: restrictions, var: restrictions}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, request_id: $request_id, background_image_file: $background_image_file, background_image_link: $background_image_link, capabilities: $capabilities, color_rgb: $color_rgb, created_time: $created_time, id: $id, kind: $kind, name: $name, org_unit_id: $org_unit_id, restrictions: $restrictions, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated use drives.delete instead.
#
# DELETE /teamdrives/{teamDriveId}
# operationId: drive.teamdrives.delete
export def "drive-teamdrives-delete" [
  team_drive_id: string
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
    path: "/teamdrives/{teamDriveId}"
    path_params: [{name: teamDriveId, var: team_drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_drive_id: $team_drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated use drives.get instead.
#
# GET /teamdrives/{teamDriveId}
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>
# operationId: drive.teamdrives.get
export def "drive-teamdrives-get" [
  team_drive_id: string
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
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the Team Drive belongs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teamdrives/{teamDriveId}"
    path_params: [{name: teamDriveId, var: team_drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_drive_id: $team_drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, use_domain_admin_access: $use_domain_admin_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deprecated use drives.update instead
#
# PATCH /teamdrives/{teamDriveId}
# Returns: record<backgroundImageFile: record<id: string, width: float, xCoordinate: float, yCoordinate: float>, backgroundImageLink: string, capabilities: record<canAddChildren: bool, canChangeCopyRequiresWriterPermissionRestriction: bool, canChangeDomainUsersOnlyRestriction: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction: bool, canChangeTeamDriveBackground: bool, canChangeTeamMembersOnlyRestriction: bool, canComment: bool, canCopy: bool, canDeleteChildren: bool, canDeleteTeamDrive: bool, canDownload: bool, canEdit: bool, canListChildren: bool, canManageMembers: bool, canReadRevisions: bool, canRemoveChildren: bool, canRename: bool, canRenameTeamDrive: bool, canResetTeamDriveRestrictions: bool, canShare: bool, canTrashChildren: bool>, colorRgb: string, createdTime: string, id: string, kind: string, name: string, orgUnitId: string, restrictions: record<adminManagedRestrictions: bool, copyRequiresWriterPermission: bool, domainUsersOnly: bool, sharingFoldersRequiresOrganizerPermission: bool, teamMembersOnly: bool>, themeId: string>
# operationId: drive.teamdrives.update
export def "drive-teamdrives-update" [
  team_drive_id: string
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
  --use-domain-admin-access: oneof<nothing, bool> # Issue the request as a domain administrator; if set to true, then the requester will be granted access if they are an administrator of the domain to which the Team Drive belongs.
  --background-image-file: record # An image file and cropping parameters from which a background image for this Team Drive is set. This is a write only field; it can only be set on drive.teamdrives.update requests that don't set themeId. When specified, all fields of the backgroundImageFile must be set. — shape: {id?: string, width?: float, xCoordinate?: float, yCoordinate?: float}
  --background-image-link: string # A short-lived link to this Team Drive's background image.
  --capabilities: record # Capabilities the current user has on this Team Drive. — shape: {canAddChildren?: bool, canChangeCopyRequiresWriterPermissionRestriction?: bool, canChangeDomainUsersOnlyRestriction?: bool, canChangeSharingFoldersRequiresOrganizerPermissionRestriction?: bool, canChangeTeamDriveBackground?: bool, canChangeTeamMembersOnlyRestriction?: bool, canComment?: bool, canCopy?: bool, canDeleteChildren?: bool, canDeleteTeamDrive?: bool, canDownload?: bool, canEdit?: bool, canListChildren?: bool, canManageMembers?: bool, canReadRevisions?: bool, canRemoveChildren?: bool, ... (5 more fields)}
  --color-rgb: string # The color of this Team Drive as an RGB hex string. It can only be set on a drive.teamdrives.update request that does not set themeId.
  --created-time: string # The time at which the Team Drive was created (RFC 3339 date-time). (format: date-time)
  --id: string # The ID of this Team Drive which is also the ID of the top level folder of this Team Drive.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "drive#teamDrive". (default: drive#teamDrive)
  --name: string # The name of this Team Drive.
  --org-unit-id: string # The organizational unit of this shared drive. This field is only populated on drives.list responses when the useDomainAdminAccess parameter is set to true.
  --restrictions: record # A set of restrictions that apply to this Team Drive or items inside this Team Drive. — shape: {adminManagedRestrictions?: bool, copyRequiresWriterPermission?: bool, domainUsersOnly?: bool, sharingFoldersRequiresOrganizerPermission?: bool, teamMembersOnly?: bool}
  --theme-id: string # The ID of the theme from which the background image and color will be set. The set of possible teamDriveThemes can be retrieved from a drive.about.get response. When not specified on a drive.teamdrives.create request, a random theme is chosen from which the background image and color are set. This is a write-only field; it can only be set on requests that don't set colorRgb or backgroundImageFile.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/teamdrives/{teamDriveId}"
    path_params: [{name: teamDriveId, var: team_drive_id}]
    query: [{name: alt, var: alt}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: userIp, var: user_ip}, {name: useDomainAdminAccess, var: use_domain_admin_access}]
    body: {content_type: "application/json", kind: json, fields: [{name: backgroundImageFile, var: background_image_file}, {name: backgroundImageLink, var: background_image_link}, {name: capabilities, var: capabilities}, {name: colorRgb, var: color_rgb}, {name: createdTime, var: created_time}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: restrictions, var: restrictions}, {name: themeId, var: theme_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_drive_id: $team_drive_id, alt: $alt, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, user_ip: $user_ip, use_domain_admin_access: $use_domain_admin_access, background_image_file: $background_image_file, background_image_link: $background_image_link, capabilities: $capabilities, color_rgb: $color_rgb, created_time: $created_time, id: $id, kind: $kind, name: $name, org_unit_id: $org_unit_id, restrictions: $restrictions, theme_id: $theme_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
