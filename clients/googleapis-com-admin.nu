# Auto-generated client for Admin SDK API vdirectory_v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/admin/directory_v1/openapi.json
# Auth: --token flag or $env.ADMIN_SDK_API_TOKEN

const CLIENT = {
  base_url: "https://admin.googleapis.com"
  token_env_var: "ADMIN_SDK_API_TOKEN"
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

def base-url-completer [] { ["https://admin.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def order-by-completer [] { ["annotatedLocation" "annotatedUser" "lastSync" "notes" "serialNumber" "status"] }
def projection-completer [] { ["BASIC" "FULL"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def deprovision-reason-completer [] { ["deprovisionReasonDifferentModelReplacement" "deprovisionReasonDomainMove" "deprovisionReasonNotRequired" "deprovisionReasonOther" "deprovisionReasonRepairCenter" "deprovisionReasonRetiringDevice" "deprovisionReasonSameModelReplacement" "deprovisionReasonServiceExpiration" "deprovisionReasonUnspecified" "deprovisionReasonUpgrade" "deprovisionReasonUpgradeTransfer"] }
def command-type-completer [] { ["CAPTURE_LOGS" "COMMAND_TYPE_UNSPECIFIED" "DEVICE_START_CRD_SESSION" "REBOOT" "REMOTE_POWERWASH" "SET_VOLUME" "TAKE_A_SCREENSHOT" "WIPE_USERS"] }
def order-by-completer-1 [] { ["deviceId" "email" "lastSync" "model" "name" "os" "status" "type"] }
def type-completer [] { ["all" "children"] }
def coordinates-source-completer [] { ["CLIENT_SPECIFIED" "RESOLVED_FROM_ADDRESS" "SOURCE_UNSPECIFIED"] }
def order-by-completer-2 [] { ["email"] }
def event-completer [] { ["add" "delete" "makeAdmin" "undelete" "update"] }
def order-by-completer-3 [] { ["email" "familyName" "givenName"] }
def projection-completer-1 [] { ["basic" "custom" "full"] }
def view-type-completer [] { ["admin_view" "domain_public"] }
def event-completer-1 [] { ["add" "delete"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    directory-chromeosdevices-list: "record<chromeosdevices: table<activeTimeRanges: list, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: list, cpuStatusReports: list, deprovisionReason: string, deviceFiles: list, deviceId: string, diskVolumeReports: list, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: list, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record, osVersion: string, platformVersion: string, recentUsers: list, screenshotFiles: list, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: list, systemRamTotal: string, tpmVersionInfo: record, willAutoRenew: bool>, etag: string, kind: string, nextPageToken: string>"
    directory-chromeosdevices-get: "record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>"
    directory-chromeosdevices-patch: "record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>"
    directory-chromeosdevices-update: "record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>"
    admin-customer-devices-chromeos-commands-get: "record<commandExpireTime: string, commandId: string, commandResult: record<commandResultPayload: string, errorMessage: string, executeTime: string, result: string>, issueTime: string, payload: string, state: string, type: string>"
    admin-customer-devices-chromeos-issue-command: "record<commandId: string>"
    directory-mobiledevices-list: "record<etag: string, kind: string, mobiledevices: table<adbStatus: bool, applications: list, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list, networkOperator: string, os: string, otherAccountsInfo: list, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string>, nextPageToken: string>"
    directory-mobiledevices-get: "record<adbStatus: bool, applications: table<displayName: string, packageName: string, permission: list, versionCode: int, versionName: string>, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list<string>, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list<string>, networkOperator: string, os: string, otherAccountsInfo: list<string>, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string>"
    directory-orgunits-list: "record<etag: string, kind: string, organizationUnits: table<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>>"
    directory-orgunits-insert: "record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>"
    directory-orgunits-get: "record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>"
    directory-orgunits-patch: "record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>"
    directory-orgunits-update: "record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>"
    directory-schemas-list: "record<etag: string, kind: string, schemas: table<displayName: string, etag: string, fields: list, kind: string, schemaId: string, schemaName: string>>"
    directory-schemas-insert: "record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>"
    directory-schemas-get: "record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>"
    directory-schemas-patch: "record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>"
    directory-schemas-update: "record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>"
    directory-domain-aliases-list: "record<domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, etag: string, kind: string>"
    directory-domain-aliases-insert: "record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>"
    directory-domain-aliases-get: "record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>"
    directory-domains-list: "record<domains: table<creationTime: string, domainAliases: list, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>, etag: string, kind: string>"
    directory-domains-insert: "record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>"
    directory-domains-get: "record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>"
    directory-resources-buildings-list: "record<buildings: table<address: record, buildingId: string, buildingName: string, coordinates: record, description: string, etags: string, floorNames: list, kind: string>, etag: string, kind: string, nextPageToken: string>"
    directory-resources-buildings-insert: "record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>"
    directory-resources-buildings-get: "record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>"
    directory-resources-buildings-patch: "record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>"
    directory-resources-buildings-update: "record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>"
    directory-resources-calendars-list: "record<etag: string, items: table<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>, kind: string, nextPageToken: string>"
    directory-resources-calendars-insert: "record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>"
    directory-resources-calendars-get: "record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>"
    directory-resources-calendars-patch: "record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>"
    directory-resources-calendars-update: "record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>"
    directory-resources-features-list: "record<etag: string, features: table<etags: string, kind: string, name: string>, kind: string, nextPageToken: string>"
    directory-resources-features-insert: "record<etags: string, kind: string, name: string>"
    directory-resources-features-get: "record<etags: string, kind: string, name: string>"
    directory-resources-features-patch: "record<etags: string, kind: string, name: string>"
    directory-resources-features-update: "record<etags: string, kind: string, name: string>"
    directory-role-assignments-list: "record<etag: string, items: table<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>, kind: string, nextPageToken: string>"
    directory-role-assignments-insert: "record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>"
    directory-role-assignments-get: "record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>"
    directory-roles-list: "record<etag: string, items: table<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: list>, kind: string, nextPageToken: string>"
    directory-roles-insert: "record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>"
    directory-privileges-list: "record<etag: string, items: table<childPrivileges: list, etag: string, isOuScopable: bool, kind: string, privilegeName: string, serviceId: string, serviceName: string>, kind: string>"
    directory-roles-get: "record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>"
    directory-roles-patch: "record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>"
    directory-roles-update: "record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>"
    directory-customers-get: "record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>"
    directory-customers-patch: "record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>"
    directory-customers-update: "record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>"
    directory-groups-list: "record<etag: string, groups: table<adminCreated: bool, aliases: list, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list>, kind: string, nextPageToken: string>"
    directory-groups-insert: "record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>"
    directory-groups-get: "record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>"
    directory-groups-patch: "record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>"
    directory-groups-update: "record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>"
    directory-groups-aliases-list: "record<aliases: list<any>, etag: string, kind: string>"
    directory-groups-aliases-insert: "record<alias: string, etag: string, id: string, kind: string, primaryEmail: string>"
    directory-members-has-member: "record<isMember: bool>"
    directory-members-list: "record<etag: string, kind: string, members: table<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>, nextPageToken: string>"
    directory-members-insert: "record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>"
    directory-members-get: "record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>"
    directory-members-patch: "record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>"
    directory-members-update: "record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>"
    directory-users-list: "record<etag: string, kind: string, nextPageToken: string, trigger_event: string, users: table<addresses: any, agreedToTerms: bool, aliases: list, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record, nonEditableAliases: list, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>>"
    directory-users-insert: "record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>"
    directory-users-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    directory-users-get: "record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>"
    directory-users-patch: "record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>"
    directory-users-update: "record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>"
    directory-users-aliases-list: "record<aliases: list<any>, etag: string, kind: string>"
    directory-users-aliases-insert: "record<alias: string, etag: string, id: string, kind: string, primaryEmail: string>"
    directory-users-aliases-watch: "record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>"
    directory-asps-list: "record<etag: string, items: table<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string>, kind: string>"
    directory-asps-get: "record<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string>"
    directory-users-photos-get: "record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>"
    directory-users-photos-patch: "record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>"
    directory-users-photos-update: "record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>"
    directory-tokens-list: "record<etag: string, items: table<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list, userKey: string>, kind: string>"
    directory-tokens-get: "record<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list<string>, userKey: string>"
    directory-verification-codes-list: "record<etag: string, items: table<etag: string, kind: string, userId: string, verificationCode: string>, kind: string>"
    admin-customers-chrome-print-servers-delete: "record"
    admin-customers-chrome-print-servers-get: "record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>"
    admin-customers-chrome-print-servers-patch: "record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>"
    admin-customers-chrome-print-servers-list: "record<nextPageToken: string, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>>"
    admin-customers-chrome-print-servers-create: "record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>"
    admin-customers-chrome-print-servers-batch-create-print-servers: "record<failures: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>>"
    admin-customers-chrome-print-servers-batch-delete-print-servers: "record<failedPrintServers: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServerIds: list<string>>"
    admin-customers-chrome-printers-list: "record<nextPageToken: string, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>>"
    admin-customers-chrome-printers-create: "record<auxiliaryMessages: table<auxiliaryMessage: string, fieldMask: string, severity: string>, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>"
    admin-customers-chrome-printers-batch-create-printers: "record<failures: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>>"
    admin-customers-chrome-printers-batch-delete-printers: "record<failedPrinters: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printerIds: list<string>>"
    admin-customers-chrome-printers-list-printer-models: "record<nextPageToken: string, printerModels: table<displayName: string, makeAndModel: string, manufacturer: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["directory-chromeosdevices-list" "directory-chromeosdevices-move-devices-to-ou" "directory-chromeosdevices-get" "directory-chromeosdevices-patch" "directory-chromeosdevices-update" "admin-customer-devices-chromeos-commands-get" "admin-customer-devices-chromeos-issue-command" "directory-chromeosdevices-action" "directory-mobiledevices-list" "directory-mobiledevices-delete" "directory-mobiledevices-get" "directory-mobiledevices-action" "directory-orgunits-list" "directory-orgunits-insert" "directory-orgunits-delete" "directory-orgunits-get" "directory-orgunits-patch" "directory-orgunits-update" "directory-schemas-list" "directory-schemas-insert" "directory-schemas-delete" "directory-schemas-get" "directory-schemas-patch" "directory-schemas-update" "directory-domain-aliases-list" "directory-domain-aliases-insert" "directory-domain-aliases-delete" "directory-domain-aliases-get" "directory-domains-list" "directory-domains-insert" "directory-domains-delete" "directory-domains-get" "directory-resources-buildings-list" "directory-resources-buildings-insert" "directory-resources-buildings-delete" "directory-resources-buildings-get" "directory-resources-buildings-patch" "directory-resources-buildings-update" "directory-resources-calendars-list" "directory-resources-calendars-insert" "directory-resources-calendars-delete" "directory-resources-calendars-get" "directory-resources-calendars-patch" "directory-resources-calendars-update" "directory-resources-features-list" "directory-resources-features-insert" "directory-resources-features-delete" "directory-resources-features-get" "directory-resources-features-patch" "directory-resources-features-update" "directory-resources-features-rename" "directory-role-assignments-list" "directory-role-assignments-insert" "directory-role-assignments-delete" "directory-role-assignments-get" "directory-roles-list" "directory-roles-insert" "directory-privileges-list" "directory-roles-delete" "directory-roles-get" "directory-roles-patch" "directory-roles-update" "directory-customers-get" "directory-customers-patch" "directory-customers-update" "directory-groups-list" "directory-groups-insert" "directory-groups-delete" "directory-groups-get" "directory-groups-patch" "directory-groups-update" "directory-groups-aliases-list" "directory-groups-aliases-insert" "directory-groups-aliases-delete" "directory-members-has-member" "directory-members-list" "directory-members-insert" "directory-members-delete" "directory-members-get" "directory-members-patch" "directory-members-update" "directory-users-list" "directory-users-insert" "directory-users-watch" "directory-users-delete" "directory-users-get" "directory-users-patch" "directory-users-update" "directory-users-aliases-list" "directory-users-aliases-insert" "directory-users-aliases-watch" "directory-users-aliases-delete" "directory-asps-list" "directory-asps-delete" "directory-asps-get" "directory-users-make-admin" "directory-users-photos-delete" "directory-users-photos-get" "directory-users-photos-patch" "directory-users-photos-update" "directory-users-sign-out" "directory-tokens-list" "directory-tokens-delete" "directory-tokens-get" "directory-two-step-verification-turn-off" "directory-users-undelete" "directory-verification-codes-list" "directory-verification-codes-generate" "directory-verification-codes-invalidate" "admin-customers-chrome-print-servers-delete" "admin-customers-chrome-print-servers-get" "admin-customers-chrome-print-servers-patch" "admin-customers-chrome-print-servers-list" "admin-customers-chrome-print-servers-create" "admin-customers-chrome-print-servers-batch-create-print-servers" "admin-customers-chrome-print-servers-batch-delete-print-servers" "admin-customers-chrome-printers-list" "admin-customers-chrome-printers-create" "admin-customers-chrome-printers-batch-create-printers" "admin-customers-chrome-printers-batch-delete-printers" "admin-customers-chrome-printers-list-printer-models" "admin-channels-stop" "commands"] | sort) } | get name | first)
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

# Retrieves a paginated list of Chrome OS devices within an account.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos
# Returns: record<chromeosdevices: table<activeTimeRanges: list, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: list, cpuStatusReports: list, deprovisionReason: string, deviceFiles: list, deviceId: string, diskVolumeReports: list, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: list, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record, osVersion: string, platformVersion: string, recentUsers: list, screenshotFiles: list, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: list, systemRamTotal: string, tpmVersionInfo: record, willAutoRenew: bool>, etag: string, kind: string, nextPageToken: string>
# operationId: directory.chromeosdevices.list
export def "directory-chromeosdevices-list" [
  customer_id: string
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
  --include-child-orgunits: oneof<nothing, bool> # Return devices from all child orgunits, as well as the specified org unit. If this is set to true, 'orgUnitPath' must be provided.
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer # Device property to use for sorting results.
  --org-unit-path: string # The full path of the organizational unit (minus the leading `/`) or its unique ID.
  --page-token: string # The `pageToken` query parameter is used to request the next page of query results. The follow-on request's `pageToken` query parameter is the `nextPageToken` from your previous response.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --query: string # Search string in the format given at https://developers.google.com/admin-sdk/directory/v1/list-query-operators
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Must be used with the `orderBy` parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeChildOrgunits, var: include_child_orgunits}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: orgUnitPath, var: org_unit_path}, {name: pageToken, var: page_token}, {name: projection, var: projection}, {name: query, var: query}, {name: sortOrder, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_child_orgunits: $include_child_orgunits, max_results: $max_results, order_by: $order_by, org_unit_path: $org_unit_path, page_token: $page_token, projection: $projection, query: $query, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves or inserts multiple Chrome OS devices to an organizational unit. You can move up to 50 devices at once.
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/moveDevicesToOu
# operationId: directory.chromeosdevices.moveDevicesToOu
export def "directory-chromeosdevices-move-devices-to-ou" [
  customer_id: string
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
  --org-unit-path: string # Full path of the target organizational unit or its ID (required)
  --device-ids: list<string> # Chrome OS devices to be moved to OU
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/moveDevicesToOu"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: orgUnitPath, var: org_unit_path, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deviceIds, var: device_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, org_unit_path: $org_unit_path, device_ids: $device_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a Chrome OS device's properties.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# Returns: record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>
# operationId: directory.chromeosdevices.get
export def "directory-chromeosdevices-get" [
  customer_id: string
  device_id: string
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
  --projection: string@projection-completer # Determines whether the response contains the full list of properties or only a subset.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}"
    path_params: [{name: customerId, var: customer_id}, {name: deviceId, var: device_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projection, var: projection}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, device_id: $device_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, projection: $projection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a device's updatable properties, such as `annotatedUser`, `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# Returns: record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>
# operationId: directory.chromeosdevices.patch
export def "directory-chromeosdevices-patch" [
  customer_id: string
  device_id: string
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --active-time-ranges: list # A list of active time ranges (Read-only). — item shape: {activeTime?: int, date?: string}
  --annotated-asset-id: string # The asset identifier as noted by an administrator or specified during enrollment.
  --annotated-location: string # The address or location of the device as noted by the administrator. Maximum length is `200` characters. Empty values are allowed.
  --annotated-user: string # The user of the device as noted by the administrator. Maximum length is 100 characters. Empty values are allowed.
  --auto-update-expiration: string # (Read-only) The timestamp after which the device will stop receiving Chrome updates or support (format: int64)
  --boot-mode: string # The boot mode for the device. The possible values are: * `Verified`: The device is running a valid version of the Chrome OS. * `Dev`: The devices's developer hardware switch is enabled. When booted, the device has a command line shell. For an example of a developer switch, see the [Chromebook developer information](https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-series-5-chromebook#TOC-Developer-switch).
  --cpu-info: list # Information regarding CPU specs in the device. — item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
  --cpu-status-reports: list # Reports of CPU utilization and temperature (Read-only) — item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
  --deprovision-reason: string@deprovision-reason-completer # (Read-only) Deprovision reason.
  --device-files: list # A list of device files to download (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --body-device-id: string # The unique ID of the Chrome device. (spec name: deviceId)
  --disk-volume-reports: list # Reports of disk space and other info about mounted/connected volumes. — item shape: {volumeInfo?: list}
  --dock-mac-address: string # (Read-only) Built-in MAC address for the docking station that the device connected to. Factory sets Media access control address (MAC address) assigned for use by a dock. It is reserved specifically for MAC pass through device policy. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --etag: string # ETag of the resource.
  --ethernet-mac-address: string # The device's MAC address on the ethernet network interface.
  --ethernet-mac-address0: string # (Read-only) MAC address used by the Chromebook’s internal ethernet port, and for onboard network (ethernet) interface. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --firmware-version: string # The Chrome device's firmware version.
  --first-enrollment-time: string # Date and time for the first time the device was enrolled.
  --kind: string # The type of resource. For the Chromeosdevices resource, the value is `admin#directory#chromeosdevice`. (default: admin#directory#chromeosdevice)
  --last-deprovision-timestamp: string # (Read-only) Date and time for the last deprovision of the device.
  --last-enrollment-time: string # Date and time the device was last enrolled (Read-only) (format: date-time)
  --last-known-network: list # Contains last known network (Read-only) — item shape: {ipAddress?: string, wanIpAddress?: string}
  --last-sync: string # Date and time the device was last synchronized with the policy settings in the G Suite administrator control panel (Read-only) (format: date-time)
  --mac-address: string # The device's wireless MAC address. If the device does not have this information, it is not included in the response.
  --manufacture-date: string # (Read-only) The date the device was manufactured in yyyy-mm-dd format.
  --meid: string # The Mobile Equipment Identifier (MEID) or the International Mobile Equipment Identity (IMEI) for the 3G mobile card in a mobile device. A MEID/IMEI is typically used when adding a device to a wireless carrier's post-pay service plan. If the device does not have this information, this property is not included in the response. For more information on how to export a MEID/IMEI list, see the [Developer's Guide](/admin-sdk/directory/v1/guides/manage-chrome-devices.html#export_meid).
  --model: string # The device's model information. If the device does not have this information, this property is not included in the response.
  --notes: string # Notes about this device added by the administrator. This property can be [searched](https://support.google.com/chrome/a/answer/1698333) with the [list](/admin-sdk/directory/v1/reference/chromeosdevices/list) method's `query` parameter. Maximum length is 500 characters. Empty values are allowed.
  --order-number: string # The device's order number. Only devices directly purchased from Google have an order number.
  --org-unit-id: string # The unique ID of the organizational unit. orgUnitPath is the human readable version of orgUnitId. While orgUnitPath may change by renaming an organizational unit within the path, orgUnitId is unchangeable for one organizational unit. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --org-unit-path: string # The full parent path with the organizational unit's name associated with the device. Path names are case insensitive. If the parent organizational unit is the top-level organization, it is represented as a forward slash, `/`. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --os-update-status: record # Contains information regarding the current OS update status. — shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
  --os-version: string # The Chrome device's operating system version.
  --platform-version: string # The Chrome device's platform version.
  --recent-users: list # A list of recent device users, in descending order, by last login time. — item shape: {email?: string, type?: string}
  --screenshot-files: list # A list of screenshot files to download. Type is always "SCREENSHOT_FILE". (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --serial-number: string # The Chrome device serial number entered when the device was enabled. This value is the same as the Admin console's *Serial Number* in the *Chrome OS Devices* tab.
  --status: string # The status of the device.
  --support-end-date: string # Final date the device will be supported (Read-only) (format: date-time)
  --system-ram-free-reports: list # Reports of amounts of available RAM memory (Read-only) — item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
  --system-ram-total: string # Total RAM on the device [in bytes] (Read-only) (format: int64)
  --tpm-version-info: record # Trusted Platform Module (TPM) (Read-only) — shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
  --will-auto-renew: oneof<nothing, bool> # Determines if the device will auto renew its support after the support end date. This is a read-only property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}"
    path_params: [{name: customerId, var: customer_id}, {name: deviceId, var: device_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projection, var: projection}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeTimeRanges, var: active_time_ranges}, {name: annotatedAssetId, var: annotated_asset_id}, {name: annotatedLocation, var: annotated_location}, {name: annotatedUser, var: annotated_user}, {name: autoUpdateExpiration, var: auto_update_expiration}, {name: bootMode, var: boot_mode}, {name: cpuInfo, var: cpu_info}, {name: cpuStatusReports, var: cpu_status_reports}, {name: deprovisionReason, var: deprovision_reason}, {name: deviceFiles, var: device_files}, {name: deviceId, var: body_device_id}, {name: diskVolumeReports, var: disk_volume_reports}, {name: dockMacAddress, var: dock_mac_address}, {name: etag, var: etag}, {name: ethernetMacAddress, var: ethernet_mac_address}, {name: ethernetMacAddress0, var: ethernet_mac_address0}, {name: firmwareVersion, var: firmware_version}, {name: firstEnrollmentTime, var: first_enrollment_time}, {name: kind, var: kind}, {name: lastDeprovisionTimestamp, var: last_deprovision_timestamp}, {name: lastEnrollmentTime, var: last_enrollment_time}, {name: lastKnownNetwork, var: last_known_network}, {name: lastSync, var: last_sync}, {name: macAddress, var: mac_address}, {name: manufactureDate, var: manufacture_date}, {name: meid, var: meid}, {name: model, var: model}, {name: notes, var: notes}, {name: orderNumber, var: order_number}, {name: orgUnitId, var: org_unit_id}, {name: orgUnitPath, var: org_unit_path}, {name: osUpdateStatus, var: os_update_status}, {name: osVersion, var: os_version}, {name: platformVersion, var: platform_version}, {name: recentUsers, var: recent_users}, {name: screenshotFiles, var: screenshot_files}, {name: serialNumber, var: serial_number}, {name: status, var: status}, {name: supportEndDate, var: support_end_date}, {name: systemRamFreeReports, var: system_ram_free_reports}, {name: systemRamTotal, var: system_ram_total}, {name: tpmVersionInfo, var: tpm_version_info}, {name: willAutoRenew, var: will_auto_renew}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, device_id: $device_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, projection: $projection, active_time_ranges: $active_time_ranges, annotated_asset_id: $annotated_asset_id, annotated_location: $annotated_location, annotated_user: $annotated_user, auto_update_expiration: $auto_update_expiration, boot_mode: $boot_mode, cpu_info: $cpu_info, cpu_status_reports: $cpu_status_reports, deprovision_reason: $deprovision_reason, device_files: $device_files, body_device_id: $body_device_id, disk_volume_reports: $disk_volume_reports, dock_mac_address: $dock_mac_address, etag: $etag, ethernet_mac_address: $ethernet_mac_address, ethernet_mac_address0: $ethernet_mac_address0, firmware_version: $firmware_version, first_enrollment_time: $first_enrollment_time, kind: $kind, last_deprovision_timestamp: $last_deprovision_timestamp, last_enrollment_time: $last_enrollment_time, last_known_network: $last_known_network, last_sync: $last_sync, mac_address: $mac_address, manufacture_date: $manufacture_date, meid: $meid, model: $model, notes: $notes, order_number: $order_number, org_unit_id: $org_unit_id, org_unit_path: $org_unit_path, os_update_status: $os_update_status, os_version: $os_version, platform_version: $platform_version, recent_users: $recent_users, screenshot_files: $screenshot_files, serial_number: $serial_number, status: $status, support_end_date: $support_end_date, system_ram_free_reports: $system_ram_free_reports, system_ram_total: $system_ram_total, tpm_version_info: $tpm_version_info, will_auto_renew: $will_auto_renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a device's updatable properties, such as `annotatedUser`, `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`.
#
# PUT /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# Returns: record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool>
# operationId: directory.chromeosdevices.update
export def "directory-chromeosdevices-update" [
  customer_id: string
  device_id: string
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --active-time-ranges: list # A list of active time ranges (Read-only). — item shape: {activeTime?: int, date?: string}
  --annotated-asset-id: string # The asset identifier as noted by an administrator or specified during enrollment.
  --annotated-location: string # The address or location of the device as noted by the administrator. Maximum length is `200` characters. Empty values are allowed.
  --annotated-user: string # The user of the device as noted by the administrator. Maximum length is 100 characters. Empty values are allowed.
  --auto-update-expiration: string # (Read-only) The timestamp after which the device will stop receiving Chrome updates or support (format: int64)
  --boot-mode: string # The boot mode for the device. The possible values are: * `Verified`: The device is running a valid version of the Chrome OS. * `Dev`: The devices's developer hardware switch is enabled. When booted, the device has a command line shell. For an example of a developer switch, see the [Chromebook developer information](https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-series-5-chromebook#TOC-Developer-switch).
  --cpu-info: list # Information regarding CPU specs in the device. — item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
  --cpu-status-reports: list # Reports of CPU utilization and temperature (Read-only) — item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
  --deprovision-reason: string@deprovision-reason-completer # (Read-only) Deprovision reason.
  --device-files: list # A list of device files to download (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --body-device-id: string # The unique ID of the Chrome device. (spec name: deviceId)
  --disk-volume-reports: list # Reports of disk space and other info about mounted/connected volumes. — item shape: {volumeInfo?: list}
  --dock-mac-address: string # (Read-only) Built-in MAC address for the docking station that the device connected to. Factory sets Media access control address (MAC address) assigned for use by a dock. It is reserved specifically for MAC pass through device policy. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --etag: string # ETag of the resource.
  --ethernet-mac-address: string # The device's MAC address on the ethernet network interface.
  --ethernet-mac-address0: string # (Read-only) MAC address used by the Chromebook’s internal ethernet port, and for onboard network (ethernet) interface. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --firmware-version: string # The Chrome device's firmware version.
  --first-enrollment-time: string # Date and time for the first time the device was enrolled.
  --kind: string # The type of resource. For the Chromeosdevices resource, the value is `admin#directory#chromeosdevice`. (default: admin#directory#chromeosdevice)
  --last-deprovision-timestamp: string # (Read-only) Date and time for the last deprovision of the device.
  --last-enrollment-time: string # Date and time the device was last enrolled (Read-only) (format: date-time)
  --last-known-network: list # Contains last known network (Read-only) — item shape: {ipAddress?: string, wanIpAddress?: string}
  --last-sync: string # Date and time the device was last synchronized with the policy settings in the G Suite administrator control panel (Read-only) (format: date-time)
  --mac-address: string # The device's wireless MAC address. If the device does not have this information, it is not included in the response.
  --manufacture-date: string # (Read-only) The date the device was manufactured in yyyy-mm-dd format.
  --meid: string # The Mobile Equipment Identifier (MEID) or the International Mobile Equipment Identity (IMEI) for the 3G mobile card in a mobile device. A MEID/IMEI is typically used when adding a device to a wireless carrier's post-pay service plan. If the device does not have this information, this property is not included in the response. For more information on how to export a MEID/IMEI list, see the [Developer's Guide](/admin-sdk/directory/v1/guides/manage-chrome-devices.html#export_meid).
  --model: string # The device's model information. If the device does not have this information, this property is not included in the response.
  --notes: string # Notes about this device added by the administrator. This property can be [searched](https://support.google.com/chrome/a/answer/1698333) with the [list](/admin-sdk/directory/v1/reference/chromeosdevices/list) method's `query` parameter. Maximum length is 500 characters. Empty values are allowed.
  --order-number: string # The device's order number. Only devices directly purchased from Google have an order number.
  --org-unit-id: string # The unique ID of the organizational unit. orgUnitPath is the human readable version of orgUnitId. While orgUnitPath may change by renaming an organizational unit within the path, orgUnitId is unchangeable for one organizational unit. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --org-unit-path: string # The full parent path with the organizational unit's name associated with the device. Path names are case insensitive. If the parent organizational unit is the top-level organization, it is represented as a forward slash, `/`. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --os-update-status: record # Contains information regarding the current OS update status. — shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
  --os-version: string # The Chrome device's operating system version.
  --platform-version: string # The Chrome device's platform version.
  --recent-users: list # A list of recent device users, in descending order, by last login time. — item shape: {email?: string, type?: string}
  --screenshot-files: list # A list of screenshot files to download. Type is always "SCREENSHOT_FILE". (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --serial-number: string # The Chrome device serial number entered when the device was enabled. This value is the same as the Admin console's *Serial Number* in the *Chrome OS Devices* tab.
  --status: string # The status of the device.
  --support-end-date: string # Final date the device will be supported (Read-only) (format: date-time)
  --system-ram-free-reports: list # Reports of amounts of available RAM memory (Read-only) — item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
  --system-ram-total: string # Total RAM on the device [in bytes] (Read-only) (format: int64)
  --tpm-version-info: record # Trusted Platform Module (TPM) (Read-only) — shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
  --will-auto-renew: oneof<nothing, bool> # Determines if the device will auto renew its support after the support end date. This is a read-only property.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}"
    path_params: [{name: customerId, var: customer_id}, {name: deviceId, var: device_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projection, var: projection}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeTimeRanges, var: active_time_ranges}, {name: annotatedAssetId, var: annotated_asset_id}, {name: annotatedLocation, var: annotated_location}, {name: annotatedUser, var: annotated_user}, {name: autoUpdateExpiration, var: auto_update_expiration}, {name: bootMode, var: boot_mode}, {name: cpuInfo, var: cpu_info}, {name: cpuStatusReports, var: cpu_status_reports}, {name: deprovisionReason, var: deprovision_reason}, {name: deviceFiles, var: device_files}, {name: deviceId, var: body_device_id}, {name: diskVolumeReports, var: disk_volume_reports}, {name: dockMacAddress, var: dock_mac_address}, {name: etag, var: etag}, {name: ethernetMacAddress, var: ethernet_mac_address}, {name: ethernetMacAddress0, var: ethernet_mac_address0}, {name: firmwareVersion, var: firmware_version}, {name: firstEnrollmentTime, var: first_enrollment_time}, {name: kind, var: kind}, {name: lastDeprovisionTimestamp, var: last_deprovision_timestamp}, {name: lastEnrollmentTime, var: last_enrollment_time}, {name: lastKnownNetwork, var: last_known_network}, {name: lastSync, var: last_sync}, {name: macAddress, var: mac_address}, {name: manufactureDate, var: manufacture_date}, {name: meid, var: meid}, {name: model, var: model}, {name: notes, var: notes}, {name: orderNumber, var: order_number}, {name: orgUnitId, var: org_unit_id}, {name: orgUnitPath, var: org_unit_path}, {name: osUpdateStatus, var: os_update_status}, {name: osVersion, var: os_version}, {name: platformVersion, var: platform_version}, {name: recentUsers, var: recent_users}, {name: screenshotFiles, var: screenshot_files}, {name: serialNumber, var: serial_number}, {name: status, var: status}, {name: supportEndDate, var: support_end_date}, {name: systemRamFreeReports, var: system_ram_free_reports}, {name: systemRamTotal, var: system_ram_total}, {name: tpmVersionInfo, var: tpm_version_info}, {name: willAutoRenew, var: will_auto_renew}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, device_id: $device_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, projection: $projection, active_time_ranges: $active_time_ranges, annotated_asset_id: $annotated_asset_id, annotated_location: $annotated_location, annotated_user: $annotated_user, auto_update_expiration: $auto_update_expiration, boot_mode: $boot_mode, cpu_info: $cpu_info, cpu_status_reports: $cpu_status_reports, deprovision_reason: $deprovision_reason, device_files: $device_files, body_device_id: $body_device_id, disk_volume_reports: $disk_volume_reports, dock_mac_address: $dock_mac_address, etag: $etag, ethernet_mac_address: $ethernet_mac_address, ethernet_mac_address0: $ethernet_mac_address0, firmware_version: $firmware_version, first_enrollment_time: $first_enrollment_time, kind: $kind, last_deprovision_timestamp: $last_deprovision_timestamp, last_enrollment_time: $last_enrollment_time, last_known_network: $last_known_network, last_sync: $last_sync, mac_address: $mac_address, manufacture_date: $manufacture_date, meid: $meid, model: $model, notes: $notes, order_number: $order_number, org_unit_id: $org_unit_id, org_unit_path: $org_unit_path, os_update_status: $os_update_status, os_version: $os_version, platform_version: $platform_version, recent_users: $recent_users, screenshot_files: $screenshot_files, serial_number: $serial_number, status: $status, support_end_date: $support_end_date, system_ram_free_reports: $system_ram_free_reports, system_ram_total: $system_ram_total, tpm_version_info: $tpm_version_info, will_auto_renew: $will_auto_renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets command data a specific command issued to the device.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}/commands/{commandId}
# Returns: record<commandExpireTime: string, commandId: string, commandResult: record<commandResultPayload: string, errorMessage: string, executeTime: string, result: string>, issueTime: string, payload: string, state: string, type: string>
# operationId: admin.customer.devices.chromeos.commands.get
export def "admin-customer-devices-chromeos-commands-get" [
  customer_id: string
  device_id: string
  command_id: string
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
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}/commands/{commandId}"
    path_params: [{name: customerId, var: customer_id}, {name: deviceId, var: device_id}, {name: commandId, var: command_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, device_id: $device_id, command_id: $command_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issues a command for the device to execute.
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}:issueCommand
# Returns: record<commandId: string>
# operationId: admin.customer.devices.chromeos.issueCommand
export def "admin-customer-devices-chromeos-issue-command" [
  customer_id: string
  device_id: string
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
  --command-type: string@command-type-completer # The type of command.
  --payload: string # The payload for the command, provide it only if command supports it. The following commands support adding payload: * `SET_VOLUME`: Payload is a stringified JSON object in the form: { "volume": 50 }. The volume has to be an integer in the range [0,100]. * `DEVICE_START_CRD_SESSION`: Payload is optionally a stringified JSON object in the form: { "ackedUserPresence": true }. `ackedUserPresence` is a boolean. By default, `ackedUserPresence` is set to `false`. To start a Chrome Remote Desktop session for an active device, set `ackedUserPresence` to `true`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}:issueCommand"
    path_params: [{name: customerId, var: customer_id}, {name: deviceId, var: device_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: commandType, var: command_type}, {name: payload, var: payload}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, device_id: $device_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, command_type: $command_type, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes an action that affects a Chrome OS Device. This includes deprovisioning, disabling, and re-enabling devices. *Warning:* * Deprovisioning a device will stop device policy syncing and remove device-level printers. After a device is deprovisioned, it must be wiped before it can be re-enrolled. * Lost or stolen devices should use the disable action. * Re-enabling a disabled device will consume a device license. If you do not have sufficient licenses available when completing the re-enable action, you will receive an error. For more information about deprovisioning and disabling devices, visit the [help center](https://support.google.com/chrome/a/answer/3523633).
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/{resourceId}/action
# operationId: directory.chromeosdevices.action
export def "directory-chromeosdevices-action" [
  customer_id: string
  resource_id: string
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
  --action: string # Action to be taken on the Chrome OS device.
  --deprovision-reason: string # Only used when the action is `deprovision`. With the `deprovision` action, this field is required. *Note*: The deprovision reason is audited because it might have implications on licenses for perpetual subscription customers.
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/devices/chromeos/{resourceId}/action"
    path_params: [{name: customerId, var: customer_id}, {name: resourceId, var: resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: deprovisionReason, var: deprovision_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, resource_id: $resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, deprovision_reason: $deprovision_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all user-owned mobile devices for an account. To retrieve a list that includes company-owned devices, use the Cloud Identity [Devices API](https://cloud.google.com/identity/docs/concepts/overview-devices) instead. This method times out after 60 minutes. For more information, see [Troubleshoot error codes](https://developers.google.com/admin-sdk/directory/v1/guides/troubleshoot-error-codes).
#
# GET /admin/directory/v1/customer/{customerId}/devices/mobile
# Returns: record<etag: string, kind: string, mobiledevices: table<adbStatus: bool, applications: list, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list, networkOperator: string, os: string, otherAccountsInfo: list, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string>, nextPageToken: string>
# operationId: directory.mobiledevices.list
export def "directory-mobiledevices-list" [
  customer_id: string
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
  --max-results: int # Maximum number of results to return. Max allowed value is 100.
  --order-by: string@order-by-completer-1 # Device property to use for sorting results.
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --query: string # Search string in the format given at https://developers.google.com/admin-sdk/directory/v1/search-operators
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Must be used with the `orderBy` parameter.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customerId}/devices/mobile"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: projection, var: projection}, {name: query, var: query}, {name: sortOrder, var: sort_order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, order_by: $order_by, page_token: $page_token, projection: $projection, query: $query, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a mobile device.
#
# DELETE /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}
# operationId: directory.mobiledevices.delete
export def "directory-mobiledevices-delete" [
  customer_id: string
  resource_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}"
    path_params: [{name: customerId, var: customer_id}, {name: resourceId, var: resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, resource_id: $resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a mobile device's properties.
#
# GET /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}
# Returns: record<adbStatus: bool, applications: table<displayName: string, packageName: string, permission: list, versionCode: int, versionName: string>, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list<string>, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list<string>, networkOperator: string, os: string, otherAccountsInfo: list<string>, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string>
# operationId: directory.mobiledevices.get
export def "directory-mobiledevices-get" [
  customer_id: string
  resource_id: string
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}"
    path_params: [{name: customerId, var: customer_id}, {name: resourceId, var: resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projection, var: projection}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, resource_id: $resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, projection: $projection
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Takes an action that affects a mobile device. For example, remotely wiping a device.
#
# POST /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}/action
# operationId: directory.mobiledevices.action
export def "directory-mobiledevices-action" [
  customer_id: string
  resource_id: string
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
  --action: string # The action to be performed on the device.
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}/action"
    path_params: [{name: customerId, var: customer_id}, {name: resourceId, var: resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, resource_id: $resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of all organizational units for an account.
#
# GET /admin/directory/v1/customer/{customerId}/orgunits
# Returns: record<etag: string, kind: string, organizationUnits: table<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>>
# operationId: directory.orgunits.list
export def "directory-orgunits-list" [
  customer_id: string
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
  --org-unit-path: string # The full path to the organizational unit or its unique ID. Returns the children of the specified organizational unit.
  --type: string@type-completer # Whether to return all sub-organizations or just immediate children.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customerId}/orgunits"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: orgUnitPath, var: org_unit_path}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, org_unit_path: $org_unit_path, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an organizational unit.
#
# POST /admin/directory/v1/customer/{customerId}/orgunits
# Returns: record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>
# operationId: directory.orgunits.insert
export def "directory-orgunits-insert" [
  customer_id: string
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user).
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/orgunits"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: blockInheritance, var: block_inheritance}, {name: description, var: description}, {name: etag, var: etag}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: orgUnitPath, var: org_unit_path}, {name: parentOrgUnitId, var: parent_org_unit_id}, {name: parentOrgUnitPath, var: parent_org_unit_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, block_inheritance: $block_inheritance, description: $description, etag: $etag, kind: $kind, name: $name, org_unit_id: $org_unit_id, org_unit_path: $org_unit_path, parent_org_unit_id: $parent_org_unit_id, parent_org_unit_path: $parent_org_unit_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an organizational unit.
#
# DELETE /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# operationId: directory.orgunits.delete
export def "directory-orgunits-delete" [
  customer_id: string
  org_unit_path: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}"
    path_params: [{name: customerId, var: customer_id}, {name: orgUnitPath, var: org_unit_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, org_unit_path: $org_unit_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves an organizational unit.
#
# GET /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# Returns: record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>
# operationId: directory.orgunits.get
export def "directory-orgunits-get" [
  customer_id: string
  org_unit_path: string
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
    path: "/admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}"
    path_params: [{name: customerId, var: customer_id}, {name: orgUnitPath, var: org_unit_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, org_unit_path: $org_unit_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an organizational unit. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch)
#
# PATCH /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# Returns: record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>
# operationId: directory.orgunits.patch
export def "directory-orgunits-patch" [
  customer_id: string
  org_unit_path: string
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --body-org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user). (spec name: orgUnitPath)
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}"
    path_params: [{name: customerId, var: customer_id}, {name: orgUnitPath, var: org_unit_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: blockInheritance, var: block_inheritance}, {name: description, var: description}, {name: etag, var: etag}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: orgUnitPath, var: body_org_unit_path}, {name: parentOrgUnitId, var: parent_org_unit_id}, {name: parentOrgUnitPath, var: parent_org_unit_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, org_unit_path: $org_unit_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, block_inheritance: $block_inheritance, description: $description, etag: $etag, kind: $kind, name: $name, org_unit_id: $org_unit_id, body_org_unit_path: $body_org_unit_path, parent_org_unit_id: $parent_org_unit_id, parent_org_unit_path: $parent_org_unit_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an organizational unit.
#
# PUT /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# Returns: record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>
# operationId: directory.orgunits.update
export def "directory-orgunits-update" [
  customer_id: string
  org_unit_path: string
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --body-org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user). (spec name: orgUnitPath)
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}"
    path_params: [{name: customerId, var: customer_id}, {name: orgUnitPath, var: org_unit_path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: blockInheritance, var: block_inheritance}, {name: description, var: description}, {name: etag, var: etag}, {name: kind, var: kind}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: orgUnitPath, var: body_org_unit_path}, {name: parentOrgUnitId, var: parent_org_unit_id}, {name: parentOrgUnitPath, var: parent_org_unit_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, org_unit_path: $org_unit_path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, block_inheritance: $block_inheritance, description: $description, etag: $etag, kind: $kind, name: $name, org_unit_id: $org_unit_id, body_org_unit_path: $body_org_unit_path, parent_org_unit_id: $parent_org_unit_id, parent_org_unit_path: $parent_org_unit_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all schemas for a customer.
#
# GET /admin/directory/v1/customer/{customerId}/schemas
# Returns: record<etag: string, kind: string, schemas: table<displayName: string, etag: string, fields: list, kind: string, schemaId: string, schemaName: string>>
# operationId: directory.schemas.list
export def "directory-schemas-list" [
  customer_id: string
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
    path: "/admin/directory/v1/customer/{customerId}/schemas"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a schema.
#
# POST /admin/directory/v1/customer/{customerId}/schemas
# Returns: record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>
# operationId: directory.schemas.insert
export def "directory-schemas-insert" [
  customer_id: string
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
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --body-fields: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (spec name: fields)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customerId}/schemas"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: etag, var: etag}, {name: fields, var: body_fields}, {name: kind, var: kind}, {name: schemaId, var: schema_id}, {name: schemaName, var: schema_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, display_name: $display_name, etag: $etag, body_fields: $body_fields, kind: $kind, schema_id: $schema_id, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a schema.
#
# DELETE /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# operationId: directory.schemas.delete
export def "directory-schemas-delete" [
  customer_id: string
  schema_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customerId}/schemas/{schemaKey}"
    path_params: [{name: customerId, var: customer_id}, {name: schemaKey, var: schema_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, schema_key: $schema_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a schema.
#
# GET /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# Returns: record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>
# operationId: directory.schemas.get
export def "directory-schemas-get" [
  customer_id: string
  schema_key: string
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
    path: "/admin/directory/v1/customer/{customerId}/schemas/{schemaKey}"
    path_params: [{name: customerId, var: customer_id}, {name: schemaKey, var: schema_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, schema_key: $schema_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a schema.
#
# PATCH /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# Returns: record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>
# operationId: directory.schemas.patch
export def "directory-schemas-patch" [
  customer_id: string
  schema_key: string
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
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --body-fields: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (spec name: fields)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customerId}/schemas/{schemaKey}"
    path_params: [{name: customerId, var: customer_id}, {name: schemaKey, var: schema_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: etag, var: etag}, {name: fields, var: body_fields}, {name: kind, var: kind}, {name: schemaId, var: schema_id}, {name: schemaName, var: schema_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, schema_key: $schema_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, display_name: $display_name, etag: $etag, body_fields: $body_fields, kind: $kind, schema_id: $schema_id, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a schema.
#
# PUT /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# Returns: record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string>
# operationId: directory.schemas.update
export def "directory-schemas-update" [
  customer_id: string
  schema_key: string
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
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --body-fields: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (spec name: fields)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customerId}/schemas/{schemaKey}"
    path_params: [{name: customerId, var: customer_id}, {name: schemaKey, var: schema_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: displayName, var: display_name}, {name: etag, var: etag}, {name: fields, var: body_fields}, {name: kind, var: kind}, {name: schemaId, var: schema_id}, {name: schemaName, var: schema_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, schema_key: $schema_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, display_name: $display_name, etag: $etag, body_fields: $body_fields, kind: $kind, schema_id: $schema_id, schema_name: $schema_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the domain aliases of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domainaliases
# Returns: record<domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, etag: string, kind: string>
# operationId: directory.domainAliases.list
export def "directory-domain-aliases-list" [
  customer: string
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
  --parent-domain-name: string # Name of the parent domain for which domain aliases are to be fetched.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/domainaliases"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parentDomainName, var: parent_domain_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent_domain_name: $parent_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a domain alias of the customer.
#
# POST /admin/directory/v1/customer/{customer}/domainaliases
# Returns: record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>
# operationId: directory.domainAliases.insert
export def "directory-domain-aliases-insert" [
  customer: string
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
  --creation-time: string # The creation time of the domain alias. (Read-only). (format: int64)
  --domain-alias-name: string # The domain alias name.
  --etag: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#domainAlias)
  --parent-domain-name: string # The parent domain name that the domain alias is associated with. This can either be a primary or secondary domain name within a customer.
  --verified: oneof<nothing, bool> # Indicates the verification state of a domain alias. (Read-only)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/domainaliases"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationTime, var: creation_time}, {name: domainAliasName, var: domain_alias_name}, {name: etag, var: etag}, {name: kind, var: kind}, {name: parentDomainName, var: parent_domain_name}, {name: verified, var: verified}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, creation_time: $creation_time, domain_alias_name: $domain_alias_name, etag: $etag, kind: $kind, parent_domain_name: $parent_domain_name, verified: $verified
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a domain Alias of the customer.
#
# DELETE /admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}
# operationId: directory.domainAliases.delete
export def "directory-domain-aliases-delete" [
  customer: string
  domain_alias_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}"
    path_params: [{name: customer, var: customer}, {name: domainAliasName, var: domain_alias_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, domain_alias_name: $domain_alias_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a domain alias of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}
# Returns: record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>
# operationId: directory.domainAliases.get
export def "directory-domain-aliases-get" [
  customer: string
  domain_alias_name: string
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
    path: "/admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}"
    path_params: [{name: customer, var: customer}, {name: domainAliasName, var: domain_alias_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, domain_alias_name: $domain_alias_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the domains of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domains
# Returns: record<domains: table<creationTime: string, domainAliases: list, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>, etag: string, kind: string>
# operationId: directory.domains.list
export def "directory-domains-list" [
  customer: string
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
    path: "/admin/directory/v1/customer/{customer}/domains"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a domain of the customer.
#
# POST /admin/directory/v1/customer/{customer}/domains
# Returns: record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>
# operationId: directory.domains.insert
export def "directory-domains-insert" [
  customer: string
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
  --creation-time: string # Creation time of the domain. Expressed in [Unix time](https://en.wikipedia.org/wiki/Epoch_time) format. (Read-only). (format: int64)
  --domain-aliases: list # A list of domain alias objects. (Read-only) — item shape: {creationTime?: string, domainAliasName?: string, etag?: string, kind?: string, parentDomainName?: string, verified?: bool}
  --domain-name: string # The domain name of the customer.
  --etag: string # ETag of the resource.
  --is-primary: oneof<nothing, bool> # Indicates if the domain is a primary domain (Read-only).
  --kind: string # Kind of resource this is. (default: admin#directory#domain)
  --verified: oneof<nothing, bool> # Indicates the verification state of a domain. (Read-only).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/domains"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: creationTime, var: creation_time}, {name: domainAliases, var: domain_aliases}, {name: domainName, var: domain_name}, {name: etag, var: etag}, {name: isPrimary, var: is_primary}, {name: kind, var: kind}, {name: verified, var: verified}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, creation_time: $creation_time, domain_aliases: $domain_aliases, domain_name: $domain_name, etag: $etag, is_primary: $is_primary, kind: $kind, verified: $verified
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a domain of the customer.
#
# DELETE /admin/directory/v1/customer/{customer}/domains/{domainName}
# operationId: directory.domains.delete
export def "directory-domains-delete" [
  customer: string
  domain_name: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/domains/{domainName}"
    path_params: [{name: customer, var: customer}, {name: domainName, var: domain_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, domain_name: $domain_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a domain of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domains/{domainName}
# Returns: record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>
# operationId: directory.domains.get
export def "directory-domains-get" [
  customer: string
  domain_name: string
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
    path: "/admin/directory/v1/customer/{customer}/domains/{domainName}"
    path_params: [{name: customer, var: customer}, {name: domainName, var: domain_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, domain_name: $domain_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of buildings for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/buildings
# Returns: record<buildings: table<address: record, buildingId: string, buildingName: string, coordinates: record, description: string, etags: string, floorNames: list, kind: string>, etag: string, kind: string, nextPageToken: string>
# operationId: directory.resources.buildings.list
export def "directory-resources-buildings-list" [
  customer: string
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/resources/buildings"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a building.
#
# POST /admin/directory/v1/customer/{customer}/resources/buildings
# Returns: record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>
# operationId: directory.resources.buildings.insert
export def "directory-resources-buildings-insert" [
  customer: string
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --building-id: string # Unique identifier for the building. The maximum length is 100 characters.
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/resources/buildings"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: coordinatesSource, var: coordinates_source}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: buildingId, var: building_id}, {name: buildingName, var: building_name}, {name: coordinates, var: coordinates}, {name: description, var: description}, {name: etags, var: etags}, {name: floorNames, var: floor_names}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, coordinates_source: $coordinates_source, address: $address, building_id: $building_id, building_name: $building_name, coordinates: $coordinates, description: $description, etags: $etags, floor_names: $floor_names, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a building.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# operationId: directory.resources.buildings.delete
export def "directory-resources-buildings-delete" [
  customer: string
  building_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}"
    path_params: [{name: customer, var: customer}, {name: buildingId, var: building_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, building_id: $building_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a building.
#
# GET /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# Returns: record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>
# operationId: directory.resources.buildings.get
export def "directory-resources-buildings-get" [
  customer: string
  building_id: string
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
    path: "/admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}"
    path_params: [{name: customer, var: customer}, {name: buildingId, var: building_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, building_id: $building_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a building.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# Returns: record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>
# operationId: directory.resources.buildings.patch
export def "directory-resources-buildings-patch" [
  customer: string
  building_id: string
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --body-building-id: string # Unique identifier for the building. The maximum length is 100 characters. (spec name: buildingId)
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}"
    path_params: [{name: customer, var: customer}, {name: buildingId, var: building_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: coordinatesSource, var: coordinates_source}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: buildingId, var: body_building_id}, {name: buildingName, var: building_name}, {name: coordinates, var: coordinates}, {name: description, var: description}, {name: etags, var: etags}, {name: floorNames, var: floor_names}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, building_id: $building_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, coordinates_source: $coordinates_source, address: $address, body_building_id: $body_building_id, building_name: $building_name, coordinates: $coordinates, description: $description, etags: $etags, floor_names: $floor_names, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a building.
#
# PUT /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# Returns: record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string>
# operationId: directory.resources.buildings.update
export def "directory-resources-buildings-update" [
  customer: string
  building_id: string
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --body-building-id: string # Unique identifier for the building. The maximum length is 100 characters. (spec name: buildingId)
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}"
    path_params: [{name: customer, var: customer}, {name: buildingId, var: building_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: coordinatesSource, var: coordinates_source}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: buildingId, var: body_building_id}, {name: buildingName, var: building_name}, {name: coordinates, var: coordinates}, {name: description, var: description}, {name: etags, var: etags}, {name: floorNames, var: floor_names}, {name: kind, var: kind}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, building_id: $building_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, coordinates_source: $coordinates_source, address: $address, body_building_id: $body_building_id, building_name: $building_name, coordinates: $coordinates, description: $description, etags: $etags, floor_names: $floor_names, kind: $kind
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of calendar resources for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/calendars
# Returns: record<etag: string, items: table<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>, kind: string, nextPageToken: string>
# operationId: directory.resources.calendars.list
export def "directory-resources-calendars-list" [
  customer: string
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
  --max-results: int # Maximum number of results to return.
  --order-by: string # Field(s) to sort results by in either ascending or descending order. Supported fields include `resourceId`, `resourceName`, `capacity`, `buildingId`, and `floorName`. If no order is specified, defaults to ascending. Should be of the form "field [asc|desc], field [asc|desc], ...". For example `buildingId, capacity desc` would return results sorted first by `buildingId` in ascending order then by `capacity` in descending order.
  --page-token: string # Token to specify the next page in the list.
  --query: string # String query used to filter results. Should be of the form "field operator value" where field can be any of supported fields and operators can be any of supported operations. Operators include '=' for exact match, '!=' for mismatch and ':' for prefix match or HAS match where applicable. For prefix match, the value should always be followed by a *. Logical operators NOT and AND are supported (in this order of precedence). Supported fields include `generatedResourceName`, `name`, `buildingId`, `floor_name`, `capacity`, `featureInstances.feature.name`, `resourceEmail`, `resourceCategory`. For example `buildingId=US-NYC-9TH AND featureInstances.feature.name:Phone`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/resources/calendars"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, order_by: $order_by, page_token: $page_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a calendar resource.
#
# POST /admin/directory/v1/customer/{customer}/resources/calendars
# Returns: record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>
# operationId: directory.resources.calendars.insert
export def "directory-resources-calendars-insert" [
  customer: string
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/resources/calendars"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: buildingId, var: building_id}, {name: capacity, var: capacity}, {name: etags, var: etags}, {name: featureInstances, var: feature_instances}, {name: floorName, var: floor_name}, {name: floorSection, var: floor_section}, {name: generatedResourceName, var: generated_resource_name}, {name: kind, var: kind}, {name: resourceCategory, var: resource_category}, {name: resourceDescription, var: resource_description}, {name: resourceEmail, var: resource_email}, {name: resourceId, var: resource_id}, {name: resourceName, var: resource_name}, {name: resourceType, var: resource_type}, {name: userVisibleDescription, var: user_visible_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, building_id: $building_id, capacity: $capacity, etags: $etags, feature_instances: $feature_instances, floor_name: $floor_name, floor_section: $floor_section, generated_resource_name: $generated_resource_name, kind: $kind, resource_category: $resource_category, resource_description: $resource_description, resource_email: $resource_email, resource_id: $resource_id, resource_name: $resource_name, resource_type: $resource_type, user_visible_description: $user_visible_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a calendar resource.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# operationId: directory.resources.calendars.delete
export def "directory-resources-calendars-delete" [
  customer: string
  calendar_resource_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}"
    path_params: [{name: customer, var: customer}, {name: calendarResourceId, var: calendar_resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, calendar_resource_id: $calendar_resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a calendar resource.
#
# GET /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# Returns: record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>
# operationId: directory.resources.calendars.get
export def "directory-resources-calendars-get" [
  customer: string
  calendar_resource_id: string
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
    path: "/admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}"
    path_params: [{name: customer, var: customer}, {name: calendarResourceId, var: calendar_resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, calendar_resource_id: $calendar_resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a calendar resource.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# Returns: record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>
# operationId: directory.resources.calendars.patch
export def "directory-resources-calendars-patch" [
  customer: string
  calendar_resource_id: string
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}"
    path_params: [{name: customer, var: customer}, {name: calendarResourceId, var: calendar_resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: buildingId, var: building_id}, {name: capacity, var: capacity}, {name: etags, var: etags}, {name: featureInstances, var: feature_instances}, {name: floorName, var: floor_name}, {name: floorSection, var: floor_section}, {name: generatedResourceName, var: generated_resource_name}, {name: kind, var: kind}, {name: resourceCategory, var: resource_category}, {name: resourceDescription, var: resource_description}, {name: resourceEmail, var: resource_email}, {name: resourceId, var: resource_id}, {name: resourceName, var: resource_name}, {name: resourceType, var: resource_type}, {name: userVisibleDescription, var: user_visible_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, calendar_resource_id: $calendar_resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, building_id: $building_id, capacity: $capacity, etags: $etags, feature_instances: $feature_instances, floor_name: $floor_name, floor_section: $floor_section, generated_resource_name: $generated_resource_name, kind: $kind, resource_category: $resource_category, resource_description: $resource_description, resource_email: $resource_email, resource_id: $resource_id, resource_name: $resource_name, resource_type: $resource_type, user_visible_description: $user_visible_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a calendar resource. This method supports patch semantics, meaning you only need to include the fields you wish to update. Fields that are not present in the request will be preserved.
#
# PUT /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# Returns: record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>
# operationId: directory.resources.calendars.update
export def "directory-resources-calendars-update" [
  customer: string
  calendar_resource_id: string
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}"
    path_params: [{name: customer, var: customer}, {name: calendarResourceId, var: calendar_resource_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: buildingId, var: building_id}, {name: capacity, var: capacity}, {name: etags, var: etags}, {name: featureInstances, var: feature_instances}, {name: floorName, var: floor_name}, {name: floorSection, var: floor_section}, {name: generatedResourceName, var: generated_resource_name}, {name: kind, var: kind}, {name: resourceCategory, var: resource_category}, {name: resourceDescription, var: resource_description}, {name: resourceEmail, var: resource_email}, {name: resourceId, var: resource_id}, {name: resourceName, var: resource_name}, {name: resourceType, var: resource_type}, {name: userVisibleDescription, var: user_visible_description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, calendar_resource_id: $calendar_resource_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, building_id: $building_id, capacity: $capacity, etags: $etags, feature_instances: $feature_instances, floor_name: $floor_name, floor_section: $floor_section, generated_resource_name: $generated_resource_name, kind: $kind, resource_category: $resource_category, resource_description: $resource_description, resource_email: $resource_email, resource_id: $resource_id, resource_name: $resource_name, resource_type: $resource_type, user_visible_description: $user_visible_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of features for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/features
# Returns: record<etag: string, features: table<etags: string, kind: string, name: string>, kind: string, nextPageToken: string>
# operationId: directory.resources.features.list
export def "directory-resources-features-list" [
  customer: string
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/resources/features"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a feature.
#
# POST /admin/directory/v1/customer/{customer}/resources/features
# Returns: record<etags: string, kind: string, name: string>
# operationId: directory.resources.features.insert
export def "directory-resources-features-insert" [
  customer: string
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/resources/features"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etags, var: etags}, {name: kind, var: kind}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etags: $etags, kind: $kind, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a feature.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# operationId: directory.resources.features.delete
export def "directory-resources-features-delete" [
  customer: string
  feature_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/resources/features/{featureKey}"
    path_params: [{name: customer, var: customer}, {name: featureKey, var: feature_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, feature_key: $feature_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a feature.
#
# GET /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# Returns: record<etags: string, kind: string, name: string>
# operationId: directory.resources.features.get
export def "directory-resources-features-get" [
  customer: string
  feature_key: string
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
    path: "/admin/directory/v1/customer/{customer}/resources/features/{featureKey}"
    path_params: [{name: customer, var: customer}, {name: featureKey, var: feature_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, feature_key: $feature_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a feature.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# Returns: record<etags: string, kind: string, name: string>
# operationId: directory.resources.features.patch
export def "directory-resources-features-patch" [
  customer: string
  feature_key: string
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customer}/resources/features/{featureKey}"
    path_params: [{name: customer, var: customer}, {name: featureKey, var: feature_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etags, var: etags}, {name: kind, var: kind}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, feature_key: $feature_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etags: $etags, kind: $kind, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a feature.
#
# PUT /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# Returns: record<etags: string, kind: string, name: string>
# operationId: directory.resources.features.update
export def "directory-resources-features-update" [
  customer: string
  feature_key: string
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customer}/resources/features/{featureKey}"
    path_params: [{name: customer, var: customer}, {name: featureKey, var: feature_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etags, var: etags}, {name: kind, var: kind}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, feature_key: $feature_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etags: $etags, kind: $kind, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames a feature.
#
# POST /admin/directory/v1/customer/{customer}/resources/features/{oldName}/rename
# operationId: directory.resources.features.rename
export def "directory-resources-features-rename" [
  customer: string
  old_name: string
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
  --new-name: string # New name of the feature.
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/resources/features/{oldName}/rename"
    path_params: [{name: customer, var: customer}, {name: oldName, var: old_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: newName, var: new_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, old_name: $old_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, new_name: $new_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all roleAssignments.
#
# GET /admin/directory/v1/customer/{customer}/roleassignments
# Returns: record<etag: string, items: table<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>, kind: string, nextPageToken: string>
# operationId: directory.roleAssignments.list
export def "directory-role-assignments-list" [
  customer: string
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
  --include-indirect-role-assignments: oneof<nothing, bool> # When set to `true`, fetches indirect role assignments (i.e. role assignment via a group) as well as direct ones. Defaults to `false`. You must specify `user_key` or the indirect role assignments will not be included.
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
  --role-id: string # Immutable ID of a role. If included in the request, returns only role assignments containing this role ID.
  --user-key: string # The primary email address, alias email address, or unique user or group ID. If included in the request, returns role assignments only for this user or group.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/roleassignments"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeIndirectRoleAssignments, var: include_indirect_role_assignments}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: roleId, var: role_id}, {name: userKey, var: user_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_indirect_role_assignments: $include_indirect_role_assignments, max_results: $max_results, page_token: $page_token, role_id: $role_id, user_key: $user_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a role assignment.
#
# POST /admin/directory/v1/customer/{customer}/roleassignments
# Returns: record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>
# operationId: directory.roleAssignments.insert
export def "directory-role-assignments-insert" [
  customer: string
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
  --assigned-to: string # The unique ID of the entity this role is assigned to—either the `user_id` of a user, the `group_id` of a group, or the `uniqueId` of a service account as defined in [Identity and Access Management (IAM)](https://cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts).
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. This is always `admin#directory#roleAssignment`. (default: admin#directory#roleAssignment)
  --org-unit-id: string # If the role is restricted to an organization unit, this contains the ID for the organization unit the exercise of this role is restricted to.
  --role-assignment-id: string # ID of this roleAssignment. (format: int64)
  --role-id: string # The ID of the role that is assigned. (format: int64)
  --scope-type: string # The scope in which this role is assigned.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/roleassignments"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignedTo, var: assigned_to}, {name: etag, var: etag}, {name: kind, var: kind}, {name: orgUnitId, var: org_unit_id}, {name: roleAssignmentId, var: role_assignment_id}, {name: roleId, var: role_id}, {name: scopeType, var: scope_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, assigned_to: $assigned_to, etag: $etag, kind: $kind, org_unit_id: $org_unit_id, role_assignment_id: $role_assignment_id, role_id: $role_id, scope_type: $scope_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a role assignment.
#
# DELETE /admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}
# operationId: directory.roleAssignments.delete
export def "directory-role-assignments-delete" [
  customer: string
  role_assignment_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}"
    path_params: [{name: customer, var: customer}, {name: roleAssignmentId, var: role_assignment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_assignment_id: $role_assignment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a role assignment.
#
# GET /admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}
# Returns: record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>
# operationId: directory.roleAssignments.get
export def "directory-role-assignments-get" [
  customer: string
  role_assignment_id: string
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
    path: "/admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}"
    path_params: [{name: customer, var: customer}, {name: roleAssignmentId, var: role_assignment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_assignment_id: $role_assignment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all the roles in a domain.
#
# GET /admin/directory/v1/customer/{customer}/roles
# Returns: record<etag: string, items: table<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: list>, kind: string, nextPageToken: string>
# operationId: directory.roles.list
export def "directory-roles-list" [
  customer: string
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/customer/{customer}/roles"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_results: $max_results, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a role.
#
# POST /admin/directory/v1/customer/{customer}/roles
# Returns: record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>
# operationId: directory.roles.insert
export def "directory-roles-insert" [
  customer: string
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --role-id: string # ID of the role. (format: int64)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/customer/{customer}/roles"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: isSuperAdminRole, var: is_super_admin_role}, {name: isSystemRole, var: is_system_role}, {name: kind, var: kind}, {name: roleDescription, var: role_description}, {name: roleId, var: role_id}, {name: roleName, var: role_name}, {name: rolePrivileges, var: role_privileges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, is_super_admin_role: $is_super_admin_role, is_system_role: $is_system_role, kind: $kind, role_description: $role_description, role_id: $role_id, role_name: $role_name, role_privileges: $role_privileges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all privileges for a customer.
#
# GET /admin/directory/v1/customer/{customer}/roles/ALL/privileges
# Returns: record<etag: string, items: table<childPrivileges: list, etag: string, isOuScopable: bool, kind: string, privilegeName: string, serviceId: string, serviceName: string>, kind: string>
# operationId: directory.privileges.list
export def "directory-privileges-list" [
  customer: string
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
    path: "/admin/directory/v1/customer/{customer}/roles/ALL/privileges"
    path_params: [{name: customer, var: customer}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a role.
#
# DELETE /admin/directory/v1/customer/{customer}/roles/{roleId}
# operationId: directory.roles.delete
export def "directory-roles-delete" [
  customer: string
  role_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/customer/{customer}/roles/{roleId}"
    path_params: [{name: customer, var: customer}, {name: roleId, var: role_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_id: $role_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a role.
#
# GET /admin/directory/v1/customer/{customer}/roles/{roleId}
# Returns: record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>
# operationId: directory.roles.get
export def "directory-roles-get" [
  customer: string
  role_id: string
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
    path: "/admin/directory/v1/customer/{customer}/roles/{roleId}"
    path_params: [{name: customer, var: customer}, {name: roleId, var: role_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_id: $role_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a role.
#
# PATCH /admin/directory/v1/customer/{customer}/roles/{roleId}
# Returns: record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>
# operationId: directory.roles.patch
export def "directory-roles-patch" [
  customer: string
  role_id: string
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --body-role-id: string # ID of the role. (format: int64) (spec name: roleId)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customer/{customer}/roles/{roleId}"
    path_params: [{name: customer, var: customer}, {name: roleId, var: role_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: isSuperAdminRole, var: is_super_admin_role}, {name: isSystemRole, var: is_system_role}, {name: kind, var: kind}, {name: roleDescription, var: role_description}, {name: roleId, var: body_role_id}, {name: roleName, var: role_name}, {name: rolePrivileges, var: role_privileges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_id: $role_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, is_super_admin_role: $is_super_admin_role, is_system_role: $is_system_role, kind: $kind, role_description: $role_description, body_role_id: $body_role_id, role_name: $role_name, role_privileges: $role_privileges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a role.
#
# PUT /admin/directory/v1/customer/{customer}/roles/{roleId}
# Returns: record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>>
# operationId: directory.roles.update
export def "directory-roles-update" [
  customer: string
  role_id: string
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --body-role-id: string # ID of the role. (format: int64) (spec name: roleId)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customer/{customer}/roles/{roleId}"
    path_params: [{name: customer, var: customer}, {name: roleId, var: role_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: isSuperAdminRole, var: is_super_admin_role}, {name: isSystemRole, var: is_system_role}, {name: kind, var: kind}, {name: roleDescription, var: role_description}, {name: roleId, var: body_role_id}, {name: roleName, var: role_name}, {name: rolePrivileges, var: role_privileges}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer: $customer, role_id: $role_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, is_super_admin_role: $is_super_admin_role, is_system_role: $is_system_role, kind: $kind, role_description: $role_description, body_role_id: $body_role_id, role_name: $role_name, role_privileges: $role_privileges
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a customer.
#
# GET /admin/directory/v1/customers/{customerKey}
# Returns: record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>
# operationId: directory.customers.get
export def "directory-customers-get" [
  customer_key: string
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
    path: "/admin/directory/v1/customers/{customerKey}"
    path_params: [{name: customerKey, var: customer_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_key: $customer_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a customer.
#
# PATCH /admin/directory/v1/customers/{customerKey}
# Returns: record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>
# operationId: directory.customers.patch
export def "directory-customers-patch" [
  customer_key: string
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
  --alternate-email: string # The customer's secondary contact email address. This email address cannot be on the same domain as the `customerDomain`
  --customer-creation-time: string # The customer's creation time (Readonly) (format: date-time)
  --customer-domain: string # The customer's primary domain name string. Do not include the `www` prefix when creating a new customer.
  --etag: string # ETag of the resource.
  --id: string # The unique ID for the customer's Google Workspace account. (Readonly)
  --kind: string # Identifies the resource as a customer. Value: `admin#directory#customer` (default: admin#directory#customer)
  --language: string # The customer's ISO 639-2 language code. See the [Language Codes](/admin-sdk/directory/v1/languages) page for the list of supported codes. Valid language codes outside the supported set will be accepted by the API but may lead to unexpected behavior. The default value is `en`.
  --phone-number: string # The customer's contact phone number in [E.164](https://en.wikipedia.org/wiki/E.164) format.
  --postal-address: record # shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/customers/{customerKey}"
    path_params: [{name: customerKey, var: customer_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateEmail, var: alternate_email}, {name: customerCreationTime, var: customer_creation_time}, {name: customerDomain, var: customer_domain}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: language, var: language}, {name: phoneNumber, var: phone_number}, {name: postalAddress, var: postal_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_key: $customer_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_email: $alternate_email, customer_creation_time: $customer_creation_time, customer_domain: $customer_domain, etag: $etag, id: $id, kind: $kind, language: $language, phone_number: $phone_number, postal_address: $postal_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a customer.
#
# PUT /admin/directory/v1/customers/{customerKey}
# Returns: record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>>
# operationId: directory.customers.update
export def "directory-customers-update" [
  customer_key: string
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
  --alternate-email: string # The customer's secondary contact email address. This email address cannot be on the same domain as the `customerDomain`
  --customer-creation-time: string # The customer's creation time (Readonly) (format: date-time)
  --customer-domain: string # The customer's primary domain name string. Do not include the `www` prefix when creating a new customer.
  --etag: string # ETag of the resource.
  --id: string # The unique ID for the customer's Google Workspace account. (Readonly)
  --kind: string # Identifies the resource as a customer. Value: `admin#directory#customer` (default: admin#directory#customer)
  --language: string # The customer's ISO 639-2 language code. See the [Language Codes](/admin-sdk/directory/v1/languages) page for the list of supported codes. Valid language codes outside the supported set will be accepted by the API but may lead to unexpected behavior. The default value is `en`.
  --phone-number: string # The customer's contact phone number in [E.164](https://en.wikipedia.org/wiki/E.164) format.
  --postal-address: record # shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/customers/{customerKey}"
    path_params: [{name: customerKey, var: customer_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alternateEmail, var: alternate_email}, {name: customerCreationTime, var: customer_creation_time}, {name: customerDomain, var: customer_domain}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: language, var: language}, {name: phoneNumber, var: phone_number}, {name: postalAddress, var: postal_address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_key: $customer_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alternate_email: $alternate_email, customer_creation_time: $customer_creation_time, customer_domain: $customer_domain, etag: $etag, id: $id, kind: $kind, language: $language, phone_number: $phone_number, postal_address: $postal_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all groups of a domain or of a user given a userKey (paginated).
#
# GET /admin/directory/v1/groups
# Returns: record<etag: string, groups: table<adminCreated: bool, aliases: list, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list>, kind: string, nextPageToken: string>
# operationId: directory.groups.list
export def "directory-groups-list" [
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
  --customer: string # The unique ID for the customer's Google Workspace account. In case of a multi-domain account, to fetch all groups for a customer, use this field instead of `domain`. You can also use the `my_customer` alias to represent your account's `customerId`. The `customerId` is also returned as part of the [Users](/admin-sdk/directory/v1/reference/users) resource. You must provide either the `customer` or the `domain` parameter.
  --domain: string # The domain name. Use this field to get groups from only one domain. To return all domains for a customer account, use the `customer` query parameter instead.
  --max-results: int # Maximum number of results to return. Max allowed value is 200.
  --order-by: string@order-by-completer-2 # Column to use for sorting results
  --page-token: string # Token to specify next page in the list
  --query: string # Query string search. Should be of the form "". Complete documentation is at https: //developers.google.com/admin-sdk/directory/v1/guides/search-groups
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Only of use when orderBy is also used
  --user-key: string # Email or immutable ID of the user if only those groups are to be listed, the given user is a member of. If it's an ID, it should match with the ID of the user object.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/groups"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customer, var: customer}, {name: domain, var: domain}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: query, var: query}, {name: sortOrder, var: sort_order}, {name: userKey, var: user_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, customer: $customer, domain: $domain, max_results: $max_results, order_by: $order_by, page_token: $page_token, query: $query, sort_order: $sort_order, user_key: $user_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a group.
#
# POST /admin/directory/v1/groups
# Returns: record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>
# operationId: directory.groups.insert
export def "directory-groups-insert" [
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/groups"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminCreated, var: admin_created}, {name: aliases, var: aliases}, {name: description, var: description}, {name: directMembersCount, var: direct_members_count}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: nonEditableAliases, var: non_editable_aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, admin_created: $admin_created, aliases: $aliases, description: $description, direct_members_count: $direct_members_count, email: $email, etag: $etag, id: $id, kind: $kind, name: $name, non_editable_aliases: $non_editable_aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a group.
#
# DELETE /admin/directory/v1/groups/{groupKey}
# operationId: directory.groups.delete
export def "directory-groups-delete" [
  group_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/groups/{groupKey}"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a group's properties.
#
# GET /admin/directory/v1/groups/{groupKey}
# Returns: record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>
# operationId: directory.groups.get
export def "directory-groups-get" [
  group_key: string
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
    path: "/admin/directory/v1/groups/{groupKey}"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a group's properties. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/groups/{groupKey}
# Returns: record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>
# operationId: directory.groups.patch
export def "directory-groups-patch" [
  group_key: string
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/groups/{groupKey}"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminCreated, var: admin_created}, {name: aliases, var: aliases}, {name: description, var: description}, {name: directMembersCount, var: direct_members_count}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: nonEditableAliases, var: non_editable_aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, admin_created: $admin_created, aliases: $aliases, description: $description, direct_members_count: $direct_members_count, email: $email, etag: $etag, id: $id, kind: $kind, name: $name, non_editable_aliases: $non_editable_aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a group's properties.
#
# PUT /admin/directory/v1/groups/{groupKey}
# Returns: record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>>
# operationId: directory.groups.update
export def "directory-groups-update" [
  group_key: string
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/groups/{groupKey}"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminCreated, var: admin_created}, {name: aliases, var: aliases}, {name: description, var: description}, {name: directMembersCount, var: direct_members_count}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: name, var: name}, {name: nonEditableAliases, var: non_editable_aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, admin_created: $admin_created, aliases: $aliases, description: $description, direct_members_count: $direct_members_count, email: $email, etag: $etag, id: $id, kind: $kind, name: $name, non_editable_aliases: $non_editable_aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all aliases for a group.
#
# GET /admin/directory/v1/groups/{groupKey}/aliases
# Returns: record<aliases: list<any>, etag: string, kind: string>
# operationId: directory.groups.aliases.list
export def "directory-groups-aliases-list" [
  group_key: string
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
    path: "/admin/directory/v1/groups/{groupKey}/aliases"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an alias for the group.
#
# POST /admin/directory/v1/groups/{groupKey}/aliases
# Returns: record<alias: string, etag: string, id: string, kind: string, primaryEmail: string>
# operationId: directory.groups.aliases.insert
export def "directory-groups-aliases-insert" [
  group_key: string
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
  --alias: string
  --etag: string
  --id: string
  --kind: string # default: admin#directory#alias
  --primary-email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/groups/{groupKey}/aliases"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: primaryEmail, var: primary_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alias: $alias, etag: $etag, id: $id, kind: $kind, primary_email: $primary_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an alias.
#
# DELETE /admin/directory/v1/groups/{groupKey}/aliases/{alias}
# operationId: directory.groups.aliases.delete
export def "directory-groups-aliases-delete" [
  group_key: string
  alias: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/groups/{groupKey}/aliases/{alias}"
    path_params: [{name: groupKey, var: group_key}, {name: alias, var: alias}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, alias: $alias, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks whether the given user is a member of the group. Membership can be direct or nested, but if nested, the `memberKey` and `groupKey` must be entities in the same domain or an `Invalid input` error is returned. To check for nested memberships that include entities outside of the group's domain, use the [`checkTransitiveMembership()`](https://cloud.google.com/identity/docs/reference/rest/v1/groups.memberships/checkTransitiveMembership) method in the Cloud Identity Groups API.
#
# GET /admin/directory/v1/groups/{groupKey}/hasMember/{memberKey}
# Returns: record<isMember: bool>
# operationId: directory.members.hasMember
export def "directory-members-has-member" [
  group_key: string
  member_key: string
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
    path: "/admin/directory/v1/groups/{groupKey}/hasMember/{memberKey}"
    path_params: [{name: groupKey, var: group_key}, {name: memberKey, var: member_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, member_key: $member_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of all members in a group. This method times out after 60 minutes. For more information, see [Troubleshoot error codes](https://developers.google.com/admin-sdk/directory/v1/guides/troubleshoot-error-codes).
#
# GET /admin/directory/v1/groups/{groupKey}/members
# Returns: record<etag: string, kind: string, members: table<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>, nextPageToken: string>
# operationId: directory.members.list
export def "directory-members-list" [
  group_key: string
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
  --include-derived-membership: oneof<nothing, bool> # Whether to list indirect memberships. Default: false.
  --max-results: int # Maximum number of results to return. Max allowed value is 200.
  --page-token: string # Token to specify next page in the list.
  --roles: string # The `roles` query parameter allows you to retrieve group members by role. Allowed values are `OWNER`, `MANAGER`, and `MEMBER`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/groups/{groupKey}/members"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeDerivedMembership, var: include_derived_membership}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: roles, var: roles}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_derived_membership: $include_derived_membership, max_results: $max_results, page_token: $page_token, roles: $roles
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a user to the specified group.
#
# POST /admin/directory/v1/groups/{groupKey}/members
# Returns: record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>
# operationId: directory.members.insert
export def "directory-members-insert" [
  group_key: string
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/groups/{groupKey}/members"
    path_params: [{name: groupKey, var: group_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: delivery_settings, var: delivery_settings}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, delivery_settings: $delivery_settings, email: $email, etag: $etag, id: $id, kind: $kind, role: $role, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a member from a group.
#
# DELETE /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# operationId: directory.members.delete
export def "directory-members-delete" [
  group_key: string
  member_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/groups/{groupKey}/members/{memberKey}"
    path_params: [{name: groupKey, var: group_key}, {name: memberKey, var: member_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, member_key: $member_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a group member's properties.
#
# GET /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# Returns: record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>
# operationId: directory.members.get
export def "directory-members-get" [
  group_key: string
  member_key: string
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
    path: "/admin/directory/v1/groups/{groupKey}/members/{memberKey}"
    path_params: [{name: groupKey, var: group_key}, {name: memberKey, var: member_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, member_key: $member_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the membership properties of a user in the specified group. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# Returns: record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>
# operationId: directory.members.patch
export def "directory-members-patch" [
  group_key: string
  member_key: string
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/groups/{groupKey}/members/{memberKey}"
    path_params: [{name: groupKey, var: group_key}, {name: memberKey, var: member_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: delivery_settings, var: delivery_settings}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, member_key: $member_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, delivery_settings: $delivery_settings, email: $email, etag: $etag, id: $id, kind: $kind, role: $role, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the membership of a user in the specified group.
#
# PUT /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# Returns: record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>
# operationId: directory.members.update
export def "directory-members-update" [
  group_key: string
  member_key: string
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/groups/{groupKey}/members/{memberKey}"
    path_params: [{name: groupKey, var: group_key}, {name: memberKey, var: member_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: delivery_settings, var: delivery_settings}, {name: email, var: email}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: role, var: role}, {name: status, var: status}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_key: $group_key, member_key: $member_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, delivery_settings: $delivery_settings, email: $email, etag: $etag, id: $id, kind: $kind, role: $role, status: $status, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a paginated list of either deleted users or all users in a domain.
#
# GET /admin/directory/v1/users
# Returns: record<etag: string, kind: string, nextPageToken: string, trigger_event: string, users: table<addresses: any, agreedToTerms: bool, aliases: list, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record, nonEditableAliases: list, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>>
# operationId: directory.users.list
export def "directory-users-list" [
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
  --custom-field-mask: string # A comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when `projection=custom`.
  --customer: string # The unique ID for the customer's Google Workspace account. In case of a multi-domain account, to fetch all groups for a customer, use this field instead of `domain`. You can also use the `my_customer` alias to represent your account's `customerId`. The `customerId` is also returned as part of the [Users](/admin-sdk/directory/v1/reference/users) resource. You must provide either the `customer` or the `domain` parameter.
  --domain: string # The domain name. Use this field to get groups from only one domain. To return all domains for a customer account, use the `customer` query parameter instead. Either the `customer` or the `domain` parameter must be provided.
  --event: string@event-completer # Event on which subscription is intended (if subscribing)
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer-3 # Property to use for sorting results.
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --query: string # Query string for searching user fields. For more information on constructing user queries, see [Search for Users](/admin-sdk/directory/v1/guides/search-users).
  --show-deleted: string # If set to `true`, retrieves the list of deleted users. (Default: `false`)
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order, ignoring case.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/users"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customFieldMask, var: custom_field_mask}, {name: customer, var: customer}, {name: domain, var: domain}, {name: event, var: event}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: projection, var: projection}, {name: query, var: query}, {name: showDeleted, var: show_deleted}, {name: sortOrder, var: sort_order}, {name: viewType, var: view_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_field_mask: $custom_field_mask, customer: $customer, domain: $domain, event: $event, max_results: $max_results, order_by: $order_by, page_token: $page_token, projection: $projection, query: $query, show_deleted: $show_deleted, sort_order: $sort_order, view_type: $view_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user.
#
# POST /admin/directory/v1/users
# Returns: record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>
# operationId: directory.users.insert
export def "directory-users-insert" [
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: archived, var: archived}, {name: changePasswordAtNextLogin, var: change_password_at_next_login}, {name: customSchemas, var: custom_schemas}, {name: emails, var: emails}, {name: externalIds, var: external_ids}, {name: gender, var: gender}, {name: hashFunction, var: hash_function}, {name: id, var: id}, {name: ims, var: ims}, {name: includeInGlobalAddressList, var: include_in_global_address_list}, {name: ipWhitelisted, var: ip_whitelisted}, {name: keywords, var: keywords}, {name: languages, var: languages}, {name: locations, var: locations}, {name: name, var: name}, {name: notes, var: notes}, {name: orgUnitPath, var: org_unit_path}, {name: organizations, var: organizations}, {name: password, var: password}, {name: phones, var: phones}, {name: posixAccounts, var: posix_accounts}, {name: primaryEmail, var: primary_email}, {name: recoveryEmail, var: recovery_email}, {name: recoveryPhone, var: recovery_phone}, {name: relations, var: relations}, {name: sshPublicKeys, var: ssh_public_keys}, {name: suspended, var: suspended}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addresses: $addresses, archived: $archived, change_password_at_next_login: $change_password_at_next_login, custom_schemas: $custom_schemas, emails: $emails, external_ids: $external_ids, gender: $gender, hash_function: $hash_function, id: $id, ims: $ims, include_in_global_address_list: $include_in_global_address_list, ip_whitelisted: $ip_whitelisted, keywords: $keywords, languages: $languages, locations: $locations, name: $name, notes: $notes, org_unit_path: $org_unit_path, organizations: $organizations, password: $password, phones: $phones, posix_accounts: $posix_accounts, primary_email: $primary_email, recovery_email: $recovery_email, recovery_phone: $recovery_phone, relations: $relations, ssh_public_keys: $ssh_public_keys, suspended: $suspended, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watches for changes in users list.
#
# POST /admin/directory/v1/users/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: directory.users.watch
export def "directory-users-watch" [
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
  --custom-field-mask: string # Comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when projection=custom.
  --customer: string # Immutable ID of the Google Workspace account. In case of multi-domain, to fetch all users for a customer, fill this field instead of domain.
  --domain: string # Name of the domain. Fill this field to get users from only this domain. To return all users in a multi-domain fill customer field instead."
  --event: string@event-completer # Events to watch for.
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer-3 # Column to use for sorting results
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --query: string # Query string search. Should be of the form "". Complete documentation is at https: //developers.google.com/admin-sdk/directory/v1/guides/search-users
  --show-deleted: string # If set to true, retrieves the list of deleted users. (Default: false)
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users/watch"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customFieldMask, var: custom_field_mask}, {name: customer, var: customer}, {name: domain, var: domain}, {name: event, var: event}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: projection, var: projection}, {name: query, var: query}, {name: showDeleted, var: show_deleted}, {name: sortOrder, var: sort_order}, {name: viewType, var: view_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_field_mask: $custom_field_mask, customer: $customer, domain: $domain, event: $event, max_results: $max_results, order_by: $order_by, page_token: $page_token, projection: $projection, query: $query, show_deleted: $show_deleted, sort_order: $sort_order, view_type: $view_type, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user.
#
# DELETE /admin/directory/v1/users/{userKey}
# operationId: directory.users.delete
export def "directory-users-delete" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/users/{userKey}"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a user.
#
# GET /admin/directory/v1/users/{userKey}
# Returns: record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>
# operationId: directory.users.get
export def "directory-users-get" [
  user_key: string
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
  --custom-field-mask: string # A comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when `projection=custom`.
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/users/{userKey}"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: customFieldMask, var: custom_field_mask}, {name: projection, var: projection}, {name: viewType, var: view_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_field_mask: $custom_field_mask, projection: $projection, view_type: $view_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user using patch semantics. The update method should be used instead, because it also supports patch semantics and has better performance. If you're mapping an external identity to a Google identity, use the [`update`](https://developers.google.com/admin-sdk/directory/v1/reference/users/update) method instead of the `patch` method. This method is unable to clear fields that contain repeated objects (`addresses`, `phones`, etc). Use the update method instead.
#
# PATCH /admin/directory/v1/users/{userKey}
# Returns: record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>
# operationId: directory.users.patch
export def "directory-users-patch" [
  user_key: string
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/users/{userKey}"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: archived, var: archived}, {name: changePasswordAtNextLogin, var: change_password_at_next_login}, {name: customSchemas, var: custom_schemas}, {name: emails, var: emails}, {name: externalIds, var: external_ids}, {name: gender, var: gender}, {name: hashFunction, var: hash_function}, {name: id, var: id}, {name: ims, var: ims}, {name: includeInGlobalAddressList, var: include_in_global_address_list}, {name: ipWhitelisted, var: ip_whitelisted}, {name: keywords, var: keywords}, {name: languages, var: languages}, {name: locations, var: locations}, {name: name, var: name}, {name: notes, var: notes}, {name: orgUnitPath, var: org_unit_path}, {name: organizations, var: organizations}, {name: password, var: password}, {name: phones, var: phones}, {name: posixAccounts, var: posix_accounts}, {name: primaryEmail, var: primary_email}, {name: recoveryEmail, var: recovery_email}, {name: recoveryPhone, var: recovery_phone}, {name: relations, var: relations}, {name: sshPublicKeys, var: ssh_public_keys}, {name: suspended, var: suspended}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addresses: $addresses, archived: $archived, change_password_at_next_login: $change_password_at_next_login, custom_schemas: $custom_schemas, emails: $emails, external_ids: $external_ids, gender: $gender, hash_function: $hash_function, id: $id, ims: $ims, include_in_global_address_list: $include_in_global_address_list, ip_whitelisted: $ip_whitelisted, keywords: $keywords, languages: $languages, locations: $locations, name: $name, notes: $notes, org_unit_path: $org_unit_path, organizations: $organizations, password: $password, phones: $phones, posix_accounts: $posix_accounts, primary_email: $primary_email, recovery_email: $recovery_email, recovery_phone: $recovery_phone, relations: $relations, ssh_public_keys: $ssh_public_keys, suspended: $suspended, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user. This method supports patch semantics, meaning that you only need to include the fields you wish to update. Fields that are not present in the request will be preserved, and fields set to `null` will be cleared. For repeating fields that contain arrays, individual items in the array can't be patched piecemeal; they must be supplied in the request body with the desired values for all items. See the [user accounts guide](https://developers.google.com/admin-sdk/directory/v1/guides/manage-users#update_user) for more information.
#
# PUT /admin/directory/v1/users/{userKey}
# Returns: record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>
# operationId: directory.users.update
export def "directory-users-update" [
  user_key: string
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/users/{userKey}"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: archived, var: archived}, {name: changePasswordAtNextLogin, var: change_password_at_next_login}, {name: customSchemas, var: custom_schemas}, {name: emails, var: emails}, {name: externalIds, var: external_ids}, {name: gender, var: gender}, {name: hashFunction, var: hash_function}, {name: id, var: id}, {name: ims, var: ims}, {name: includeInGlobalAddressList, var: include_in_global_address_list}, {name: ipWhitelisted, var: ip_whitelisted}, {name: keywords, var: keywords}, {name: languages, var: languages}, {name: locations, var: locations}, {name: name, var: name}, {name: notes, var: notes}, {name: orgUnitPath, var: org_unit_path}, {name: organizations, var: organizations}, {name: password, var: password}, {name: phones, var: phones}, {name: posixAccounts, var: posix_accounts}, {name: primaryEmail, var: primary_email}, {name: recoveryEmail, var: recovery_email}, {name: recoveryPhone, var: recovery_phone}, {name: relations, var: relations}, {name: sshPublicKeys, var: ssh_public_keys}, {name: suspended, var: suspended}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addresses: $addresses, archived: $archived, change_password_at_next_login: $change_password_at_next_login, custom_schemas: $custom_schemas, emails: $emails, external_ids: $external_ids, gender: $gender, hash_function: $hash_function, id: $id, ims: $ims, include_in_global_address_list: $include_in_global_address_list, ip_whitelisted: $ip_whitelisted, keywords: $keywords, languages: $languages, locations: $locations, name: $name, notes: $notes, org_unit_path: $org_unit_path, organizations: $organizations, password: $password, phones: $phones, posix_accounts: $posix_accounts, primary_email: $primary_email, recovery_email: $recovery_email, recovery_phone: $recovery_phone, relations: $relations, ssh_public_keys: $ssh_public_keys, suspended: $suspended, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all aliases for a user.
#
# GET /admin/directory/v1/users/{userKey}/aliases
# Returns: record<aliases: list<any>, etag: string, kind: string>
# operationId: directory.users.aliases.list
export def "directory-users-aliases-list" [
  user_key: string
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
  --event: string@event-completer-1 # Events to watch for.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/users/{userKey}/aliases"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: event, var: event}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an alias.
#
# POST /admin/directory/v1/users/{userKey}/aliases
# Returns: record<alias: string, etag: string, id: string, kind: string, primaryEmail: string>
# operationId: directory.users.aliases.insert
export def "directory-users-aliases-insert" [
  user_key: string
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
  --alias: string
  --etag: string
  --id: string
  --kind: string # default: admin#directory#alias
  --primary-email: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/aliases"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: alias, var: alias}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: primaryEmail, var: primary_email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, alias: $alias, etag: $etag, id: $id, kind: $kind, primary_email: $primary_email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Watches for changes in users list.
#
# POST /admin/directory/v1/users/{userKey}/aliases/watch
# Returns: record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string>
# operationId: directory.users.aliases.watch
export def "directory-users-aliases-watch" [
  user_key: string
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
  --event: string@event-completer-1 # Events to watch for.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/aliases/watch"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: event, var: event}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, event: $event, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an alias.
#
# DELETE /admin/directory/v1/users/{userKey}/aliases/{alias}
# operationId: directory.users.aliases.delete
export def "directory-users-aliases-delete" [
  user_key: string
  alias: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/users/{userKey}/aliases/{alias}"
    path_params: [{name: userKey, var: user_key}, {name: alias, var: alias}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, alias: $alias, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the ASPs issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/asps
# Returns: record<etag: string, items: table<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string>, kind: string>
# operationId: directory.asps.list
export def "directory-asps-list" [
  user_key: string
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
    path: "/admin/directory/v1/users/{userKey}/asps"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an ASP issued by a user.
#
# DELETE /admin/directory/v1/users/{userKey}/asps/{codeId}
# operationId: directory.asps.delete
export def "directory-asps-delete" [
  user_key: string
  code_id: int
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/users/{userKey}/asps/{codeId}"
    path_params: [{name: userKey, var: user_key}, {name: codeId, var: code_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, code_id: $code_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an ASP issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/asps/{codeId}
# Returns: record<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string>
# operationId: directory.asps.get
export def "directory-asps-get" [
  user_key: string
  code_id: int
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
    path: "/admin/directory/v1/users/{userKey}/asps/{codeId}"
    path_params: [{name: userKey, var: user_key}, {name: codeId, var: code_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, code_id: $code_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Makes a user a super administrator.
#
# POST /admin/directory/v1/users/{userKey}/makeAdmin
# operationId: directory.users.makeAdmin
export def "directory-users-make-admin" [
  user_key: string
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
  --status: oneof<nothing, bool> # Indicates the administrator status of the user.
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/makeAdmin"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the user's photo.
#
# DELETE /admin/directory/v1/users/{userKey}/photos/thumbnail
# operationId: directory.users.photos.delete
export def "directory-users-photos-delete" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/users/{userKey}/photos/thumbnail"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the user's photo.
#
# GET /admin/directory/v1/users/{userKey}/photos/thumbnail
# Returns: record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>
# operationId: directory.users.photos.get
export def "directory-users-photos-get" [
  user_key: string
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
    path: "/admin/directory/v1/users/{userKey}/photos/thumbnail"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a photo for the user. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/users/{userKey}/photos/thumbnail
# Returns: record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>
# operationId: directory.users.photos.patch
export def "directory-users-photos-patch" [
  user_key: string
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
  --etag: string # ETag of the resource.
  --height: int # Height of the photo in pixels. (format: int32)
  --id: string # The ID the API uses to uniquely identify the user.
  --kind: string # The type of the API resource. For Photo resources, this is `admin#directory#user#photo`. (default: admin#directory#user#photo)
  --mime-type: string # The MIME type of the photo. Allowed values are `JPEG`, `PNG`, `GIF`, `BMP`, `TIFF`, and web-safe base64 encoding.
  --photo-data: string # The user photo's upload data in [web-safe Base64](https://en.wikipedia.org/wiki/Base64#URL_applications) format in bytes. This means: * The slash (/) character is replaced with the underscore (_) character. * The plus sign (+) character is replaced with the hyphen (-) character. * The equals sign (=) character is replaced with the asterisk (*). * For padding, the period (.) character is used instead of the RFC-4648 baseURL definition which uses the equals sign (=) for padding. This is done to simplify URL-parsing. * Whatever the size of the photo being uploaded, the API downsizes it to 96x96 pixels. (format: byte)
  --primary-email: string # The user's primary email address.
  --width: int # Width of the photo in pixels. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/users/{userKey}/photos/thumbnail"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: height, var: height}, {name: id, var: id}, {name: kind, var: kind}, {name: mimeType, var: mime_type}, {name: photoData, var: photo_data}, {name: primaryEmail, var: primary_email}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, height: $height, id: $id, kind: $kind, mime_type: $mime_type, photo_data: $photo_data, primary_email: $primary_email, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a photo for the user.
#
# PUT /admin/directory/v1/users/{userKey}/photos/thumbnail
# Returns: record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int>
# operationId: directory.users.photos.update
export def "directory-users-photos-update" [
  user_key: string
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
  --etag: string # ETag of the resource.
  --height: int # Height of the photo in pixels. (format: int32)
  --id: string # The ID the API uses to uniquely identify the user.
  --kind: string # The type of the API resource. For Photo resources, this is `admin#directory#user#photo`. (default: admin#directory#user#photo)
  --mime-type: string # The MIME type of the photo. Allowed values are `JPEG`, `PNG`, `GIF`, `BMP`, `TIFF`, and web-safe base64 encoding.
  --photo-data: string # The user photo's upload data in [web-safe Base64](https://en.wikipedia.org/wiki/Base64#URL_applications) format in bytes. This means: * The slash (/) character is replaced with the underscore (_) character. * The plus sign (+) character is replaced with the hyphen (-) character. * The equals sign (=) character is replaced with the asterisk (*). * For padding, the period (.) character is used instead of the RFC-4648 baseURL definition which uses the equals sign (=) for padding. This is done to simplify URL-parsing. * Whatever the size of the photo being uploaded, the API downsizes it to 96x96 pixels. (format: byte)
  --primary-email: string # The user's primary email address.
  --width: int # Width of the photo in pixels. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/directory/v1/users/{userKey}/photos/thumbnail"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: height, var: height}, {name: id, var: id}, {name: kind, var: kind}, {name: mimeType, var: mime_type}, {name: photoData, var: photo_data}, {name: primaryEmail, var: primary_email}, {name: width, var: width}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, etag: $etag, height: $height, id: $id, kind: $kind, mime_type: $mime_type, photo_data: $photo_data, primary_email: $primary_email, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Signs a user out of all web and device sessions and reset their sign-in cookies. User will have to sign in by authenticating again.
#
# POST /admin/directory/v1/users/{userKey}/signOut
# operationId: directory.users.signOut
export def "directory-users-sign-out" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/signOut"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the set of tokens specified user has issued to 3rd party applications.
#
# GET /admin/directory/v1/users/{userKey}/tokens
# Returns: record<etag: string, items: table<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list, userKey: string>, kind: string>
# operationId: directory.tokens.list
export def "directory-tokens-list" [
  user_key: string
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
    path: "/admin/directory/v1/users/{userKey}/tokens"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all access tokens issued by a user for an application.
#
# DELETE /admin/directory/v1/users/{userKey}/tokens/{clientId}
# operationId: directory.tokens.delete
export def "directory-tokens-delete" [
  user_key: string
  client_id: string
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/directory/v1/users/{userKey}/tokens/{clientId}"
    path_params: [{name: userKey, var: user_key}, {name: clientId, var: client_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, client_id: $client_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about an access token issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/tokens/{clientId}
# Returns: record<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list<string>, userKey: string>
# operationId: directory.tokens.get
export def "directory-tokens-get" [
  user_key: string
  client_id: string
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
    path: "/admin/directory/v1/users/{userKey}/tokens/{clientId}"
    path_params: [{name: userKey, var: user_key}, {name: clientId, var: client_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, client_id: $client_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Turns off 2-Step Verification for user.
#
# POST /admin/directory/v1/users/{userKey}/twoStepVerification/turnOff
# operationId: directory.twoStepVerification.turnOff
export def "directory-two-step-verification-turn-off" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/twoStepVerification/turnOff"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undeletes a deleted user.
#
# POST /admin/directory/v1/users/{userKey}/undelete
# operationId: directory.users.undelete
export def "directory-users-undelete" [
  user_key: string
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
  --org-unit-path: string # OrgUnit of User
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/undelete"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: orgUnitPath, var: org_unit_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, org_unit_path: $org_unit_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the current set of valid backup verification codes for the specified user.
#
# GET /admin/directory/v1/users/{userKey}/verificationCodes
# Returns: record<etag: string, items: table<etag: string, kind: string, userId: string, verificationCode: string>, kind: string>
# operationId: directory.verificationCodes.list
export def "directory-verification-codes-list" [
  user_key: string
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
    path: "/admin/directory/v1/users/{userKey}/verificationCodes"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates new backup verification codes for the user.
#
# POST /admin/directory/v1/users/{userKey}/verificationCodes/generate
# operationId: directory.verificationCodes.generate
export def "directory-verification-codes-generate" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/verificationCodes/generate"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidates the current backup verification codes for the user.
#
# POST /admin/directory/v1/users/{userKey}/verificationCodes/invalidate
# operationId: directory.verificationCodes.invalidate
export def "directory-verification-codes-invalidate" [
  user_key: string
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
]: nothing -> any {
  http-request {
    method: post
    path: "/admin/directory/v1/users/{userKey}/verificationCodes/invalidate"
    path_params: [{name: userKey, var: user_key}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_key: $user_key, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a print server.
#
# DELETE /admin/directory/v1/{name}
# Returns: record
# operationId: admin.customers.chrome.printServers.delete
export def "admin-customers-chrome-print-servers-delete" [
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
    path: "/admin/directory/v1/{name}"
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

# Returns a print server's configuration.
#
# GET /admin/directory/v1/{name}
# Returns: record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>
# operationId: admin.customers.chrome.printServers.get
export def "admin-customers-chrome-print-servers-get" [
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
    path: "/admin/directory/v1/{name}"
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

# Updates a print server's configuration.
#
# PATCH /admin/directory/v1/{name}
# Returns: record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>
# operationId: admin.customers.chrome.printServers.patch
export def "admin-customers-chrome-print-servers-patch" [
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
  --update-mask: string # The list of fields to update. Some fields are read-only and cannot be updated. Values for unspecified fields are patched.
  --description: string # Editable. Description of the print server (as shown in the Admin console).
  --display-name: string # Editable. Display name of the print server (as shown in the Admin console).
  --id: string # Immutable. ID of the print server. Leave empty when creating.
  --body-name: string # Immutable. Resource name of the print server. Leave empty when creating. Format: `customers/{customer.id}/printServers/{print_server.id}` (spec name: name)
  --org-unit-id: string # ID of the organization unit (OU) that owns this print server. This value can only be set when the print server is initially created. If it's not populated, the print server is placed under the root OU. The `org_unit_id` can be retrieved using the [Directory API](/admin-sdk/directory/reference/rest/v1/orgunits).
  --uri: string # Editable. Print server URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/admin/directory/v1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: id, var: id}, {name: name, var: body_name}, {name: orgUnitId, var: org_unit_id}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, description: $description, display_name: $display_name, id: $id, body_name: $body_name, org_unit_id: $org_unit_id, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists print server configurations.
#
# GET /admin/directory/v1/{parent}/chrome/printServers
# Returns: record<nextPageToken: string, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>>
# operationId: admin.customers.chrome.printServers.list
export def "admin-customers-chrome-print-servers-list" [
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
  --filter: string # Search query in [Common Expression Language syntax](https://github.com/google/cel-spec). Supported filters are `display_name`, `description`, and `uri`. Example: `printServer.displayName=='marketing-queue'`.
  --order-by: string # Sort order for results. Supported values are `display_name`, `description`, or `create_time`. Default order is ascending, but descending order can be returned by appending "desc" to the `order_by` field. For instance, `orderBy=='description desc'` returns the print servers sorted by description in descending order.
  --org-unit-id: string # If `org_unit_id` is present in the request, only print servers owned or inherited by the organizational unit (OU) are returned. If the `PrintServer` resource's `org_unit_id` matches the one in the request, the OU owns the server. If `org_unit_id` is not specified in the request, all print servers are returned or filtered against.
  --page-size: int # The maximum number of objects to return (default `100`, max `100`). The service might return fewer than this value.
  --page-token: string # A generated token to paginate results (the `next_page_token` from a previous call).
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/{parent}/chrome/printServers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: orgUnitId, var: org_unit_id}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, org_unit_id: $org_unit_id, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a print server.
#
# POST /admin/directory/v1/{parent}/chrome/printServers
# Returns: record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>
# operationId: admin.customers.chrome.printServers.create
export def "admin-customers-chrome-print-servers-create" [
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
  --description: string # Editable. Description of the print server (as shown in the Admin console).
  --display-name: string # Editable. Display name of the print server (as shown in the Admin console).
  --id: string # Immutable. ID of the print server. Leave empty when creating.
  --name: string # Immutable. Resource name of the print server. Leave empty when creating. Format: `customers/{customer.id}/printServers/{print_server.id}`
  --org-unit-id: string # ID of the organization unit (OU) that owns this print server. This value can only be set when the print server is initially created. If it's not populated, the print server is placed under the root OU. The `org_unit_id` can be retrieved using the [Directory API](/admin-sdk/directory/reference/rest/v1/orgunits).
  --uri: string # Editable. Print server URI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printServers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: id, var: id}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, display_name: $display_name, id: $id, name: $name, org_unit_id: $org_unit_id, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates multiple print servers.
#
# POST /admin/directory/v1/{parent}/chrome/printServers:batchCreatePrintServers
# Returns: record<failures: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>>
# operationId: admin.customers.chrome.printServers.batchCreatePrintServers
export def "admin-customers-chrome-print-servers-batch-create-print-servers" [
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
  --requests: list # Required. A list of `PrintServer` resources to be created (max `50` per batch). — item shape: {parent?: string, printServer?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printServers:batchCreatePrintServers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: requests, var: requests}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, requests: $requests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes multiple print servers.
#
# POST /admin/directory/v1/{parent}/chrome/printServers:batchDeletePrintServers
# Returns: record<failedPrintServers: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServerIds: list<string>>
# operationId: admin.customers.chrome.printServers.batchDeletePrintServers
export def "admin-customers-chrome-print-servers-batch-delete-print-servers" [
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
  --print-server-ids: list<string> # A list of print server IDs that should be deleted (max `100` per batch).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printServers:batchDeletePrintServers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: printServerIds, var: print_server_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, print_server_ids: $print_server_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List printers configs.
#
# GET /admin/directory/v1/{parent}/chrome/printers
# Returns: record<nextPageToken: string, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>>
# operationId: admin.customers.chrome.printers.list
export def "admin-customers-chrome-printers-list" [
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
  --filter: string # Search query. Search syntax is shared between this api and Admin Console printers pages.
  --order-by: string # The order to sort results by. Must be one of display_name, description, make_and_model, or create_time. Default order is ascending, but descending order can be returned by appending "desc" to the order_by field. For instance, "description desc" will return the printers sorted by description in descending order.
  --org-unit-id: string # Organization Unit that we want to list the printers for. When org_unit is not present in the request then all printers of the customer are returned (or filtered). When org_unit is present in the request then only printers available to this OU will be returned (owned or inherited). You may see if printer is owned or inherited for this OU by looking at Printer.org_unit_id.
  --page-size: int # The maximum number of objects to return. The service may return fewer than this value.
  --page-token: string # A page token, received from a previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/{parent}/chrome/printers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: orgUnitId, var: org_unit_id}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, order_by: $order_by, org_unit_id: $org_unit_id, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a printer under given Organization Unit.
#
# POST /admin/directory/v1/{parent}/chrome/printers
# Returns: record<auxiliaryMessages: table<auxiliaryMessage: string, fieldMask: string, severity: string>, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>
# operationId: admin.customers.chrome.printers.create
export def "admin-customers-chrome-printers-create" [
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
  --description: string # Editable. Description of printer.
  --display-name: string # Editable. Name of printer.
  --id: string # Id of the printer. (During printer creation leave empty)
  --make-and-model: string # Editable. Make and model of printer. e.g. Lexmark MS610de Value must be in format as seen in ListPrinterModels response.
  --name: string # The resource name of the Printer object, in the format customers/{customer-id}/printers/{printer-id} (During printer creation leave empty)
  --org-unit-id: string # Organization Unit that owns this printer (Only can be set during Printer creation)
  --uri: string # Editable. Printer URI.
  --use-driverless-config: oneof<nothing, bool> # Editable. flag to use driverless configuration or not. If it's set to be true, make_and_model can be ignored
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: id, var: id}, {name: makeAndModel, var: make_and_model}, {name: name, var: name}, {name: orgUnitId, var: org_unit_id}, {name: uri, var: uri}, {name: useDriverlessConfig, var: use_driverless_config}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, display_name: $display_name, id: $id, make_and_model: $make_and_model, name: $name, org_unit_id: $org_unit_id, uri: $uri, use_driverless_config: $use_driverless_config
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates printers under given Organization Unit.
#
# POST /admin/directory/v1/{parent}/chrome/printers:batchCreatePrinters
# Returns: record<failures: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>>
# operationId: admin.customers.chrome.printers.batchCreatePrinters
export def "admin-customers-chrome-printers-batch-create-printers" [
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
  --requests: list # A list of Printers to be created. Max 50 at a time. — item shape: {parent?: string, printer?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printers:batchCreatePrinters"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: requests, var: requests}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, requests: $requests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes printers in batch.
#
# POST /admin/directory/v1/{parent}/chrome/printers:batchDeletePrinters
# Returns: record<failedPrinters: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printerIds: list<string>>
# operationId: admin.customers.chrome.printers.batchDeletePrinters
export def "admin-customers-chrome-printers-batch-delete-printers" [
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
  --printer-ids: list<string> # A list of Printer.id that should be deleted. Max 100 at a time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/directory/v1/{parent}/chrome/printers:batchDeletePrinters"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: printerIds, var: printer_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, printer_ids: $printer_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the supported printer models.
#
# GET /admin/directory/v1/{parent}/chrome/printers:listPrinterModels
# Returns: record<nextPageToken: string, printerModels: table<displayName: string, makeAndModel: string, manufacturer: string>>
# operationId: admin.customers.chrome.printers.listPrinterModels
export def "admin-customers-chrome-printers-list-printer-models" [
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
  --filter: string # Filer to list only models by a given manufacturer in format: "manufacturer:Brother". Search syntax is shared between this api and Admin Console printers pages.
  --page-size: int # The maximum number of objects to return. The service may return fewer than this value.
  --page-token: string # A page token, received from a previous call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/admin/directory/v1/{parent}/chrome/printers:listPrinterModels"
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

# Stops watching resources through this channel.
#
# POST /admin/directory_v1/channels/stop
# operationId: admin.channels.stop
export def "admin-channels-stop" [
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
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional. (spec name: token)
  --type: string # The type of delivery mechanism used for this channel.
]: any -> any {
  $in | http-request {
    method: post
    path: "/admin/directory_v1/channels/stop"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: expiration, var: expiration}, {name: id, var: id}, {name: kind, var: kind}, {name: params, var: params}, {name: payload, var: payload}, {name: resourceId, var: resource_id}, {name: resourceUri, var: resource_uri}, {name: token, var: body_token}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, address: $address, expiration: $expiration, id: $id, kind: $kind, params: $params, payload: $payload, resource_id: $resource_id, resource_uri: $resource_uri, body_token: $body_token, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
